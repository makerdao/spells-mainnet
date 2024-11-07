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
        "2024-11-14 MakerDAO Executive Spell | Hash: TODO";

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

    function actions() public override {

        // ---------- Increase SparkLend D3M Buffer Parameter ----------
        // Forum: https://forum.sky.money/t/14-nov-2024-proposed-changes-to-spark-for-upcoming-spell/25466
        // Poll: https://vote.makerdao.com/polling/QmNTKFqG#poll-detail

        // Increase SparkLend D3M buffer parameter (`buf`) by 50 million DAI from 50 million DAI to 100 million DAI.

        // ---------- Update Gelato Keeper Treasury Address ----------
        // Forum: https://forum.sky.money/t/gelato-keeper-update/25456

        // Update DssExecLib.setContract: GELATO_PAYMENT_ADAPTER - "treasury" to 0x5041c60C75633F29DEb2AED79cB0A9ed79202415

        // ---------- Approve ConsolFreight DAO Resolution ----------

        // Write-off the debt of RWA003-A by calling `cull()`

        // Approve ConsolFreight Dao Resolution with IPFS hash X (TODO)

        // ---------- Set Facilitator DAI Payment Streams ----------

        // JanSky | 2024-10-01 00:00:00 to 2025-01-31 23:59:59 | 168,000 DAI | 0xf3F868534FAD48EF5a228Fe78669cf242745a755

        // Endgame Edge | 2024-10-01 00:00:00 to 2025-01-31 23:59:59 | 168,000 DAI | 0x9E72629dF4fcaA2c2F5813FbbDc55064345431b1

        // Ecosystem | 2024-12-01 00:00:00 to 2025-01-31 23:59:59 | 84,000 DAI | 0xFCa6e196c2ad557E64D9397e283C2AFe57344b75

        // ---------- Set Facilitator MKR Payment Streams ----------

        // JanSky | 2024-10-01 00:00:00 to 2025-01-31 23:59:59 | 72.00 MKR | 0xf3F868534FAD48EF5a228Fe78669cf242745a755

        // Endgame Edge | 2024-10-01 00:00:00 to 2025-01-31 23:59:59 | 72.00 MKR | 0x9E72629dF4fcaA2c2F5813FbbDc55064345431b1

        // Ecosystem | 2024-12-01 00:00:00 to 2025-01-31 23:59:59 | 36.00 MKR | 0xFCa6e196c2ad557E64D9397e283C2AFe57344b75

        // ---------- Aligned Delegate DAI Compensation ----------

        // ---------- Aligned Delegate MKR Compensation ----------

        // ---------- Launch Project Funding ----------

        // ---------- Spark Proxy Spell ----------

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
