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
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/3c83167342af102994093588d5259d461a11763a/governance/votes/Executive%20vote%20-%20March%2024%2C%202023.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-03-24 MakerDAO Executive Spell | Hash: 0xaa8673db1a97cdb45f8efb4fe677bb1d194db54779cdfd82a3d6d1be40345426";

    // Turn office hours off
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

    address immutable internal ESM          = DssExecLib.getChangelogAddress("MCD_ESM");
    address immutable internal CROPPER      = DssExecLib.getChangelogAddress("MCD_CROPPER");
    address immutable internal STECRV_JOIN  = DssExecLib.getChangelogAddress("MCD_JOIN_CRVV1ETHSTETH_A");
    address immutable internal CHANGELOG    = DssExecLib.getChangelogAddress("CHANGELOG");

    function actions() public override {
        // Out-Of-Schedule executive proposal to fix ESM authorizations (24 March 2023)
        // https://forum.makerdao.com/t/emergency-shutdown-governance-vulnerability-proposed-emergency-spell/20255

        DssExecLib.authorize(CROPPER, ESM);
        DssExecLib.authorize(STECRV_JOIN, ESM);
        DssExecLib.authorize(CHANGELOG, ESM);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
