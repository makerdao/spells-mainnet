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
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/00004b1953dde1f56cc29524b9545a8b84600dd0/governance/votes/Executive%20vote%20-%20May%2006%2C%202024.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-05-06 MakerDAO Executive Spell | Hash: 0x8f7a9272969cd40df959c70acaa5205edd339294bd96007d95776ac897fca331";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // Note: by the previous convention it should be a comma-separated list of DAO resolutions IPFS hashes
    string public constant dao_resolutions = "QmUvqDK4EgGFw6dUqmdhcoZiSBLFuhf2e6k63WwrauRUx9";

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

    function actions() public override {
        // ---------- Approve Coinbase Custody (RWA014-A) Dao Resolution ----------
        // Forum: https://forum.makerdao.com/t/proposal-to-extend-coinbase-custody-rewards/24198
        // Forum: https://forum.makerdao.com/t/proposal-to-extend-coinbase-custody-rewards/24198/4

        // Approve Coinbase Custody (RWA014-A) Dao Resolution with IPFS hash QmUvqDK4EgGFw6dUqmdhcoZiSBLFuhf2e6k63WwrauRUx9
        // Note: see `dao_resolutions` variable declared above
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
