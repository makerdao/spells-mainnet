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

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/Executive%20vote%20-%20April%2015%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-04-22 MakerDAO Executive Spell | Hash: TODO";

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

    // --- Rates ---
    //uint256 constant FOUR_FIVE_PCT_RATE      = 1000000001395766281313196627;

    address constant internal OASIS_APP_OSM_READER     = 0x55Dc2Be8020bCa72E58e665dC931E03B749ea5E0;

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();

        // --------------------------------- Oasis.app OSM Whitelist ---------------------------------------
        // https://vote.makerdao.com/polling/QmZykRSM
        DssExecLib.addReaderToWhitelist(DssExecLib.getChangelogAddress("PIP_ETH"),    OASIS_APP_OSM_READER);
        DssExecLib.addReaderToWhitelist(DssExecLib.getChangelogAddress("PIP_WSTETH"), OASIS_APP_OSM_READER);
        DssExecLib.addReaderToWhitelist(DssExecLib.getChangelogAddress("PIP_WBTC"),   OASIS_APP_OSM_READER);
        DssExecLib.addReaderToWhitelist(DssExecLib.getChangelogAddress("PIP_RENBTC"), OASIS_APP_OSM_READER);
        DssExecLib.addReaderToWhitelist(DssExecLib.getChangelogAddress("PIP_YFI"),    OASIS_APP_OSM_READER);
        DssExecLib.addReaderToWhitelist(DssExecLib.getChangelogAddress("PIP_UNI"),    OASIS_APP_OSM_READER);
        DssExecLib.addReaderToWhitelist(DssExecLib.getChangelogAddress("PIP_LINK"),   OASIS_APP_OSM_READER);
        DssExecLib.addReaderToWhitelist(DssExecLib.getChangelogAddress("PIP_MANA"),   OASIS_APP_OSM_READER);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
