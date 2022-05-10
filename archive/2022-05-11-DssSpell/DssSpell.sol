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
pragma experimental ABIEncoderV2;
import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol";

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/8044c921dc954e321ae6e229052af4a5204778ba/governance/votes/Executive%20vote%20-%20May%2011%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        // TODO: update this
        "2022-05-11 MakerDAO Executive Spell | Hash: 0x1c715f41675838e51cce3a7435df43fc67defa27634b40b9baa3c0280715c820";

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
    uint256 constant TWO_TWO_FIVE_PCT_RATE = 1000000000705562181084137268;
    uint256 constant FOUR_PCT_RATE         = 1000000001243680656318820312;

    // Recognized Delegates DAI Transfers
    address constant FLIP_FLOP_FLAP_WALLET  = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address constant ULTRASCHUPPI_WALLET    = 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167;
    address constant FEEDBLACK_LOOPS_WALLET = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address constant MAKERMAN_WALLET        = 0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0;
    address constant ACRE_INVEST_WALLET     = 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D;
    address constant MONETSUPPLY_WALLET     = 0x4Bd73eeE3d0568Bb7C52DFCad7AD5d47Fff5E2CF;
    address constant JUSTIN_CASE_WALLET     = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
    address constant GFX_LABS_WALLET        = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;
    address constant DOO_WALLET             = 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0;
    address constant FLIPSIDE_CRYPTO_WALLET = 0x62a43123FE71f9764f26554b3F5017627996816a;

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralOnboardingAction
        onboardNewCollaterals();

        // MOMC Proposal
        // https://vote.makerdao.com/polling/QmTmehbz#poll-detail

        // Lower the WBTC-A Stability Fee from 3.25% to 2.25%.
        DssExecLib.setIlkStabilityFee("WBTC-A", TWO_TWO_FIVE_PCT_RATE, true);

        // Lower the WBTC-B Stability Fee from 4.5% to 4.0%.
        DssExecLib.setIlkStabilityFee("WBTC-B", FOUR_PCT_RATE, true);

        // Recognized Delegate Payments
        // https://forum.makerdao.com/t/recognized-delegate-compensation-breakdown-april-2022/14935

        DssExecLib.sendPaymentFromSurplusBuffer(FLIP_FLOP_FLAP_WALLET,  12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(ULTRASCHUPPI_WALLET,    12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACK_LOOPS_WALLET, 12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(MAKERMAN_WALLET,        10_929);
        DssExecLib.sendPaymentFromSurplusBuffer(ACRE_INVEST_WALLET,      9_347);
        DssExecLib.sendPaymentFromSurplusBuffer(MONETSUPPLY_WALLET,      8_626);
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTIN_CASE_WALLET,      7_522);
        DssExecLib.sendPaymentFromSurplusBuffer(GFX_LABS_WALLET,         6_607);
        DssExecLib.sendPaymentFromSurplusBuffer(DOO_WALLET,                351);
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPSIDE_CRYPTO_WALLET,    265);

        DssExecLib.setChangelogVersion("1.12.1");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
