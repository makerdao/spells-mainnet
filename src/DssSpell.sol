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
pragma solidity 0.6.12;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/master/governance/votes/Executive%20vote%20-%20March%2026%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-03-26 MakerDAO Executive Spell | Hash: 0x735b9ffaa585c6e1d6fb2a4768278ef426402aab0a101b491fb4048c72e4ae27";

    uint256 constant THOUSAND = 10**3;
    uint256 constant MILLION  = 10**6;

    // Disable Office Hours
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // Set bump parameter from 10,000 to 30,000
        DssExecLib.setSurplusAuctionAmount(30 * THOUSAND);

        // Set ETH-B dust parameter from 2,000 to 15,000
        DssExecLib.setIlkMinVaultAmount("ETH-B", 15 * THOUSAND);

        // Set DC-IAM module for UNIV2DAIETH-A, UNIV2USDCETH-A and UNIV2DAIUSDC-A
        DssExecLib.setIlkAutoLineParameters("UNIV2DAIETH-A", 30 * MILLION, 5 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2USDCETH-A", 50 * MILLION, 5 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2DAIUSDC-A", 50 * MILLION, 10 * MILLION, 12 hours);
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
