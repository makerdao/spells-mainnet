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

contract DssSpellAction is DssAction {

    uint256 constant MILLION  = 10**6;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/287beee2bb76636b8b9e02c7e698fa639cb6b859/governance/votes/Executive%20vote%20-%20October%2022%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-10-22 MakerDAO Executive Spell | Hash: 0x1980e67884fc3b449708d14f67d095b612118e9fb183de4b107f37c0bc8499aa";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant FOUR_PCT_RATE = 1000000001243680656318820312;

    address public constant STETH_GEM              = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant WSTETH_GEM             = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant MCD_JOIN_WSTETH_A      = 0x10CD5fbe1b404B7E19Ef964B63939907bdaf42E2;
    address public constant MCD_CLIP_WSTETH_A      = 0x49A33A28C4C7D9576ab28898F4C9ac7e52EA457A;
    address public constant MCD_CLIP_CALC_WSTETH_A = 0x15282b886675cc1Ce04590148f456428E87eaf13;
    address public constant PIP_WSTETH             = 0xFe7a2aC0B945f12089aEEB6eCebf4F384D9f043F;

    function actions() public override {


        // Increase the GUNIV3DAIUSDC1-A Debt Ceiling - October 11, 2021
        //  https://vote.makerdao.com/polling/QmU6fTQx?network=mainnet#poll-detail
        DssExecLib.setIlkAutoLineParameters("GUNIV3DAIUSDC1-A", 50 * MILLION, 10 * MILLION, 8 hours);


        // Parameter Changes Proposal - MakerDAO Open Market Committee - October 18, 2021
        //  https://vote.makerdao.com/polling/QmP6GPeK?network=mainnet#poll-detail
        DssExecLib.setIlkAutoLineParameters("ETH-A", 15_000 * MILLION, 150 * MILLION, 6 hours);
        DssExecLib.setIlkAutoLineParameters("ETH-B", 500 * MILLION, 20 * MILLION, 6 hours);
        DssExecLib.setIlkAutoLineParameters("WBTC-A", 1_500 * MILLION, 60 * MILLION, 6 hours);


        // Add stETH (Lido Staked ETH) as a new Vault Type - October 11, 2021
        //  https://vote.makerdao.com/polling/QmXXHpYi?network=mainnet#poll-detail
        //  https://forum.makerdao.com/t/steth-collateral-onboarding-risk-evaluation/9061
        CollateralOpts memory WSTETH_A = CollateralOpts({
            ilk:                   "WSTETH-A",
            gem:                   WSTETH_GEM,
            join:                  MCD_JOIN_WSTETH_A,
            clip:                  MCD_CLIP_WSTETH_A,
            calc:                  MCD_CLIP_CALC_WSTETH_A,
            pip:                   PIP_WSTETH,
            isLiquidatable:        true,
            isOSM:                 true,
            whitelistOSM:          true,
            ilkDebtCeiling:        3 * MILLION, // Start at 3mm, DCIAM sets to 5mm
            minVaultAmount:        10000,
            maxLiquidationAmount:  3 * MILLION,
            liquidationPenalty:    1300,        // 13% penalty fee
            ilkStabilityFee:       FOUR_PCT_RATE,
            startingPriceFactor:   13000,       // Auction price begins at 130% of oracle
            breakerTolerance:      5000,        // Allows for a 50% hourly price drop before disabling liquidations
            auctionDuration:       140 minutes,
            permittedDrop:         4000,        // 40% price drop before reset
            liquidationRatio:      16000,       // 160% collateralization
            kprFlatReward:         300,         // 300 Dai
            kprPctReward:          10           // 0.1%
        });
        DssExecLib.addNewCollateral(WSTETH_A);
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_WSTETH_A, 90 seconds, 9900);
        DssExecLib.setIlkAutoLineParameters("WSTETH-A", 5 * MILLION, 3 * MILLION, 8 hours);


        DssExecLib.setChangelogAddress("STETH", STETH_GEM);
        DssExecLib.setChangelogAddress("WSTETH", WSTETH_GEM);
        DssExecLib.setChangelogAddress("PIP_WSTETH", PIP_WSTETH);
        DssExecLib.setChangelogAddress("MCD_JOIN_WSTETH_A", MCD_JOIN_WSTETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_WSTETH_A", MCD_CLIP_WSTETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_WSTETH_A", MCD_CLIP_CALC_WSTETH_A);


        // bump changelog version
        DssExecLib.setChangelogVersion("1.9.8");
    }
}


contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
