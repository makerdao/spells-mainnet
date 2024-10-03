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

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";
import { DssInstance, MCD } from "dss-test/MCD.sol";
import { DssLitePsmMigrationPhase3, DssLitePsmMigrationConfigPhase3 } from "./dependencies/dss-lite-psm/phase-3/DssLitePsmMigrationPhase3.sol";
import { D3MInit, D3MCommonConfig, D3MOperatorPlanConfig, D3MAaveUSDSPoolConfig } from "src/dependencies/dss-direct-deposit/D3MInit.sol";
import { D3MInstance } from "src/dependencies/dss-direct-deposit/D3MInstance.sol";

interface SUsdsLike {
    function file(bytes32, uint256) external;
    function drip() external returns (uint256);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-10-04 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
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
    uint256 internal constant FIVE_PT_FIVE_PCT_RATE   = 1000000001697766583380253701;
    uint256 internal constant SIX_PT_FIVE_PCT_RATE    = 1000000001996917783620820123;
    uint256 internal constant NINE_PCT_RATE               = 1000000002732676825177582095;
    uint256 internal constant NINE_PT_TWO_FIVE_PCT_RATE   = 1000000002805322428706865331;
    uint256 internal constant NINE_PT_SEVEN_FIVE_PCT_RATE = 1000000002950116251408586949;

    // --- Math ---
    uint256 internal constant MILLION = 10 ** 6;
    uint256 internal constant BILLION = 10 ** 9;
    uint256 internal constant WAD     = 10 ** 18;
    uint256 internal constant RAY     = 10 ** 27;
    uint256 internal constant RAD     = 10 ** 45;

    // --- Offboarding: Current Liquidation Ratio ---
    uint256 constant CURRENT_WBTC_A_MAT =  145 * RAY / 100;
    uint256 constant CURRENT_WBTC_B_MAT =  130 * RAY / 100;

    // --- Offboarding: Target Liquidation Ratio ---
    uint256 constant TARGET_WBTC_A_MAT = 150 * RAY / 100;
    uint256 constant TARGET_WBTC_B_MAT = 150 * RAY / 100;

    // ---------- Contracts ----------
    address internal immutable D3M_HUB         = DssExecLib.getChangelogAddress("DIRECT_HUB");
    address internal immutable D3M_MOM         = DssExecLib.getChangelogAddress("DIRECT_MOM");
    address internal immutable MCD_PSM_USDC_A  = DssExecLib.getChangelogAddress("MCD_PSM_USDC_A");
    address internal immutable SUSDS           = DssExecLib.getChangelogAddress("SUSDS");
    address internal immutable USDS            = DssExecLib.getChangelogAddress("USDS");
    address internal immutable USDS_JOIN       = DssExecLib.getChangelogAddress("USDS_JOIN");
    address internal immutable MCD_PAUSE_PROXY = DssExecLib.getChangelogAddress("MCD_PAUSE_PROXY");


    address internal constant DIRECT_SPK_AAVE_LIDO_USDS_PLAN     = 0xea2abB24bF40ac97746AFf6daCA0BBF885014b31;
    address internal constant DIRECT_SPK_AAVE_LIDO_USDS_POOL     = 0xbf674d0cD6841C1d7f9b8E809B967B3C5E867653;
    address internal constant DIRECT_SPK_AAVE_LIDO_USDS_ORACLE   = 0x9dB0EB29c2819f9AE0A91A6E6f644C35a7493E9b;
    address internal constant DIRECT_SPK_AAVE_LIDO_USDS_OPERATOR = 0x298b375f24CeDb45e936D7e21d6Eb05e344adFb5;

    address internal constant DIRECT_SPK_AAVE_LIDO_USDS_AUSDS         = 0x09AA30b182488f769a9824F15E6Ce58591Da4781;
    address internal constant DIRECT_SPK_AAVE_LIDO_USDS_STABLE_DEBT   = 0x779dB175167C60c2B2193Be6B8d8B3602435e89E;
    address internal constant DIRECT_SPK_AAVE_LIDO_USDS_VARIABLE_DEBT = 0x2D9fe18b6c35FE439cC15D932cc5C943bf2d901E;


    function actions() public override {
        // ---------- Stability Scope Parameter Changes  ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-16-sfs-ssr-dsr-spark-effective-dai-borrow-rate-changes/25257

        // Stability Fee (SF) changes:
        // Note: only heading, changes follow

        // WBTC-A: Increase by 1.5 percentage points, from 7.75% to 9.25%
        DssExecLib.setIlkStabilityFee("WBTC-A", NINE_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // WBTC-B: Increase by 1.5 percentage points, from 8.25% to 9.75%
        DssExecLib.setIlkStabilityFee("WBTC-B", NINE_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // WBTC-C: Increase by 1.5 percentage points, from 7.5% to 9%
        DssExecLib.setIlkStabilityFee("WBTC-C", NINE_PCT_RATE, /* doDrip = */ true);

        // Dai & SKY Savings Rate:
        // Note: only heading, changes follow

        // DSR: Decrease by 0.5 percentage points, from 6% to 5.5%
        DssExecLib.setDSR(FIVE_PT_FIVE_PERCENT_RATE, /* doDrip = */ true);

        // SSR: Increase by 0.25 percentage points, from 6.25% to 6.5%
        SUsdsLike(SUSDS).drip();
        SUsdsLike(SUSDS).file("ssr", SIX_PT_FIVE_PERCENT_RATE);

        // ---------- Update PSM-USDC-A Fees  ----------
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-3-final-migration-proposed-parameters/25183/2
        // Poll: https://vote.makerdao.com/polling/QmRjrFYG

        // PSM-USDC-A tin: Decrease by 0.01 percentage points, from 0.01% to 0%
        // Note: this is done via the DssLitePsmMigrationPhase3 script: line 78

        // PSM-USDC-A tout: Decrease by 0.01 percentage points, from 0.01% to 0%
        // Note: this is done via the DssLitePsmMigrationPhase3 script: line 79

        // ---------- Phase 3 USDC Migration from PSM-USDC-A to LITE-PSM-USDC-A  ----------
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-3-final-migration-proposed-parameters/25183/2
        // Poll: https://vote.makerdao.com/polling/QmRjrFYG

        // ---------- Update PSM-USDC-A DC-IAM  ----------
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-3-final-migration-proposed-parameters/25183/2
        // Poll: https://vote.makerdao.com/polling/QmRjrFYG

        // ---------- Update MCD_LITE_PSM_USDC_A Buf  ----------
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-3-final-migration-proposed-parameters/25183/2
        // Poll: https://vote.makerdao.com/polling/QmRjrFYG

        // ---------- Update LITE-PSM-USDC-A DC-IAM  ----------
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-3-final-migration-proposed-parameters/25183/2
        // Poll: https://vote.makerdao.com/polling/QmRjrFYG

        // Migrate all remaining USDC reserves from PSM-USDC-A to LITE-PSM-USDC-A with a script executed in the spell
        // Note: only heading, copied from the exec sheet for consistency

        // PSM-USDC-A DC-IAM line: Decrease by 2,5 billion DAI, from 2,5 billion DAI to 0
        // Note: this is done via the DssLitePsmMigrationPhase3 script

        // Disable PSM-USDC-A DC-IAM
        // Note: this is done via the DssLitePsmMigrationPhase3 script

        // Note: load the MCD contracts depencencies
        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);

        // Note: specify the migration config
        DssLitePsmMigrationConfigPhase3 memory migrationCfg = DssLitePsmMigrationConfigPhase3({
            // Note: chainlog key of LITE-PSM-USDC-A
            dstPsmKey:  "MCD_LITE_PSM_USDC_A",

            // MCD_LITE_PSM_USDC_A buf: Increase by 200 million DAI, from 200 million DAI to 400 million DAI
            dstBuf: 400 * MILLION * WAD,

            // LITE-PSM-USDC-A DC-IAM line: Increase by 2,5 billion DAI, from 7,5 billion DAI to 10 billion DAI.
            dstMaxLine: 10 * BILLION * RAD,

            // LITE-PSM-USDC-A DC-IAM gap: Increase by 200 million DAI, from 200 million DAI to 400 million DAI.
            dstGap: 400 * MILLION * RAD,

            // LITE-PSM-USDC-A DC-IAM ttl: 12h (Unchanged)
            dstTtl: 12 hours,

            // Note: chainlog key of PSM-USDC-A
            srcPsmKey:  "MCD_PSM_USDC_A"

        });

        // Note: LitePSM migration was extracted into a library,
        //       and implemented as part of the LitePSM module.
        DssLitePsmMigrationPhase3.migrate(dss, migrationCfg);

        // ---------- Activate Aave Lido Market USDS D3M  ----------
        // Forum: https://forum.sky.money/t/risk-assessment-and-parameter-recommendations-spark-ddm-to-aave-lido-market/25175

        // Set D3M DC-IAM with the following parameters:
        // line: 100 million USDS
        // gap: 50 million USDS
        // ttl: 24 hours
        // tau: 7 days
        // D3M Addresses:
        // oracle: 0x9D9CD271C9f203375b96673056BB20BcC0526E80
        // plan: 0x4Cb3f51b97D64C122fC52B3CA828516B5FD66EF7
        // pool: 0x077B5B4b14ebbEF0DAeE21cfAc4CE14523576E07
        // aToken: 0x09AA30b182488f769a9824F15E6Ce58591Da4781
        // operator: 0x298b375f24CeDb45e936D7e21d6Eb05e344adFb5
        // stabledebt address: 0x779dB175167C60c2B2193Be6B8d8B3602435e89E
        // variabledebt address: 0x2D9fe18b6c35FE439cC15D932cc5C943bf2d901E
        // Additional Actions
        // Expand DIRECT_MOM breaker to also include new D3M
        // Note: this is already done within D3MInit.sol line 232

        D3MInstance memory d3m = D3MInstance({
            plan:   DIRECT_SPK_AAVE_LIDO_USDS_PLAN,
            pool:   DIRECT_SPK_AAVE_LIDO_USDS_POOL,
            oracle: DIRECT_SPK_AAVE_LIDO_USDS_ORACLE
        });

        D3MCommonConfig memory d3mCfg = D3MCommonConfig({
            hub:         D3M_HUB,
            mom:         D3M_MOM,
            ilk:         "DIRECT-SPK-AAVE-LIDO-USDS",
            existingIlk: false,
            maxLine:     100 * MILLION * RAD,
            gap:         50 * MILLION * RAD,
            ttl:         24 hours,
            tau:         7 days
        });

        D3MAaveUSDSPoolConfig memory aaveCfg = D3MAaveUSDSPoolConfig({
            king:         MCD_PAUSE_PROXY,
            ausds:        DIRECT_SPK_AAVE_LIDO_USDS_AUSDS,
            usdsJoin:     USDS_JOIN,
            usds:         USDS,
            stableDebt:   DIRECT_SPK_AAVE_LIDO_USDS_STABLE_DEBT,
            variableDebt: DIRECT_SPK_AAVE_LIDO_USDS_VARIABLE_DEBT
        });

        D3MOperatorPlanConfig memory operatorCfg = D3MOperatorPlanConfig({
            operator: DIRECT_SPK_AAVE_LIDO_USDS_OPERATOR
        });

        D3MInit.initCommon({
            dss:     dss,
            d3m:     d3m,
            cfg:     d3mCfg
        });

        D3MInit.initAaveUSDSPool({
            dss:     dss,
            d3m:     d3m,
            cfg:     d3mCfg,
            aaveCfg: aaveCfg
        });

        D3MInit.initOperatorPlan({
            d3m: d3m,
            operatorCfg: operatorCfg
        });

        // ---------- Update WBTC Legacy Vaults Parameters  ----------
        // Forum: https://forum.makerdao.com/t/wbtc-changes-and-risk-mitigation-10-august-2024/24844/48

        // Decrease liquidation penalty for WBTC-A, WBTC-B, and WBTC-C from 13% to 0%
        DssExecLib.setIlkLiquidationPenalty("WBTC-A", 0);
        DssExecLib.setIlkLiquidationPenalty("WBTC-B", 0);
        DssExecLib.setIlkLiquidationPenalty("WBTC-C", 0);

        address spotter = DssExecLib.spotter();

        // WBTC-A: Increase LERP for liquidation ratios from 145% to 150% over 6 days
        DssExecLib.linearInterpolation({
            _name:      "WBTC-A Offboarding",
            _target:    spotter,
            _ilk:       "WBTC-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_WBTC_A_MAT,
            _end:       TARGET_WBTC_A_MAT,
            _duration:  6 days
        });

        // WBTC-B: Increase LERP for liquidation ratios from 130% to 150% over 6 days
        DssExecLib.linearInterpolation({
            _name:      "WBTC-B Offboarding",
            _target:    spotter,
            _ilk:       "WBTC-B",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_WBTC_B_MAT,
            _end:       TARGET_WBTC_B_MAT,
            _duration:  6 days
        });

        // ---------- Chainlog bump ----------
        // Note: we need to increase chainlog version as D3MInit.initCommon added new keys
        DssExecLib.setChangelogVersion("1.19.1");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
