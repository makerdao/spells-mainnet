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

    uint256 constant MILLION  = 10**6;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-10-22 MakerDAO Executive Spell | Hash: 0x";

    address public constant STETH = 0xae7ab96520de3a18e5e111b5eaab095312d7fe84;
    address public constant WSTETH  = 0x7f39c581f595b53c5cb19bd0b3f8da6c935e2ca0;
    address public constant MCD_JOIN_WSTETH_A = address(0); // TODO
    address public constant MCD_CLIP_WSTETH_A = address(0); // TODO
    address public constant MCD_CLIP_CALC_WSTETH_A = address(0); // TODO
    address public constant MCD_PIP_WSTETH  = 0xfe7a2ac0b945f12089aeeb6ecebf4f384d9f043f;

    function actions() public override {


        // Increase the GUNIV3DAIUSDC1-A Debt Ceiling - October 11, 2021
        //  https://vote.makerdao.com/polling/QmU6fTQx?network=mainnet#poll-detail
        DssExecLib.setIlkAutoLineParameters("GUNIV3DAIUSDC1-A", 50 * MILLION, 50 * MILLION, 8 hours);


        // Add stETH (Lido Staked ETH) as a new Vault Type - October 11, 2021
        //  https://vote.makerdao.com/polling/QmXXHpYi?network=mainnet#poll-detail
        //  https://forum.makerdao.com/t/steth-collateral-onboarding-risk-evaluation/9061
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_WSTETH_A, 90 seconds, 9900);

        CollateralOpts memory STETH_A = CollateralOpts({
            ilk:                   "WSTETH-A",
            gem:                   address(WSTETH_GEM),
            join:                  address(MCD_JOIN_WSTETH_A),
            clip:                  address(MCD_CLIP_WSTETH_A),
            calc:                  address(MCD_CLIP_CALC_WSTETH_A),
            pip:                   MCD_PIP_WSTETH,
            isLiquidatable:        true,
            isOSM:                 true,
            whitelistOSM:          true,
            ilkDebtCeiling:        5 * MILLION,
            minVaultAmount:        10000,
            maxLiquidationAmount:  3 * MILLION,
            liquidationPenalty:    1300,
            ilkStabilityFee:       FOUR_PCT_RATE,
            startingPriceFactor:   13000,
            breakerTolerance:      5000,   // Allows for a 50% hourly price drop before disabling liquidations
            auctionDuration:       140 minutes,
            permittedDrop:         4000,
            liquidationRatio:      13000,
            kprFlatReward:         300,     // 300 Dai
            kprPctReward:          10       // 0.1%
        });
        DssExecLib.addNewCollateral(WSTETH_A);
        DssExecLib.setIlkAutoLineParameters("WSTETH-A", 5 * MILLION, 3 * MILLION, 8 hours);


        DssExecLib.setChangelogAddress("STETH", STETH);
        DssExecLib.setChangelogAddress("WSTETH", WSTETH);
        DssExecLib.setChangelogAddress("MCD_JOIN_WSTETH_A", MCD_JOIN_WSTETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_WSTETH_A", MCD_CLIP_WSTETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_WSTETH_A", MCD_CLIP_CALC_WSTETH_A);
        DssExecLib.setChangelogAddress("MCD_PIP_WSTETH", MCD_PIP_WSTETH);


        // bump changelog version
        DssExecLib.setChangelogVersion("TODO");
    }
}


contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
