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

interface FlashKillerLike {
    function vat() external view returns (address);
    function flash() external view returns (address);
}

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget  -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-03-09 MakerDAO Executive Spell | Hash: ";

    address constant FLASH_KILLER = 0x07a4BaAEFA236A649880009B5a2B862097D9a1cD;

    // Turn office hours off
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        require(FlashKillerLike(FLASH_KILLER).vat() == DssExecLib.vat(), "DssSpell/non-matching-vat");
        address flash = DssExecLib.getChangelogAddress("MCD_FLASH");
        require(FlashKillerLike(FLASH_KILLER).flash() == flash, "DssSpell/non-matching-flash");
        DssExecLib.authorize(flash, FLASH_KILLER);
        DssExecLib.setChangelogAddress("FLASH_KILLER", FLASH_KILLER);
        DssExecLib.setChangelogVersion("1.10.1");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
