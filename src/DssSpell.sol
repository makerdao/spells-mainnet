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
import { MCD, DssInstance } from "dss-test/MCD.sol";
import { DssLitePsmInstance } from "./dependencies/dss-lite-psm/DssLitePsmInstance.sol";
import { DssLitePsmMigrationPhase1, DssLitePsmMigrationConfigPhase1 } from "./dependencies/dss-lite-psm/phase-1/DssLitePsmMigrationPhase1.sol";

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

interface PauseLike {
    function setDelay(uint256 delay_) external;
}

interface DssCronSequencerLike {
    function addJob(address job) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-07-25 MakerDAO Executive Spell | Hash: TODO";

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
    // uint256 internal constant X_PCT_1000000003022265980097387650RATE = ;

    // --- Math ---
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant BILLION  = 10 ** 9;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAD      = 10 ** 45;

    // ---------- LITE-PSM-USDC-A Phase 1 ----------
    address internal immutable MCD_PAUSE                      = DssExecLib.getChangelogAddress("MCD_PAUSE");
    address internal immutable MCD_ESM                        = DssExecLib.getChangelogAddress("MCD_ESM");
    address internal immutable USDC                           = DssExecLib.getChangelogAddress("USDC");
    address internal immutable PIP_USDC                       = DssExecLib.getChangelogAddress("PIP_USDC");
    address internal constant  MCD_LITE_PSM_USDC_A            = 0xf6e72Db5454dd049d0788e411b06CfAF16853042;
    address internal constant  MCD_LITE_PSM_USDC_A_POCKET     = 0x37305B1cD40574E4C5Ce33f8e8306Be057fD7341;
    address internal constant  LITE_PSM_MOM                   = 0x467b32b0407Ad764f56304420Cddaa563bDab425;
    address internal constant  MCD_LITE_PSM_USDC_A_JAR        = 0x69cA348Bd928A158ADe7aa193C133f315803b06e;
    address internal constant  MCD_LITE_PSM_USDC_A_IN_CDT_JAR = 0x5eeB3D8D60B06a44f6124a84EeE7ec0bB747BE6d;

    // ---------- Add LitePSM keeper network job ----------
    address internal immutable CRON_SEQUENCER    = DssExecLib.getChangelogAddress("CRON_SEQUENCER");
    address internal constant  CRON_LITE_PSM_JOB = 0x689cE517a4DfCf0C5eC466F2757D324fc292C8Be;

    // ---------- Spark Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0x18427dB17D3113309a0406284aC738f4E649613B;

    function actions() public override {
        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);
        DssLitePsmInstance memory inst = DssLitePsmInstance({
            // ---------- LITE-PSM-USDC-A Phase 1 ----------
            // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-1-test-period-proposed-parameters/24644

            // Onboard MCD_LITE_PSM_USDC_A at 0xf6e72Db5454dd049d0788e411b06CfAF16853042
            litePsm: MCD_LITE_PSM_USDC_A,

            // ---------- PSM_MOM GSM Delay Exception ----------
            // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-1-test-period-proposed-parameters/24644

            // Activate PSM_MOM GSM Delay Exception at 0x467b32b0407Ad764f56304420Cddaa563bDab425
            mom:     LITE_PSM_MOM
        });
        DssLitePsmMigrationConfigPhase1 memory cfg = DssLitePsmMigrationConfigPhase1({
            // ---------- LITE-PSM-USDC-A Phase 1 ----------
            // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-1-test-period-proposed-parameters/24644

            dstPip:       PIP_USDC,
            dstGem:       USDC,
            dstIlk:       "LITE-PSM-USDC-A",
            srcPsmKey:    "MCD_PSM_USDC_A",
            // Onboard MCD_LITE_PSM_USDC_A_POCKET at 0x37305B1cD40574E4C5Ce33f8e8306Be057fD7341
            dstPocket:    MCD_LITE_PSM_USDC_A_POCKET,
            // buf: Set to 20M
            dstBuf:       20 * MILLION * WAD,

            // ---------- Update PSM-USDC-A DC-IAM ----------
            // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-1-test-period-proposed-parameters/24644

            // DC-IAM line: Set to 50M
            dstMaxLine:   50 * MILLION * RAD,
            // DC-IAM gap: Set to 20M
            dstGap:       20 * MILLION * RAD,
            // DC-IAM ttl: Set to 12h
            dstTtl:       12 hours,

            // ---------- Set up LITE-PSM-USDC-A DC-IAM ----------
            // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-1-test-period-proposed-parameters/24644

            // DC-IAM line: 10B (Unchanged)
            srcMaxLine:   10 * BILLION * RAD,
            // DC-IAM gap: Decrease for 20M from 400M to 380M
            srcGap:       380 * MILLION * RAD,
            // DC-IAM ttl: 12h (Unchanged)
            srcTtl:       12 hours,

            // ---------- Initial USDC Migration from PSM-USDC-A to LitePSM ----------
            // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-1-test-period-proposed-parameters/24644

            // Migrate 20 million USDC from PSM-USDC-A to LITE-PSM-USDC-A
            dstWant:      20 * MILLION * WAD,
            // Leave at least 200M USDC reserves in PSM-USDC-A
            srcKeep:      200 * MILLION * WAD,

            // ---------- Chainlog additions ----------
            // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-1-test-period-proposed-parameters/24644

            // Add 0x467b32b0407Ad764f56304420Cddaa563bDab425 as LITE_PSM_MOM
            psmMomKey:    "LITE_PSM_MOM",
            // Add 0xf6e72Db5454dd049d0788e411b06CfAF16853042 as MCD_LITE_PSM_USDC_A
            dstPsmKey:    "MCD_LITE_PSM_USDC_A",
            // Add 0x37305B1cD40574E4C5Ce33f8e8306Be057fD7341 as MCD_LITE_PSM_USDC_A_POCKET
            dstPocketKey: "MCD_LITE_PSM_USDC_A_POCKET",

        });
        DssLitePsmMigrationPhase1.initAndMigrate(dss, inst, cfg);

        // ---------- GSM Delay Update ----------
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-1-test-period-proposed-parameters/24644

        // Decrease the GSM Pause Delay by 14h, from 30h to 16h
        PauseLike(MCD_PAUSE).setDelay(16 hours);

        // ---------- Emergency Shutdown Module Minimum Threshold Update ----------
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-1-test-period-proposed-parameters/24644

        // Increase the ESM (Emergency Shutdown Module) minimum threshold by 150k MKR from 150k MKR to 300k MKR
        DssExecLib.setValue(MCD_ESM, "min", 300 * THOUSAND * WAD);

        // ---------- Add LitePSM keeper network job ----------
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-1-test-period-proposed-parameters/24644

        // sequencer.addJob(0x689cE517a4DfCf0C5eC466F2757D324fc292C8Be)
        DssCronSequencerLike(CRON_SEQUENCER).addJob(CRON_LITE_PSM_JOB);

        // ---------- Chainlog additions ----------
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-1-test-period-proposed-parameters/24644

        // Add 0x69cA348Bd928A158ADe7aa193C133f315803b06e as MCD_LITE_PSM_USDC_A_JAR
        DssExecLib.setChangelogAddress("MCD_LITE_PSM_USDC_A_JAR", MCD_LITE_PSM_USDC_A_JAR);
        // Add 0x5eeB3D8D60B06a44f6124a84EeE7ec0bB747BE6d as MCD_LITE_PSM_USDC_A_IN_CDT_JAR
        DssExecLib.setChangelogAddress("MCD_LITE_PSM_USDC_A_IN_CDT_JAR", MCD_LITE_PSM_USDC_A_IN_CDT_JAR);

        DssExecLib.setChangelogVersion("1.17.5");

        // ---------- Spark Spell ----------
        // Forum: https://forum.makerdao.com/t/jul-12-2024-proposed-changes-to-spark-for-upcoming-spell/24635

        // Trigger Spark Proxy Spell at 0x18427dB17D3113309a0406284aC738f4E649613B
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
