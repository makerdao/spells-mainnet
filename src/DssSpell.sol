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
        "2024-01-24 MakerDAO Executive Spell | Hash: TODO";

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
        // ---------- Stability Fee Changes ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-8/23445

        // Increase the ETH-A Stability Fee (SF) by 1.49%, from 5.25% to 6.74%.
        // TODO

        // Increase the ETH-B Stability Fee (SF) by 1.49%, from 5.75% to 7.24%.
        // TODO

        // Increase the ETH-C Stability Fee (SF) by 1.49%, from 5.00% to 6.49%.
        // TODO

        // Increase the WSTETH-A Stability Fee (SF) by 1.91%, from 5.25% to 7.16%.
        // TODO

        // Increase the WSTETH-B Stability Fee (SF) by 1.91%, from 5.00% to 6.91%.
        // TODO

        // Increase the WBTC-A Stability Fee (SF) by 0.91%, from 5.79% to 6.70%.
        // TODO

        // Increase the WBTC-B Stability Fee (SF) by 0.91%, from 6.29% to 7.20%.
        // TODO

        // Increase the WBTC-C Stability Fee (SF) by 0.91%, from 5.54% to 6.45%.
        // TODO

        // ---------- Reduce PSM-PAX-A Debt Ceiling & Disable DC-IAM ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-8/23445

        // Remove PSM-PAX-A from Autoline.
        // TODO

        // Set PSM-PAX-A debt ceiling to 0
        // TODO

        // Reduce Global Debt Ceiling? Yes
        // TODO

        // ---------- RETH-A Offboarding Parameters Finalization ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-8/23445

        // Set chop to 0%.
        // TODO

        // Set tip to 0%
        // TODO

        // Set chip to 0%
        // TODO

        // Set Liquidation Ratio to 10,000%.
        // TODO

        // ---------- SBE parameter changes ----------
        // Forum: https://forum.makerdao.com/t/smart-burn-engine-transaction-analysis-parameter-reconfiguration-update-4/23441

        // Increase bump by 20,000, from 30,000 to 50,000 DAI
        // TODO

        // Increase hop by 10,512, from 15,768 to 26,280 Seconds
        // TODO

        // ---------- Trigger Spark Proxy Spell ----------
        // Forum: https://forum.makerdao.com/t/jan-10-2024-proposed-changes-to-sparklend-for-upcoming-spell/23389
        // Poll: https://vote.makerdao.com/polling/Qmc3NjZA
        // Poll: https://vote.makerdao.com/polling/QmNrXB9P
        // Poll: https://vote.makerdao.com/polling/QmTauEqL
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-8/23445

        // Activate Spark Proxy Spell - TBD
        // TODO
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
