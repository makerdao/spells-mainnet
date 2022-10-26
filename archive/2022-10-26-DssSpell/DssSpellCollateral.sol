// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
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

import "dss-exec-lib/DssExecLib.sol";

contract DssSpellCollateralAction {

    // --- Rates ---
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    // https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    uint256 internal constant ONE_FIVE_PCT_RATE = 1000000000472114805215157978;
    
    // --- Math ---
    uint256 constant THOUSAND   = 10 ** 3;
    uint256 constant MILLION    = 10 ** 6;
    // uint256 constant BILLION    = 10 ** 9;

    // --- DEPLOYED COLLATERAL ADDRESSES ---
    address internal constant RETH                 = 0xae78736Cd615f374D3085123A210448E74Fc6393;
    address internal constant PIP_RETH             = 0xeE7F0b350aA119b3d05DC733a4621a81972f7D47;
    address internal constant MCD_JOIN_RETH_A      = 0xC6424e862f1462281B0a5FAc078e4b63006bDEBF;
    address internal constant MCD_CLIP_RETH_A      = 0x27CA5E525ea473eD52Ea9423CD08cCc081d96a98;
    address internal constant MCD_CLIP_CALC_RETH_A = 0xc59B62AFC96cf9737F717B5e5815070C0f154396;

    function collateralAction() internal {
        onboardCollaterals();
        //updateCollaterals();
        //offboardCollaterals();
    }

    function onboardCollaterals() internal {
        // ----------------------------- Collateral onboarding -----------------------------
        //  Add RETH-A as a new Vault Type
        //  Poll Link 1: https://vote.makerdao.com/polling/QmfMswF2
        //  Poll Link 2: https://vote.makerdao.com/polling/QmS7dBuQ
        //  Forum Post:  https://forum.makerdao.com/t/reth-collateral-onboarding-risk-evaluation/15286

        DssExecLib.addNewCollateral(
            CollateralOpts({
                ilk:                  "RETH-A",
                gem:                  RETH,
                join:                 MCD_JOIN_RETH_A,
                clip:                 MCD_CLIP_RETH_A,
                calc:                 MCD_CLIP_CALC_RETH_A,
                pip:                  PIP_RETH,
                isLiquidatable:       true,
                isOSM:                true,
                whitelistOSM:         true,
                ilkDebtCeiling:       0,                 // line updated to 0 (previously 5M)
                minVaultAmount:       15 * THOUSAND,            // debt floor - dust in DAI
                maxLiquidationAmount: 2 * MILLION,
                liquidationPenalty:   13_00,             // 13% penalty on liquidation
                ilkStabilityFee:      ONE_FIVE_PCT_RATE, // 1.50% stability fee
                startingPriceFactor:  110_00,            // Auction price begins at 110% of oracle price
                breakerTolerance:     50_00,             // Allows for a 50% hourly price drop before disabling liquidation
                auctionDuration:      120 minutes,
                permittedDrop:        45_00,             // 45% price drop before reset
                liquidationRatio:     170_00,            // 170% collateralization
                kprFlatReward:        250,               // 250 DAI tip - flat fee per kpr
                kprPctReward:         10                 // 0.1% chip - per kpr
            })
        );

        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_RETH_A, 90 seconds, 99_00);

        // ChainLog Updates
        // Add the new join, clip, and abacus to the Chainlog
        DssExecLib.setChangelogAddress("RETH",                 RETH);
        DssExecLib.setChangelogAddress("PIP_RETH",             PIP_RETH);
        DssExecLib.setChangelogAddress("MCD_JOIN_RETH_A",      MCD_JOIN_RETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_RETH_A",      MCD_CLIP_RETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_RETH_A", MCD_CLIP_CALC_RETH_A);

    }

    function updateCollaterals() internal {
        // ------------------------------- Collateral updates -------------------------------

        // Enable autoline for XXX-A
        // Poll Link:
        // Forum Link:
        // DssExecLib.setIlkAutoLineParameters(
        //    XXX-A,
        //    AMOUNT,
        //    GAP,
        //    TTL
        // );
    }

    function offboardCollaterals() internal {
        // ----------------------------- Collateral offboarding -----------------------------
        // 1st Stage of Collateral Offboarding Process
        // Poll Link:
        // uint256 line;
        // uint256 lineReduction;

        // Set XXX-A Maximum Debt Ceiling to 0
        // (,,,line,) = vat.ilks("XXX-A");
        // lineReduction += line;
        // DssExecLib.removeIlkFromAutoLine("XXX-A");
        // DssExecLib.setIlkDebtCeiling("XXX-A", 0);

        // Set XXX-A Maximum Debt Ceiling to 0
        // (,,,line,) = vat.ilks("XXX-A");
        // lineReduction += line;
        // DssExecLib.removeIlkFromAutoLine("XXX-A");
        // DssExecLib.setIlkDebtCeiling("XXX-A", 0);

        // Decrease Global Debt Ceiling by total amount of offboarded ilks
        // vat.file("Line", _sub(vat.Line(), lineReduction));

        // 2nd Stage of Collateral Offboarding Process
        // address spotter = DssExecLib.spotter();

        // Offboard XXX-A
        // Poll Link:
        // Forum Link:

        // DssExecLib.setIlkLiquidationPenalty("XXX-A", 0);
        // DssExecLib.setKeeperIncentiveFlatRate("XXX-A", 0);
        // DssExecLib.linearInterpolation({
        //     _name:      "XXX-A Offboarding",
        //     _target:    spotter,
        //     _ilk:       "XXX-A",
        //     _what:      "mat",
        //     _startTime: block.timestamp,
        //     _start:     CURRENT_XXX_A_MAT,
        //     _end:       TARGET_XXX_A_MAT,
        //     _duration:  30 days
        // });

        // Offboard XXX-A
        // Poll Link:
        // Forum Link:

        // DssExecLib.setIlkLiquidationPenalty("XXX-A", 0);
        // DssExecLib.setKeeperIncentiveFlatRate("XXX-A", 0);
        // DssExecLib.linearInterpolation({
        //     _name:      "XXX-A Offboarding",
        //     _target:    spotter,
        //     _ilk:       "XXX-A",
        //     _what:      "mat",
        //     _startTime: block.timestamp,
        //     _start:     CURRENT_XXX_A_MAT,
        //     _end:       TARGET_XXX_A_MAT,
        //     _duration:  30 days
        // });
    }

    // --- Offboarding: Current Liquidation Ratio ---
    // uint256 constant CURRENT_XXX_A_MAT              =  XYZ * RAY / 100;

    // --- Offboarding: Target Liquidation Ratio ---
    // uint256 constant TARGET_XXX_A_MAT               =  XYZ * RAY / 100;

}
