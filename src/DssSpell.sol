// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
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

interface ChainlogLike {
    function removeAddress(bytes32) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/40b362fc70793e9980a8d53c47b1937e05d0c6d3/governance/votes/Executive%20vote%20-%20August%2020%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-09-03 MakerDAO Executive Spell | Hash: ";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant ONE_PCT_RATE = 1000000000315522921573372069;

    // Math
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    address constant GUNI                   = 0xAbDDAfB225e10B90D798bB8A886238Fb835e2053;
    address constant MCD_JOIN_GUNI_A        = ;
    address constant MCD_CLIP_GUNI_A        = ;
    address constant MCD_CLIP_CALC_GUNI_A   = ;
    address constant PIP_GUNI               = ;

    function actions() public override {
        DssExecLib.setChangelogAddress("PAX", DssExecLib.getChangelogAddress("PAXUSD"));
        DssExecLib.setChangelogAddress("PIP_PAX", DssExecLib.getChangelogAddress("PIP_PAXUSD"));

        ChainlogLike(DssExecLib.LOG).removeAddress("PIP_PSM_PAX");

        // G-UNI DAI/USDC

        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_GUNI_A, 90 seconds, 9900);

        CollateralOpts memory GUNI_A = CollateralOpts({
            ilk:                   "GUNIDAIUSDC1-A",
            gem:                   GUNI,
            join:                  MCD_JOIN_GUNI_A,
            clip:                  MCD_CLIP_GUNI_A,
            calc:                  MCD_CLIP_CALC_GUNI_A,
            pip:                   PIP_GUNI,
            isLiquidatable:        false,
            isOSM:                 false,
            whitelistOSM:          false,
            ilkDebtCeiling:        3 * MILLION,
            minVaultAmount:        10 * THOUSAND,
            maxLiquidationAmount:  5 * MILLION,
            liquidationPenalty:    1300,
            ilkStabilityFee:       ONE_PCT_RATE,
            startingPriceFactor:   10500,
            breakerTolerance:      9500, // Allows for a 5% hourly price drop before disabling liquidations
            auctionDuration:       220 minutes,
            permittedDrop:         9000,
            liquidationRatio:      10500,
            kprFlatReward:         300,
            kprPctReward:          10 // 0.1%
        });

        DssExecLib.addNewCollateral(GUNI_A);
        DssExecLib.setIlkAutoLineParameters("GUNIDAIUSDC1-A", 3 * MILLION, 3 * MILLION, 8 hours);

        DssExecLib.setChangelogAddress("GUNIDAIUSDC1", GUNI);
        DssExecLib.setChangelogAddress("MCD_JOIN_GUNIDAIUSDC1_A", MCD_JOIN_GUNI_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_GUNIDAIUSDC1_A", MCD_CLIP_GUNI_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_GUNIDAIUSDC1_A", MCD_CLIP_CALC_GUNI_A);
        DssExecLib.setChangelogAddress("PIP_GUNIDAIUSDC1", PIP_GUNI);

        // Bump changelog version
        DssExecLib.setChangelogVersion("1.9.5");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
