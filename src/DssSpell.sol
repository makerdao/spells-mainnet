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

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";


contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-10-15 MakerDAO Executive Spell | Hash: 0x";
    
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant ZERO_PCT_RATE = 1000000000000000000000000000;

    address constant ADAI                            = 0x028171bCA77440897B824Ca71D1c56caC55b68A3;
    address constant MCD_JOIN_DIRECT_AAVEV2_DAI      = ;
    address constant MCD_CLIP_DIRECT_AAVEV2_DAI      = ;
    address constant MCD_CLIP_CALC_DIRECT_AAVEV2_DAI = ;
    address constant PIP_DIRECT_AAVEV2_DAI           = 0x47c3dC029825Da43BE595E21fffD0b66FfcB7F6e;      // DAI PIP

    function actions() public override {

        // D3M
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_DIRECT_AAVEV2_DAI, 120 seconds, 9990);

        CollateralOpts memory DIRECT_AAVEV2_DAI = CollateralOpts({
            ilk:                   "DIRECT-AAVEV2-DAI",
            gem:                   ADAI,
            join:                  MCD_JOIN_DIRECT_AAVEV2_DAI,
            clip:                  MCD_CLIP_DIRECT_AAVEV2_DAI,
            calc:                  MCD_CLIP_CALC_DIRECT_AAVEV2_DAI,
            pip:                   PIP_DIRECT_AAVEV2_DAI,
            isLiquidatable:        false,
            isOSM:                 false,
            whitelistOSM:          false,
            ilkDebtCeiling:        3 * MILLION,
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
        });

        DssExecLib.addNewCollateral(DIRECT_AAVEV2_DAI);

        DssExecLib.setChangelogAddress("ADAI", ADAI);
        DssExecLib.setChangelogAddress("MCD_JOIN_DIRECT_AAVEV2_DAI", MCD_JOIN_DIRECT_AAVEV2_DAI);
        DssExecLib.setChangelogAddress("MCD_CLIP_DIRECT_AAVEV2_DAI", MCD_CLIP_DIRECT_AAVEV2_DAI);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_DIRECT_AAVEV2_DAI", MCD_CLIP_CALC_DIRECT_AAVEV2_DAI);
        DssExecLib.setChangelogAddress("PIP_DIRECT_AAVEV2_DAI", PIP_DIRECT_AAVEV2_DAI);
    }
}


contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
