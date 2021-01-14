// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity 0.6.11;

interface DssExecFactory {
    function newExec(string memory,uint256,address) external returns (address);
    function newWeeklyExec(string memory,address) external returns (address);
    function newMonthlyExec(string memory,address) external returns (address);
}

import "./DssSpell.sol";

contract SpellFab {

    // Mainnet
    address public constant  EXEC_FACTORY = 0xf610426dFAb48f7AE5678e97Be0286C1aDCedb11;
    // Mainnet
    address public constant  EXEC_LIB     = 0xFC32E74e6e33D924bd2fBFC7A27b6F2177032760;
    address public immutable action;
    address public immutable spell;

    constructor() public {
        address _action = action = address(new SpellAction(EXEC_LIB, true)); // office hours enabled
        spell  = DssExecFactory(EXEC_FACTORY).newWeeklyExec(
            SpellAction(_action).description(),    // action description
            address(_action)                       // action address
        );
    }

}
