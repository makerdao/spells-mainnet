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

import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol";

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/45ce05217966639a20dda7334f75e2c6ac0c69af/governance/votes/Executive%20vote%20-%20January%2014%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-01-21 MakerDAO Executive Spell | Hash: 0x0";

    // --- Rates ---
    uint256 constant TWO_FIVE_PCT_RATE       = 1000000000782997609082909351;
    uint256 constant THREE_PCT_RATE          = 1000000000937303470807876289;

    // Turn office hours off
    // function officeHours() public override returns (bool) {
    //     return false;
    // }

    function actions() public override {

        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();

        // ----------------------------- Rates updates -----------------------------
        // https://vote.makerdao.com/polling/QmVyyjPF?network=mainnet#poll-detail
        // Decrease the ETH-A Stability Fee from 2.75% to 2.5%
        DssExecLib.setIlkStabilityFee("ETH-A", TWO_FIVE_PCT_RATE, true);

        // Decrease the WSTETH-A Stability Fee from 4.0% to 3.0%
        DssExecLib.setIlkStabilityFee("WSTETH-A", THREE_PCT_RATE, true);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
