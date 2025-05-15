// SPDX-FileCopyrightText: © 2025 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

import { DssInstance } from "dss-test/MCD.sol";
import { SkyInit } from "../sky/SkyInit.sol";
import { LockstakeInit, LockstakeConfig } from "../lockstake/LockstakeInit.sol";
import { StakingRewardsInit, StakingRewardsInitParams } from "../endgame-toolkit/StakingRewardsInit.sol";
import { MigrationInstance } from "./MigrationInstance.sol";

interface ChiefLike {
    function gov() external view returns (address);
    function maxYays() external view returns (uint256);
    function launchThreshold() external view returns (uint256);
    function liftCooldown() external view returns (uint256);
}

interface VoteDelegateFactoryLike {
    function chief() external view returns (address);
    function polling() external view returns (address);
}

interface OsmLike {
    function src() external view returns (address);
}

interface StakingRewardsLike {
    function stakingToken() external view returns (address);
    function rewardsToken() external view returns (address);
    function setRewardsDuration(uint256) external;
}

interface AuthedLike {
    function setAuthority(address) external;
}

interface MkrSkyLike {
    function rate() external view returns (uint256);
}

interface FlapperLike {
    function file(bytes32, address) external;
}

interface SplitterLike {
    function file(bytes32, address) external;
}

interface VowLike {
    function file(bytes32, uint256) external;
}

interface EsmLike {
    function file(bytes32, uint256) external;
}

struct MigrationConfig {
    uint256 maxYays;
    uint256 launchThreshold;
    uint256 liftCooldown;
    address skyOracle;
    uint256 rewardsDuration;
    LockstakeConfig lockstakeConfig;
}

library MigrationInit {
    function initMigration(
        DssInstance       memory dss,
        MigrationInstance memory inst,
        MigrationConfig   memory cfg
    ) internal {
        address sky = dss.chainlog.getAddress("SKY");

        // Sanity checks
        require(ChiefLike(inst.chief).gov()             == sky);
        require(ChiefLike(inst.chief).maxYays()         == cfg.maxYays);
        require(ChiefLike(inst.chief).launchThreshold() == cfg.launchThreshold);
        require(ChiefLike(inst.chief).liftCooldown()    == cfg.liftCooldown);

        require(VoteDelegateFactoryLike(inst.voteDelegateFactory).chief()   == inst.chief);
        require(VoteDelegateFactoryLike(inst.voteDelegateFactory).polling() == VoteDelegateFactoryLike(dss.chainlog.getAddress("VOTE_DELEGATE_FACTORY")).polling());

        require(OsmLike(inst.skyOsm).src() == cfg.skyOracle);

        require(StakingRewardsLike(inst.lsskyUsdsFarm).stakingToken() == inst.lockstakeInstance.lssky);
        require(StakingRewardsLike(inst.lsskyUsdsFarm).rewardsToken() == dss.chainlog.getAddress("USDS"));

        // Chief migration
        // Note: this list does not include the Spark FREEZER_MOM, which authority should be changed in a Spark sub-spell
        AuthedLike(dss.chainlog.getAddress("MCD_PAUSE")).setAuthority(inst.chief);
        AuthedLike(dss.chainlog.getAddress("SPLITTER_MOM")).setAuthority(inst.chief);
        AuthedLike(dss.chainlog.getAddress("OSM_MOM")).setAuthority(inst.chief);
        AuthedLike(dss.chainlog.getAddress("CLIPPER_MOM")).setAuthority(inst.chief);
        AuthedLike(dss.chainlog.getAddress("DIRECT_MOM")).setAuthority(inst.chief);
        AuthedLike(dss.chainlog.getAddress("STARKNET_ESCROW_MOM")).setAuthority(inst.chief);
        AuthedLike(dss.chainlog.getAddress("LINE_MOM")).setAuthority(inst.chief);
        AuthedLike(dss.chainlog.getAddress("LITE_PSM_MOM")).setAuthority(inst.chief);
        AuthedLike(dss.chainlog.getAddress("SPBEAM_MOM")).setAuthority(inst.chief);
        dss.chainlog.setAddress("MCD_ADM", inst.chief);

        // New VoteDelegate factory (must be done before initLockstake)
        dss.chainlog.setAddress("VOTE_DELEGATE_FACTORY_LEGACY", dss.chainlog.getAddress("VOTE_DELEGATE_FACTORY"));
        dss.chainlog.setAddress("VOTE_DELEGATE_FACTORY", inst.voteDelegateFactory);

        // New MKR to SKY migrator (must be done before initLockstake)
        SkyInit.updateMkrSky(dss, inst.mkrSky);

        // Set the new SKY oracle in the flapper
        // Note: we assume the current flapper is given permission to read from the oracle
        FlapperLike(dss.chainlog.getAddress("MCD_FLAP")).file("pip", cfg.skyOracle);
        dss.chainlog.setAddress("FLAP_SKY_ORACLE", cfg.skyOracle);

        // New SKY OSM (must be done before initLockstake)
        // Note: we assume the OSM is given permission to read from the oracle
        // Note: the rest of the OSM setup is done in initLockstake below
        // Note: PIP_MKR is still used in the old lockstake, so we don't remove it yet from the chainlog
        dss.chainlog.setAddress("PIP_SKY", inst.skyOsm);

        // Init new farm to be used in lockstake
        // Note: we assume that if splitter.burn, splitter.hop, vow.bump or vow.hump are modified it is done outside this lib
        // Note: we assume cfg.rewardsDuration to be same as the final value of splitter.hop for the spell
        address splitter = dss.chainlog.getAddress("MCD_SPLIT");
        StakingRewardsInit.init(inst.lsskyUsdsFarm, StakingRewardsInitParams({dist: splitter}));
        StakingRewardsLike(inst.lsskyUsdsFarm).setRewardsDuration(cfg.rewardsDuration);
        SplitterLike(splitter).file("farm", inst.lsskyUsdsFarm);
        dss.chainlog.setAddress("REWARDS_LSSKY_USDS", inst.lsskyUsdsFarm);
        dss.chainlog.setAddress("REWARDS_LSMKR_USDS_LEGACY", dss.chainlog.getAddress("REWARDS_LSMKR_USDS"));
        dss.chainlog.removeAddress("REWARDS_LSMKR_USDS");

        // Lockstake Migration
        LockstakeInit.initLockstake(dss, inst.lockstakeInstance, cfg.lockstakeConfig);

        // MKR flops are turned off
        VowLike(dss.chainlog.getAddress("MCD_VOW")).file("sump", type(uint256).max);

        // ESM full disablement
        EsmLike(dss.chainlog.getAddress("MCD_ESM")).file("min", type(uint256).max);

        // Handle more chainlog keys (should be done last as MCD_GOV is assumed as MKR above)
        dss.chainlog.setAddress("MKR", dss.chainlog.getAddress("MCD_GOV"));
        dss.chainlog.setAddress("MCD_GOV", sky);
        dss.chainlog.removeAddress("MCD_GOV_ACTIONS");
        dss.chainlog.setAddress("MKR_GUARD", dss.chainlog.getAddress("GOV_GUARD"));
        dss.chainlog.removeAddress("GOV_GUARD");
    }
}
