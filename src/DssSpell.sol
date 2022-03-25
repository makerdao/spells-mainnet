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

interface GemJoin6Like {
    function setImplementation(
        address implementation,
        uint256 permitted
    ) external;
}

interface AuthLike {
    function rely(address) external;
}

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/Executive%20Vote%20-%20March%2025%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-03-25 MakerDAO Executive Spell | Hash: TODO";

    address public constant TUSD_PREV_IMPL = 0xffc40F39806F1400d8278BfD33823705b5a4c196;
    address public constant TUSD_NEXT_IMPL = 0xd8D59c59Ab40B880b54C969920E8d9172182Ad7b;

    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // onboardNewCollaterals();

        // Update TUSD implementation
        // https://forum.makerdao.com/t/2022-03-25-adding-support-for-the-new-tusd-implementation-address/14189
        address MCD_JOIN_TUSD_A = DssExecLib.getChangelogAddress("MCD_JOIN_TUSD_A");
        GemJoin6Like(MCD_JOIN_TUSD_A).setImplementation(TUSD_PREV_IMPL, 0);
        GemJoin6Like(MCD_JOIN_TUSD_A).setImplementation(TUSD_NEXT_IMPL, 1);

        // Authorize ESM on DssFlash
        // https://forum.makerdao.com/t/proposed-security-fix-to-be-added-in-the-march-25th-2022-executive-spell
        address MCD_FLASH = DssExecLib.getChangelogAddress("MCD_FLASH");
        address MCD_ESM = DssExecLib.esm();
        DssExecLib.authorize(MCD_FLASH, MCD_ESM);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
