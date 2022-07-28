// SPDX-FileCopyrightText: © 2020 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
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
// Enable ABIEncoderV2 when onboarding collateral through `DssExecLib.addNewCollateral()`
// pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

import { DssSpellCollateralAction } from "./DssSpellCollateral.sol";

interface ERC20Like {
    function approve(address, uint256) external returns (bool);
}

interface RwaUrnLike {
    function lock(uint256) external;
    function draw(uint256) external;
}

contract DssSpellAction is DssAction, DssSpellCollateralAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/master/governance/votes/Executive%20vote%20-%20July%2029%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-07-29 MakerDAO Executive Spell | Hash: 0x18850080b101bb43125dd2bec32e5e7196586c5614bb9a0f05f9bbe392901d64";

    address constant RWA_TOKEN_FAB = 0x2B3a4c18705e99bC29b22222dA7E10b643658552;

    uint256 constant RWA009_DRAW_AMOUNT = 25_000_000 * WAD;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmX2QMoM1SZq2XMoTbMak8pZP86Y2icpgPAKDjQg4r4YHn
    //

    function officeHours() public override returns (bool) {
        return true;
    }

    function actions() public override {

        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralAction
        onboardNewCollaterals();
        // offboardCollaterals();

        drawFromRWA009Urn();

        // Add RWA_TOKEN_FAB to changelog
        DssExecLib.setChangelogAddress("RWA_TOKEN_FAB", RWA_TOKEN_FAB);

        DssExecLib.setChangelogVersion("1.13.3");
    }

    function drawFromRWA009Urn() internal {
        // lock RWA009 Token in the URN
        ERC20Like(RWA009).approve(RWA009_A_URN, 1 * WAD);
        RwaUrnLike(RWA009_A_URN).lock(1 * WAD);

        // draw DAI to genesis address
        RwaUrnLike(RWA009_A_URN).draw(RWA009_DRAW_AMOUNT);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
