// SPDX-FileCopyrightText: © 2021-2022 Dai Foundation <www.daifoundation.org>
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
// pragma experimental ABIEncoderV2;
import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol";

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/428d97b75ec8bdb4f2b87e69dcc917ad750b8c76/governance/votes/Executive%20vote%20-%20June%208%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-06-22 MakerDAO Executive Spell | Hash: 0x0";

    // Math
    uint256 constant WAD = 10**18;

    address public constant DECO_WALLET = 0xF482D1031E5b172D42B2DAA1b6e5Cbf6519596f7;
    address public constant RWF_WALLET  = 0x96d7b01Cc25B141520C717fa369844d34FF116ec;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmPgPVrVxDCGyNR5rGp9JC5AUxppLzUAqvncRJDcxQnX1u
    //

    // Turn office hours off
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();

        // transfer 500 MKR from treasury to DECO wallet
        // https://vote.makerdao.com/polling/QmPPvUhN#vote-breakdown
        GemLike(DssExecLib.mkr()).transfer(DECO_WALLET, 500 * WAD);

        // transfer 80 MKR from treasury to RWF wallet
        // https://vote.makerdao.com/polling/QmYNiuNE#vote-breakdown
        GemLike(DssExecLib.mkr()).transfer(RWF_WALLET, 80 * WAD);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
