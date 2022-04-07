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
// pragma experimental ABIEncoderV2;
import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol";

interface DssVestLike {
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function restrict(uint256) external;
    function yank(uint256) external;
}

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/a7095d5b92ee825bef28b6f5d22baec50718d438/governance/votes/Executive%20vote%20-%20April%201%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-04-08 MakerDAO Executive Spell | Hash: TODO";

    // Math
    uint256 constant internal MILLION  = 10 ** 6;
    uint256 constant internal BILLION  = 10 ** 9;

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
    uint256 constant ZERO_PCT_RATE           = 1000000000000000000000000000;
    uint256 constant ZERO_ZERO_FIVE_PCT_RATE = 1000000000015850933588756013;
    uint256 constant TWO_TWO_FIVE_PCT_RATE   = 1000000000705562181084137268;
    uint256 constant THREE_TWO_FIVE_PCT_RATE = 1000000001014175731521720677;
    uint256 constant FOUR_FIVE_PCT_RATE      = 1000000001395766281313196627;

    // Recognized Delegates DAI Transfers
    address constant FLIP_FLOP_FLAP_WALLET  = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address constant FEEDBLACK_LOOPS_WALLET = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address constant ULTRASCHUPPI_WALLET    = 0x89C5d54C979f682F40b73a9FC39F338C88B434c6;
    address constant MAKERMAN_WALLET        = 0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0;
    address constant ACRE_INVEST_WALLET     = 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D;
    address constant MONETSUPPLY_WALLET     = 0x4Bd73eeE3d0568Bb7C52DFCad7AD5d47Fff5E2CF;
    address constant JUSTIN_CASE_WALLET     = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
    address constant GFX_LABS_WALLET        = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;
    address constant DOO_WALLET             = 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0;

    // ETH Amsterdam Event SPF
    address constant ETH_AMSTERDAM_WALLET   = 0xF34ac684BA2734039772f0C0d77bc2545e819212;

    // Turn office hours off
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();


        // ------------------------- Rates Updates -----------------------------
        // https://vote.makerdao.com/polling/QmdS8mCx#poll-detail

        // Decrease the WSTETH-A Stability Fee from 2.5% to 2.25%
        DssExecLib.setIlkStabilityFee("WSTETH-A", TWO_TWO_FIVE_PCT_RATE, true);

        // Decrease the CRVV1ETHSTETH-A Stability Fee from 3.5% to 2.25%
        DssExecLib.setIlkStabilityFee("CRVV1ETHSTETH-A", TWO_TWO_FIVE_PCT_RATE, true);

        // Decrease the WBTC-A Stability Fee from 3.75% to 3.25%
        DssExecLib.setIlkStabilityFee("WBTC-A", THREE_TWO_FIVE_PCT_RATE, true);

        // Decrease the WBTC-B Stability Fee from 5.0% to 4.5%
        DssExecLib.setIlkStabilityFee("WBTC-B", FOUR_FIVE_PCT_RATE, true);

        // Decrease the GUNIV3DAIUSDC1-A Stability Fee from 0.1% to 0%
        DssExecLib.setIlkStabilityFee("GUNIV3DAIUSDC1-A", ZERO_PCT_RATE, true);

        // Decrease the GUNIV3DAIUSDC2-A Stability Fee from 0.25% to 0.05%
        DssExecLib.setIlkStabilityFee("GUNIV3DAIUSDC2-A", ZERO_ZERO_FIVE_PCT_RATE, true);


        // ---------------------- Debt Ceiling Updates -------------------------

        // https://forum.makerdao.com/t/immediate-short-term-parameter-changes-proposal-for-crvv1ethsteth-a-dc-and-gap-increase/14476
        // Increase the CRVV1ETHSTETH-A Maximum Debt Ceiling from 3 million DAI to 5 million DAI.
        DssExecLib.setIlkAutoLineDebtCeiling("CRVV1ETHSTETH-A", 5 * MILLION);

        // https://vote.makerdao.com/polling/QmdS8mCx#poll-detail
        // Increase the GUNIV3DAIUSDC1-A Maximum Debt Ceiling from 100 million DAI to 750 million DAI.
        // Increase the GUNIV3DAIUSDC1-A gap from 10 million to 50 million
        // Leave the GUNIV3DAIUSDC1-A ttl the same
        DssExecLib.setIlkAutoLineParameters("GUNIV3DAIUSDC1-A", 750 * MILLION, 50 * MILLION, 8 hours);

        // https://vote.makerdao.com/polling/QmdS8mCx#poll-detail
        // Increase the GUNIV3DAIUSDC2-A Maximum Debt Ceiling from 750 million DAI to 1 billion DAI.
        DssExecLib.setIlkAutoLineDebtCeiling("GUNIV3DAIUSDC2-A", 1 * BILLION);


        // ----------------------- Target Borrow Rates -------------------------
        // https://vote.makerdao.com/polling/QmdS8mCx#poll-detail 

        // Increase the DIRECT-AAVEV2-DAI target borrow rate from 2.85% to 3.5%
        DssExecLib.setD3MTargetInterestRate(DssExecLib.getChangelogAddress("MCD_JOIN_DIRECT_AAVEV2_DAI"), 350); // 3.5%

        // --------------------------- DAI payouts -----------------------------
        // Recognized Delegate Compensation Distribution (Payout: 77,183 DAI)
        // https://forum.makerdao.com/t/recognized-delegate-compensation-breakdown-march-2022/14427
        DssExecLib.sendPaymentFromSurplusBuffer(FLIP_FLOP_FLAP_WALLET,  12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACK_LOOPS_WALLET, 12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(ULTRASCHUPPI_WALLET,    12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(MAKERMAN_WALLET,        10_761);
        DssExecLib.sendPaymentFromSurplusBuffer(ACRE_INVEST_WALLET,      9_295);
        DssExecLib.sendPaymentFromSurplusBuffer(MONETSUPPLY_WALLET,      7_598);
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTIN_CASE_WALLET,      6_640);
        DssExecLib.sendPaymentFromSurplusBuffer(GFX_LABS_WALLET,         6_606);
        DssExecLib.sendPaymentFromSurplusBuffer(DOO_WALLET,                283);

        // ETH Amsterdam Event SPF
        // https://mips.makerdao.com/mips/details/MIP55c3SP3#sentence-summary
        // https://forum.makerdao.com/t/mip55c3-sp3-ethamsterdam-event-spf/13781/74?u=patrick_j
        DssExecLib.sendPaymentFromSurplusBuffer(ETH_AMSTERDAM_WALLET, 50_000);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
