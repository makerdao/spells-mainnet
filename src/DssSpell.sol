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

interface Bumpable {
    function bump(bytes32, uint256) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/6d2eaab1360395916b9b09c4137c5da6f2de9f1a/governance/votes/Executive%20vote%20-%20July%2017%2C%202021.md -q -O - 2> /dev/null)"
    string public constant override description =
        "2021-07-17 MakerDAO Executive Spell | Hash: 0x887d27e20f47d0701d1eea14045bb5fdbea634401f7dc5aedd729af13a5c8ddc";

    // Turn off office hours
    function officeHours() public override returns (bool) {
        return false;
    }

    uint256 constant WAD     = 10 ** 18;
    uint256 constant MILLION = 10 ** 6;

    address constant RWA_LIQUIDATION_ORACLE = 0x88f88Bb9E66241B73B84f3A6E197FbBa487b1E30;

    function actions() public override {

        // https://vote.makerdao.com/polling/QmUNouQ7?network=mainnet#poll-detail

        bytes32 ilk = bytes32("RWA002-A");

        // Will also increase the global debt ceiling.
        DssExecLib.increaseIlkDebtCeiling(ilk, 15 * MILLION, true);

        // Must increase the price to enable DAI to be drawn--value corresponds to
        // [ (debt ceiling) + (2 years interest at current rate) ] * mat, i.e.
        // 20MM * 1.035^2 * 1.05 as a WAD
        Bumpable(RWA_LIQUIDATION_ORACLE).bump(ilk, 22_495_725 * WAD);
        DssExecLib.updateCollateralPrice(ilk);

        // ---------------------------------------------------------------------

        // https://vote.makerdao.com/polling/Qmb65Ynh?network=mainnet#poll-detail

        DssExecLib.setSurplusAuctionBidDuration(30 minutes);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
