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

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol";

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/5a8f09353e2a7d7f0d9f6a357cd05901348fe227/governance/votes/Executive%20vote%20-%20January%2024%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-01-24 MakerDAO Emergency Executive Spell | Hash: 0x75da13d2bed7612e2e1960e7fe193453b66ead6e5d68b9a553258b0d421a21db";

    address constant SB_LERP = 0x0239311B645A8EF91Dc899471497732A1085BA8b;

    // Math
    uint256 constant MILLION = 10**6;

    // Turn office hours off
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {

        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();

        // Deauthorize the existing lerp to prevent additional overwrites of hump.
        DssExecLib.deauthorize(DssExecLib.vow(), SB_LERP);

        DssExecLib.setSurplusBuffer(250 * MILLION);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
