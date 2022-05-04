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
pragma experimental ABIEncoderV2;
import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol";

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/6b4cedd333d710702f50b0e679b005286773b6d3/governance/votes/Executive%20vote%20-%20April%2022%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        // TODO: update this
        "2022-XX-YY MakerDAO Executive Spell | Hash: 0x0000000000000000000000000000000000000000000000000000000000000000";

    // Math

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmPgPVrVxDCGyNR5rGp9JC5AUxppLzUAqvncRJDcxQnX1u
    //

    uint256 constant TWO_TWO_FIVE_PCT_RATE = 1000000000705562181084137268;
    uint256 constant FOUR_PCT_RATE         = 1000000001243680656318820312;

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralOnboardingAction
        onboardNewCollaterals();

        // MOMC Proposal
        // https://vote.makerdao.com/polling/QmTmehbz#poll-detail

        //Lower the WBTC-A Stability Fee from 3.25% to 2.25%.
        DssExecLib.setIlkStabilityFee("WBTC-A", TWO_TWO_FIVE_PCT_RATE, true);

        //Lower the WBTC-B Stability Fee from 4.5% to 4.0%.
        DssExecLib.setIlkStabilityFee("WBTC-B", FOUR_PCT_RATE, true);

        DssExecLib.setChangelogVersion("1.12.1");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
