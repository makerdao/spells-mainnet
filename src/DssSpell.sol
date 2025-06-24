// SPDX-FileCopyrightText: © 2020 Dai Foundation <www.daifoundation.org>
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

pragma solidity 0.8.16;

// import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

import {GemAbstract} from "dss-interfaces/ERC/GemAbstract.sol";
import {VestAbstract} from "dss-interfaces/dss/VestAbstract.sol";

// Import init scripts and structs from dependencies
import {StakingRewardsInit, StakingRewardsInitParams} from "./dependencies/endgame-toolkit/StakingRewardsInit.sol";
import {VestInit, VestCreateParams} from "./dependencies/endgame-toolkit/VestInit.sol";
import {VestedRewardsDistributionInit, VestedRewardsDistributionInitParams} from "./dependencies/endgame-toolkit/VestedRewardsDistributionInit.sol";

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

interface PauseLike {
    function delay() external view returns (uint256);
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
    function plot(address, bytes32, bytes calldata, uint256) external;
}

interface ChainlogLike {
    function getAddress(bytes32) external view returns (address);
}

interface SpellActionLike {
    function officeHours() external view returns (bool);
    function description() external view returns (string memory);
    function nextCastTime(uint256) external view returns (uint256);
}

interface VestedRewardsDistributionLike {
    function distribute() external;
}

interface VestedRewardsDistributionJobLike {
    function set(address dist, uint256 period) external;
}

interface LockstakeEngineLike {
    function addFarm(address farm) external;
}

interface MkrSkyLike {
    function mkrToSky(address usr, uint256 mkrAmt) external;
}

contract DssExec {
    ChainlogLike  constant public   chainlog = ChainlogLike(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    uint256                public   eta;
    bytes                  public   sig;
    bool                   public   done;
    bytes32      immutable public   tag;
    address      immutable public   action;
    uint256      immutable public   expiration;
    PauseLike    immutable public   pause;

    // 2025-06-30T14:00:00Z
    uint256       constant internal JUN_30_2025_14_00_UTC = 1751292000;
    uint256       constant public   MIN_ETA               = JUN_30_2025_14_00_UTC;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://<executive-vote-canonical-post> -q -O - 2>/dev/null)"
    function description() external view returns (string memory) {
        return SpellActionLike(action).description();
    }

    function officeHours() external view returns (bool) {
        return SpellActionLike(action).officeHours();
    }

    function nextCastTime() external view returns (uint256 castTime) {
        return SpellActionLike(action).nextCastTime(eta);
    }

    // @param _description  A string description of the spell
    // @param _expiration   The timestamp this spell will expire. (Ex. block.timestamp + 30 days)
    // @param _spellAction  The address of the spell action
    constructor(uint256 _expiration, address _spellAction) {
        pause       = PauseLike(chainlog.getAddress("MCD_PAUSE"));
        expiration  = _expiration;
        action      = _spellAction;

        sig = abi.encodeWithSignature("execute()");
        bytes32 _tag;                    // Required for assembly access
        address _action = _spellAction;  // Required for assembly access
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
        require(block.timestamp <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        // ---------- Set earliest execution date June 30, 14:00 UTC ----------
        // Forum: TODO
        // Poll: TODO
        // Note: In case the spell is scheduled later than planned, we have to switch
        //       back to the regular logic to respect GSM delay enforced by MCD_PAUSE
        eta = _max(block.timestamp + PauseLike(pause).delay(), MIN_ETA);
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description = "2025-06-26 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

        // ---------- Rates ----------
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // uint256 internal constant X_PCT_RATE = ;

    // ---------- Contracts ----------
    address internal immutable MCD_VAT               = DssExecLib.vat();
    address internal immutable MCD_PAUSE_PROXY       = DssExecLib.pauseProxy();
    address internal immutable USDS                  = DssExecLib.getChangelogAddress("USDS");
    address internal immutable LSSKY                 = DssExecLib.getChangelogAddress("LOCKSTAKE_SKY");
    address internal immutable CRON_REWARDS_DIST_JOB = DssExecLib.getChangelogAddress("CRON_REWARDS_DIST_JOB");
    address internal immutable LOCKSTAKE_ENGINE      = DssExecLib.getChangelogAddress("LOCKSTAKE_ENGINE");
    address internal immutable MKR_SKY               = DssExecLib.getChangelogAddress("MKR_SKY");
    address internal immutable MCD_VEST_MKR_TREASURY = DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY");
    address internal immutable MKR                   = DssExecLib.getChangelogAddress("MKR");

    address internal constant SPK                    = 0xc20059e0317DE91738d13af027DfC4a50781b066;
    address internal constant MCD_VEST_SPK_TREASURY  = 0xF9A2002b471f600A5484da5a735a2A053d377078;
    address internal constant REWARDS_USDS_SPK       = 0x173e314C7635B45322cd8Cb14f44b312e079F3af;
    address internal constant REWARDS_DIST_USDS_SPK  = 0x3959e23A63CA7ac12D658bb44F90cb1f7Ee4C02c;
    address internal constant REWARDS_LSSKY_SPK      = 0x99cBC0e4E6427F6939536eD24d1275B95ff77404;
    address internal constant REWARDS_DIST_LSSKY_SPK = 0xa3Ee378BdD0b7DD403cEd3a0A65B2B389A2eaB7e;

    // ---------- Math ----------
    uint256 internal constant WAD = 10 ** 18;

    // ---------- Execute Spark Proxy Spell ----------
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = address(0);

    function actions() public override {

        // ---------- SPK Farms ----------
        // Forum: https://forum.sky.money/t/technical-scope-of-spk-farms/26703
        // Atlas: https://sky-atlas.powerhouse.io/A.2.9.1.2.2.1.2.2.2_Spark_Token_Reward_Distribution_Schedule/1fef2ff0-8d73-809d-ac41-eb9753c05d41|9e1f80092582d59891b002d4366698bb

        // ---------- Initialize the SPK vest: ----------

        // Approve MCD_VEST_SPK_TREASURY to spend SPK in the treasury:
        // spender: 0xF9A2002b471f600A5484da5a735a2A053d377078
        // amount: 3_250_000_000 * WAD
        GemAbstract(SPK).approve(MCD_VEST_SPK_TREASURY, 3_250_000_000 * WAD);

        // Set cap in MCD_VEST_SPK_TREASURY:
        // target: 0xF9A2002b471f600A5484da5a735a2A053d377078
        // what: "cap"
        // amt: 2_502_500_000 * WAD / 730 days
        DssExecLib.setValue(MCD_VEST_SPK_TREASURY, "cap", 2_502_500_000 * WAD / 730 days);

        // Add MCD_VEST_SPK_TREASURY to the Chainlog:
        // key: "MCD_VEST_SPK_TREASURY"
        // addr: 0xF9A2002b471f600A5484da5a735a2A053d377078
        DssExecLib.setChangelogAddress("MCD_VEST_SPK_TREASURY", MCD_VEST_SPK_TREASURY);

        // Add SPK to the Chainlog:
        // key: "SPK"
        // addr: 0xC20059E0317De91738D13Af027DfC4a50781b066
        DssExecLib.setChangelogAddress("SPK", SPK);

        // ---------- USDS to SPK Farm ----------

        // Initialize the USDS to SPK farm:
        // Create the vesting stream for the USDS to SPK farm:
        // vest: 0xF9A2002b471f600A5484da5a735a2A053d377078
        // p.usr: 0x3959e23A63CA7ac12D658bb44F90cb1f7Ee4C02c
        // p.tot: 2_275_000_000 * WAD
        // p.bgn: block.timestamp - 7 days
        // p.tau: 730 days
        // p.eta: 0
        // restricted: true
        uint256 vestIdUsdsSpk = VestInit.create(
            MCD_VEST_SPK_TREASURY,
            VestCreateParams({
                usr: REWARDS_DIST_USDS_SPK,
                tot: 2_275_000_000 * WAD,
                bgn: block.timestamp - 7 days,
                tau: 730 days,
                eta: 0
            })
        );

        // Initialize REWARDS_USDS_SPK:
        // rewards: 0x173e314C7635B45322cd8Cb14f44b312e079F3af
        // p.dist: 0x3959e23A63CA7ac12D658bb44F90cb1f7Ee4C02c
        // duration: 7 days
        StakingRewardsInit.init(
            REWARDS_USDS_SPK,
            StakingRewardsInitParams({ dist: REWARDS_DIST_USDS_SPK })
        );

        // Initialize REWARDS_DIST_USDS_SPK:
        // dist: 0x3959e23A63CA7ac12D658bb44F90cb1f7Ee4C02c
        // p.vestId: {vestIdUsdsSpk}
        VestedRewardsDistributionInit.init(
            REWARDS_DIST_USDS_SPK,
            VestedRewardsDistributionInitParams({ vestId: vestIdUsdsSpk })
        );

        // Call distribute() on REWARDS_DIST_USDS_SPK
        VestedRewardsDistributionLike(REWARDS_DIST_USDS_SPK).distribute();

        // Add REWARDS_DIST_USDS_SPK to CRON_REWARDS_DIST_JOB:
        // dist: 0x3959e23A63CA7ac12D658bb44F90cb1f7Ee4C02c
        // period: 7 days - 1 hours
        VestedRewardsDistributionJobLike(CRON_REWARDS_DIST_JOB).set(REWARDS_DIST_USDS_SPK, 7 days - 1 hours);

        // Add REWARDS_USDS_SPK and REWARDS_DIST_USDS_SPK to the Chainlog:
        // key: "REWARDS_USDS_SPK"
        // addr: 0x173e314C7635B45322cd8Cb14f44b312e079F3af
        // key: "REWARDS_DIST_USDS_SPK"
        // addr: 0x3959e23A63CA7ac12D658bb44F90cb1f7Ee4C02c
        DssExecLib.setChangelogAddress("REWARDS_USDS_SPK", REWARDS_USDS_SPK);
        DssExecLib.setChangelogAddress("REWARDS_DIST_USDS_SPK", REWARDS_DIST_USDS_SPK);

        // ---------- LSSKY to SPK Farm ----------
        // Initialize the LSSKY to SPK farm:
        // Create the vesting stream for the LSSKY to SPK farm:
        // vest: 0xF9A2002b471f600A5484da5a735a2A053d377078
        // p.usr: 0xa3Ee378BdD0b7DD403cEd3a0A65B2B389A2eaB7e
        // p.tot: 975_000_000 * WAD
        // p.bgn: block.timestamp - 7 days
        // p.tau: 730 days
        // p.eta: 0
        // restricted: true
        uint256 vestIdLsskySpk = VestInit.create(
            MCD_VEST_SPK_TREASURY,
            VestCreateParams({
                usr: REWARDS_DIST_LSSKY_SPK,
                tot: 975_000_000 * WAD,
                bgn: block.timestamp - 7 days,
                tau: 730 days,
                eta: 0
            })
        );

        // Initialize REWARDS_LSSKY_SPK:
        // rewards: 0x99cBC0e4E6427F6939536eD24d1275B95ff77404
        // p.dist: 0xa3Ee378BdD0b7DD403cEd3a0A65B2B389A2eaB7e
        // duration: 7 days
        StakingRewardsInit.init(
            REWARDS_LSSKY_SPK,
            StakingRewardsInitParams({ dist: REWARDS_DIST_LSSKY_SPK })
        );

        // Initialize REWARDS_DIST_LSSKY_SPK:
        // dist: 0xa3Ee378BdD0b7DD403cEd3a0A65B2B389A2eaB7e
        // p.vestId: vestIdLsskySpk
        VestedRewardsDistributionInit.init(
            REWARDS_DIST_LSSKY_SPK,
            VestedRewardsDistributionInitParams({ vestId: vestIdLsskySpk })
        );

        // Call distribute() on REWARDS_DIST_LSSKY_SPK
        VestedRewardsDistributionLike(REWARDS_DIST_LSSKY_SPK).distribute();

        // Add REWARDS_DIST_LSSKY_SPK to CRON_REWARDS_DIST_JOB:
        // dist: 0xa3Ee378BdD0b7DD403cEd3a0A65B2B389A2eaB7e
        // period: 7 days - 1 hours
        VestedRewardsDistributionJobLike(CRON_REWARDS_DIST_JOB).set(REWARDS_DIST_LSSKY_SPK, 7 days - 1 hours);

        // Add REWARDS_LSSKY_SPK farm to the Lockstake Engine:
        // farm: 0x99cBC0e4E6427F6939536eD24d1275B95ff77404
        LockstakeEngineLike(LOCKSTAKE_ENGINE).addFarm(REWARDS_LSSKY_SPK);

        // Add REWARDS_LSSKY_SPK and REWARDS_DIST_LSSKY_SPK to the Chainlog:
        // key: "REWARDS_LSSKY_SPK"
        // addr: 0x99cBC0e4E6427F6939536eD24d1275B95ff77404
        // key: "REWARDS_DIST_LSSKY_SPK"
        // addr: 0xa3Ee378BdD0b7DD403cEd3a0A65B2B389A2eaB7e
        DssExecLib.setChangelogAddress("REWARDS_LSSKY_SPK", REWARDS_LSSKY_SPK);
        DssExecLib.setChangelogAddress("REWARDS_DIST_LSSKY_SPK", REWARDS_DIST_LSSKY_SPK);

        // ---------- Convert MKR balance of the PauseProxy to SKY ----------
        // Forum: https://forum.sky.money/t/phase-3-mkr-to-sky-migration-items-june-26-spell/26710
        // Atlas: https://sky-atlas.powerhouse.io/A.4.1.2.1.4.2.3_Upgrade_MKR_In_Pause_Proxy_To_SKY/1f1f2ff0-8d73-8064-ab0e-d51c96127c19|b341f4c0b83472dc1f9e1a3b

        // Note: get unpaid MKR for MCD_VEST_MKR_TREASURY id 39
        uint256 unpaidMkr = VestAbstract(MCD_VEST_MKR_TREASURY).unpaid(39);
        // Note: approve MKR_SKY to spend MKR balance of the PauseProxy
        GemAbstract(MKR).approve(MKR_SKY, GemAbstract(MKR).balanceOf(address(this)) - unpaidMkr);
        // Call mkrToSky() on MKR_SKY with the MKR balance of the PauseProxy minus the unpaid() MKR for MCD_VEST_MKR_TREASURY id 39
        MkrSkyLike(MKR_SKY).mkrToSky(address(this), GemAbstract(MKR).balanceOf(address(this)) - unpaidMkr);

        // Note: bump chainlog version because of new contracts being added
        DssExecLib.setChangelogVersion("1.20.2");

        // ---------- Execute Spark Proxy Spell ----------
        // Forum: TODO
        // Poll: TODO

        // Execute Spark Proxy Spell at address TODO
        // ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
