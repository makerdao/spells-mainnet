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
        "2023-11-29 MakerDAO Executive Spell | Hash: TODO";

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
    // uint256 internal constant X_PCT_RATE      = ;

    function actions() public override {
        // ---------- Stability Fee Changes ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-7/22882#increase-rwa014-a-coinbase-custody-debt-ceiling-9

        // Decrease the WBTC-A Stability Fee (SF) by 0.07%, from 5.86% to 5.79%
        // TODO

        // Decrease the WBTC-B Stability Fee (SF) by 0.07%, from 6.36% to 6.29%
        // TODO

        // Decrease the WBTC-C Stability Fee (SF) by 0.07%, from 5.61% to 5.54%
        // TODO

        // ---------- Reduce PSM-GUSD-A Debt Ceiling ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-7/22882#increase-rwa014-a-coinbase-custody-debt-ceiling-9

        // Decrease the PSM-GUSD-A DC-IAM LINE (max DC) by 110M DAI, from 110M to 0
        // TODO

        // ---------- Increase RWA014-A (Coinbase Custody) Debt Ceiling ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-7/22882#increase-rwa014-a-coinbase-custody-debt-ceiling-9

        // Increase the RWA014-A (Coinbase Custody) debt ceiling by 1b DAI, from 500M to 1.5b
        // TODO

        // ---------- SBE parameter changes ----------
        // Forum: https://forum.makerdao.com/t/smart-burn-engine-transaction-analysis-parameter-reconfiguration-update-3/22876

        // Increase bump by 10,000, from 20,000 to 30,000
        // TODO

        // Increase hop by 9,460, from 6,308 to 15,768
        // TODO

        // ---------- RWA Foundation Service Provider Changes ----------
        // Forum: https://forum.makerdao.com/t/dao-resolution-rwa-foundation-service-provider-changes/22866

        // Approve Dao resolution with IPFS hash QmPiEHtt8rkVtSibBXMrhEzHUmSriXWz4AL2bjscq8dUvU
        // TODO

        // ---------- Andromeda Legal Expenses ----------
        // Forum: https://forum.makerdao.com/t/project-andromeda-legal-expenses-ii/22577/4

        // Transfer 201,738 Dai to 0xc4dB894A11B1eACE4CDb794d0753A3cB7A633767
        // TODO

        // ---------- Trigger Spark Proxy Spell ----------
        // Forum: https://forum.makerdao.com/t/accounting-discrepancy-in-the-dai-market/22845/2

        // Mainnet - 0x68a075249fA77173b8d1B92750c9920423997e2B
        // TODO
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
