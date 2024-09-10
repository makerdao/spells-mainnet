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
        // ---------- Set earliest execution date September 17, 12:00 UTC ----------
        // Forum: https://forum.makerdao.com/t/sky-protocol-launch-season-token-and-product-launch-parameter-proposal/25031
        // Poll: https://vote.makerdao.com/polling/QmTySKwi
        // Note: In case the spell is scheduled later than planned, we have to switch back to the regular logic to respect GSM delay enforced by MCD_PAUSE
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
    address internal constant UNIV2DAIMKR                 = 0x517F9dD285e75b599234F7221227339478d0FcC8;
    address internal constant UNIV2USDSSKY                = 0x2621CC0B3F3c079c1Db0E80794AA24976F0b9e3c;
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

        // Note: load the Maker Protocol contracts depencencies
        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);

        // ---------- New Tokens Init ----------
        // Forum: https://forum.makerdao.com/t/sky-protocol-launch-season-token-and-product-launch-parameter-proposal/25031
        // Poll: https://vote.makerdao.com/polling/QmTySKwi

        // Init USDS by calling UsdsInit.init with the following parameters:
        UsdsInit.init(
            // Note: Maker Protocol contracts dependencies
            dss,
            UsdsInstance({
                // Init USDS with usds parameter being 0xdC035D45d973E3EC169d2276DDab16f1e407384F
                usds: USDS,
                // Init USDS with usdsImp parameter being 0x1923DfeE706A8E78157416C29cBCCFDe7cdF4102
                usdsImp: USDS_IMP,
                // Init USDS with UsdsJoin parameter being 0x3C0f895007CA717Aa01c8693e59DF1e8C3777FEB
                usdsJoin: USDS_JOIN,
                // Init USDS with DaiUsds parameter being 0x3225737a9Bbb6473CB4a45b7244ACa2BeFdB276A
                daiUsds: DAI_USDS
            })
        );

        // Add usds to chainlog with key "USDS" via the UsdsInit.init function

        // Add usdsImp to chainlog under the key "USDS_IMP" via the UsdsInit.init function

        // Add UsdsJoin to chainlog under the key "USDS_JOIN" via the UsdsInit.init function

        // Add DaiUsds to chainlog under the key "DAI_USDS" via the UsdsInit.init function

        // The usdsJoin Adapter will be authorized in the usds contract by calling rely via the UsdsInit.init function

        // Note: the actions above are executed through UsdsInit.init()

        // Init sUSDS by calling SUsdsInit.init with the following parameters:
        SUsdsInit.init(
            // Note: Maker Protocol contracts dependencies
            dss,
            SUsdsInstance({
                // Init sUSDS with sUsds parameter being 0xa3931d71877C0E7a3148CB7Eb4463524FEc27fbD
                sUsds: SUSDS,
                // Init sUSDS with sUsdsImp parameter being 0x4e7991e5C547ce825BdEb665EE14a3274f9F61e0
                sUsdsImp: SUSDS_IMP
            }),
            SUsdsConfig({
                // Init sUSDS with usdsJoin parameter being 0x3C0f895007CA717Aa01c8693e59DF1e8C3777FEB
                usdsJoin: USDS_JOIN,
                // Init sUSDS with usds parameter being 0xdC035D45d973E3EC169d2276DDab16f1e407384F
                usds: USDS,
                // Init sUSDS with ssr parameter being 6.25%
                ssr: SIX_PT_TWO_FIVE_PCT_RATE
            })
        );

        // Add sUsds to chainlog under the key "SUSDS" via the SUsdsInit.init function

        // Add sUsdsImp to chainlog under the key "SUSDS_IMP" via the SUsdsInit.init function

        // sUSDS will be authorized to access the vat by calling rely via the SUsdsInit.init function

        // Note: the actions above are executed through SUsdsInit.init()

        // Init SKY by calling SkyInit.init with the following parameters:
        SkyInit.init(
            // Note: Maker Protocol contracts dependencies
            dss,
            SkyInstance({
                // Init SKY with sky parameter being 0x56072C95FAA701256059aa122697B133aDEd9279
                sky: SKY,
                // Init SKY with mkrSky parameter being 0xBDcFCA946b6CDd965f99a839e4435Bcdc1bc470B
                mkrSky: MKR_SKY
            }),
            // Init SKY with rate parameter being 24,000
            24_000
        );

        // Add sky to chainlog under the key "SKY" via the SkyInit.init function

        // Add mkrSky to chainlog under the key "MKR_SKY" via the SkyInit.init function

        // The mkrSky contract will be authorized in the sky contract by calling rely via the SkyInit.init function

        // The mkrSky contract will be authorized in the MkrAuthority contract by calling rely via the SkyInit.init function

        // Note: the actions above are executed through SkyInit.init()

        // ---------- Pool Migration and Flapper Init ----------
        // Forum: https://forum.makerdao.com/t/sky-protocol-launch-season-token-and-product-launch-parameter-proposal/25031
        // Poll: https://vote.makerdao.com/polling/QmTySKwi

        // Migrate full DAI/MKR UniswapV2 liquidity into USDS/SKY by calling UniV2PoolMigratorInit.init with the following parameters:
        UniV2PoolMigratorInit.init(
            // Note: Maker Protocol contracts dependencies
            dss,
            // Migrate liquidity to the new pool with pairDaiMkr parameter being 0x517F9dD285e75b599234F7221227339478d0FcC8
            UNIV2DAIMKR,
            // Migrate liquidity to the new pool with pairUsdsSky parameter being 0x2621CC0B3F3c079c1Db0E80794AA24976F0b9e3c
            UNIV2USDSSKY
        );

        // Init Splitter by calling FlapperInit.initSplitter with the following parameters:
        FlapperInit.initSplitter(
            // Note: Maker Protocol contracts dependencies
            dss,
            SplitterInstance({
                // Init Splitter with splitter parameter being 0xBF7111F13386d23cb2Fba5A538107A73f6872bCF
                splitter: MCD_SPLIT,
                // Init Splitter with mom parameter being 0xF51a075d468dE7dE3599C1Dc47F5C42d02C9230e
                mom: SPLITTER_MOM
            }),
            SplitterConfig({
                // Init Splitter with hump parameter being 55M DAI
                hump: 55 * MILLION * RAD,
                // Init Splitter with bump parameter being 65,000 DAI/USDS
                bump: 65 * THOUSAND * RAD,
                // Init Splitter with hop parameter being 10,249 seconds
                hop: 10_249,
                // Init Splitter with burn parameter being 100% (1 * WAD)
                burn: 1 * WAD,
                // Init Splitter with usdsJoin parameter being 0x3C0f895007CA717Aa01c8693e59DF1e8C3777FEB
                usdsJoin: USDS_JOIN,
                // Init Splitter with splitterChainlogKey parameter being MCD_SPLIT
                splitterChainlogKey: "MCD_SPLIT",
                // Init Splitter with prevMomChainlogKey parameter being FLAPPER_MOM
                prevMomChainlogKey: "FLAPPER_MOM",
                // Init Splitter with momChainlogKey parameter being SPLITTER_MOM
                momChainlogKey: "SPLITTER_MOM"
            })
        );

        // The flapper variable in the vow will be changed by the splitter address by calling file via the initSplitter function

        // Note: the actions above are executed through FlapperIni.initSplitter()

        // Init new Flapper by calling FlapperInit.initFlapperUniV2 with the following parameters:
        FlapperInit.initFlapperUniV2(
            // Note: Maker Protocol contracts dependencies
            dss,
            // Init new Flapper with flapper_ parameter being 0xc5A9CaeBA70D6974cBDFb28120C3611Dd9910355
            MCD_FLAP,
            FlapperUniV2Config({
                // Init new Flapper with want parameter being 98% (98 * WAD / 100)
                want: 98 * WAD / 100,
                // Init new Flapper with pip parameter being 0x38e8c1D443f546Dc014D7756ec63116161CB7B25
                pip: FLAP_SKY_ORACLE,
                // Init new Flapper with pair parameter being 0x2621CC0B3F3c079c1Db0E80794AA24976F0b9e3c
                pair: UNIV2USDSSKY,
                // Init new Flapper with usds parameter being 0xdC035D45d973E3EC169d2276DDab16f1e407384F
                usds: USDS,
                // Init new Flapper with splitter parameter being 0xBF7111F13386d23cb2Fba5A538107A73f6872bCF
                splitter: MCD_SPLIT,
                // Init new Flapper with prevChainlogKey parameter being MCD_FLAP
                prevChainlogKey: "MCD_FLAP",
                // Init new Flapper with chainlogKey parameter being MCD_FLAP
                chainlogKey: "MCD_FLAP"
            })
        );

        // Init new Oracle by calling FlapperInit.initOracleWrapper with the following parameters:
        FlapperInit.initOracleWrapper(
            // Note: Maker Protocol contracts dependencies
            dss,
            // Init new Oracle with wrapper_ parameter being 0x38e8c1D443f546Dc014D7756ec63116161CB7B25
            FLAP_SKY_ORACLE,
            // Init new Oracle with divisor parameter being 24,000
            24_000,
            // Init new Oracle with clKey parameter being FLAP_SKY_ORACLE
            "FLAP_SKY_ORACLE"
        );

        // Authorize wrapper to read MKR oracle price

        // Note: the actions above are executed through FlapperInit.initOracleWrapper()

        // ---------- Setup DssVestMintable for SKY ----------
        // Forum: https://forum.makerdao.com/t/sky-protocol-launch-season-token-and-product-launch-parameter-proposal/25031
        // Poll: https://vote.makerdao.com/polling/QmTySKwi

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
        UsdsSkyFarmingInit.init(UsdsSkyFarmingInitParams({
            // Init USDS -> SKY rewards with usds parameter being 0xdC035D45d973E3EC169d2276DDab16f1e407384F
            usds: USDS,
            // Init USDS -> SKY rewards with sky parameter being 0x56072C95FAA701256059aa122697B133aDEd9279
            sky: SKY,
            // Init USDS -> SKY rewards with rewards parameter being 0x0650CAF159C5A49f711e8169D4336ECB9b950275
            rewards: REWARDS_USDS_SKY,
            // Init USDS -> SKY rewards with rewardsKey parameter being REWARDS_USDS_SKY
            rewardsKey: "REWARDS_USDS_SKY",
            // Init USDS -> SKY rewards with dist parameter being 0x2F0C88e935Db5A60DDA73b0B4EAEef55883896d9
            dist: REWARDS_DIST_USDS_SKY,
            // Init USDS -> SKY rewards with distKey parameter being REWARDS_DIST_USDS_SKY
            distKey: "REWARDS_DIST_USDS_SKY",
            // Init USDS -> SKY rewards with vest parameter being 0xB313Eab3FdE99B2bB4bA9750C2DDFBe2729d1cE9
            vest: MCD_VEST_SKY,
            // Init USDS -> SKY rewards with vestTot parameter being 600M * WAD
            vestTot: 600 * MILLION * WAD,
            // Init USDS -> SKY rewards with vestBgn parameter being block.timestamp - 7 days
            vestBgn: block.timestamp - 7 days,
            // Init USDS -> SKY rewards with vestTau parameter being 365 days - 1
            vestTau: 365 days - 1
        }));

        // Call distribute() in VestedRewardsDistribution contract in the spell execution
        VestedRewardsDistributionLike(REWARDS_DIST_USDS_SKY).distribute();

        // SKY Vesting Stream  | from 'block.timestamp - 7 days' for '365 days - 1' | 600M * WAD SKY | 0x2F0C88e935Db5A60DDA73b0B4EAEef55883896d9

        // Note: the actions above are executed through UsdsSkyFarmingInit.init()

        // Initialize the new cron job by calling VestedRewardsDistributionJobInit.init with the following parameters:
        VestedRewardsDistributionJobInit.init(
            // Initialize cron job with job parameter being 0x6464C34A02DD155dd0c630CE233DD6e21C24F9A5
            CRON_REWARDS_DIST_JOB,
            VestedRewardsDistributionJobInitConfig({
                // Initialize cron job with cfg.jobKey parameter being CRON_REWARDS_DIST_JOB
                jobKey: "CRON_REWARDS_DIST_JOB"
            })
        );

        // Add VestedRewardsDistribution to the new cron job by calling VestedRewardsDistributionJobInit.setDist with the following parameters:
        VestedRewardsDistributionJobInit.setDist(
            // Add VestedRewardsDistribution to the new cron job with job parameter being 0x6464C34A02DD155dd0c630CE233DD6e21C24F9A5
            CRON_REWARDS_DIST_JOB,
            VestedRewardsDistributionJobSetDistConfig({
                // Add VestedRewardsDistribution to the new cron job with cfg.dist parameter being 0x2F0C88e935Db5A60DDA73b0B4EAEef55883896d9
                dist: REWARDS_DIST_USDS_SKY,
                // Add VestedRewardsDistribution to the new cron job with cfg.interval parameter being 7 days
                interval: 7 days
            })
        );

        // ---------- USDS => 01 Farm Setup ----------
        // Forum: https://forum.makerdao.com/t/sky-protocol-launch-season-token-and-product-launch-parameter-proposal/25031
        // Poll: https://vote.makerdao.com/polling/QmTySKwi

        // Init Rewards-01 by calling Usds01PreFarmingInit.init with the following parameters:
        Usds01PreFarmingInit.init(Usds01PreFarmingInitParams({
            // Init Rewards-01 with usds parameter being 0xdC035D45d973E3EC169d2276DDab16f1e407384F
            usds: USDS,
            // Init Rewards-01 with rewards parameter being 0x10ab606B067C9C461d8893c47C7512472E19e2Ce
            rewards: REWARDS_USDS_01,
            // Init Rewards-01 with rewardsKey parameter being REWARDS_USDS_01
            rewardsKey: "REWARDS_USDS_01"
        }));

        // ---------- MISC ----------
        // Forum: https://forum.makerdao.com/t/sky-protocol-launch-season-token-and-product-launch-parameter-proposal/25031
        // Poll: https://vote.makerdao.com/polling/QmTySKwi

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
