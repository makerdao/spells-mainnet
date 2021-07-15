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

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

contract DssSpellAction is DssAction {

    // Turn off office hours
    function officeHours() public override returns (bool) {
        return false;
    }

    uint256 constant MILLION = 10 ** 6;

    function actions() public override {

        // https://vote.makerdao.com/polling/QmUNouQ7?network=mainnet#poll-detail
        // Will also increase the global debt ceiling.
        DssExecLib.increaseIlkDebtCeiling(bytes32("RWA002-A"), 15 * MILLION, true);

        // https://vote.makerdao.com/polling/Qmb65Ynh?network=mainnet#poll-detail
        DssExecLib.setSurplusAuctionBidDuration(30 minutes);
    }
}

contract DssSpell is DssExec {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/Executive%20vote%20-%20July%2016%2C%202021.md -q -O - 2> /dev/null)"
    string private constant description_ =
        "2021-07-16 MakerDAO Executive Spell | Hash: TODO";

    constructor() DssExec(description_, block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
