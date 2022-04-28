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

    // --- Math ---
    uint256 constant MILLION = 10**6;

    uint256 constant ZERO_SEVEN_FIVE_PCT_RATE = 1000000000236936036262880196;

    // --- DEPLOYED COLLATERAL ADDRESSES ---
    // address constant STETH                  = 0x1643E812aE58766192Cf7D2Cf9567dF2C37e9B7F;
    address constant WSTETH                 = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address constant PIP_WSTETH             = 0xFe7a2aC0B945f12089aEEB6eCebf4F384D9f043F;
    address constant MCD_JOIN_WSTETH_B      = 0x248cCBf4864221fC0E840F29BB042ad5bFC89B5c;
    address constant MCD_CLIP_WSTETH_B      = 0x3ea60191b7d5990a3544B6Ef79983fD67e85494A;
    address constant MCD_CLIP_CALC_WSTETH_B = 0x95098b29F579dbEb5c198Db6F30E28F7f3955Fbb;

    function onboardNewCollaterals() internal {
        // ----------------------------- Collateral onboarding -----------------------------
        //  Add WSTETH-B as a new Vault Type
        //  Poll Link: https://vote.makerdao.com/polling/QmaE5doB#poll-detail

        DssExecLib.addNewCollateral(CollateralOpts({
            ilk:                   "WSTETH-B",
            gem:                   WSTETH,
            join:                  MCD_JOIN_WSTETH_B,
            clip:                  MCD_CLIP_WSTETH_B,
            calc:                  MCD_CLIP_CALC_WSTETH_B,
            pip:                   PIP_WSTETH,
            isLiquidatable:        true,
            isOSM:                 true,
            whitelistOSM:          false,
            ilkDebtCeiling:        0,
            minVaultAmount:        5000,
            maxLiquidationAmount:  10 * MILLION,
            liquidationPenalty:    1300,                     // 13% penalty fee
            ilkStabilityFee:       ZERO_SEVEN_FIVE_PCT_RATE, //0.75% stability fee
            startingPriceFactor:   12000,                    // Auction price begins at 120% of oracle
            breakerTolerance:      5000,                     // Allows for a 50% hourly price drop before disabling liquidations
            auctionDuration:       140 minutes,
            permittedDrop:         4000,                     // 40% price drop before reset
            liquidationRatio:      18500,                    // 185% collateralization
            kprFlatReward:         300,                      // 300 Dai
            kprPctReward:          10                        // chip 0.1%
        }));

        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_WSTETH_B, 90 seconds, 9900);
        DssExecLib.setIlkAutoLineParameters("WSTETH-B", 150 * MILLION, 15 * MILLION, 8 hours);

        // ChainLog Updates
        // Add the new join, clip, and abacus to the Chainlog
        DssExecLib.setChangelogAddress("MCD_JOIN_WSTETH_B",      MCD_JOIN_WSTETH_B);
        DssExecLib.setChangelogAddress("MCD_CLIP_WSTETH_B",      MCD_CLIP_WSTETH_B);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_WSTETH_B", MCD_CLIP_CALC_WSTETH_B);
    }
}
