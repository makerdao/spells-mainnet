// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2021-2022 Dai Foundation
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
import "lib/dss-interfaces/src/dss/DaiJoinAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dss/VestAbstract.sol";

import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol";


contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/TODO -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-02-04 MakerDAO Executive Spell | Hash: TODO";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant ZERO_PCT_RATE                = 1000000000000000000000000000;
    uint256 constant ZERO_PT_TWO_FIVE_PCT_RATE    = 1000000000079175551708715274;
    uint256 constant ZERO_PT_SEVEN_FIVE_PCT_RATE  = 1000000000236936036262880196;
    uint256 constant ONE_PCT_RATE                 = 1000000000315522921573372069;
    uint256 constant ONE_PT_FIVE_PCT_RATE         = 1000000000472114805215157978;
    uint256 constant TWO_PCT_RATE                 = 1000000000627937192491029810;
    uint256 constant TWO_PT_TWO_FIVE_PCT_RATE     = 1000000000705562181084137268;
    uint256 constant TWO_PT_FIVE_PCT_RATE         = 1000000000782997609082909351;
    uint256 constant THREE_PT_SEVEN_FIVE_PCT_RATE = 1000000001167363430498603315;
    uint256 constant FOUR_PCT_RATE                = 1000000001243680656318820312;
    uint256 constant FIVE_PCT_RATE                = 1000000001547125957863212448;

    address constant NEW_MCD_ESM  = 0x09e05fF6142F2f9de8B6B65855A1d56B6cfE4c58;
    bytes32 constant MCD_ESM_NAME = "MCD_ESM";

    address constant FLIP_FLOP_FLAP_WALLET  = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address constant FEEDBLACK_LOOPS_WALLET = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address constant SCHUPPI_WALLET         = 0x89C5d54C979f682F40b73a9FC39F338C88B434c6;
    address constant MAKERMAN_WALLET        = 0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0;
    address constant MONETSUPPLY_WALLET     = 0x4Bd73eeE3d0568Bb7C52DFCad7AD5d47Fff5E2CF;
    address constant ACRE_INVEST_WALLET     = 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D;
    address constant JUSTIN_CASE_WALLET     = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
    address constant GFX_LABS_WALLET        = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;

    VestAbstract immutable VEST             = VestAbstract(DssExecLib.getChangelogAddress("MCD_VEST_DAI"));
    address immutable      MCD_VAT          = DssExecLib.getChangelogAddress("MCD_VAT");
    address immutable      MCD_VOW          = DssExecLib.getChangelogAddress("MCD_VOW");
    address immutable      MCD_JOIN_DAI     = DssExecLib.getChangelogAddress("MCD_JOIN_DAI");
    address immutable      OLD_MCD_ESM      = DssExecLib.getChangelogAddress(MCD_ESM_NAME);

    address constant SF_001_WALLET          = 0xf737C76D2B358619f7ef696cf3F94548fEcec379;
    address constant SNE_001_WALLET         = 0x6D348f18c88D45243705D4fdEeB6538c6a9191F1;

    uint256 constant MAR_01_2022            = 1646092800;
    uint256 constant JUL_31_2022            = 1659225600;

    // Math
    uint256 constant MILLION = 10**6;
    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "sub-underflow");
    }

    function actions() public override {

        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();

        address addr;


        //////////////////////////////////////////////////////////
        // Update rates to mainnet
        // PPG - Open Market Committee Proposal - January 31, 2022
        // https://vote.makerdao.com/polling/QmWReBMh?network=mainnet#poll-detail

        /// Stability Fee Decreases

        // Decrease the ETH-A Stability Fee from 2.5% to 2.25%.
        DssExecLib.setIlkStabilityFee("ETH-A", TWO_PT_TWO_FIVE_PCT_RATE, true);

        // Decrease the ETH-B Stability Fee from 6.5% to 4%.
        DssExecLib.setIlkStabilityFee("ETH-B", FOUR_PCT_RATE, true);

        // Decrease the WSTETH-A Stability Fee from 3% to 2.5%.
        DssExecLib.setIlkStabilityFee("WSTETH-A", TWO_PT_FIVE_PCT_RATE, true);

        // Decrease the WBTC-A Stability Fee from 4% to 3.75%.
        DssExecLib.setIlkStabilityFee("WBTC-A", THREE_PT_SEVEN_FIVE_PCT_RATE, true);

        // Decrease the WBTC-B Stability Fee from 7% to 5%.
        DssExecLib.setIlkStabilityFee("WBTC-B", FIVE_PCT_RATE, true);

        // Decrease the WBTC-C Stability Fee from 1.5% to 0.75%.
        DssExecLib.setIlkStabilityFee("WBTC-C", ZERO_PT_SEVEN_FIVE_PCT_RATE, true);

        // Decrease the UNIV2DAIETH-A Stability Fee from 2% to 1%.
        DssExecLib.setIlkStabilityFee("UNIV2DAIETH-A", ONE_PCT_RATE, true);

        // Decrease the UNIV2WBTCETH-A Stability Fee from 3% to 2%.
        DssExecLib.setIlkStabilityFee("UNIV2WBTCETH-A", TWO_PCT_RATE, true);

        // Decrease the UNIV2USDCETH-A Stability Fee from 2.5% to 1.5%.
        DssExecLib.setIlkStabilityFee("UNIV2USDCETH-A", ONE_PT_FIVE_PCT_RATE, true);

        // Decrease the GUNIV3DAIUSDC2-A Stability Fee from 0.5% to 0.25%.
        DssExecLib.setIlkStabilityFee("GUNIV3DAIUSDC2-A", ZERO_PT_TWO_FIVE_PCT_RATE, true);

        // Decrease the TUSD-A Stability Fee from 1% to 0%.
        DssExecLib.setIlkStabilityFee("TUSD-A", ZERO_PCT_RATE, true);


        /// DIRECT-AAVEV2-DAI (Aave D3M) Target Borrow Rate Decrease

        // Decrease the DIRECT-AAVEV2-DAI Target Borrow Rate from 3.75% to 3.5%.
        DssExecLib.setValue(DssExecLib.getChangelogAddress("MCD_JOIN_DIRECT_AAVEV2_DAI"), "bar", 3.5 * 10**27 / 100);


        /// Maximum Debt Ceiling Changes + GUNIV3DAIUSDC2-A Target Available Debt Increase

        // Decrease the GUNIV3DAIUSDC1-A Maximum Debt Ceiling from 500 million DAI to 100 million DAI.
        DssExecLib.setIlkAutoLineDebtCeiling("GUNIV3DAIUSDC1-A", 100 * MILLION);

        // Increase the GUNIV3DAIUSDC2-A Maximum Debt Ceiling from 500 million DAI to 750 million DAI.
        // Increase the GUNIV3DAIUSDC2-A Target Available Debt (gap) from 10 million DAI to 50 million DAI.
        DssExecLib.setIlkAutoLineParameters("GUNIV3DAIUSDC2-A", 750 * MILLION, 50 * MILLION, 8 hours);


        //////////////////////////////////////////////////////////
        // Set the ESM threshold to 100k MKR
        // https://vote.makerdao.com/polling/QmQSVmrh?network=mainnet#poll-detail

        DssExecLib.setValue(NEW_MCD_ESM, "min", 100_000 * WAD);

        // MCD_END
        addr = DssExecLib.getChangelogAddress("MCD_END");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_ETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_ETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_ETH_B
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_ETH_B");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_ETH_C
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_ETH_C");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_BAT_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_BAT_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_USDC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_USDC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_USDC_B
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_USDC_B");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_TUSD_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_TUSD_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_WBTC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_WBTC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_ZRX_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_ZRX_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_KNC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_KNC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_MANA_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_MANA_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_USDT_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_USDT_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_PAXUSD_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_PAXUSD_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_COMP_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_COMP_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_LRC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_LRC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_LINK_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_LINK_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_BAL_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_BAL_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_YFI_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_YFI_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_GUSD_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_GUSD_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNI_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNI_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_RENBTC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_RENBTC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_AAVE_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_AAVE_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_PSM_USDC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_PSM_USDC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_MATIC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_MATIC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2DAIETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2DAIETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2WBTCETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2WBTCETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2USDCETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2USDCETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2DAIUSDC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2DAIUSDC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2ETHUSDT_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2ETHUSDT_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2LINKETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2LINKETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2UNIETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2UNIETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2WBTCDAI_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2WBTCDAI_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2AAVEETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2AAVEETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2DAIUSDT_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2DAIUSDT_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_PSM_PAX_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_PSM_PAX_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_GUNIV3DAIUSDC1_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_GUNIV3DAIUSDC1_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_WSTETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_WSTETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_WBTC_B
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_WBTC_B");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_WBTC_C
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_WBTC_C");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_PSM_GUSD_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_PSM_GUSD_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_GUNIV3DAIUSDC2_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_GUNIV3DAIUSDC2_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_VAT
        addr = DssExecLib.getChangelogAddress("MCD_VAT");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_DIRECT_AAVEV2_DAI
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_DIRECT_AAVEV2_DAI");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // OPTIMISM_DAI_BRIDGE
        addr = DssExecLib.getChangelogAddress("OPTIMISM_DAI_BRIDGE");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // OPTIMISM_ESCROW
        addr = DssExecLib.getChangelogAddress("OPTIMISM_ESCROW");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // OPTIMISM_GOV_RELAY
        addr = DssExecLib.getChangelogAddress("OPTIMISM_GOV_RELAY");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // ARBITRUM_DAI_BRIDGE
        addr = DssExecLib.getChangelogAddress("ARBITRUM_DAI_BRIDGE");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // ARBITRUM_ESCROW
        addr = DssExecLib.getChangelogAddress("ARBITRUM_ESCROW");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // ARBITRUM_GOV_RELAY
        addr = DssExecLib.getChangelogAddress("ARBITRUM_GOV_RELAY");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_JOIN_DIRECT_AAVEV2_DAI
        addr = DssExecLib.getChangelogAddress("MCD_JOIN_DIRECT_AAVEV2_DAI");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        DssExecLib.setChangelogAddress(MCD_ESM_NAME, NEW_MCD_ESM);
        DssExecLib.setChangelogVersion("1.10.0");

        //////////////////////////////////////////////////////////
        // Delegate Compensation January Distribution
        // https://forum.makerdao.com/t/recognized-delegate-compensation-breakdown-january-2022/13001

        DssExecLib.sendPaymentFromSurplusBuffer(FLIP_FLOP_FLAP_WALLET,  12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACK_LOOPS_WALLET, 12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(SCHUPPI_WALLET,         12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(MAKERMAN_WALLET,         8_620);
        DssExecLib.sendPaymentFromSurplusBuffer(MONETSUPPLY_WALLET,      4_807);
        DssExecLib.sendPaymentFromSurplusBuffer(ACRE_INVEST_WALLET,      3_795);
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTIN_CASE_WALLET,        889);
        DssExecLib.sendPaymentFromSurplusBuffer(GFX_LABS_WALLET,           641);


        //////////////////////////////////////////////////////////
        // Repair Dai Streams
        // https://forum.makerdao.com/t/correction-to-last-weeks-executive/13022

        // MIP40c3-SP47: Core Unit Budget (SNE-001) - Phase II StarkNet Fast Withdrawal and Wormhole
        // https://mips.makerdao.com/mips/details/MIP40c3SP47
        uint256 _sneId = 24;
        // Send first month payment minus accrued amount
        uint256 snePayment = sub(42_917 * WAD, VEST.accrued(_sneId));
        VatAbstract(MCD_VAT).suck(MCD_VOW, address(this), snePayment * RAY);
        DaiJoinAbstract(MCD_JOIN_DAI).exit(SNE_001_WALLET, snePayment);
        // Cancel
        VEST.unrestrict(_sneId);
        VEST.vest(_sneId); // Pay unpaid stream amount
        VEST.yank(_sneId);
        // Stream payments for months 2-6
        VEST.restrict(
            VEST.create(SNE_001_WALLET,     214_583 * WAD, MAR_01_2022, JUL_31_2022 - MAR_01_2022,            0, address(0))
        );
        // Total of payments = 257_500

        // MIP40c3-SP46: Adding Strategic Finance Core Unit Budget (SF-001)
        // https://mips.makerdao.com/mips/details/MIP40c3SP46
        uint256 _sfId = 26;
        // Send first month payment minus accrued amount
        uint256 sfPayment = sub(82_417 * WAD, VEST.accrued(_sfId));
        VatAbstract(MCD_VAT).suck(MCD_VOW, address(this), sfPayment * RAY);
        DaiJoinAbstract(MCD_JOIN_DAI).exit(SF_001_WALLET, sfPayment);
        // Cancel stream
        VEST.unrestrict(_sfId);
        VEST.vest(_sfId); // Pay unpaid stream amount
        VEST.yank(_sfId);
        // Stream payments for months 2-6
        VEST.restrict(
            VEST.create(SF_001_WALLET,      412_085 * WAD, MAR_01_2022, JUL_31_2022 - MAR_01_2022,            0, address(0))
        );
        // Total of payments = 494_502

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
