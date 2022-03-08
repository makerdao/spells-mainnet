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

interface CurveLPOracleLike {
    function orbs(uint256) external view returns (address);
}

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
    uint256 constant THREE_POINT_FIVE_PCT = 1000000001090862085746321732;

    // --- Math ---
    uint256 constant THOUSAND   = 10 ** 3;
    uint256 constant MILLION    = 10 ** 6;

    // --- PRE-REQUISITE GENERAL DEPLOYS ---
    address constant CDP_REGISTRY              = 0xBe0274664Ca7A68d6b5dF826FB3CcB7c620bADF3;
    address constant PROXY_ACTIONS_CROPPER     = 0xa2f69F8B9B341CFE9BfBb3aaB5fe116C89C95bAF;
    address constant PROXY_ACTIONS_END_CROPPER = 0xAa61752a5Abf86A527A09546F23FE8bCB8fAB2C4;
    address constant CROPPER                   = 0x8377CD01a5834a6EaD3b7efb482f678f2092b77e;

    // --- DEPLOYED COLLATERAL ADDRESSES ---
    address constant ETHSTETH                  = 0x06325440D014e39736583c165C2963BA99fAf14E;
    address constant PIP_ETHSTETH              = 0x100db6699D58467a1099a193F43c5C1203a9edDA;
    address constant MCD_JOIN_ETHSTETH_A       = 0x036A451114E3835AbEF163A67163B6B376cF2480;
    address constant MCD_CLIP_ETHSTETH_A       = 0x2Ae099CE87c1A1291953373F660bdEbbdc1928E9;
    address constant MCD_CLIP_CALC_ETHSTETH_A  = 0x8a4780acABadcae1a297b2eAe5DeEbd7d50DEeB8;

    function onboardNewCollaterals() internal {
        // ----------------------------- Collateral onboarding -----------------------------
        //  Add CRVV1ETHSTETH-A as a new Vault Type
        //  Poll Link: https://vote.makerdao.com/polling/Qmek9vzo?network=mainnet#poll-detail
        DssExecLib.addNewCollateral(
            CollateralOpts({
                ilk:                   "CRVV1ETHSTETH-A",
                gem:                   ETHSTETH,
                join:                  MCD_JOIN_ETHSTETH_A,
                clip:                  MCD_CLIP_ETHSTETH_A,
                calc:                  MCD_CLIP_CALC_ETHSTETH_A,
                pip:                   PIP_ETHSTETH,
                isLiquidatable:        true,
                isOSM:                 true,
                whitelistOSM:          false,           // We need to whitelist OSM, but Curve Oracle orbs() function is not supported
                ilkDebtCeiling:        3 * MILLION,
                minVaultAmount:        15 * THOUSAND,
                maxLiquidationAmount:  3 * MILLION,
                liquidationPenalty:    1300,
                ilkStabilityFee:       THREE_POINT_FIVE_PCT,
                startingPriceFactor:   13000,
                breakerTolerance:      5000,
                auctionDuration:       140 minutes,
                permittedDrop:         4000,
                liquidationRatio:      15500,
                kprFlatReward:         300,
                kprPctReward:          10
            })
        );
        DssExecLib.setStairstepExponentialDecrease(
            MCD_CLIP_CALC_ETHSTETH_A,
            90 seconds,
            9900
        );
        DssExecLib.setIlkAutoLineParameters(
            "CRVV1ETHSTETH-A",
            3 * MILLION,
            3 * MILLION,
            8 hours
        );

        // Extra for crop-join - need to authorize the join adapter with the cropper
        DssExecLib.authorize(MCD_JOIN_ETHSTETH_A, CROPPER);

        // Whitelist OSM - normally handled in addNewCollateral, but Curve LP Oracle format is not supported yet
        DssExecLib.addReaderToWhitelistCall(CurveLPOracleLike(PIP_ETHSTETH).orbs(0), PIP_ETHSTETH);
        DssExecLib.addReaderToWhitelistCall(CurveLPOracleLike(PIP_ETHSTETH).orbs(1), PIP_ETHSTETH);

        // ChainLog Updates
        // Add the new clip and join to the Chainlog
        DssExecLib.setChangelogAddress("CDP_REGISTRY", CDP_REGISTRY);
        DssExecLib.setChangelogAddress("CROPPER", CROPPER);
        DssExecLib.setChangelogAddress("PROXY_ACTIONS_CROPPER", PROXY_ACTIONS_CROPPER);
        DssExecLib.setChangelogAddress("PROXY_ACTIONS_END_CROPPER", PROXY_ACTIONS_END_CROPPER);
        
        DssExecLib.setChangelogAddress("CRVV1ETHSTETH", ETHSTETH);
        DssExecLib.setChangelogAddress("PIP_CRVV1ETHSTETH", PIP_ETHSTETH);
        DssExecLib.setChangelogAddress("MCD_JOIN_CRVV1ETHSTETH_A", MCD_JOIN_ETHSTETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CRVV1ETHSTETH_A", MCD_CLIP_ETHSTETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_CRVV1ETHSTETH_A", MCD_CLIP_CALC_ETHSTETH_A);
    }
}
