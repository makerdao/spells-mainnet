// SPDX-FileCopyrightText: © 2020 Dai Foundation <www.daifoundation.org>
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
// Enable ABIEncoderV2 when onboarding collateral through `DssExecLib.addNewCollateral()`
// pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

// import { DssSpellCollateralAction } from "./DssSpellCollateral.sol";

interface RwaUrnLike {
    function draw(uint256) external;
}

interface HopeLike {
    function hope(address) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/TODO.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-08-10 MakerDAO Executive Spell | Hash: ";

    uint256 public constant MILLION            = 10 **  6;
    uint256 public constant BILLION            = 10 **  9;
    uint256 public constant WAD                = 10 ** 18;
    uint256 public constant RWA009_DRAW_AMOUNT = 25_000_000 * WAD;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // --- Rates ---
    uint256 public constant ZERO_PCT_RATE             = 1000000000000000000000000000;
    uint256 public constant ZERO_ZERO_TWO_PCT_RATE    = 1000000000006341324285480111;
    uint256 public constant ZERO_ZERO_SIX_PCT_RATE    = 1000000000019020169709960675;
    uint256 public constant TWO_TWO_FIVE_PCT_RATE     = 1000000000705562181084137268;
    uint256 public constant THREE_SEVEN_FIVE_PCT_RATE = 1000000001167363430498603315;

    function actions() public override {

        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralAction
        // onboardNewCollaterals();
        // offboardCollaterals();


        // ----------------------------- RWA Draws -----------------------------
        // https://vote.makerdao.com/polling/QmQMDasC#poll-detail
        // Weekly Draw for HVB
        address RWA009_A_URN = DssExecLib.getChangelogAddress("RWA009_A_URN");
        RwaUrnLike(RWA009_A_URN).draw(RWA009_DRAW_AMOUNT);

        // --------------------------- Rates updates ---------------------------
        // https://vote.makerdao.com/polling/QmfMRfE4#poll-detail

        // Reduce Stability Fee for    ETH-B   from 4% to 3.75%
        DssExecLib.setIlkStabilityFee("ETH-B", THREE_SEVEN_FIVE_PCT_RATE, true);

        // Reduce Stability Fee for    WSTETH-A   from 2.50% to 2.25%
        DssExecLib.setIlkStabilityFee("WSTETH-A", TWO_TWO_FIVE_PCT_RATE, true);

        // Reduce Stability Fee for    WSTETH-B   from 0.75% to 0%
        DssExecLib.setIlkStabilityFee("WSTETH-B", ZERO_PCT_RATE, true);

        // Reduce Stability Fee for    WBTC-B   from 4.00% to 3.75%
        DssExecLib.setIlkStabilityFee("WBTC-B", THREE_SEVEN_FIVE_PCT_RATE, true);

        // Increase Stability Fee for  GUNIV3DAIUSDC1-A   from 0.01% to 0.02%
        DssExecLib.setIlkStabilityFee("GUNIV3DAIUSDC1-A", ZERO_ZERO_TWO_PCT_RATE, true);

        // Increase Stability Fee for  GUNIV3DAIUSDC2-A   from 0.05% to 0.06%
        DssExecLib.setIlkStabilityFee("GUNIV3DAIUSDC2-A", ZERO_ZERO_SIX_PCT_RATE, true);

        // Increase Stability Fee for  UNIV2DAIUSDC-A   from 0.01% to 0.02%
        DssExecLib.setIlkStabilityFee("UNIV2DAIUSDC-A", ZERO_ZERO_TWO_PCT_RATE, true);

        // ------------------------ Debt Ceiling updates -----------------------
        // https://vote.makerdao.com/polling/QmfMRfE4#poll-detail

        // Increase the line for              GUNIV3DAIUSDC2-A from   1 billion to 1.25 billion DAI
        DssExecLib.setIlkAutoLineDebtCeiling("GUNIV3DAIUSDC2-A",                   1250 * MILLION);
        // Increase the line for              GUINV3DAIUSDC1-A from 750 million to 1 billion DAI
        DssExecLib.setIlkAutoLineDebtCeiling("GUNIV3DAIUSDC1-A",                   1 * BILLION);
        // Increase the line for              MANA-A           from  15 million to 17 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("MANA-A",                             17 * MILLION);

        // ----------------------- Activate SocGen Vault -----------------------
        // NOTE: ignore in goerli
        // call hope() on RWA008_A_OUTPUT_CONDUIT
        // https://discord.com/channels/893112320329396265/897483518316265553/1004725159506231316
        // address RWA008_A_OPERATOR       = DssExecLib.getChangelogAddress("RWA008_A_OPERATOR");
        // address RWA008_A_OUTPUT_CONDUIT = DssExecLib.getChangelogAddress("RWA008_A_OUTPUT_CONDUIT");
        // HopeLike(RWA008_A_OUTPUT_CONDUIT).hope(RWA008_A_OPERATOR);

        // ------------------------- Delegate Payments -------------------------
        // NOTE: ignore in goerli
        // Recognized Delegate Compensation - July 2022
        // Flip Flop Flap Delegate LLC - 12000 DAI - 0x688d508f3a6B0a377e266405A1583B3316f9A2B3
        // Feedblack Loops LLC         - 12000 DAI - 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1
        // JustinCase                  - 12000 DAI - 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473
        // Doo                         - 12000 DAI - 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0
        // schuppi                     - 11918 DAI - 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167
        // Flipside Crypto             - 11387 DAI - 0x62a43123FE71f9764f26554b3F5017627996816a
        // Penn Blockchain             -  9438 DAI - 0x2165d41af0d8d5034b9c266597c1a415fa0253bd
        // Chris Blec                  -  9174 DAI - 0xa3f0AbB4Ba74512b5a736C5759446e9B50FDA170
        // GFX Labs                    -  8512 DAI - 0xa6e8772af29b29B9202a073f8E36f447689BEef6
        // MakerMan                    -  6912 DAI - 0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0
        // ACREInvest                  -  6628 DAI - 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D
        // mhonkasalo & teemulau       -  4029 DAI - 0x97Fb39171ACd7C82c439b6158EA2F71D26ba383d
        // Llama                       -  3797 DAI - 0x82cD339Fa7d6f22242B31d5f7ea37c1B721dB9C3
        // Blockchain@Columbia         -  2013 DAI - 0xdC1F98682F4F8a5c6d54F345F448437b83f5E432

    }

}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
