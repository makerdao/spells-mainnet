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

import "dss-exec-lib/DssExecLib.sol";

contract DssSpellCollateralOnboardingAction {

    // --- Rates ---
    uint256 constant ONE_PCT_RATE = 1000000000315522921573372069;

    // --- Math ---
    uint256 constant MILLION = 10 ** 6;

    // --- GUNIV3DAIUSDC2-A ---
    address constant GUNIV3DAIUSDC2                 = 0x50379f632ca68D36E50cfBC8F78fe16bd1499d1e;
    address constant MCD_JOIN_GUNIV3DAIUSDC2_A      = 0xA7e4dDde3cBcEf122851A7C8F7A55f23c0Daf335;
    address constant MCD_CLIP_GUNIV3DAIUSDC2_A      = 0xB55da3d3100C4eBF9De755b6DdC24BF209f6cc06;
    address constant MCD_CLIP_CALC_GUNIV3DAIUSDC2_A = 0xef051Ca2A2d809ba47ee0FC8caaEd06E3D832225;
    address constant PIP_GUNIV3DAIUSDC2             = 0xcCBa43231aC6eceBd1278B90c3a44711a00F4e93;

    function onboardNewCollaterals() internal {
        // ----------------------------- Collateral onboarding -----------------------------
        //  Add GUNIV3DAIUSDC2-A as a new Vault Type
        //  https://vote.makerdao.com/polling/QmSkHE8T?network=mainnet#poll-detail
        DssExecLib.addNewCollateral(
            CollateralOpts({
                ilk:                   "GUNIV3DAIUSDC2-A",
                gem:                   GUNIV3DAIUSDC2,
                join:                  MCD_JOIN_GUNIV3DAIUSDC2_A,
                clip:                  MCD_CLIP_GUNIV3DAIUSDC2_A,
                calc:                  MCD_CLIP_CALC_GUNIV3DAIUSDC2_A,
                pip:                   PIP_GUNIV3DAIUSDC2,
                isLiquidatable:        false,
                isOSM:                 true,
                whitelistOSM:          true,
                ilkDebtCeiling:        10 * MILLION,
                minVaultAmount:        15_000,
                maxLiquidationAmount:  5 * MILLION,
                liquidationPenalty:    1300,
                ilkStabilityFee:       ONE_PCT_RATE,
                startingPriceFactor:   10500,
                breakerTolerance:      9500,
                auctionDuration:       220 minutes,
                permittedDrop:         9000,
                liquidationRatio:      10500,
                kprFlatReward:         300,
                kprPctReward:          10
            })
        );

        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_GUNIV3DAIUSDC2_A, 120 seconds, 9990);
        DssExecLib.setIlkAutoLineParameters("GUNIV3DAIUSDC2-A", 10 * MILLION, 10 * MILLION, 8 hours);
    }
}