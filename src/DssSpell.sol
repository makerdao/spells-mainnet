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
import { VatAbstract, LerpFactoryAbstract, SpotAbstract} from "dss-interfaces/Interfaces.sol";

interface LerpAbstract {
    function tick() external returns (uint256);
}

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

    address constant MCD_JOIN_PSM_GUSD_A      = 0xF0C8fbBC793903ed9FA1e59792d496e866a7Cbc1;
    address constant MCD_CLIP_PSM_GUSD_A      = 0xf93CC3a50f450ED245e003BFecc8A6Ec1732b0b2;
    address constant MCD_CLIP_CALC_PSM_GUSD_A = 0x7f67a68a0ED74Ea89A82eD9F243C159ed43a502a;
    address constant MCD_PSM_GUSD_A           = 0xfd21BAEFe8F2D10cF7d16562203b4ed89fB3BFAF;

    function actions() public override {
        address WBTC     = DssExecLib.getChangelogAddress("WBTC");
        address PIP_WBTC = DssExecLib.getChangelogAddress("PIP_WBTC");
        address GUSD     = DssExecLib.getChangelogAddress("GUSD");
        address PIP_GUSD = DssExecLib.getChangelogAddress("PIP_GUSD");

        //  Set Aave D3M Max Debt Ceiling
        //  https://vote.makerdao.com/polling/QmZhvNu5?network=mainnet#poll-detail
        DssExecLib.setIlkAutoLineDebtCeiling("DIRECT-AAVEV2-DAI", 100 * MILLION);

        //  Increase the Surplus Buffer via Lerp
        //  https://vote.makerdao.com/polling/QmUqfZRv?network=mainnet#poll-detail
        DssExecLib.linearInterpolation({
            _name:      "Increase SB - 20211126",
            _target:    DssExecLib.vow(),
            _what:      "mat",
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
        DssExecLib.setIlkAutoLineParameters("PSM-GUSD-A", 100 * MILLION, 10 * MILLION, 24 hours);

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
