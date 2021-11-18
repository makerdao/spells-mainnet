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
pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";
import "dss-interfaces/dss/VatAbstract.sol";

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/Executive%20Vote%20-%20November%2012%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-11-19 MakerDAO Executive Spell | Hash: ";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //

    // --- Rates ---
    uint256 constant FOUR_PCT_RATE          = 1000000001243680656318820312;
    uint256 constant SEVEN_PCT_RATE         = 1000000002145441671308778766;

    // --- Math ---
    uint256 constant MILLION                = 10 ** 6;
    uint256 constant RAY                    = 10 ** 27;

    // --- WBTC-B ---
    address constant MCD_JOIN_WBTC_B        = 0xfA8c996e158B80D77FbD0082BB437556A65B96E0;
    address constant MCD_CLIP_WBTC_B        = 0xe30663C6f83A06eDeE6273d72274AE24f1084a22;
    address constant MCD_CLIP_CALC_WBTC_B   = 0xeb911E99D7ADD1350DC39d84D60835BA9B287D96;

    // --- Offboarding: Current Liquidation Ratio ---
    uint256 constant CURRENT_AAVE_MAT       =  165 * RAY / 100;
    uint256 constant CURRENT_BAL_MAT        =  165 * RAY / 100;
    uint256 constant CURRENT_COMP_MAT       =  165 * RAY / 100;

    // --- Offboarding: Target Liquidation Ratio ---
    uint256 constant TARGET_AAVE_MAT        = 2200 * RAY / 100;
    uint256 constant TARGET_BAL_MAT         = 2200 * RAY / 100;
    uint256 constant TARGET_COMP_MAT        = 2000 * RAY / 100;

    function _add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "DssSpellAction-add-overflow");
    }
    function _sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "DssSpellAction-sub-underflow");
    }

    function actions() public override {

        // WBTC
        address WBTC     = DssExecLib.getChangelogAddress("WBTC");
        address PIP_WBTC = DssExecLib.getChangelogAddress("PIP_WBTC");

        //  Add WBTC-B as a new Vault Type
        //  https://vote.makerdao.com/polling/QmSL1kDq?network=mainnet#poll-detail (WBTC-B Onboarding)
        //  https://vote.makerdao.com/polling/QmRUgsvi?network=mainnet#poll-detail (Stability Fee)
        //  https://forum.makerdao.com/t/wbtc-b-collateral-onboarding-risk-assessment/11397
        //  https://forum.makerdao.com/t/signal-request-new-iam-vault-type-for-wbtc-with-lower-lr/5736
        DssExecLib.addNewCollateral(
            CollateralOpts({
                ilk:                   "WBTC-B",
                gem:                   WBTC,
                join:                  MCD_JOIN_WBTC_B,
                clip:                  MCD_CLIP_WBTC_B,
                calc:                  MCD_CLIP_CALC_WBTC_B,
                pip:                   PIP_WBTC,
                isLiquidatable:        true,
                isOSM:                 true,
                whitelistOSM:          true,
                ilkDebtCeiling:        30 * MILLION,
                minVaultAmount:        30000,
                maxLiquidationAmount:  25 * MILLION,
                liquidationPenalty:    1300,           // 13% penalty fee
                ilkStabilityFee:       SEVEN_PCT_RATE, // 7% stability fee
                startingPriceFactor:   12000,          // Auction price begins at 120% of oracle
                breakerTolerance:      5000,           // Allows for a 50% hourly price drop before disabling liquidations
                auctionDuration:       90 minutes,
                permittedDrop:         4000,           // 40% price drop before reset
                liquidationRatio:      13000,          // 130% collateralization
                kprFlatReward:         300,            // 300 Dai
                kprPctReward:          10              // 0.1%
            })
        );
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_WBTC_B, 60 seconds, 9900);
        DssExecLib.setIlkAutoLineParameters("WBTC-B", 500 * MILLION, 30 * MILLION, 8 hours);

        // Changelog
        DssExecLib.setChangelogAddress("MCD_JOIN_WBTC_B", MCD_JOIN_WBTC_B);
        DssExecLib.setChangelogAddress("MCD_CLIP_WBTC_B", MCD_CLIP_WBTC_B);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_WBTC_B", MCD_CLIP_CALC_WBTC_B);

        DssExecLib.setChangelogVersion("1.9.10");

        //
        // Collateral Offboarding
        //

        uint256 totalLineReduction;
        uint256 line;
        VatAbstract vat = VatAbstract(DssExecLib.vat());

        // Offboard AAVE-A
        // https://vote.makerdao.com/polling/QmPdvqZg?network=mainnet#poll-detail
        // https://forum.makerdao.com/t/proposed-offboarding-collateral-parameters-2/11548
        // https://forum.makerdao.com/t/signal-request-offboarding-matic-comp-aave-and-bal/11184

        (,,,line,) = vat.ilks("AAVE-A");
        totalLineReduction = _add(totalLineReduction, line);
        DssExecLib.setIlkLiquidationPenalty("AAVE-A", 0);
        DssExecLib.removeIlkFromAutoLine("AAVE-A");
        DssExecLib.setIlkDebtCeiling("AAVE-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "AAVE-A Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "AAVE-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_AAVE_MAT,
            _end:       TARGET_AAVE_MAT,
            _duration:  30 days
        });

        // Offboard BAL-A
        // https://vote.makerdao.com/polling/QmcwtUau?network=mainnet#poll-detail
        // https://forum.makerdao.com/t/proposed-offboarding-collateral-parameters-2/11548
        // https://forum.makerdao.com/t/signal-request-offboarding-matic-comp-aave-and-bal/11184

        (,,,line,) = vat.ilks("BAL-A");
        totalLineReduction = _add(totalLineReduction, line);
        DssExecLib.setIlkLiquidationPenalty("BAL-A", 0);
        DssExecLib.removeIlkFromAutoLine("BAL-A");
        DssExecLib.setIlkDebtCeiling("BAL-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "BAL-A Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "BAL-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_BAL_MAT,
            _end:       TARGET_BAL_MAT,
            _duration:  30 days
        });

        // Offboard COMP-A
        // https://vote.makerdao.com/polling/QmRDeGCn?network=mainnet#poll-detail
        // https://forum.makerdao.com/t/proposed-offboarding-collateral-parameters-2/11548
        // https://forum.makerdao.com/t/signal-request-offboarding-matic-comp-aave-and-bal/11184

        (,,,line,) = vat.ilks("COMP-A");
        totalLineReduction = _add(totalLineReduction, line);
        DssExecLib.setIlkLiquidationPenalty("COMP-A", 0);
        DssExecLib.removeIlkFromAutoLine("COMP-A");
        DssExecLib.setIlkDebtCeiling("COMP-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "COMP-A Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "COMP-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_COMP_MAT,
            _end:       TARGET_COMP_MAT,
            _duration:  30 days
        });

        // Decrease Global Debt Ceiling in accordance with Offboarded Ilks
        vat.file("Line", _sub(vat.Line(), totalLineReduction));

        // Increase Ilk Local Liquidation Limits (ilk.hole)
        // https://vote.makerdao.com/polling/QmQN6FX8?network=mainnet#poll-detail
        // https://forum.makerdao.com/t/auction-throughput-parameters-adjustments-nov-9-2021/11531
        DssExecLib.setIlkMaxLiquidationAmount("ETH-A",    65 * MILLION); // From 40M to 65M DAI
        DssExecLib.setIlkMaxLiquidationAmount("ETH-B",    30 * MILLION); // From 25M to 30M DAI
        DssExecLib.setIlkMaxLiquidationAmount("ETH-C",    35 * MILLION); // From 30M to 35M DAI
        DssExecLib.setIlkMaxLiquidationAmount("WBTC-A",   40 * MILLION); // From 25M to 40M DAI
        DssExecLib.setIlkMaxLiquidationAmount("WSTETH-A",  7 * MILLION); // From  3M to  7M DAI

        // Increase WBTC-A Stability Fee (duty)
        // https://vote.makerdao.com/polling/QmRUgsvi?network=mainnet#poll-detail
        // https://forum.makerdao.com/t/mid-month-parameter-changes-proposal-ppg-omc-001-2021-11-10/11562
        DssExecLib.setIlkStabilityFee("WBTC-A", FOUR_PCT_RATE, true); // From 2.5% to 4%
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
