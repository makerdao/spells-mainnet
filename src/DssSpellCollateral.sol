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

interface VatLike {
    function Line() external view returns (uint256);
    function file(bytes32, uint256) external;
    function ilks(bytes32) external returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
}

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
    uint256 internal constant FIFTY_PCT_RATE = 1000000012857214317438491659;

    // --- Math ---
    uint256 internal constant MILLION  = 10 ** 6;
    // uint256 internal constant THOUSAND = 10 ** 3;

    function _sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "sub-underflow");
    }

    function collateralAction() internal {
        onboardCollaterals();
        updateCollaterals();
        offboardCollaterals();
    }

    function onboardCollaterals() internal {
        // ----------------------------- Collateral onboarding -----------------------------
        // Add ______________ as a new Vault Type
        // Poll Link:

        // DssExecLib.addNewCollateral(
        //     CollateralOpts({
        //         ilk:                   "XXX-A",
        //         gem:                   XXX,
        //         join:                  MCD_JOIN_XXX_A,
        //         clip:                  MCD_CLIP_XXX_A,
        //         calc:                  MCD_CLIP_CALC_XXX_A,
        //         pip:                   PIP_XXX,
        //         isLiquidatable:        BOOL,
        //         isOSM:                 BOOL,
        //         whitelistOSM:          BOOL,
        //         ilkDebtCeiling:        line,
        //         minVaultAmount:        dust,
        //         maxLiquidationAmount:  hole,
        //         liquidationPenalty:    chop,
        //         ilkStabilityFee:       duty,
        //         startingPriceFactor:   buf,
        //         breakerTolerance:      tolerance,
        //         auctionDuration:       tail,
        //         permittedDrop:         cusp,
        //         liquidationRatio:      mat,
        //         kprFlatReward:         tip,
        //         kprPctReward:          chip
        //     })
        // );

        // DssExecLib.setStairstepExponentialDecrease(
        //     CALC_ADDR,
        //     DURATION,
        //     PCT_BPS
        // );

        // DssExecLib.setIlkAutoLineParameters(
        //     "XXX-A",
        //     AMOUNT,
        //     GAP,
        //     TTL
        // );

        // ChainLog Updates
        // DssExecLib.setChangelogAddress("XXX", XXX);
        // DssExecLib.setChangelogAddress("PIP_XXX", PIP_XXX);
        // DssExecLib.setChangelogAddress("MCD_JOIN_XXX_A", MCD_JOIN_XXX_A);
        // DssExecLib.setChangelogAddress("MCD_CLIP_XXX_A", MCD_CLIP_XXX_A);
        // DssExecLib.setChangelogAddress("MCD_CLIP_CALC_XXX_A", MCD_CLIP_CALC_XXX_A);
    }

    function updateCollaterals() internal {
        // ------------------------------- Collateral updates -------------------------------
        uint256 lineReduction;

        VatLike vat = VatLike(DssExecLib.vat());

        // Adjust autoline DC for MATIC-A
        // Poll Link:  N/A
        // Forum Link: https://forum.makerdao.com/t/urgent-signal-request-urgent-recommended-collateral-parameter-changes/18764
        DssExecLib.setIlkAutoLineDebtCeiling("MATIC-A", 10 * MILLION);

        // Adjust autoline DC for LINK-A
        // Poll Link:  N/A
        // Forum Link: https://forum.makerdao.com/t/urgent-signal-request-urgent-recommended-collateral-parameter-changes/18764
        DssExecLib.setIlkAutoLineDebtCeiling("LINK-A", 5 * MILLION);

        // Adjust autoline DC for YFI-A
        // Poll Link:  N/A
        // Forum Link: https://forum.makerdao.com/t/urgent-signal-request-urgent-recommended-collateral-parameter-changes/18764
        DssExecLib.setIlkAutoLineDebtCeiling("YFI-A", 3 * MILLION);

        // Set RENBTC-A Maximum Debt Ceiling to 0
        // Poll Link:  N/A
        // Forum Link: https://forum.makerdao.com/t/urgent-signal-request-urgent-recommended-collateral-parameter-changes/18764
        (,,,lineReduction,) = vat.ilks("RENBTC-A");
        DssExecLib.removeIlkFromAutoLine("RENBTC-A");
        DssExecLib.setIlkDebtCeiling("RENBTC-A", 0);
        vat.file("Line", _sub(vat.Line(), lineReduction));

        // Adjust: 
        //   - autoline DC for MANA-A
        //   - stability fee for MANA-A to 50%
        //   - liquidation penalty for MANA-A to 30%
        // Poll Link:  N/A
        // Forum Link: https://forum.makerdao.com/t/urgent-signal-request-urgent-recommended-collateral-parameter-changes/18764
        DssExecLib.setIlkAutoLineDebtCeiling("MANA-A", 3 * MILLION);
        DssExecLib.setIlkStabilityFee("MANA-A", FIFTY_PCT_RATE, true);
        DssExecLib.setIlkLiquidationPenalty("MANA-A", 3000); // (30% = 30.00 * 100 = 3000)
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
}
