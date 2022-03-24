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

import "dss-exec-lib/DssExecLib.sol";

contract DssSpellCollateralOnboardingAction {

    // --- Rates ---
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmTRiQ3GqjCiRhh1ojzKzgScmSsiwQPLyjhgYSxZASQekj
    //
    uint256 constant NUMBER_PCT = 1000000001234567890123456789;

    // --- Math ---
    uint256 constant THOUSAND   = 10 ** 3;
    uint256 constant MILLION    = 10 ** 6;

    // --- DEPLOYED COLLATERAL ADDRESSES ---
    address constant XXX                  = 0x06325440D014e39736583c165C2963BA99fAf14E;
    address constant PIP_XXX              = 0x0A7DA4e31582a2fB4FD4067943e88f127F70ab39;
    address constant MCD_JOIN_XXX_A       = 0x82D8bfDB61404C796385f251654F6d7e92092b5D;
    address constant MCD_CLIP_XXX_A       = 0x1926862F899410BfC19FeFb8A3C69C7Aed22463a;
    address constant MCD_CLIP_CALC_XXX_A  = 0x8a4780acABadcae1a297b2eAe5DeEbd7d50DEeB8;

    function onboardNewCollaterals() internal {
        // ----------------------------- Collateral onboarding -----------------------------
        //  Add CRVV1ETHSTETH-A as a new Vault Type
        //  Poll Link: https://vote.makerdao.com/polling/Qmek9vzo?network=mainnet#poll-detail
        // DssExecLib.addNewCollateral(
        //     CollateralOpts({
        //         ilk:                   "XXX-A",
        //         gem:                   XXX,
        //         join:                  MCD_JOIN_XXX_A,
        //         clip:                  MCD_CLIP_XXX_A,
        //         calc:                  MCD_CLIP_CALC_XXX_A,
        //         pip:                   PIP_XXX,
        //         isLiquidatable:        true,
        //         isOSM:                 true,
        //         whitelistOSM:          false,           // We need to whitelist OSM, but Curve Oracle orbs() function is not supported
        //         ilkDebtCeiling:        3 * MILLION,
        //         minVaultAmount:        25 * THOUSAND,
        //         maxLiquidationAmount:  3 * MILLION,
        //         liquidationPenalty:    1300,
        //         ilkStabilityFee:       NUMBER_PCT,
        //         startingPriceFactor:   13000,
        //         breakerTolerance:      5000,
        //         auctionDuration:       140 minutes,
        //         permittedDrop:         4000,
        //         liquidationRatio:      15500,
        //         kprFlatReward:         300,
        //         kprPctReward:          10
        //     })
        // );
        // DssExecLib.setStairstepExponentialDecrease(
        //     MCD_CLIP_CALC_XXX_A,
        //     90 seconds,
        //     9900
        // );
        // DssExecLib.setIlkAutoLineParameters(
        //     "XXX-A",
        //     3 * MILLION,
        //     3 * MILLION,
        //     8 hours
        // );

        // Whitelist OSM - normally handled in addNewCollateral, but Curve LP Oracle format is not supported yet
        // DssExecLib.addReaderToWhitelistCall(CurveLPOracleLike(PIP_ETHSTETH).orbs(0), PIP_ETHSTETH);
        // DssExecLib.addReaderToWhitelistCall(CurveLPOracleLike(PIP_ETHSTETH).orbs(1), PIP_ETHSTETH);

        // ChainLog Updates
        // DssExecLib.setChangelogAddress("XXX", XXX);
        // DssExecLib.setChangelogAddress("PIP_XXX", PIP_XXX);
        // DssExecLib.setChangelogAddress("MCD_JOIN_XXX_A", MCD_JOIN_XXX_A);
        // DssExecLib.setChangelogAddress("MCD_CLIP_XXX_A", MCD_CLIP_XXX_A);
        // DssExecLib.setChangelogAddress("MCD_CLIP_CALC_XXX_A", MCD_CLIP_CALC_XXX_A);
    }
}
