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
import "dss-interfaces/dss/FlapAbstract.sol";

import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol";


contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/6fa5724ffd5801bbcf37802205ed4f54092c6147/governance/votes/Executive%20vote%20-%20March%204%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-03-11 MakerDAO Executive Spell | Hash: TODO";

    // Flap
    address constant MCD_FLAP = 0xa4f79bC4a5612bdDA35904FDF55Fc4Cb53D1BFf6;

    // Math
    uint256 constant RAD = 10**45;

    function actions() public override {
        onboardNewCollaterals();

        // Replace Flapper with rate limit one
        // https://vote.makerdao.com/polling/Qmdd4Pg7
        address MCD_VOW = DssExecLib.vow();
        address MCD_FLAP_OLD = DssExecLib.flap();
        DssExecLib.setValue(MCD_FLAP, "beg", FlapAbstract(MCD_FLAP_OLD).beg());
        DssExecLib.setValue(MCD_FLAP, "ttl", FlapAbstract(MCD_FLAP_OLD).ttl());
        DssExecLib.setValue(MCD_FLAP, "tau", FlapAbstract(MCD_FLAP_OLD).tau());
        DssExecLib.setValue(MCD_FLAP, "lid", 150_000 * RAD);
        DssExecLib.deauthorize(MCD_FLAP_OLD, MCD_VOW);
        DssExecLib.authorize(MCD_FLAP, MCD_VOW);
        DssExecLib.setContract(MCD_VOW, "flapper", MCD_FLAP);

        // Changelog updates
        DssExecLib.setChangelogAddress("MCD_FLAP", MCD_FLAP);
        DssExecLib.setChangelogVersion("1.10.1");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
