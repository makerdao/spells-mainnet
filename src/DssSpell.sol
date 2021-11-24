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
    uint256 constant ZERO_PCT_RATE           = 1000000000000000000000000000;
    uint256 constant ONE_FIVE_PCT_RATE       = 1000000000472114805215157978;

    // --- Math ---
    uint256 constant MILLION                 = 10 ** 6;

    // --- WBTC-C ---
    address constant MCD_JOIN_WBTC_C         = ;
    address constant MCD_CLIP_WBTC_C         = ;
    address constant MCD_CLIP_CALC_WBTC_C    = ;

    function actions() public override {

        // WBTC
        address WBTC     = DssExecLib.getChangelogAddress("WBTC");
        address PIP_WBTC = DssExecLib.getChangelogAddress("PIP_WBTC");

        //  Add WBTC-C as a new Vault Type
        //  https://vote.makerdao.com/polling/QmdVYMRo?network=mainnet#poll-detail (WBTC-C Onboarding)
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

        // Changelog
        DssExecLib.setChangelogAddress("MCD_JOIN_WBTC_C", MCD_JOIN_WBTC_C);
        DssExecLib.setChangelogAddress("MCD_CLIP_WBTC_C", MCD_CLIP_WBTC_C);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_WBTC_C", MCD_CLIP_CALC_WBTC_C);

        DssExecLib.setChangelogVersion("1.9.11");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
