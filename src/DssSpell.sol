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
        "2023-08-18 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

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
        // ---------- EDSR Update ----------
        // Forum: https://forum.makerdao.com/t/request-for-gov12-1-2-edit-to-the-stability-scope-to-quickly-modify-enhanced-dsr-based-on-observed-data/21581

        // ---------- DSR-based Stability Fee Updates ----------
        // Forum: https://forum.makerdao.com/t/request-for-gov12-1-2-edit-to-the-stability-scope-to-quickly-modify-enhanced-dsr-based-on-observed-data/21581

        // ---------- Smart Burn Engine Parameter Updates ----------
        // Poll: https://vote.makerdao.com/polling/QmTRJNNH
        // Forum: https://forum.makerdao.com/t/smart-burn-engine-parameters-update-1/21545

        // ---------- Non-DSR Related Parameter Changes ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-4/21567
        // Mip: https://mips.makerdao.com/mips/details/MIP104#14-3-native-vault-engine

        // ---------- CRVV1ETHSTETH-A 2nd Stage Offboarding ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-4/21567#crvv1ethsteth-a-offboarding-parameters-13
        // Mip: https://mips.makerdao.com/mips/details/MIP104#14-3-native-vault-engine
        // NOTE: ignore on goerli (since there is no CRVV1ETHSTETH-A there)

        // ---------- Aligned Delegate Compensation for July 2023 ----------
        // NOTE: ignore on goerli

        // ---------- Old D3M Parameter Housekeeping ----------

        // ---------- Remainder of Spark Admin Transfers ----------
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
