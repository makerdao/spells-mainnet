// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
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

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

interface ChainlogLike {
    function removeAddress(bytes32) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/40b362fc70793e9980a8d53c47b1937e05d0c6d3/governance/votes/Executive%20vote%20-%20August%2020%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-09-03 MakerDAO Executive Spell | Hash: ";

    function actions() public override {
        DssExecLib.setChangelogAddress("PAX", DssExecLib.getChangelogAddress("PAXUSD"));
        DssExecLib.setChangelogAddress("PIP_PAX", DssExecLib.getChangelogAddress("PIP_PAXUSD"));

        ChainlogLike(DssExecLib.LOG).removeAddress("PIP_PSM_PAX");

        // Bump changelog version
        DssExecLib.setChangelogVersion("1.9.5");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
