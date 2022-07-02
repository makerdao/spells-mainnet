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

// Enable ABIEncoderV2 when onboarding collateral
// pragma experimental ABIEncoderV2;
import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

import { DssSpellCollateralAction } from "./DssSpellCollateral.sol";

interface DssVestLike {
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function restrict(uint256) external;
}

contract DssSpellAction is DssAction, DssSpellCollateralAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/TODO -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-07-06 MakerDAO Executive Spell | Hash: TODO";

    DssVestLike immutable MCD_VEST_DAI = DssVestLike(DssExecLib.getChangelogAddress("MCD_VEST_DAI"));

    address constant GRO_001_WALLET = 0x7800C137A645c07132886539217ce192b9F0528e;
    address constant SF_001_WALLET  = 0xf737C76D2B358619f7ef696cf3F94548fEcec379;
    address constant KEEP3R_MANAGER = 0xc6A048550C9553F8Ac20fbdeB06f114c27ECcabb;

    address constant FEEDBLACK_LOOPS_WALLET     = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address constant FLIP_FLOP_FLAP_WALLET      = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address constant ULTRASCHUPPI_WALLET        = 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167;
    address constant MAKERMAN_WALLET            = 0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0;
    address constant ACRE_INVEST_WALLET         = 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D;
    address constant JUSTIN_CASE_WALLET         = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
    address constant GFX_LABS_WALLET            = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;
    address constant DOO_WALLET                 = 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0;
    address constant PENNBLOCKCHAIN_WALLET      = 0x070341aA5Ed571f0FB2c4a5641409B1A46b4961b;
    address constant FLIPSIDE_CRYPTO_WALLET     = 0x62a43123FE71f9764f26554b3F5017627996816a;
    address constant CHRIS_BLEC_WALLET          = 0xa3f0AbB4Ba74512b5a736C5759446e9B50FDA170;
    address constant BLOCKCHAIN_COLUMBIA_WALLET = 0xdC1F98682F4F8a5c6d54F345F448437b83f5E432;
    address constant MHONKASALO_TEEMULAU_WALLET = 0x97Fb39171ACd7C82c439b6158EA2F71D26ba383d;
    address constant GOVERNANCE_HOUSE_WALLET    = 0xd2362DbB5Aa708Bc454Ce5C3F11050C016764fA6;

    // Friday, 1 July 2022 00:00:00
    uint256 constant JUL_01_2022 = 1656633600;
    // Tuesday, 31 January 2023 00:00:00
    uint256 constant JAN_31_2023 = 1675123200;
    // Friday, 30 June 2023 00:00:00
    uint256 constant JUN_30_2023 = 1688083200;
    // Saturday, 1 July 2023 00:00:00
    uint256 constant JUL_01_2023 = 1688169600;

    // Math
    uint256 constant WAD = 10**18;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmPgPVrVxDCGyNR5rGp9JC5AUxppLzUAqvncRJDcxQnX1u
    //

    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {

        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralAction
        // onboardNewCollaterals();
        // offboardCollaterals();

        // Core Unit Budget Streams
        // SF-001 | 2022-07-01 to 2023-07-01 | 989,004 DAI | 0xf737C76D2B358619f7ef696cf3F94548fEcec379
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                SF_001_WALLET,
                989_004 * WAD,
                JUL_01_2022,
                JUL_01_2023 - JUL_01_2022,
                0,
                address(0)
            )
        );

        // GRO-001 | 2022-07-01 to 2023-06-30 | 2,913,994.22 DAI | 0x7800C137A645c07132886539217ce192b9F0528e
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                GRO_001_WALLET,
                2_913_994 * WAD,
                JUL_01_2022,
                JUN_30_2023 - JUL_01_2022,
                0,
                address(0)
            )
        );

        // Core Unit Budget Transfer
        // GRO-001 - 648,133.59 DAI - 0x7800C137A645c07132886539217ce192b9F0528e
        DssExecLib.sendPaymentFromSurplusBuffer(GRO_001_WALLET, 648_133);

        // Keep3r Network Stream
        // Keep3r Network | 2022-07-01 to 2023-01-31 | 215,000 DAI | 0xc6A048550C9553F8Ac20fbdeB06f114c27ECcabb
        MCD_VEST_DAI.restrict(
            MCD_VEST_DAI.create(
                KEEP3R_MANAGER,
                215_000 * WAD,
                JUL_01_2022,
                JAN_31_2023 - JUL_01_2022,
                0,
                address(0)
            )
        );

        // Recognized Delegate Payments for June
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACK_LOOPS_WALLET,    11_573);
        DssExecLib.sendPaymentFromSurplusBuffer(FLIP_FLOP_FLAP_WALLET,     11_528);
        DssExecLib.sendPaymentFromSurplusBuffer(ULTRASCHUPPI_WALLET,       11_292);
        DssExecLib.sendPaymentFromSurplusBuffer(MAKERMAN_WALLET,            9_366);
        DssExecLib.sendPaymentFromSurplusBuffer(ACRE_INVEST_WALLET,         8_813);
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTIN_CASE_WALLET,         8_158);
        DssExecLib.sendPaymentFromSurplusBuffer(GFX_LABS_WALLET,            6_679);
        DssExecLib.sendPaymentFromSurplusBuffer(DOO_WALLET,                 5_075);
        DssExecLib.sendPaymentFromSurplusBuffer(PENNBLOCKCHAIN_WALLET,      3_795);
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPSIDE_CRYPTO_WALLET,     3_186);
        DssExecLib.sendPaymentFromSurplusBuffer(CHRIS_BLEC_WALLET,          2_739);
        DssExecLib.sendPaymentFromSurplusBuffer(BLOCKCHAIN_COLUMBIA_WALLET, 2_150);
        DssExecLib.sendPaymentFromSurplusBuffer(MHONKASALO_TEEMULAU_WALLET,   704);
        DssExecLib.sendPaymentFromSurplusBuffer(GOVERNANCE_HOUSE_WALLET,      127);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
