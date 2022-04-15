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

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/87e837c372818efd5954f862bf4df3471a087ddc/governance/votes/Executive%20vote%20-%20April%2015%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-04-15 MakerDAO Executive Spell | Hash: 0x37b77be342627636565ca93ad72165c6c4bfc9a450d8c8e8ac5ad65a50018321";

    // Math
    uint256 constant internal MILLION  = 10 ** 6;
    uint256 constant internal WAD      = 10 ** 18;

    DssVestLike immutable MCD_VEST_DAI = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_DAI"));

    address constant internal MCD_CLIP_CALC_TUSD_A = 0x9B207AfAAAD1ae300Ea659e71306a7Bd6D81C160;
    address constant internal       GRO_001_WALLET = 0x7800C137A645c07132886539217ce192b9F0528e;
    address constant internal    AMBASSADOR_WALLET = 0xF411d823a48D18B32e608274Df16a9957fE33E45;
    address constant internal    GELATO_WALLET_OLD = 0x926c21602FeC84d6d0fA6450b40Edba595B5c6e4;
    address constant internal    GELATO_WALLET_NEW = 0x478c7Ce3e1df09130f8D65a23AD80e05b352af62;

    uint256 constant APR_01_2022 = 1648771200;
    // 2022-04-01 to 2022-09-30 23:59:59 UTC
    uint256 constant SIX_MONTHS = 183 days;

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
    //uint256 constant FOUR_FIVE_PCT_RATE      = 1000000001395766281313196627;


    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();

        // ----------------- Core Unit Budgets -----------------
        // https://mips.makerdao.com/mips/details/MIP40c3SP37#budget-implementation
        DssExecLib.sendPaymentFromSurplusBuffer(GRO_001_WALLET, 474_683);

        // -------------- Fund Ambassador Program --------------
        // https://vote.makerdao.com/polling/QmPpQ49p#poll-detail
        DssExecLib.sendPaymentFromSurplusBuffer(AMBASSADOR_WALLET, 25_000);

        // ---- Replace Gelato Keeper Top Up Contract Stream ---
        // https://forum.makerdao.com/t/update-to-the-gelato-keeper-network-top-up-contract/14524
        // Yank existing stream
        MCD_VEST_DAI.yank(36);
        // Replace stream
        // Address: 0x478c7Ce3e1df09130f8D65a23AD80e05b352af62
        // Amount: 1,000 DAI/day
        // Start Date: Apr 1, 2022
        // End Date: Sep 30, 2022 23:59:59 UTC
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                GELATO_WALLET_NEW,
                183_000 * WAD,
                APR_01_2022,
                SIX_MONTHS,
                0,
                address(0)
            )
        );

        // ------------------ Offboard TUSD-A -------------------
        // https://vote.makerdao.com/polling/QmVkRdjg#poll-detail
        bytes32 _ilk  = bytes32("TUSD-A");
        address _clip = DssExecLib.getChangelogAddress("MCD_CLIP_TUSD_A");
        //
        // Enable liquidations for TUSD-A
        // Note: ClipperMom cannot circuit-break on a DS-Value but we're adding
        //       the rely for consistency with other collaterals and in case the PIP
        //       changes to an OSM.
        DssExecLib.authorize(_clip, DssExecLib.clipperMom());
        DssExecLib.setValue(_clip, "stopped", 0);
        // Use Abacus/LinearDecrease
        DssExecLib.setContract(_clip, "calc", MCD_CLIP_CALC_TUSD_A);
        // Set Liquidation Penalty to 0
        DssExecLib.setIlkLiquidationPenalty(_ilk, 0);
        // Set Liquidation Ratio to 150%
        DssExecLib.setIlkLiquidationRatio(_ilk, 15000);
        // Set Auction Price Multiplier (buf) to 1
        DssExecLib.setStartingPriceMultiplicativeFactor(_ilk, 10000);
        // Set Local Liquidation Limit (ilk.hole) to 5 million DAI
        DssExecLib.setIlkMaxLiquidationAmount(_ilk, 5 * MILLION);
        // Set tau for Abacus/LinearDecrease to 21,600,000 second (estimated 10bps drop per 6 hours = 250 days till 0)
        DssExecLib.setLinearDecrease(MCD_CLIP_CALC_TUSD_A, 21_600_000);
        // Set Max Auction Duration (tail) to 432,000 seconds (5 days, implies minimum price of 0.98)
        DssExecLib.setAuctionTimeBeforeReset(_ilk, 432_000);
        // Inferred by risk. Enforcing here with approval https://discord.com/channels/893112320329396265/897483518316265553/963575806653767720
        DssExecLib.setAuctionPermittedDrop(_ilk, 9800);
        // Set Proportional Kick Incentive (chip) to 0
        DssExecLib.setKeeperIncentivePercent(_ilk, 0);
        // Set Flat Kick Incentive (tip) to 500
        DssExecLib.setKeeperIncentiveFlatRate(_ilk, 500);
        // Update spotter price
        DssExecLib.updateCollateralPrice(_ilk);
        // Update calc in changelog
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_TUSD_A", MCD_CLIP_CALC_TUSD_A);

        // Update changelog version
        DssExecLib.setChangelogVersion("1.11.1");
    }

}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
