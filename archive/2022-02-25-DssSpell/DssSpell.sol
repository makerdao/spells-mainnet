// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2021-2022 Dai Foundation
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
// Enable ABIEncoderV2 when onboarding collateral
//pragma experimental ABIEncoderV2;
import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol";


contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/181833b1a139cd09705d809697adc2e6a94f54dd/governance/votes/Executive%20Vote%20-%20February%2025%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-02-25 MakerDAO Executive Spell | Hash: 0x29cc4d6453529846a34d9de91c0d19005bcf4f8d2526f26f1cd03b4be8ef4052";

    uint256 constant MILLION = 10**6;

    address constant MAKERMAN_WALLET = 0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0;

    // Turn office hours off
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // Increase PSM-GUSD-A max debt ceiling from 10M to 60M
        // https://vote.makerdao.com/polling/QmWPYU9c
        DssExecLib.setIlkAutoLineDebtCeiling("PSM-GUSD-A", 60 * MILLION);

        // Pay retroactive delegate compensation to MakerMan
        // https://vote.makerdao.com/polling/QmR2DX4L
        DssExecLib.sendPaymentFromSurplusBuffer(MAKERMAN_WALLET, 8_245);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
