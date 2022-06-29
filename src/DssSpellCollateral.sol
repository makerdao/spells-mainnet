// SPDX-FileCopyrightText: © 2021 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
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

import "dss-exec-lib/DssExecLib.sol";

contract DssSpellCollateralAction {
    // --- Math ---
    uint256 constant RAY  = 10 ** 27;

    // --- Offboarding: Current Liquidation Ratio ---
    uint256 constant CURRENT_UNI_A_MAT              =  165 * RAY / 100;
    uint256 constant CURRENT_UNIV2DAIETH_A_MAT      =  120 * RAY / 100;
    uint256 constant CURRENT_UNIV2WBTCETH_A_MAT     =  145 * RAY / 100;
    uint256 constant CURRENT_UNIV2WBTCDAI_A_MAT     =  120 * RAY / 100;

    // --- Offboarding: Target Liquidation Ratio ---
    uint256 constant TARGET_UNI_A_MAT               = 1_300 * RAY / 100;
    uint256 constant TARGET_UNIV2DAIETH_A_MAT       = 2_000 * RAY / 100;
    uint256 constant TARGET_UNIV2WBTCETH_A_MAT      = 2_400 * RAY / 100;
    uint256 constant TARGET_UNIV2WBTCDAI_A_MAT      = 800 * RAY / 100;

    // --- Rates ---
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmTRiQ3GqjCiRhh1ojzKzgScmSsiwQPLyjhgYSxZASQekj
    //

    function onboardNewCollaterals() internal {
        // ----------------------------- Collateral onboarding -----------------------------
        //  Add ______________ as a new Vault Type
        //  Poll Link:

        // DssExecLib.addNewCollateral(
        //     CollateralOpts({
        //         ilk:                   ,
        //         gem:                   ,
        //         join:                  ,
        //         clip:                  ,
        //         calc:                  ,
        //         pip:                   ,
        //         isLiquidatable:        ,
        //         isOSM:                 ,
        //         whitelistOSM:          ,
        //         ilkDebtCeiling:        ,
        //         minVaultAmount:        ,
        //         maxLiquidationAmount:  ,
        //         liquidationPenalty:    ,
        //         ilkStabilityFee:       ,
        //         startingPriceFactor:   ,
        //         breakerTolerance:      ,
        //         auctionDuration:       ,
        //         permittedDrop:         ,
        //         liquidationRatio:      ,
        //         kprFlatReward:         ,
        //         kprPctReward:
        //     })
        // );

        // DssExecLib.setStairstepExponentialDecrease(
        //     CALC_ADDR,
        //     DURATION,
        //     PCT_BPS
        // );

        // DssExecLib.setIlkAutoLineParameters(
        //     ILK,
        //     AMOUNT,
        //     GAP,
        //     TTL
        // );

        // ChainLog Updates
        // Add the new flip and join to the Chainlog
        // address constant CHAINLOG        = DssExecLib.LOG();
        // ChainlogAbstract(CHAINLOG).setAddress("<join-name>", <join-address>);
        // ChainlogAbstract(CHAINLOG).setAddress("<clip-name>", <clip-address>);
        // ChainlogAbstract(CHAINLOG).setVersion("<new-version>");
    }

    function offboardCollaterals() internal {

        address spotter = DssExecLib.spotter();

        // Offboard UNI-A
        // https://vote.makerdao.com/polling/QmSfLS6V#poll-detail
        // https://forum.makerdao.com/t/signal-request-offboard-uni-univ2daieth-univ2wbtceth-univ2unieth-and-univ2wbtcdai/15160

        DssExecLib.setIlkLiquidationPenalty("UNI-A", 0);
        DssExecLib.setKeeperIncentiveFlatRate("UNI-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "UNI-A Offboarding",
            _target:    spotter,
            _ilk:       "UNI-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_UNI_A_MAT,
            _end:       TARGET_UNI_A_MAT,
            _duration:  30 days
        });

        // Offboard UNIV2DAIETH-A
        // https://vote.makerdao.com/polling/QmQUozNn#poll-detail
        // https://forum.makerdao.com/t/signal-request-offboard-uni-univ2daieth-univ2wbtceth-univ2unieth-and-univ2wbtcdai/15160

        DssExecLib.setIlkLiquidationPenalty("UNIV2DAIETH-A", 0);
        DssExecLib.setKeeperIncentiveFlatRate("UNIV2DAIETH-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "UNIV2DAIETH-A Offboarding",
            _target:    spotter,
            _ilk:       "UNIV2DAIETH-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_UNIV2DAIETH_A_MAT,
            _end:       TARGET_UNIV2DAIETH_A_MAT,
            _duration:  30 days
        });

        // Offboard UNIV2WBTCETH-A
        // https://vote.makerdao.com/polling/QmY3YsDB#poll-detail
        // https://forum.makerdao.com/t/signal-request-offboard-uni-univ2daieth-univ2wbtceth-univ2unieth-and-univ2wbtcdai/15160

        DssExecLib.setIlkLiquidationPenalty("UNIV2WBTCETH-A", 0);
        DssExecLib.setKeeperIncentiveFlatRate("UNIV2WBTCETH-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "UNIV2WBTCETH-A Offboarding",
            _target:    spotter,
            _ilk:       "UNIV2WBTCETH-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_UNIV2WBTCETH_A_MAT,
            _end:       TARGET_UNIV2WBTCETH_A_MAT,
            _duration:  30 days
        });

        // Offboard UNIV2UNIETH-A
        // https://vote.makerdao.com/polling/QmUeYVa2#poll-detail
        // https://forum.makerdao.com/t/signal-request-offboard-uni-univ2daieth-univ2wbtceth-univ2unieth-and-univ2wbtcdai/15160

        DssExecLib.setIlkLiquidationPenalty("UNIV2UNIETH-A", 0);
        DssExecLib.setKeeperIncentiveFlatRate("UNIV2UNIETH-A", 0);

        // Offboard UNIV2WBTCDAI-A
        // https://vote.makerdao.com/polling/QmZHNkip#poll-detail
        // https://forum.makerdao.com/t/signal-request-offboard-uni-univ2daieth-univ2wbtceth-univ2unieth-and-univ2wbtcdai/15160

        DssExecLib.setIlkLiquidationPenalty("UNIV2WBTCDAI-A", 0);
        DssExecLib.setKeeperIncentiveFlatRate("UNIV2WBTCDAI-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "UNIV2WBTCDAI-A Offboarding",
            _target:    spotter,
            _ilk:       "UNIV2WBTCDAI-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_UNIV2WBTCDAI_A_MAT,
            _end:       TARGET_UNIV2WBTCDAI_A_MAT,
            _duration:  30 days
        });
    }
}
