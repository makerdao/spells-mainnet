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
        "2022-01-21 MakerDAO Executive Spell | Hash: 0x0 TODO";

    // --- Rates ---
    uint256 constant ZERO_FIVE_PCT_RATE      = 1000000000158153903837946257;
    uint256 constant TWO_FIVE_PCT_RATE       = 1000000000782997609082909351;
    uint256 constant THREE_PCT_RATE          = 1000000000937303470807876289;

    // Math
    uint256 constant MILLION = 10**6;

    // Turn office hours off
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {

        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();

        // ------------------------- Rates updates -----------------------------
        // https://vote.makerdao.com/polling/QmVyyjPF?network=mainnet#poll-detail
        // Decrease the ETH-A Stability Fee from 2.75% to 2.5%
        DssExecLib.setIlkStabilityFee("ETH-A", TWO_FIVE_PCT_RATE, true);

        // Decrease the WSTETH-A Stability Fee from 4.0% to 3.0%
        DssExecLib.setIlkStabilityFee("WSTETH-A", THREE_PCT_RATE, true);

        // Decrease the GUNIV3DAIUSDC2-A Stability Fee from 1% to 0.5%
        DssExecLib.setIlkStabilityFee("GUNIV3DAIUSDC2-A", ZERO_FIVE_PCT_RATE, true);


        // ---------------------- Debt Ceiling updates -------------------------
        // https://vote.makerdao.com/polling/QmVyyjPF?network=mainnet#poll-detail
        // Decrease the LINK-A Maximum Debt Ceiling from 140 million DAI to 100 million DAI.
        DssExecLib.setIlkAutoLineDebtCeiling("LINK-A", 100 * MILLION);

        // Decrease the YFI-A Maximum Debt Ceiling (line) from 130 million DAI to 50 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("YFI-A", 50 * MILLION);

        // Decrease the UNI-A Maximum Debt Ceiling (line) from 50 million DAI to 25 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("UNI-A", 25 * MILLION);

        // Decrease the UNIV2UNIETH-A Maximum Debt Ceiling (line) from 20 million DAI to 5 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("UNIV2UNIETH-A", 5 * MILLION);

        // Decrease the GUSD-A Debt Ceiling from 5 million DAI to zero DAI
        DssExecLib.decreaseIlkDebtCeiling("GUSD-A", 5 * MILLION, true);

        // Increase the GUNIV3DAIUSDC2-A Maximum Debt Ceiling (line) from 10 million DAI to 500 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("GUNIV3DAIUSDC2-A", 500 * MILLION);


        // ------------------ Liquiduation Ratio updates -----------------------
        // https://vote.makerdao.com/polling/QmbFqWGK?network=mainnet#poll-detail
        // Decrease the GUNIV3DAIUSDC2-A Liquidation Ratio from 105% to 102%
        DssExecLib.setIlkLiquidationRatio("GUNIV3DAIUSDC2-A", 10200);


        // ------------------------- AAVE D3M updates --------------------------
        // https://vote.makerdao.com/polling/QmVyyjPF?network=mainnet#poll-detail
        // Decrease the DIRECT-AAVEV2-DAI Target Borrow Rate (bar) from 3.9% to 3.75%
        DssExecLib.setValue(DssExecLib.getChangelogAddress("MCD_JOIN_DIRECT_AAVEV2_DAI"), "bar", 3.75 * 10**27 / 100);

        // Increase the DIRECT-AAVEV2-DAI Target Available Debt (gap) from 25 million DAI to 50 million DAI
        // Increase the DIRECT-AAVEV2-DAI Maximum Debt Ceiling (line) from 100 million DAI to 220 million DAI
        DssExecLib.setIlkAutoLineParameters("DIRECT-AAVEV2-DAI", 220 * MILLION, 50 * MILLION, 12 hours);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
