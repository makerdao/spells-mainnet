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

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-08-12 MakerDAO Executive Spell | Hash: TODO";

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

    function actions() public override {

        // ----- Update PSM state variable in the conduit contracts to MCD_LITE_PSM_USDC_A -----
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-2-major-migration-proposed-parameters/24839
        // Poll: https://vote.makerdao.com/polling/QmU7XJ6X

        // RWA014_A_INPUT_CONDUIT_URN

        // RWA014_A_INPUT_CONDUIT_JAR

        // RWA014_A_OUTPUT_CONDUIT

        // RWA007_A_JAR_INPUT_CONDUIT

        // RWA007_A_INPUT_CONDUIT

        // RWA007_A_OUTPUT_CONDUIT

        // RWA015_A_INPUT_CONDUIT_JAR_USDC

        // RWA015_A_INPUT_CONDUIT_URN_USDC

        // RWA015_A_OUTPUT_CONDUIT

        // RWA009_A_INPUT_CONDUIT_URN_USDC

        // ----- Phase 2 USDC Migration from PSM-USDC-A to LITE-PSM-USDC-A -----
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-2-major-migration-proposed-parameters/24839
        // Poll: https://vote.makerdao.com/polling/QmU7XJ6X

        // Migrate all but 200 million USDC reserves from PSM-USDC-A to LITE-PSM-USDC-A

        // ----- Update PSM-USDC-A Fees -----
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-2-major-migration-proposed-parameters/24839
        // Poll: https://vote.makerdao.com/polling/QmU7XJ6X

        // PSM-USDC-A tin: Increase by 0.01 percentage points, from 0% to 0.01%

        // PSM-USDC-A tout: Increase by 0.01 percentage points, from 0% to 0.01%

        // ----- Update PSM-USDC-A DC-IAM -----
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-2-major-migration-proposed-parameters/24839
        // Poll: https://vote.makerdao.com/polling/QmU7XJ6X

        // PSM-USDC-A DC-IAM DC-IAM line: Decrease by 7,500 million DAI, from 10,000 million DAI to 2,500 million DAI.

        // PSM-USDC-A DC-IAM DC-IAM gap: Decrease by 180 million DAI, from 380 million DAI to 200 million DAI.

        // PSM-USDC-A DC-IAM DC-IAM ttl: 12h (Unchanged)

        // ----- Update MCD_LITE_PSM_USDC_A Buf -----
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-2-major-migration-proposed-parameters/24839
        // Poll: https://vote.makerdao.com/polling/QmU7XJ6X

        // MCD_LITE_PSM_USDC_A buf: Increase by 180 million DAI, from 20 million DAI to 200 million DAI

        // ----- Update LITE-PSM-USDC-A DC-IAM -----
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-2-major-migration-proposed-parameters/24839
        // Poll: https://vote.makerdao.com/polling/QmU7XJ6X

        // LITE-PSM-USDC-A DC-IAM line: Increase by 7,450 million DAI, from 50 million DAI to 7,500 million DAI.

        // LITE-PSM-USDC-A DC-IAM gap: Increase by 180 million DAI, from 20 million DAI to 200 million DAI.

        // LITE-PSM-USDC-A DC-IAM ttl: 12h (Unchanged)

        // ----- GSM Delay Update -----
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-2-major-migration-proposed-parameters/24839
        // Poll: https://vote.makerdao.com/polling/QmU7XJ6X

        // Increase the GSM Pause Delay by 14h, from 16h to 30h

        // ----- Update LitePSM Keeper Network Job -----
        // Forum: https://forum.makerdao.com/t/lite-psm-usdc-a-phase-2-major-migration-proposed-parameters/24839
        // Poll: https://vote.makerdao.com/polling/QmU7XJ6X

        // Remove the old LitePSMJob (0x689cE517a4DfCf0C5eC466F2757D324fc292C8Be) from the CronSequencer

        // Add the new LitePSMJob (0x0c86162ba3e507592fc8282b07cf18c7f902c401) to the Cron Sequencer

        // fill: Set the rushThreshold to 20 million DAI

        // trim: Set the gushThreshold to 20 million DAI

        // chug: Set the cutThreshold to 300,000 DAI (Unchanged)

        // Update CRON_LITE_PSM_JOB to 0x0c86162ba3e507592fc8282b07cf18c7f902c401 in the Chainlog
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
