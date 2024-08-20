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
import { DssLitePsmMigrationPhase2, DssLitePsmMigrationConfigPhase2 } from "./dependencies/dss-lite-psm/phase-2/DssLitePsmMigrationPhase2.sol";

interface RwaMultiSwapOutputConduitLike {
    function clap(address) external;
    function slap(address) external;
}

interface PauseLike {
    function setDelay(uint256 delay_) external;
}

interface DssCronSequencerLike {
    function addJob(address job) external;
    function removeJob(address job) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/8d95eaf1c9eb6722008172504df88bc27f91ed3c/governance/votes/Executive%20vote%20-%20August%2022%2C%202024.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-08-22 MakerDAO Executive Spell | Hash: 0xe3794c8152d2a1de72080b1fc7d8429a979015b3f41cbe2c26f755724c70951d";

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

    // --- Math ---
    uint256 internal constant MILLION  = 10 ** 6;
    uint256 internal constant WAD      = 10 ** 18;
    uint256 internal constant RAD      = 10 ** 45;

    // ---------- LITE-PSM-USDC-A Phase 2 ----------
    address internal immutable MCD_PAUSE                       = DssExecLib.getChangelogAddress("MCD_PAUSE");
    address internal immutable MCD_PSM_USDC_A                  = DssExecLib.getChangelogAddress("MCD_PSM_USDC_A");
    address internal immutable MCD_LITE_PSM_USDC_A             = DssExecLib.getChangelogAddress("MCD_LITE_PSM_USDC_A");
    address internal immutable RWA014_A_INPUT_CONDUIT_URN      = DssExecLib.getChangelogAddress("RWA014_A_INPUT_CONDUIT_URN");
    address internal immutable RWA014_A_INPUT_CONDUIT_JAR      = DssExecLib.getChangelogAddress("RWA014_A_INPUT_CONDUIT_JAR");
    address internal immutable RWA014_A_OUTPUT_CONDUIT         = DssExecLib.getChangelogAddress("RWA014_A_OUTPUT_CONDUIT");
    address internal immutable RWA007_A_JAR_INPUT_CONDUIT      = DssExecLib.getChangelogAddress("RWA007_A_JAR_INPUT_CONDUIT");
    address internal immutable RWA007_A_INPUT_CONDUIT          = DssExecLib.getChangelogAddress("RWA007_A_INPUT_CONDUIT");
    address internal immutable RWA007_A_OUTPUT_CONDUIT         = DssExecLib.getChangelogAddress("RWA007_A_OUTPUT_CONDUIT");
    address internal immutable RWA015_A_INPUT_CONDUIT_JAR_USDC = DssExecLib.getChangelogAddress("RWA015_A_INPUT_CONDUIT_JAR_USDC");
    address internal immutable RWA015_A_INPUT_CONDUIT_URN_USDC = DssExecLib.getChangelogAddress("RWA015_A_INPUT_CONDUIT_URN_USDC");
    address internal immutable RWA015_A_OUTPUT_CONDUIT         = DssExecLib.getChangelogAddress("RWA015_A_OUTPUT_CONDUIT");
    address internal immutable RWA009_A_INPUT_CONDUIT_URN_USDC = DssExecLib.getChangelogAddress("RWA009_A_INPUT_CONDUIT_URN_USDC");

    // ---------- Add LitePSM keeper network job ----------
    address internal immutable CRON_SEQUENCER                  = DssExecLib.getChangelogAddress("CRON_SEQUENCER");
    address internal immutable CRON_LITE_PSM_JOB               = DssExecLib.getChangelogAddress("CRON_LITE_PSM_JOB");
    address internal constant  CRON_LITE_PSM_JOB_NEW           = 0x0C86162ba3E507592fC8282b07cF18c7F902C401;

    function actions() public override {

        // ----- Update PSM state variable in the conduit contracts to MCD_LITE_PSM_USDC_A -----
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-2-major-migration-proposed-parameters/24839
        // Poll: https://vote.makerdao.com/polling/QmU7XJ6X

        // RWA014_A_INPUT_CONDUIT_URN
        DssExecLib.setContract(RWA014_A_INPUT_CONDUIT_URN , "psm", MCD_LITE_PSM_USDC_A);

        // RWA014_A_INPUT_CONDUIT_JAR
        DssExecLib.setContract(RWA014_A_INPUT_CONDUIT_JAR , "psm", MCD_LITE_PSM_USDC_A);

        // RWA014_A_OUTPUT_CONDUIT
        DssExecLib.setContract(RWA014_A_OUTPUT_CONDUIT , "psm", MCD_LITE_PSM_USDC_A);

        // RWA007_A_JAR_INPUT_CONDUIT
        DssExecLib.setContract(RWA007_A_JAR_INPUT_CONDUIT , "psm", MCD_LITE_PSM_USDC_A);

        // RWA007_A_INPUT_CONDUIT
        DssExecLib.setContract(RWA007_A_INPUT_CONDUIT , "psm", MCD_LITE_PSM_USDC_A);

        // RWA007_A_OUTPUT_CONDUIT
        DssExecLib.setContract(RWA007_A_OUTPUT_CONDUIT , "psm", MCD_LITE_PSM_USDC_A);

        // RWA015_A_INPUT_CONDUIT_JAR_USDC
        DssExecLib.setContract(RWA015_A_INPUT_CONDUIT_JAR_USDC , "psm", MCD_LITE_PSM_USDC_A);

        // RWA015_A_INPUT_CONDUIT_URN_USDC
        DssExecLib.setContract(RWA015_A_INPUT_CONDUIT_URN_USDC , "psm", MCD_LITE_PSM_USDC_A);

        // RWA015_A_OUTPUT_CONDUIT
        // Note: This contract does not have a single `psm` state variable, it relies on the mapping `pal` instead

        // Note: remove MCD_PSM_USDC_A
        RwaMultiSwapOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).slap(MCD_PSM_USDC_A);

        // Note: add MCD_LITE_PSM_USDC_A
        RwaMultiSwapOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).clap(MCD_LITE_PSM_USDC_A);

        // RWA009_A_INPUT_CONDUIT_URN_USDC
        DssExecLib.setContract(RWA009_A_INPUT_CONDUIT_URN_USDC , "psm", MCD_LITE_PSM_USDC_A);

        // ----- Phase 2 USDC Migration from PSM-USDC-A to LITE-PSM-USDC-A -----
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-2-major-migration-proposed-parameters/24839
        // Poll: https://vote.makerdao.com/polling/QmU7XJ6X

        // ----- Update PSM-USDC-A Fees -----
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-2-major-migration-proposed-parameters/24839
        // Poll: https://vote.makerdao.com/polling/QmU7XJ6X

        // ----- Update PSM-USDC-A DC-IAM -----
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-2-major-migration-proposed-parameters/24839
        // Poll: https://vote.makerdao.com/polling/QmU7XJ6X

        // ----- Update MCD_LITE_PSM_USDC_A Buf -----
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-2-major-migration-proposed-parameters/24839
        // Poll: https://vote.makerdao.com/polling/QmU7XJ6X

        // ----- Update LITE-PSM-USDC-A DC-IAM -----
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-2-major-migration-proposed-parameters/24839
        // Poll: https://vote.makerdao.com/polling/QmU7XJ6X

        // Note: load the MCD contracts depencencies
        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);

        // Note: specify the migration config
        DssLitePsmMigrationConfigPhase2 memory cfg = DssLitePsmMigrationConfigPhase2({
            // Note: chainlog key of new psm lite
            dstPsmKey:  "MCD_LITE_PSM_USDC_A",

            // MCD_LITE_PSM_USDC_A buf: Increase by 180 million DAI, from 20 million DAI to 200 million DAI
            dstBuf:     200 * MILLION * WAD,

            // Increase by 7,450 million DAI, from 50 million DAI to 7,500 million DAI.
            dstMaxLine: 7_500 * MILLION * RAD,

            // Increase by 180 million DAI, from 20 million DAI to 200 million DAI.
            dstGap:     200 * MILLION * RAD,

            // LITE-PSM-USDC-A DC-IAM ttl: 12h (Unchanged)
            dstTtl:     12 hours,

            // Note: chainlog key of old psm
            srcPsmKey:  "MCD_PSM_USDC_A",

            // PSM-USDC-A tin: Increase by 0.01 percentage points, from 0% to 0.01%
            srcTin:     0.0001 ether, // Note: ether is a keyword helper, no transfers are made here

            // PSM-USDC-A tout: Increase by 0.01 percentage points, from 0% to 0.01%
            srcTout:    0.0001 ether, // Note: ether is a keyword helper, no transfers are made here

            // PSM-USDC-A DC-IAM DC-IAM line: Decrease by 7,500 million DAI, from 10,000 million DAI to 2,500 million DAI.
            srcMaxLine: 2_500 * MILLION * RAD,

            // PSM-USDC-A DC-IAM DC-IAM gap: Decrease by 180 million DAI, from 380 million DAI to 200 million DAI.
            srcGap:     200 * MILLION * RAD,

            // PSM-USDC-A DC-IAM DC-IAM ttl: 12h (Unchanged)
            srcTtl:     12 hours,

            // Migrate all but 200 million USDC reserves from PSM-USDC-A to LITE-PSM-USDC-A
            srcKeep:    200 * MILLION * WAD
        });

        // Note: LitePSM migration was extracted into a library,
        //       and implemented as part of the LitePSM module.
        DssLitePsmMigrationPhase2.migrate(dss, cfg);

        // ----- GSM Delay Update -----
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-2-major-migration-proposed-parameters/24839
        // Poll: https://vote.makerdao.com/polling/QmU7XJ6X

        // Increase the GSM Pause Delay by 14h, from 16h to 30h
        PauseLike(MCD_PAUSE).setDelay(30 hours);

        // ----- Update LitePSM Keeper Network Job -----
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-2-major-migration-proposed-parameters/24839
        // Poll: https://vote.makerdao.com/polling/QmU7XJ6X

        // Remove the old LitePSMJob (0x689cE517a4DfCf0C5eC466F2757D324fc292C8Be) from the CronSequencer
        DssCronSequencerLike(CRON_SEQUENCER).removeJob(CRON_LITE_PSM_JOB);

        // Add the new LitePSMJob (0x0c86162ba3e507592fc8282b07cf18c7f902c401) to the Cron Sequencer
        DssCronSequencerLike(CRON_SEQUENCER).addJob(CRON_LITE_PSM_JOB_NEW);

        // fill: Set the rushThreshold to 20 million DAI
        // Note: The value is already set in CRON_LITE_PSM_JOB_NEW

        // trim: Set the gushThreshold to 20 million DAI
        // Note: The value is already set in CRON_LITE_PSM_JOB_NEW

        // chug: Set the cutThreshold to 300,000 DAI (Unchanged)
        // Note: The value is already set in CRON_LITE_PSM_JOB_NEW

        // Update CRON_LITE_PSM_JOB to 0x0c86162ba3e507592fc8282b07cf18c7f902c401 in the Chainlog
        DssExecLib.setChangelogAddress("CRON_LITE_PSM_JOB", CRON_LITE_PSM_JOB_NEW);

        // Note: bump chainlog version due to the updated CRON_LITE_PSM_JOB address
        DssExecLib.setChangelogVersion("1.17.7");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
