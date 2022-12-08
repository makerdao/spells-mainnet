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
pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

interface GemLike {
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface VatLike {
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function Line() external view returns (uint256);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-12-09 MakerDAO Executive Spell | Hash: 0x";


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    uint256 internal constant ONE_PCT_RATE      = 1000000000315522921573372069;
    uint256 internal constant TWO_FIVE_PCT_RATE = 1000000000782997609082909351;

    // --- MATH ---
    uint256 internal constant MILLION           = 10 ** 6;
    uint256 internal constant WAD               = 10 ** 18;
    uint256 internal constant RAY               = 10 ** 27;

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    address internal immutable VAT            = DssExecLib.vat();
    address internal immutable MCD_PSM_PAX_A  = DssExecLib.getChangelogAddress("MCD_PSM_PAX_A");
    address internal immutable MCD_PSM_GUSD_A = DssExecLib.getChangelogAddress("MCD_PSM_GUSD_A");

    GemLike internal immutable MKR = GemLike(DssExecLib.mkr());

    address constant internal STABLENODE         = 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0;
    address constant internal ULTRASCHUPPI       = 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167;
    address constant internal FLIPFLOPFLAP       = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address constant internal FLIPSIDE           = 0x1ef753934C40a72a60EaB12A68B6f8854439AA78;
    address constant internal FEEDBLACKLOOPS     = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address constant internal PENNBLOCKCHAIN     = 0x2165D41aF0d8d5034b9c266597c1A415FA0253bd;
    address constant internal MHONKASALOTEEMULAU = 0x97Fb39171ACd7C82c439b6158EA2F71D26ba383d;
    address constant internal BLOCKCHAINCOLUMBIA = 0xdC1F98682F4F8a5c6d54F345F448437b83f5E432;
    address constant internal ACREINVEST         = 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D;
    address constant internal LBSBLOCKCHAIN      = 0xB83b3e9C8E3393889Afb272D354A7a3Bd1Fbcf5C;
    address constant internal CALBLOCKCHAIN      = 0x7AE109A63ff4DC852e063a673b40BED85D22E585;
    address constant internal JUSTINCASE         = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
    address constant internal FRONTIERRESEARCH   = 0xA2d55b89654079987CF3985aEff5A7Bd44DA15A8;
    address constant internal CHRISBLEC          = 0xa3f0AbB4Ba74512b5a736C5759446e9B50FDA170;
    address constant internal GFXLABS            = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;
    address constant internal ONESTONE           = 0x4eFb12d515801eCfa3Be456B5F348D3CD68f9E8a;
    address constant internal CODEKNIGHT         = 0x46dFcBc2aFD5DD8789Ef0737fEdb03489D33c428;
    address constant internal LLAMA              = 0xA519a7cE7B24333055781133B13532AEabfAC81b;
    address constant internal PVL                = 0x6ebB1A9031177208A4CA50164206BF2Fa5ff7416;
    address constant internal CONSENSYS          = 0xE78658A8acfE982Fde841abb008e57e6545e38b3;

    address constant internal TECH_001           = 0x2dC0420A736D1F40893B9481D8968E4D7424bC0B;

    // --- DEPLOYED COLLATERAL ADDRESSES ---
    address internal constant GNO                 = 0x6810e776880C02933D47DB1b9fc05908e5386b96;
    address internal constant PIP_GNO             = 0xd800ca44fFABecd159c7889c3bf64a217361AEc8;
    address internal constant MCD_JOIN_GNO_A      = 0x7bD3f01e24E0f0838788bC8f573CEA43A80CaBB5;
    address internal constant MCD_CLIP_GNO_A      = 0xd9e758bd239e5d568f44D0A748633f6a8d52CBbb;
    address internal constant MCD_CLIP_CALC_GNO_A = 0x17b6D0e4237ea7F880aF5F58257cd232a04171D9;

    function actions() public override {

        // Delegate Compensation - November 2022
        // https://forum.makerdao.com/t/recognized-delegate-compensation-november-2022/19012
        // StableNode - 12000 DAI - 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0
        DssExecLib.sendPaymentFromSurplusBuffer(STABLENODE,          12_000);
        // schuppi - 12000 DAI - 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167
        DssExecLib.sendPaymentFromSurplusBuffer(ULTRASCHUPPI,        12_000);
        // Flip Flop Flap Delegate LLC - 12000 DAI - 0x688d508f3a6B0a377e266405A1583B3316f9A2B3
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPFLOPFLAP,        12_000);
        // Flipside Crypto - 11396 DAI - 0x1ef753934C40a72a60EaB12A68B6f8854439AA78
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPSIDE,            11_396);
        // Feedblack Loops LLC - 10900 DAI - 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACKLOOPS,      10_900);
        // Penn Blockchain - 10385 DAI - 0x2165d41af0d8d5034b9c266597c1a415fa0253bd
        DssExecLib.sendPaymentFromSurplusBuffer(PENNBLOCKCHAIN,      10_385);
        // mhonkasalo & teemulau - 8945 DAI - 0x97Fb39171ACd7C82c439b6158EA2F71D26ba383d
        DssExecLib.sendPaymentFromSurplusBuffer(MHONKASALOTEEMULAU,   8_945);
        // Blockchain@Columbia - 5109 DAI - 0xdC1F98682F4F8a5c6d54F345F448437b83f5E432
        DssExecLib.sendPaymentFromSurplusBuffer(BLOCKCHAINCOLUMBIA,   5_109);
        // AcreInvest - 4568 DAI - 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D
        DssExecLib.sendPaymentFromSurplusBuffer(ACREINVEST,           4_568);
        // London Business School Blockchain - 3797 DAI - 0xB83b3e9C8E3393889Afb272D354A7a3Bd1Fbcf5C
        DssExecLib.sendPaymentFromSurplusBuffer(LBSBLOCKCHAIN,        3_797);
        // CalBlockchain - 3421 DAI - 0x7AE109A63ff4DC852e063a673b40BED85D22E585
        DssExecLib.sendPaymentFromSurplusBuffer(CALBLOCKCHAIN,        3_421);
        // JustinCase - 3208 DAI - 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTINCASE,           3_208);
        // Frontier Research LLC - 2278 DAI - 0xA2d55b89654079987CF3985aEff5A7Bd44DA15A8
        DssExecLib.sendPaymentFromSurplusBuffer(FRONTIERRESEARCH,     2_278);
        // Chris Blec - 1883 DAI - 0xa3f0AbB4Ba74512b5a736C5759446e9B50FDA170
        DssExecLib.sendPaymentFromSurplusBuffer(CHRISBLEC,            1_883);
        // GFX Labs - 532 DAI - 0xa6e8772af29b29B9202a073f8E36f447689BEef6
        DssExecLib.sendPaymentFromSurplusBuffer(GFXLABS,                532);
        // ONESTONE - 299 DAI - 0x4eFb12d515801eCfa3Be456B5F348D3CD68f9E8a
        DssExecLib.sendPaymentFromSurplusBuffer(ONESTONE,               299);
        // CodeKnight - 271 DAI - 0x46dFcBc2aFD5DD8789Ef0737fEdb03489D33c428
        DssExecLib.sendPaymentFromSurplusBuffer(CODEKNIGHT,             271);
        // Llama - 145 DAI - 0xA519a7cE7B24333055781133B13532AEabfAC81b
        DssExecLib.sendPaymentFromSurplusBuffer(LLAMA,                  145);
        // pvl - 65 DAI - 0x6ebB1A9031177208A4CA50164206BF2Fa5ff7416
        DssExecLib.sendPaymentFromSurplusBuffer(PVL,                     65);
        // ConsenSys - 28 DAI - 0xE78658A8acfE982Fde841abb008e57e6545e38b3
        DssExecLib.sendPaymentFromSurplusBuffer(CONSENSYS,               28);

        // Tech-Ops MKR Transfer
        // https://mips.makerdao.com/mips/details/MIP40c3SP54
        // TECH-001 - 257.31 MKR - 0x2dC0420A736D1F40893B9481D8968E4D7424bC0B
        MKR.transfer(TECH_001, 257.31 ether);

        // MOMC Parameter Changes
        // https://vote.makerdao.com/polling/QmVXj9cW

        // Increase WSTETH-A line from 150 million DAI to 500 million DAI
        // Reduce WSTETH-A gap from 30 million DAI to 15 million DAI
        DssExecLib.setIlkAutoLineParameters("WSTETH-A", 500 * MILLION, 15 * MILLION, 6 hours);
        // Increase WSTETH-B line from 200 million DAI to 500 million DAI
        // Reduce WSTETH-B gap from 30 million DAI to 15 million DAI
        DssExecLib.setIlkAutoLineParameters("WSTETH-B", 500 * MILLION, 15 * MILLION, 8 hours);
        // Reduce ETH-B line from 500 million to 250 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("ETH-B", 250 * MILLION);
        // Reduce WBTC-A line from 2 billion DAI to 500 million DAI
        // Reduce WBTC-A gap from 80 million DAI to 20 million DAI
        // Increase WBTC-A ttl from 6 hours to 24 hours
        DssExecLib.setIlkAutoLineParameters("WBTC-A", 500 * MILLION, 20 * MILLION, 24 hours);
        // Reduce WBTC-B line from 500 million DAI to 250 million DAI
        // Reduce WBTC-B gap from 30 million DAI to 10 million DAI
        // Increase WBTC-B ttl from 8 hours to 24 hours
        DssExecLib.setIlkAutoLineParameters("WBTC-B", 250 * MILLION, 10 * MILLION, 24 hours);
        // Reduce WBTC-C line from 1 billion DAI to 500 million DAI
        // Reduce WBTC-C gap from 100 million DAI to 20 million DAI
        // Increase WBTC-C ttl from 8 hours to 24 hours
        DssExecLib.setIlkAutoLineParameters("WBTC-C", 500 * MILLION, 20 * MILLION, 24 hours);
        // Reduce MANA-A line from 1 million DAI to 0 DAI
        bytes32 _ilk = "MANA-A";
        DssExecLib.removeIlkFromAutoLine(_ilk);
        (,,, uint256 _Line,) = VatLike(VAT).ilks(_ilk);
        DssExecLib.setValue(VAT, _ilk, "line", 0);
        DssExecLib.setValue(VAT, "Line", sub(VatLike(VAT).Line(), _Line));
        // Reduce GUNIV3DAIUSDC1-A line from 1 billion DAI to 100 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("GUNIV3DAIUSDC1-A", 100 * MILLION);
        // Reduce GUINV3DAIUSDC2-A line from 1.25 billion DAI to 100 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("GUNIV3DAIUSDC2-A", 100 * MILLION);
        // Reduce the UNIV2DAIUSDC-A line from 300 million DAI to 100 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("UNIV2DAIUSDC-A", 100 * MILLION);
        // Reduce the PSM-USDP-A line from 500 million DAI to 450 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("PSM-PAX-A", 450 * MILLION);
        // Reduce LINK-A gap from 7 million DAI to 2.5 million DAI
        DssExecLib.setIlkAutoLineParameters("LINK-A", 5 * MILLION, 2_500_000, 8 hours);
        // Reduce YFI-A gap from 7 million DAI to 1.5 million DAI
        DssExecLib.setIlkAutoLineParameters("YFI-A", 3 * MILLION, 1_500_000, 8 hours);


        // PSM tin increases
        // Increase PSM-USDP-A tin from 0% to 0.1%
        DssExecLib.setValue(MCD_PSM_PAX_A, "tin", 1 * WAD / 1000);
        // Increase PSM-GUSD-A tin from 0% to 0.1%
        DssExecLib.setValue(MCD_PSM_GUSD_A, "tin", 1 * WAD / 1000);

        // PSM tout decrease
        // Reduce PSM-GUSD-A tout from 0.2% to 0.1%
        DssExecLib.setValue(MCD_PSM_GUSD_A, "tout", 1 * WAD / 1000);


        // DSR Adjustment
        // https://vote.makerdao.com/polling/914#vote-breakdown
        // Increase the DSR to 1%
        DssExecLib.setDSR(ONE_PCT_RATE, true);


        // ----------------------------- Collateral onboarding -----------------------------
        //  Add GNO-A as a new Vault Type
        //  Poll Link:   https://vote.makerdao.com/polling/QmUBoGiu#poll-detail
        //  Forum Post:  https://forum.makerdao.com/t/gno-collateral-onboarding-risk-evaluation/18820

        DssExecLib.addNewCollateral(
            CollateralOpts({
                ilk:                  "GNO-A",
                gem:                  GNO,
                join:                 MCD_JOIN_GNO_A,
                clip:                 MCD_CLIP_GNO_A,
                calc:                 MCD_CLIP_CALC_GNO_A,
                pip:                  PIP_GNO,
                isLiquidatable:       true,
                isOSM:                true,
                whitelistOSM:         true,
                ilkDebtCeiling:       5_000_000,         // line updated to 5M
                minVaultAmount:       100_000,           // debt floor - dust in DAI
                maxLiquidationAmount: 2_000_000,
                liquidationPenalty:   13_00,             // 13% penalty on liquidation
                ilkStabilityFee:      TWO_FIVE_PCT_RATE, // 2.50% stability fee
                startingPriceFactor:  120_00,            // Auction price begins at 120% of oracle price
                breakerTolerance:     50_00,             // Allows for a 50% hourly price drop before disabling liquidation
                auctionDuration:      140 minutes,
                permittedDrop:        25_00,             // 25% price drop before reset
                liquidationRatio:     350_00,            // 350% collateralization
                kprFlatReward:        250,               // 250 DAI tip - flat fee per kpr
                kprPctReward:         10                 // 0.1% chip - per kpr
            })
        );

        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_GNO_A, 60 seconds, 99_00);
        DssExecLib.setIlkAutoLineParameters("GNO-A", 5_000_000, 3_000_000, 8 hours);


        // RWA-010 Onboarding
        // https://vote.makerdao.com/polling/QmNucsGt
        // TODO


        // RWA-011 Onboarding
        // https://vote.makerdao.com/polling/QmNucsGt
        // TODO


        // RWA-012 Onboarding
        // https://vote.makerdao.com/polling/QmNucsGt
        // TODO


        // RWA-013 Onboarding
        // https://vote.makerdao.com/polling/QmNucsGt
        // TODO


        // ----------------------------- Collateral offboarding -----------------------------
        //  Offboard RENBTC-A
        //  Poll Link:   https://vote.makerdao.com/polling/QmTNMDfb#poll-detail
        //  Forum Post:  https://forum.makerdao.com/t/renbtc-a-proposed-offboarding-parameters-context/18864

        DssExecLib.setIlkLiquidationPenalty("RENBTC-A", 0);
        DssExecLib.setKeeperIncentiveFlatRate("RENBTC-A", 0);
        // setIlkLiquidationRatio to 5000%
        // We are using low level methods because DssExecLib allow to set `mat < 1000%`: https://github.com/makerdao/dss-exec-lib/blob/2afff4373e8a827659df28f6d349feb25f073e59/src/DssExecLib.sol#L733
        DssExecLib.setValue(DssExecLib.spotter(), "RENBTC-A", "mat", 50 * RAY); // 5000%
        DssExecLib.setIlkMaxLiquidationAmount("RENBTC-A", 350_000);
        
        // -------------------- Changelog Update ---------------------
        DssExecLib.setChangelogAddress("GNO",                 GNO);
        DssExecLib.setChangelogAddress("PIP_GNO",             PIP_GNO);
        DssExecLib.setChangelogAddress("MCD_JOIN_GNO_A",      MCD_JOIN_GNO_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_GNO_A",      MCD_CLIP_GNO_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_GNO_A", MCD_CLIP_CALC_GNO_A);

        // Bump changelog
        DssExecLib.setChangelogVersion("1.14.7");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
