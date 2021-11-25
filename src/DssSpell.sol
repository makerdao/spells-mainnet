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
import {VestAbstract} from "dss-interfaces/Interfaces.sol";

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/e27219d6d1b5a9751e3a7af48474643c657e3dfa/governance/votes/Executive%20vote%20-%20November%2019%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-11-26 MakerDAO Executive Spell | Hash: TODO";

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
    uint256 constant ZERO_PCT_RATE            = 1000000000000000000000000000;
    uint256 constant ONE_FIVE_PCT_RATE        = 1000000000472114805215157978;

    // --- Math ---
    uint256 constant MILLION                  = 10 ** 6;
    uint256 constant RAD                      = 10 ** 45;

    // --- WBTC-C ---
    address constant MCD_JOIN_WBTC_C          = 0x7f62f9592b823331E012D3c5DdF2A7714CfB9de2;
    address constant MCD_CLIP_WBTC_C          = 0x39F29773Dcb94A32529d0612C6706C49622161D1;
    address constant MCD_CLIP_CALC_WBTC_C     = 0x4fa2A328E7f69D023fE83454133c273bF5ACD435;

    // --- PSM-GUSD-A ---
    address constant MCD_JOIN_PSM_GUSD_A      = 0x79A0FA989fb7ADf1F8e80C93ee605Ebb94F7c6A5;
    address constant MCD_CLIP_PSM_GUSD_A      = 0xf93CC3a50f450ED245e003BFecc8A6Ec1732b0b2;
    address constant MCD_CLIP_CALC_PSM_GUSD_A = 0x7f67a68a0ED74Ea89A82eD9F243C159ed43a502a;
    address constant MCD_PSM_GUSD_A           = 0x204659B2Fd2aD5723975c362Ce2230Fba11d3900;

    // --- Wallets + Dates ---
    address constant SAS_WALLET     = 0xb1f950a51516a697E103aaa69E152d839182f6Fe;
    address constant IS_WALLET      = 0xd1F2eEf8576736C1EbA36920B957cd2aF07280F4;
    address constant DECO_WALLET    = 0xF482D1031E5b172D42B2DAA1b6e5Cbf6519596f7;
    address constant RWF_WALLET     = 0x9e1585d9CA64243CE43D42f7dD7333190F66Ca09;
    address constant COM_WALLET     = 0x1eE3ECa7aEF17D1e74eD7C447CcBA61aC76aDbA9;
    address constant MKT_WALLET     = 0xDCAF2C84e1154c8DdD3203880e5db965bfF09B60;

    uint256 constant DEC_01_2021    = 1638316800;
    uint256 constant DEC_31_2021    = 1640908800;
    uint256 constant JAN_01_2022    = 1640995200;
    uint256 constant APR_30_2022    = 1651276800;
    uint256 constant JUN_30_2022    = 1656547200;
    uint256 constant AUG_01_2022    = 1659312000;
    uint256 constant NOV_30_2022    = 1669766400;
    uint256 constant DEC_31_2022    = 1672444800;
    uint256 constant SEP_01_2024    = 1725148800;

    function actions() public override {
        address WBTC            = DssExecLib.getChangelogAddress("WBTC");
        address PIP_WBTC        = DssExecLib.getChangelogAddress("PIP_WBTC");
        address GUSD            = DssExecLib.getChangelogAddress("GUSD");
        address PIP_GUSD        = DssExecLib.getChangelogAddress("PIP_GUSD");
        address MCD_VEST_DAI    = DssExecLib.getChangelogAddress("MCD_VEST_DAI");

        //  Set Aave D3M Max Debt Ceiling
        //  https://vote.makerdao.com/polling/QmZhvNu5?network=mainnet#poll-detail
        DssExecLib.setIlkAutoLineDebtCeiling("DIRECT-AAVEV2-DAI", 100 * MILLION);

        //  Increase the Surplus Buffer via Lerp
        //  https://vote.makerdao.com/polling/QmUqfZRv?network=mainnet#poll-detail
        DssExecLib.linearInterpolation({
            _name:      "Increase SB - 20211126",
            _target:    DssExecLib.vow(),
            _what:      "hump",
            _startTime: block.timestamp,
            _start:     60 * MILLION * RAD,
            _end:       90 * MILLION * RAD,
            _duration:  210 days
        });

        //  Add WBTC-C as a new Vault Type
        //  https://vote.makerdao.com/polling/QmdVYMRo?network=mainnet#poll-detail
        DssExecLib.addNewCollateral(
            CollateralOpts({
                ilk:                   "WBTC-C",
                gem:                   WBTC,
                join:                  MCD_JOIN_WBTC_C,
                clip:                  MCD_CLIP_WBTC_C,
                calc:                  MCD_CLIP_CALC_WBTC_C,
                pip:                   PIP_WBTC,
                isLiquidatable:        true,
                isOSM:                 true,
                whitelistOSM:          true,
                ilkDebtCeiling:        100 * MILLION,
                minVaultAmount:        7500,
                maxLiquidationAmount:  25 * MILLION,
                liquidationPenalty:    1300,
                ilkStabilityFee:       ONE_FIVE_PCT_RATE,
                startingPriceFactor:   12000,
                breakerTolerance:      5000,
                auctionDuration:       90 minutes,
                permittedDrop:         4000,
                liquidationRatio:      17500,
                kprFlatReward:         300,
                kprPctReward:          10
            })
        );
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_WBTC_C, 90 seconds, 9900);
        DssExecLib.setIlkAutoLineParameters("WBTC-C", 1000 * MILLION, 100 * MILLION, 8 hours);

        //  Add PSM-GUSD-A as a new Vault Type
        //  https://vote.makerdao.com/polling/QmayeEjz?network=mainnet#poll-detail
        DssExecLib.addNewCollateral(
            CollateralOpts({
                ilk:                   "PSM-GUSD-A",
                gem:                   GUSD,
                join:                  MCD_JOIN_PSM_GUSD_A,
                clip:                  MCD_CLIP_PSM_GUSD_A,
                calc:                  MCD_CLIP_CALC_PSM_GUSD_A,
                pip:                   PIP_GUSD,
                isLiquidatable:        false,
                isOSM:                 false,
                whitelistOSM:          false,
                ilkDebtCeiling:        10 * MILLION,
                minVaultAmount:        0,
                maxLiquidationAmount:  0,
                liquidationPenalty:    1300,
                ilkStabilityFee:       ZERO_PCT_RATE,
                startingPriceFactor:   10500,
                breakerTolerance:      9500, // Allows for a 5% hourly price drop before disabling liquidations
                auctionDuration:       220 minutes,
                permittedDrop:         9000,
                liquidationRatio:      10000,
                kprFlatReward:         300,
                kprPctReward:          10 // 0.1%
            })
        );
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_PSM_GUSD_A, 120 seconds, 9990);
        DssExecLib.setIlkAutoLineParameters("PSM-GUSD-A", 10 * MILLION, 10 * MILLION, 24 hours);

        //  Core Unit Budget Distributions
        DssExecLib.sendPaymentFromSurplusBuffer(SAS_WALLET, 245_738);
        DssExecLib.sendPaymentFromSurplusBuffer(IS_WALLET, 195_443);
        DssExecLib.sendPaymentFromSurplusBuffer(DECO_WALLET, 465_625);

        VestAbstract(MCD_VEST_DAI).restrict(
            VestAbstract(MCD_VEST_DAI).create(RWF_WALLET, 1_860_000.00 * 10**18, JAN_01_2022, DEC_31_2022 - JAN_01_2022, 0, address(0))
        );
        VestAbstract(MCD_VEST_DAI).restrict(
            VestAbstract(MCD_VEST_DAI).create(COM_WALLET, 12_242.00 * 10**18, DEC_01_2021, DEC_31_2021 - DEC_01_2021, 0, address(0))
        );
        VestAbstract(MCD_VEST_DAI).restrict(
            VestAbstract(MCD_VEST_DAI).create(COM_WALLET, 257_500.00 * 10**18, JAN_01_2022, JUN_30_2022 - JAN_01_2022, 0, address(0))
        );
        VestAbstract(MCD_VEST_DAI).restrict(
            VestAbstract(MCD_VEST_DAI).create(SAS_WALLET, 1_130_393.00 * 10**18, DEC_01_2021, NOV_30_2022 - DEC_01_2021, 0, address(0))
        );
        VestAbstract(MCD_VEST_DAI).restrict(
            VestAbstract(MCD_VEST_DAI).create(IS_WALLET, 366_563.00 * 10**18, DEC_01_2021, AUG_01_2022 - DEC_01_2021, 0, address(0))
        );
        VestAbstract(MCD_VEST_DAI).restrict(
            VestAbstract(MCD_VEST_DAI).create(MKT_WALLET, 424_944.00 * 10**18, DEC_01_2021, APR_30_2022 - DEC_01_2021, 0, address(0))
        );
        VestAbstract(MCD_VEST_DAI).restrict(
            VestAbstract(MCD_VEST_DAI).create(MKT_WALLET, 5_121_875.00 * 10**18, DEC_01_2021, SEP_01_2024 - DEC_01_2021, 0, address(0))
        );

        // Changelog
        DssExecLib.setChangelogAddress("MCD_JOIN_WBTC_C", MCD_JOIN_WBTC_C);
        DssExecLib.setChangelogAddress("MCD_CLIP_WBTC_C", MCD_CLIP_WBTC_C);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_WBTC_C", MCD_CLIP_CALC_WBTC_C);

        DssExecLib.setChangelogAddress("MCD_JOIN_PSM_GUSD_A", MCD_JOIN_PSM_GUSD_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_PSM_GUSD_A", MCD_CLIP_PSM_GUSD_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_PSM_GUSD_A", MCD_CLIP_CALC_PSM_GUSD_A);
        DssExecLib.setChangelogAddress("MCD_PSM_GUSD_A", MCD_PSM_GUSD_A);

        DssExecLib.setChangelogVersion("1.9.11");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
