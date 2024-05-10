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

interface DssCronSequencerLike {
    function addJob(address job) external;
    function removeJob(address job) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description =
        "TODO MakerDAO Executive Spell | Hash: TODO";

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
    // uint256 internal constant X_PCT_1000000003022265980097387650RATE = ;

    // ---------- Contract addresses ----------

    // ---------- Dss-Cron Update ----------
    address internal constant CRON_SEQUENCER                = 0x238b4E35dAed6100C6162fAE4510261f88996EC9;
    address internal constant CRON_D3M_JOB                  = 0x1Bb799509b0B039345f910dfFb71eEfAc7022323;
    address internal constant CRON_D3M_JOB_NEW              = 0x2Ea4aDE144485895B923466B4521F5ebC03a0AeF;

    function actions() public override {
        // ---------- Dss-Cron Update ----------

        // Update D3MJob in the sequencer (0x238b4E35dAed6100C6162fAE4510261f88996EC9)
        DssCronSequencerLike(CRON_SEQUENCER).removeJob(CRON_D3M_JOB);
        DssCronSequencerLike(CRON_SEQUENCER).addJob(CRON_D3M_JOB_NEW);

        // Note: overwrite the old address with the new address in the chainlog
        DssExecLib.setChangelogAddress("CRON_D3M_JOB", CRON_D3M_JOB_NEW);

        // Note: bump chainlog version due to the changed key
        DssExecLib.setChangelogVersion("1.17.4");

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
