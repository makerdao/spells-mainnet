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

// import { DssSpellCollateralAction } from "./DssSpellCollateral.sol";

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/Executive%TODO.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-09-07 MakerDAO Executive Spell | Hash: TODO";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // --- Rates ---

    uint256 internal constant ONE_FIVE_PCT_RATE     = 1000000000472114805215157978;
    uint256 internal constant TWO_PCT_RATE          = 1000000000627937192491029810;
    uint256 internal constant TWO_TWO_FIVE_PCT_RATE = 1000000000705562181084137268;
    uint256 internal constant THREE_PCT_RATE        = 1000000000937303470807876289;
    uint256 internal constant THREE_FIVE_PCT_RATE   = 1000000001090862085746321732;
    uint256 internal constant FOUR_FIVE_PCT_RATE    = 1000000001395766281313196627;

    uint256 internal constant MILLION = 10**6;

    uint256 internal constant WAD = 10**18; // TODO: is needed?
    uint256 internal constant RAY = 10**27; // TODO: is needed?

    // TODO: is office hours indeed on?

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralAction
        // onboardNewCollaterals();
        // offboardCollaterals();

        // ----------------------------- MKR Vesting -----------------------------
        // NOTE: ignore in goerli

        // ------------------------ Delegate Compensation ------------------------
        // NOTE: ignore in goerli

        // ------------------ PPG - Maker Open Market Committee ------------------
        // https://vote.makerdao.com/polling/QmXHnn2u#poll-detail

        ////// Stability Fee Changes //////

        // Decrease the CRVV1ETHSTETH-A Stability Fee from 2.25% to 2.0%.
        DssExecLib.setIlkStabilityFee("CRVV1ETHSTETH-A", TWO_PCT_RATE, true);

        // Decrease the MANA-A Stability Fee from 6% to 4.5%.
        DssExecLib.setIlkStabilityFee("MANA-A", FOUR_FIVE_PCT_RATE, true);

        // Decrease the ETH-A Stability Fee from 2.25% to 1.5%.
        DssExecLib.setIlkStabilityFee("ETH-A", ONE_FIVE_PCT_RATE, true);

        // Decrease the ETH-B Stability Fee from 3.75% to 3.0%.
        DssExecLib.setIlkStabilityFee("ETH-B", THREE_PCT_RATE, true);

        // Decrease the WSTETH-A Stability Fee from 2.25% to 1.5%.
        DssExecLib.setIlkStabilityFee("WSTETH-A", ONE_FIVE_PCT_RATE, true);

        // Decrease the WBTC-A Stability Fee from 2.25% to 2%.
        DssExecLib.setIlkStabilityFee("WBTC-A", TWO_PCT_RATE, true);

        // Decrease the WBTC-B Stability Fee from 3.75% to 3.5%.
        DssExecLib.setIlkStabilityFee("WBTC-B", THREE_FIVE_PCT_RATE, true);

        // Decrease the RENBTC-A Stability Fee from 2.5% to 2.25%.
        DssExecLib.setIlkStabilityFee("RENBTC-A", TWO_TWO_FIVE_PCT_RATE, true);

        ////// Maximum Debt Ceiling Changes + Target Available Debt Change //////

        // Increase the WSTETH-B Maximum Debt Ceiling from 100 million DAI to 200 million DAI.
        DssExecLib.setIlkAutoLineDebtCeiling("WSTETH-B", 200 * MILLION);

        // Increase the CRVV1ETHSTETH-A Maximum Debt Ceiling from 5 million DAI to 20 million DAI
        // Increase the CRVV1ETHSTETH-A Target Available Debt from 3 million DAI to 10 million DAI.
        DssExecLib.setIlkAutoLineParameters("CRVV1ETHSTETH-A", 20 * MILLION, 10 * MILLION, 8 hours);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
