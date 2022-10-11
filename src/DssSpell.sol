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

import { DssSpellCollateralAction } from "./DssSpellCollateral.sol";

interface GemLike {
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface RwaUrnLike {
    function lock(uint256) external;
}

interface VestLike {
    function restrict(uint256) external;
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
}

contract DssSpellAction is DssAction, DssSpellCollateralAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/ef7c8c881c961e9b4b3cc9644619986a75ef83d7/governance/votes/Executive%20vote%20-%20October%205%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-10-05 MakerDAO Executive Spell | Hash: 0xf791ea9d7a97cace07a1cd79de48ce9a41dc79f53a43465faad83a30292dfc81";

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
    uint256 internal constant ONE_FIVE_PCT_RATE = 1000000000472114805215157978; 
    // --- Math ---
    uint256 internal constant MILLION = 10 ** 6;
    // --- Wallets ---
    address internal constant JUSTIN_CASE_WALLET  = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
    address internal constant DOO_WALLET  = 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0;
    address internal constant ULTRASCHUPPI_WALLET  = 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167;
    address internal constant FLIPFLOPFLAP_WALLET  = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address internal constant FLIPSIDE_WALLET  = 0x62a43123FE71f9764f26554b3F5017627996816a;
    address internal constant FEEDBLACKLOOPS_WALLET  = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address internal constant PENNBLOCKCHAIN_WALLET  = 0x2165D41aF0d8d5034b9c266597c1A415FA0253bd;
    address internal constant GFXLABS_WALLET  = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;
    address internal constant MHONKASALOTEEMULAU_WALLET  = 0x97Fb39171ACd7C82c439b6158EA2F71D26ba383d;
    address internal constant CHRISBLEC_WALLET  = 0xa3f0AbB4Ba74512b5a736C5759446e9B50FDA170;
    address internal constant ACREINVEST_WALLET  = 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D;
    address internal constant BLOCKCHAINCOLUMBIA_WALLET  = 0xdC1F98682F4F8a5c6d54F345F448437b83f5E432;
    address internal constant FRONTIER_RESEARCH  = 0xA2d55b89654079987CF3985aEff5A7Bd44DA15A8;
    address internal constant LLAMA_WALLET  = 0xA519a7cE7B24333055781133B13532AEabfAC81b;
    address internal constant CODEKNIGHT_WALLET  = 0x46dFcBc2aFD5DD8789Ef0737fEdb03489D33c428;
    
    
    function actions() public override {
        // Includes changes from the DssSpellCollateralAction
        // onboardNewCollaterals();

        // ---------------------------------------------------------------------
        // Collateral Auction Parameter Changes
        // https://vote.makerdao.com/polling/QmREbu1j#poll-detail
        // https://forum.makerdao.com/t/collateral-auctions-analysis-parameter-updates-september-2022/18063#proposed-changes-17
        
        // buf changes (Starting auction price multiplier)
        DssExecLib.setStartingPriceMultiplicativeFactor("ETH-A"           , 110_00);
        DssExecLib.setStartingPriceMultiplicativeFactor("ETH-B"           , 110_00);
        DssExecLib.setStartingPriceMultiplicativeFactor("ETH-C"           , 110_00);
        DssExecLib.setStartingPriceMultiplicativeFactor("WBTC-A"          , 110_00);
        DssExecLib.setStartingPriceMultiplicativeFactor("WBTC-B"          , 110_00);
        DssExecLib.setStartingPriceMultiplicativeFactor("WBTC-C"          , 110_00);
        DssExecLib.setStartingPriceMultiplicativeFactor("WSTETH-A"        , 110_00);
        DssExecLib.setStartingPriceMultiplicativeFactor("WSTETH-B"        , 110_00);
        DssExecLib.setStartingPriceMultiplicativeFactor("CRVV1ETHSTETH-A" , 120_00); 
        DssExecLib.setStartingPriceMultiplicativeFactor("LINK-A"          , 120_00);
        DssExecLib.setStartingPriceMultiplicativeFactor("MANA-A"          , 120_00);
        DssExecLib.setStartingPriceMultiplicativeFactor("MATIC-A"         , 120_00);
        DssExecLib.setStartingPriceMultiplicativeFactor("RENBTC-A"        , 120_00);
        
        // cusp changes (Max percentage drop permitted before auction reset)
        DssExecLib.setAuctionPermittedDrop("ETH-A"    , 45_00);
        DssExecLib.setAuctionPermittedDrop("ETH-B"    , 45_00);
        DssExecLib.setAuctionPermittedDrop("ETH-C"    , 45_00);
        DssExecLib.setAuctionPermittedDrop("WBTC-A"   , 45_00);
        DssExecLib.setAuctionPermittedDrop("WBTC-B"   , 45_00);
        DssExecLib.setAuctionPermittedDrop("WBTC-C"   , 45_00);
        DssExecLib.setAuctionPermittedDrop("WSTETH-A" , 45_00);
        DssExecLib.setAuctionPermittedDrop("WSTETH-B" , 45_00);
        
        // tail changes (Max auction duration)
        DssExecLib.setAuctionTimeBeforeReset("ETH-A"    , 7200 seconds);
        DssExecLib.setAuctionTimeBeforeReset("ETH-C"    , 7200 seconds);
        DssExecLib.setAuctionTimeBeforeReset("WBTC-A"   , 7200 seconds);
        DssExecLib.setAuctionTimeBeforeReset("WBTC-C"   , 7200 seconds);
        DssExecLib.setAuctionTimeBeforeReset("WSTETH-A" , 7200 seconds);
        DssExecLib.setAuctionTimeBeforeReset("WSTETH-B" , 7200 seconds);
        DssExecLib.setAuctionTimeBeforeReset("ETH-B"    , 4800 seconds);
        DssExecLib.setAuctionTimeBeforeReset("WBTC-B"   , 4800 seconds);
        
        // ilk hole changes (Max concurrent liquidation amount for an ilk)
        DssExecLib.setIlkMaxLiquidationAmount("ETH-A"    , 40 * MILLION);
        DssExecLib.setIlkMaxLiquidationAmount("ETH-B"    , 15 * MILLION);
        DssExecLib.setIlkMaxLiquidationAmount("WBTC-A"   , 30 * MILLION);
        DssExecLib.setIlkMaxLiquidationAmount("WBTC-B"   , 10 * MILLION);
        DssExecLib.setIlkMaxLiquidationAmount("WBTC-C"   , 20 * MILLION);
        DssExecLib.setIlkMaxLiquidationAmount("LINK-A"   ,  3 * MILLION);
        DssExecLib.setIlkMaxLiquidationAmount("YFI-A"    ,  1 * MILLION);
        DssExecLib.setIlkMaxLiquidationAmount("RENBTC-A" ,  2 * MILLION);

        // tip changes (Max keeper incentive in DAI)
        DssExecLib.setKeeperIncentiveFlatRate("ETH-A"           , 250);
        DssExecLib.setKeeperIncentiveFlatRate("ETH-B"           , 250);
        DssExecLib.setKeeperIncentiveFlatRate("ETH-C"           , 250);
        DssExecLib.setKeeperIncentiveFlatRate("WBTC-A"          , 250);
        DssExecLib.setKeeperIncentiveFlatRate("WBTC-B"          , 250);
        DssExecLib.setKeeperIncentiveFlatRate("WBTC-C"          , 250);
        DssExecLib.setKeeperIncentiveFlatRate("WSTETH-A"        , 250);
        DssExecLib.setKeeperIncentiveFlatRate("WSTETH-B"        , 250);
        DssExecLib.setKeeperIncentiveFlatRate("CRVV1ETHSTETH-A" , 250); 
        DssExecLib.setKeeperIncentiveFlatRate("LINK-A"          , 250);
        DssExecLib.setKeeperIncentiveFlatRate("MANA-A"          , 250);
        DssExecLib.setKeeperIncentiveFlatRate("MATIC-A"         , 250);
        DssExecLib.setKeeperIncentiveFlatRate("RENBTC-A"        , 250); 
        DssExecLib.setKeeperIncentiveFlatRate("YFI-A"           , 250);

        // dog Hole change (Max concurrent global liquidation value)
        DssExecLib.setMaxTotalDAILiquidationAmount(70 * MILLION);

        // ---------------------------------------------------------------------
        // MOMC Parameter Changes
        // https://vote.makerdao.com/polling/QmbLyNUd#poll-detail
        // https://forum.makerdao.com/t/parameter-changes-proposal-ppg-omc-001-29-september-2022/18143
        
        // CRVV1ETHSTETH-A stability fee change (2.0% --> 1.5%) 
        DssExecLib.setIlkStabilityFee("CRVV1ETHSTETH-A" , ONE_FIVE_PCT_RATE , true); 
        
        // YFI-A DC IAM line change (25M --> 10M)
        DssExecLib.setIlkAutoLineDebtCeiling("YFI-A" , 10 * MILLION);

        // ---------------------------------------------------------------------
        // Delegate Compensation - September 2022 
        

        // ---------------------------------------------------------------------
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
