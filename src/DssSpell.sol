// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2021 Dai Foundation
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

    uint256 constant THOUSAND = 10**3;
    uint256 constant MILLION  = 10**6;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-10-15 MakerDAO Executive Spell | Hash: 0x";

    address constant public PI_WALLET = 0xBde950A3588C680fee26A7cFC7A34aE97EB45B8C;

    function actions() public override {


        // PaperImperium Supplemental Compensation - October 11, 2021
        //  https://vote.makerdao.com/polling/QmdmeUjv#poll-detail
        DssExecLib.sendPaymentFromSurplusBuffer(PI_WALLET, 50 * THOUSAND);

        // Increase the GUNIV3DAIUSDC1-A Debt Ceiling - October 11, 2021
        //  https://vote.makerdao.com/polling/QmU6fTQx#poll-detail
        DssExecLib.increaseIlkDebtCeiling("GUNIV3DAIUSDC1-A", 40 * MILLION, true);
    }
}


contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
