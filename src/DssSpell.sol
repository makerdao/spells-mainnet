// SPDX-FileCopyrightText: © 2021-2022 Dai Foundation <www.daifoundation.org>
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

// Enable ABIEncoderV2 when onboarding collateral
// pragma experimental ABIEncoderV2;
import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol";

interface VatLike {
    function Line() external view returns (uint256);
    function file(bytes32, uint256) external;
    function ilks(bytes32) external returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
}

interface DssVestLike {
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function restrict(uint256) external;
}

interface StarknetLike {
    function setCeiling(uint256) external;
}

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/428d97b75ec8bdb4f2b87e69dcc917ad750b8c76/governance/votes/Executive%20vote%20-%20June%208%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-06-08 MakerDAO Executive Spell | Hash: 0xf962d424ea3663316d9d91fc3854d8864b7b45165d949688117ffba9798e90b9";

    VatLike     immutable vat                   = VatLike(DssExecLib.vat());

    DssVestLike immutable MCD_VEST_DAI          = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_DAI"));
    DssVestLike immutable MCD_VEST_MKR_TREASURY = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY"));

    address constant STARKNET_ESCROW_MOM    = 0xc238E3D63DfD677Fa0FA9985576f0945C581A266;
    address constant STARKNET_ESCROW        = 0x0437465dfb5B79726e35F08559B0cBea55bb585C;
    address constant STARKNET_DAI_BRIDGE    = 0x659a00c33263d9254Fed382dE81349426C795BB6;
    address constant STARKNET_GOV_RELAY     = 0x9eed6763BA8D89574af1478748a7FDF8C5236fE0;

    address constant SH_MULTISIG            = 0xc657aC882Fb2D6CcF521801da39e910F8519508d;
    address constant SH_WALLET              = 0x955993Df48b0458A01cfB5fd7DF5F5DCa6443550;

    address constant FLIPFLOPFLAP_WALLET    = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address constant SCHUPPI_WALLET         = 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167;
    address constant FEEDBLACKLOOPS_WALLET  = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address constant MAKERMAN_WALLET        = 0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0;
    address constant ACREINVEST_WALLET      = 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D;
    address constant MONETSUPPLY_WALLET     = 0x4Bd73eeE3d0568Bb7C52DFCad7AD5d47Fff5E2CF;
    address constant JUSTINCASE_WALLET      = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
    address constant GFXLABS_WALLET         = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;
    address constant DOO_WALLET             = 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0;
    address constant FLIPSIDECRYPTO_WALLET  = 0x62a43123FE71f9764f26554b3F5017627996816a;
    address constant PENNBLOCKCHAIN_WALLET  = 0x070341aA5Ed571f0FB2c4a5641409B1A46b4961b;


    // Wed 01 Jun 2022 12:00:00 AM UTC
    uint256 constant JUN_01_2022 = 1654041600;
    // Wed 15 Mar 2023 12:00:00 AM UTC
    uint256 constant MAR_15_2023 = 1678838400;
    // Thu 23 Nov 2023 12:00:00 AM UTC
    uint256 constant NOV_23_2023 = 1700697600;


    // Math
    uint256 constant MILLION = 10 ** 6;
    uint256 constant WAD     = 10 ** 18;
    uint256 constant RAD     = 10 ** 45;

    function _sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "sub-underflow");
    }

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmPgPVrVxDCGyNR5rGp9JC5AUxppLzUAqvncRJDcxQnX1u
    //

    // Turn office hours off
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();


        // Core Unit Budget DAI Transfer
        // https://mips.makerdao.com/mips/details/MIP40c3SP67#budget-request-up-front
        //
        //    SH-001 - 230,000 DAI - 0xc657aC882Fb2D6CcF521801da39e910F8519508d
        DssExecLib.sendPaymentFromSurplusBuffer(SH_MULTISIG, 230_000);

        // Core Unit DAI Budget Stream
        // https://mips.makerdao.com/mips/details/MIP40c3SP67#budget-request-up-front
        //
        //    SH-001 | 2022-06-01 to 2023-03-15 | 540,000 DAI | 0xc657aC882Fb2D6CcF521801da39e910F8519508d
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                SH_MULTISIG,
                540_000 * WAD,
                JUN_01_2022,
                MAR_15_2023 - JUN_01_2022,
                0,
                address(0)
            )
        );

        // Core Unit MKR Budget Stream
        // https://mips.makerdao.com/mips/details/MIP40c3SP67#budget-request-up-front
        //
        //    SH-001 | 2022-06-01 to 2026-06-01 | Cliff 2023-11-23 | 250 MKR | 0x955993Df48b0458A01cfB5fd7DF5F5DCa6443550
        MCD_VEST_MKR_TREASURY.restrict(
            MCD_VEST_MKR_TREASURY.create(
                SH_WALLET,
                250 * WAD,
                JUN_01_2022,
                4 * 365 days,
                NOV_23_2023 - JUN_01_2022,
                SH_MULTISIG
            )
        );


        // MOMC Proposal
        // https://vote.makerdao.com/polling/QmYx9e3k#poll-detail
        //
        // Maximum Debt Ceiling Decreases
        //
        //    Decrease WSTETH-A Maximum Debt Ceiling from 300 million to 200 million
        DssExecLib.setIlkAutoLineDebtCeiling("WSTETH-A", 200 * MILLION);

        //    Reduce Aave D3M Maximum Debt Ceiling from 300 million to 100 million
        DssExecLib.setIlkAutoLineDebtCeiling("DIRECT-AAVEV2-DAI", 100 * MILLION);

        //    Reduce LINK-A Maximum Debt Ceiling from 100 million DAI to 50 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("LINK-A", 50 * MILLION);

        // Maximum Debt Ceiling Increase
        //
        //    Increase MANA-A Maximum Debt Ceiling from 10 million DAI to 15 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("MANA-A", 15 * MILLION);

        // D3M Target Borrow Rate Decrease
        //
        //    Reduce DIRECT-AAVEV2-DAI Target Borrow Rate from 3.5% to 2.75%
        DssExecLib.setD3MTargetInterestRate(DssExecLib.getChangelogAddress("MCD_JOIN_DIRECT_AAVEV2_DAI"), 275);

        // Target Available Debt Increase
        //
        //    Increase WSTETH-B Target Available Debt from 15 million DAI to 30 million DAI
        DssExecLib.setIlkAutoLineParameters("WSTETH-B", 150 * MILLION, 30 * MILLION, 8 hours);


        // 1st Stage of Collateral Offboarding Process
        // https://forum.makerdao.com/t/signal-request-offboard-uni-univ2daieth-univ2wbtceth-univ2unieth-and-univ2wbtcdai/15160
        //
        uint256 line;
        uint256 lineReduction;

        //    Set UNI-A Maximum Debt Ceiling to 0
        (,,,line,) = vat.ilks("UNI-A");
        lineReduction += line;
        DssExecLib.removeIlkFromAutoLine("UNI-A");
        DssExecLib.setIlkDebtCeiling("UNI-A", 0);

        //    Set UNIV2DAIETH-A Maximum Debt Ceiling to 0
        (,,,line,) = vat.ilks("UNIV2DAIETH-A");
        lineReduction += line;
        DssExecLib.removeIlkFromAutoLine("UNIV2DAIETH-A");
        DssExecLib.setIlkDebtCeiling("UNIV2DAIETH-A", 0);

        //    Set UNIV2WBTCETH-A Maximum Debt Ceiling to 0
        (,,,line,) = vat.ilks("UNIV2WBTCETH-A");
        lineReduction += line;
        DssExecLib.removeIlkFromAutoLine("UNIV2WBTCETH-A");
        DssExecLib.setIlkDebtCeiling("UNIV2WBTCETH-A", 0);

        //    Set UNIV2UNIETH-A Maximum Debt Ceiling to 0
        (,,,line,) = vat.ilks("UNIV2UNIETH-A");
        lineReduction += line;
        DssExecLib.removeIlkFromAutoLine("UNIV2UNIETH-A");
        DssExecLib.setIlkDebtCeiling("UNIV2UNIETH-A", 0);

        //    Set UNIV2WBTCDAI-A Maximum Debt Ceiling to 0
        (,,,line,) = vat.ilks("UNIV2WBTCDAI-A");
        lineReduction += line;
        DssExecLib.removeIlkFromAutoLine("UNIV2WBTCDAI-A");
        DssExecLib.setIlkDebtCeiling("UNIV2WBTCDAI-A", 0);

        // Decrease Global Debt Ceiling by total amount of offboarded ilks
        vat.file("Line", _sub(vat.Line(), lineReduction));


        // Recognized Delegate Compensation
        //    https://forum.makerdao.com/t/recognized-delegate-compensation-breakdown-may-2022/15536
        //
        //    Flip Flop Flap Delegate LLC - 12000 DAI - 0x688d508f3a6B0a377e266405A1583B3316f9A2B3
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPFLOPFLAP_WALLET, 12_000);
        //    schuppi - 12000 DAI - 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167
        DssExecLib.sendPaymentFromSurplusBuffer(SCHUPPI_WALLET, 12_000);
        //    Feedblack Loops LLC - 12000 DAI - 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACKLOOPS_WALLET, 12_000);
        //    MakerMan - 11025 DAI - 0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0
        DssExecLib.sendPaymentFromSurplusBuffer(MAKERMAN_WALLET, 11025);
        //    ACREInvest - 9372 DAI - 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D
        DssExecLib.sendPaymentFromSurplusBuffer(ACREINVEST_WALLET, 9372);
        //    monetsupply - 6275 DAI - 0x4Bd73eeE3d0568Bb7C52DFCad7AD5d47Fff5E2CF
        DssExecLib.sendPaymentFromSurplusBuffer(MONETSUPPLY_WALLET, 6275);
        //    JustinCase - 7626 DAI - 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTINCASE_WALLET, 7626);
        //    GFX Labs - 6607 DAI - 0xa6e8772af29b29B9202a073f8E36f447689BEef6
        DssExecLib.sendPaymentFromSurplusBuffer(GFXLABS_WALLET, 6607);
        //    Doo - 622 DAI - 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0
        DssExecLib.sendPaymentFromSurplusBuffer(DOO_WALLET, 622);
        //    Flipside Crypto - 270 DAI - 0x62a43123FE71f9764f26554b3F5017627996816a
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPSIDECRYPTO_WALLET, 270);
        //    Penn Blockchain - 265 DAI - 0x070341aA5Ed571f0FB2c4a5641409B1A46b4961b
        DssExecLib.sendPaymentFromSurplusBuffer(PENNBLOCKCHAIN_WALLET, 265);


        // Starknet Bridge Changes
        // https://forum.makerdao.com/t/details-about-spells-to-be-included-in-june-8th-2022-executive-vote/15532
        //
        //    Increase Starknet Bridge Limit from 100,000 DAI to 200,000 DAI
        StarknetLike(STARKNET_DAI_BRIDGE).setCeiling(200_000 * WAD);
        //    Give DSChief control over L1EscrowMom
        DssExecLib.setAuthority(STARKNET_ESCROW_MOM, DssExecLib.getChangelogAddress("MCD_ADM"));


        // Changelog
        DssExecLib.setChangelogAddress("STARKNET_ESCROW_MOM", STARKNET_ESCROW_MOM);
        DssExecLib.setChangelogAddress("STARKNET_ESCROW", STARKNET_ESCROW);
        DssExecLib.setChangelogAddress("STARKNET_DAI_BRIDGE", STARKNET_DAI_BRIDGE);
        DssExecLib.setChangelogAddress("STARKNET_GOV_RELAY", STARKNET_GOV_RELAY);
        DssExecLib.setChangelogVersion("1.13.1");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
