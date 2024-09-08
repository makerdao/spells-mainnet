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
import { MCD, DssInstance } from "dss-test/MCD.sol";

import { UsdsInit } from "./dependencies/01-usds/UsdsInit.sol";
import { UsdsInstance } from "./dependencies/01-usds/UsdsInstance.sol";

import { SUsdsInit, SUsdsConfig } from "./dependencies/02-susds/SUsdsInit.sol";
import { SUsdsInstance } from "./dependencies/02-susds/SUsdsInstance.sol";

import { SkyInit } from "./dependencies/03-sky/SkyInit.sol";
import { SkyInstance } from "./dependencies/03-sky/SkyInstance.sol";

import { UniV2PoolMigratorInit } from "./dependencies/04-univ2-pool-migrator/UniV2PoolMigratorInit.sol";

import { FlapperInit, SplitterConfig, FlapperUniV2Config } from "./dependencies/05-flapper/FlapperInit.sol";
import { SplitterInstance } from "./dependencies/05-flapper/SplitterInstance.sol";

import { UsdsSkyFarmingInit, UsdsSkyFarmingInitParams } from "./dependencies/06-farm/phase-1b/UsdsSkyFarmingInit.sol";
import { Usds01PreFarmingInit, Usds01PreFarmingInitParams } from "./dependencies/06-farm/phase-1b/Usds01PreFarmingInit.sol";

import {
    VestedRewardsDistributionJobInit,
    VestedRewardsDistributionJobInitConfig,
    VestedRewardsDistributionJobSetDistConfig
} from "./dependencies/07-cron/VestedRewardsDistributionJobInit.sol";

interface PauseLike {
    function delay() external view returns (uint256);
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function setDelay(uint256) external;
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

contract DssExec {
    ChainlogLike  constant public   chainlog = ChainlogLike(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    uint256                public   eta;
    bytes                  public   sig;
    bool                   public   done;
    bytes32      immutable public   tag;
    address      immutable public   action;
    uint256      immutable public   expiration;
    PauseLike    immutable public   pause;

    uint256       constant internal SEP_17_2024_NOON_UTC = 1726574400; // 2024-09-17T12:00:00Z
    uint256       constant public   MIN_ETA              = SEP_17_2024_NOON_UTC;

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
        // Set earliest execution date September 17, 12:00 UTC
        // Note: In case the spell is scheduled later than planned, we have to switch back to the regular logic to
        //       respect GSM delay enforced by MCD_PAUSE
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
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/3c1ea8b373f3fc30885619ddcc8ee7aa2be0030a/governance/votes/Executive%20vote%20-%20September%205%2C%202024.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-09-13 MakerDAO Executive Spell | Hash: TODO";

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
    uint256 internal constant SIX_PT_TWO_FIVE_PCT_RATE = 1000000001922394148741344865;

    // ---------- Math ----------
    uint256 internal constant THOUSAND = 10**3;
    uint256 internal constant MILLION  = 10**6;
    uint256 internal constant WAD      = 10**18;
    uint256 internal constant RAD      = 10**45;

    // ---------- Phase 1b Addresses ----------

    address internal constant USDS                         = 0xdC035D45d973E3EC169d2276DDab16f1e407384F;
    address internal constant USDS_IMP                     = 0x1923DfeE706A8E78157416C29cBCCFDe7cdF4102;
    address internal constant USDS_JOIN                    = 0x3C0f895007CA717Aa01c8693e59DF1e8C3777FEB;
    address internal constant DAI_USDS                     = 0x3225737a9Bbb6473CB4a45b7244ACa2BeFdB276A;
    address internal constant SUSDS                        = 0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD;
    address internal constant SUSDS_IMP                    = 0x4e7991e5C547ce825BdEb665EE14a3274f9F61e0;
    address internal constant SKY                          = 0x56072C95FAA701256059aa122697B133aDEd9279;
    address internal constant MKR_SKY                      = 0xBDcFCA946b6CDd965f99a839e4435Bcdc1bc470B;
    address internal constant PAIR_DAI_MKR                 = 0x517F9dD285e75b599234F7221227339478d0FcC8;
    address internal constant PAIR_USDS_SKY                = 0x2621CC0B3F3c079c1Db0E80794AA24976F0b9e3c;
    address internal constant MCD_SPLIT                    = 0xBF7111F13386d23cb2Fba5A538107A73f6872bCF;
    address internal constant SPLITTER_MOM                 = 0xF51a075d468dE7dE3599C1Dc47F5C42d02C9230e;
    address internal constant MCD_FLAP                     = 0xc5A9CaeBA70D6974cBDFb28120C3611Dd9910355;
    address internal constant FLAP_SKY_ORACLE              = 0x38e8c1D443f546Dc014D7756ec63116161CB7B25;
    address internal constant MCD_VEST_SKY                 = 0xB313Eab3FdE99B2bB4bA9750C2DDFBe2729d1cE9;
    address internal constant REWARDS_USDS_SKY             = 0x0650CAF159C5A49f711e8169D4336ECB9b950275;
    address internal constant REWARDS_DIST_USDS_SKY        = 0x2F0C88e935Db5A60DDA73b0B4EAEef55883896d9;
    address internal constant REWARDS_USDS_01              = 0x10ab606B067C9C461d8893c47C7512472E19e2Ce;
    address internal constant CRON_REWARDS_DIST_JOB        = 0x6464C34A02DD155dd0c630CE233DD6e21C24F9A5;
    address internal constant WRAPPER_USDS_LITE_PSM_USDC_A = 0xA188EEC8F81263234dA3622A406892F3D630f98c;

    // ---------- MCD Addresses ----------
    address internal MCD_PAUSE = DssExecLib.getChangelogAddress("MCD_PAUSE");

    function actions() public override {

        // Note: load the MCD contracts depencencies
        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);

        // ---------- New Tokens Init ----------
        // Forum: TODO
        // Poll: TODO
        // MIP: TODO

        // Init USDS by calling UsdsInit.init with the following parameters:
        // Init USDS with usds parameter being 0xdC035D45d973E3EC169d2276DDab16f1e407384F
        // Init USDS with usdsImp parameter being 0x1923DfeE706A8E78157416C29cBCCFDe7cdF4102
        // Init USDS with UsdsJoin parameter being 0x3C0f895007CA717Aa01c8693e59DF1e8C3777FEB
        // Init USDS with DaiUsds parameter being 0x3225737a9Bbb6473CB4a45b7244ACa2BeFdB276A
        UsdsInit.init(
            dss,
            UsdsInstance({
                usds: USDS,
                usdsImp: USDS_IMP,
                usdsJoin: USDS_JOIN,
                daiUsds: DAI_USDS
            })
        );

        // Init sUSDS by calling SUsdsInit.init with the following parameters:
        // Init sUSDS with sUsds parameter being 0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD
        // Init sUSDS with sUsdsImp parameter being 0x4e7991e5C547ce825BdEb665EE14a3274f9F61e0
        // Init sUSDS with usdsJoin parameter being 0x3C0f895007CA717Aa01c8693e59DF1e8C3777FEB
        // Init sUSDS with usds parameter being 0xdC035D45d973E3EC169d2276DDab16f1e407384F
        // Init sUSDS with ssr parameter being 6.25%
        SUsdsInit.init(
            dss,
            SUsdsInstance({
                sUsds: SUSDS,
                sUsdsImp: SUSDS_IMP
            }),
            SUsdsConfig({
                usdsJoin: USDS_JOIN,
                usds: USDS,
                ssr: SIX_PT_TWO_FIVE_PCT_RATE
            })
        );

        // Init SKY by calling SkyInit.init with the following parameters:
        // Init SKY with sky parameter being 0x56072C95FAA701256059aa122697B133aDEd9279
        // Init SKY with mkrSky parameter being 0xBDcFCA946b6CDd965f99a839e4435Bcdc1bc470B
        // Init SKY with rate parameter being 24,000
        SkyInit.init(
            dss,
            SkyInstance({
                sky: SKY,
                mkrSky: MKR_SKY
            }),
            24_000
        );

        // ---------- Pool Migration and Flapper Init ----------
        // Forum: TODO
        // Poll: TODO
        // MIP: TODO

        // Migrate liquidity to the new pool by calling UniV2PoolMigratorInit.init with the following parameters:
        // Migrate liquidity to the new pool with pairDaiMkr parameter being 0x517F9dD285e75b599234F7221227339478d0FcC8
        // Migrate liquidity to the new pool with pairUsdsSky parameter being 0x2621CC0B3F3c079c1Db0E80794AA24976F0b9e3c
        UniV2PoolMigratorInit.init(
            dss,
            PAIR_DAI_MKR,
            PAIR_USDS_SKY
        );

        // Init Splitter by calling FlapperInit.initSplitter with the following parameters:
        // Init Splitter with splitter parameter being 0xBF7111F13386d23cb2Fba5A538107A73f6872bCF
        // Init Splitter with mom parameter being 0xF51a075d468dE7dE3599C1Dc47F5C42d02C9230e
        // Init Splitter with hump parameter being 55M DAI/SKY
        // Init Splitter with bump parameter being 65,000 DAI/SKY
        // Init Splitter with hop parameter being 10,249 seconds
        // Init Splitter with burn parameter being 100% (1 * WAD)
        // Init Splitter with usdsJoin parameter being 0x3C0f895007CA717Aa01c8693e59DF1e8C3777FEB
        // Init Splitter with splitterChainlogKey parameter being MCD_SPLIT
        // Init Splitter with prevMomChainlogKey parameter being FLAPPER_MOM
        // Init Splitter with momChainlogKey parameter being SPLITTER_MOM
        FlapperInit.initSplitter(
            dss,
            SplitterInstance({
                splitter: MCD_SPLIT,
                mom: SPLITTER_MOM
            }),
            SplitterConfig({
                hump: 55 * MILLION * RAD,
                bump: 65 * THOUSAND * RAD,
                hop: 10_249,
                burn: 1 * WAD,
                usdsJoin: USDS_JOIN,
                splitterChainlogKey: "MCD_SPLIT",
                prevMomChainlogKey: "FLAPPER_MOM",
                momChainlogKey: "SPLITTER_MOM"
            })
        );

        // Init new Flapper by calling FlapperInit.initFlapperUniV2 with the following parameters:
        // Init new Flapper with flapper_ parameter being 0xc5A9CaeBA70D6974cBDFb28120C3611Dd9910355
        // Init new Flapper with want parameter being 98% (98 * WAD / 100)
        // Init new Flapper with pip parameter being 0x38e8c1D443f546Dc014D7756ec63116161CB7B25
        // Init new Flapper with pair parameter being 0x2621CC0B3F3c079c1Db0E80794AA24976F0b9e3c
        // Init new Flapper with usds parameter being 0xdC035D45d973E3EC169d2276DDab16f1e407384F
        // Init new Flapper with splitter parameter being 0xBF7111F13386d23cb2Fba5A538107A73f6872bCF
        // Init new Flapper with prevChainlogKey parameter being MCD_FLAP
        // Init new Flapper with chainlogKey parameter being MCD_FLAP
        FlapperInit.initFlapperUniV2(
            dss,
            MCD_FLAP,
            FlapperUniV2Config({
                want: 98 * WAD / 100,
                pip: FLAP_SKY_ORACLE,
                pair: PAIR_USDS_SKY,
                usds: USDS,
                splitter: MCD_SPLIT,
                prevChainlogKey: "MCD_FLAP",
                chainlogKey: "MCD_FLAP"
            })
        );

        // Init new Oracle by calling FlapperInit.initOracleWrapper with the following parameters:
        // Init new Oracle with wrapper_ parameter being 0x38e8c1D443f546Dc014D7756ec63116161CB7B25
        // Init new Oracle with divisor parameter being 24,000
        // Init new Oracle with clKey parameter being FLAP_SKY_ORACLE
        FlapperInit.initOracleWrapper(
            dss,
            FLAP_SKY_ORACLE,
            24_000,
            "FLAP_SKY_ORACLE"
        );


        // ---------- Setup DssVestMintable for SKY ----------
        // Forum: TODO
        // Poll: TODO
        // MIP: TODO

        // Authorize DssVestMintable on SKY by calling DssExecLib.authorize with the following parameters:
        // Authorize DssVestMintable on SKY with _base parameter being 0x56072C95FAA701256059aa122697B133aDEd9279
        // Authorize DssVestMintable on SKY with _ward parameter being 0xB313Eab3FdE99B2bB4bA9750C2DDFBe2729d1cE9
        DssExecLib.authorize(SKY, MCD_VEST_SKY);

        // Set DssVestMintable max rate (cap) by calling DssExecLib.setValue with the following parameters:
        // Set DssVestMintable max rate (cap) with _base parameter being 0xB313Eab3FdE99B2bB4bA9750C2DDFBe2729d1cE9
        // Set DssVestMintable max rate (cap) with _what parameter being "cap"
        // Set DssVestMintable max rate (cap) with _amt parameter being 799,999,999.999999999985808000 Sky per year (800M * WAD / 365 days )
        DssExecLib.setValue(MCD_VEST_SKY, "cap", 800 * MILLION * WAD / 365 days);

        // Add DssVestMintable to Chainlog by calling DssExecLib.setChangelogAddress with the following parameters:
        // Add DssVestMintable to Chainlog with _key parameter being MCD_VEST_SKY
        // Add DssVestMintable to Chainlog with _val parameter being 0xB313Eab3FdE99B2bB4bA9750C2DDFBe2729d1cE9
        DssExecLib.setChangelogAddress("MCD_VEST_SKY", MCD_VEST_SKY);

        // ---------- USDS => SKY Farm Setup ----------

        // Init USDS -> SKY rewards by calling UsdsSkyFarmingInit.init with the following parameters:
        // Init USDS -> SKY rewards with usds parameter being 0xdC035D45d973E3EC169d2276DDab16f1e407384F
        // Init USDS -> SKY rewards with sky parameter being 0x56072C95FAA701256059aa122697B133aDEd9279
        // Init USDS -> SKY rewards with rewards parameter being 0x0650CAF159C5A49f711e8169D4336ECB9b950275
        // Init USDS -> SKY rewards with rewardsKey parameter being REWARDS_USDS_SKY
        // Init USDS -> SKY rewards with dist parameter being 0x2F0C88e935Db5A60DDA73b0B4EAEef55883896d9
        // Init USDS -> SKY rewards with distKey parameter being REWARDS_DIST_USDS_SKY
        // Init USDS -> SKY rewards with vest parameter being 0xB313Eab3FdE99B2bB4bA9750C2DDFBe2729d1cE9
        // Init USDS -> SKY rewards with vestTot parameter being 600M * WAD
        // Init USDS -> SKY rewards with vestBgn parameter being block.timestamp - 7 days
        // Init USDS -> SKY rewards with vestTau parameter being 365 days
        UsdsSkyFarmingInit.init(UsdsSkyFarmingInitParams({
            usds: USDS,
            sky: SKY,
            rewards: REWARDS_USDS_SKY,
            rewardsKey: "REWARDS_USDS_SKY",
            dist: REWARDS_DIST_USDS_SKY,
            distKey: "REWARDS_DIST_USDS_SKY",
            vest: MCD_VEST_SKY,
            vestTot: 600 * MILLION * WAD,
            vestBgn: block.timestamp - 7 days,
            vestTau: 365 days
        }));

        // Call distribute() in VestedRewardsDistribution contract in the spell execution
        VestedRewardsDistributionLike(REWARDS_DIST_USDS_SKY).distribute();

        // Initialize the new cron job by calling VestedRewardsDistributionJobInit.init with the following parameters:
        // Initialize cron job with job parameter being 0x6464C34A02DD155dd0c630CE233DD6e21C24F9A5
        // Initialize cron job with cfg.jobKey parameter being CRON_REWARDS_DIST_JOB
        VestedRewardsDistributionJobInit.init(
            CRON_REWARDS_DIST_JOB,
            VestedRewardsDistributionJobInitConfig({
                jobKey: "CRON_REWARDS_DIST_JOB"
            })
        );

        // Add VestedRewardsDistribution to the new cron job by calling VestedRewardsDistributionJobInit.setDist with the following parameters:
        // Add VestedRewardsDistribution to the new cron job with job parameter being 0x6464C34A02DD155dd0c630CE233DD6e21C24F9A5
        // Add VestedRewardsDistribution to the new cron job with cfg.dist parameter being 0x2F0C88e935Db5A60DDA73b0B4EAEef55883896d9
        // Add VestedRewardsDistribution to the new cron job with cfg.interval parameter being 7 days
        VestedRewardsDistributionJobInit.setDist(CRON_REWARDS_DIST_JOB, VestedRewardsDistributionJobSetDistConfig({
            dist: REWARDS_DIST_USDS_SKY,
            interval: 7 days
        }));

        // ---------- USDS => 01 Farm Setup ----------
        // Forum: TODO
        // Poll: TODO
        // MIP: TODO

        // Init Rewards-01 by calling Usds01PreFarmingInit.init with the following parameters:
        // Init Rewards-01 with usds parameter being 0xdC035D45d973E3EC169d2276DDab16f1e407384F
        // Init Rewards-01 with rewards parameter being 0x10ab606B067C9C461d8893c47C7512472E19e2Ce
        // Init Rewards-01 with rewardsKey parameter being REWARDS_USDS_01
        Usds01PreFarmingInit.init(Usds01PreFarmingInitParams({
            usds: USDS,
            rewards: REWARDS_USDS_01,
            rewardsKey: "REWARDS_USDS_01"
        }));

        // ---------- USDS => 01 Farm Setup ----------
        // Forum: TODO
        // Poll: TODO
        // MIP: TODO

        // Add LitePsmWrapper to the Chainlog by calling DssExecLib.setChangelogAddress with the following parameters:
        // Add LitePsmWrapper to the Chainlog with _key parameter being WRAPPER_USDS_LITE_PSM_USDC_A
        // Add LitePsmWrapper to the Chainlog with _val parameter being 0xA188EEC8F81263234dA3622A406892F3D630f98c
        DssExecLib.setChangelogAddress("WRAPPER_USDS_LITE_PSM_USDC_A", WRAPPER_USDS_LITE_PSM_USDC_A);

        // Update GSM Delay
        // Reduce GSM Delay by 14 hours, from 30 hours to 16 hours by calling MCD_PAUSE.setDelay
        PauseLike(MCD_PAUSE).setDelay(16 hours);

        // Note: bump chainlog version due to new modules being onboarded
        DssExecLib.setChangelogVersion("1.18.0");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
