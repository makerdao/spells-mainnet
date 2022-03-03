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
//pragma experimental ABIEncoderV2;
import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";
import "dss-interfaces/dss/VestAbstract.sol";

import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol";


contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/Executive%20Vote%20-%20February%2025%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-03-04 MakerDAO Executive Spell | Hash: TODO";

    // Recognized Delegates DAI Transfers
    address constant FLIP_FLOP_FLAP_WALLET  = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address constant FEEDBLACK_LOOPS_WALLET = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address constant ULTRASCHUPPI_WALLET    = 0x89C5d54C979f682F40b73a9FC39F338C88B434c6;
    address constant MAKERMAN_WALLET        = 0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0;
    address constant ACRE_INVEST_WALLET     = 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D;
    address constant MONETSUPPLY_WALLET     = 0x4Bd73eeE3d0568Bb7C52DFCad7AD5d47Fff5E2CF;
    address constant JUSTIN_CASE_WALLET     = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
    address constant GFX_LABS_WALLET        = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;

    // Core Units DAI Transfers and Streams
    address constant CES_001_WALLET         = 0x25307aB59Cd5d8b4E2C01218262Ddf6a89Ff86da;
    address constant IS_001_WALLET          = 0xd1F2eEf8576736C1EbA36920B957cd2aF07280F4;

    // Core Units DAI Streams
    VestAbstract immutable VEST             = VestAbstract(DssExecLib.getChangelogAddress("MCD_VEST_DAI"));

    address constant RISK_001_WALLET        = 0xb386Bc4e8bAE87c3F67ae94Da36F385C100a370a;

    uint256 constant MAR_01_2022            = 1646092800; // 2022-03-01
    uint256 constant APR_01_2022            = 1648771200; // 2022-04-01
    uint256 constant DEC_01_2022            = 1669852800; // 2022-12-01
    uint256 constant FEB_28_2023            = 1677542400; // 2023-02-28
    uint256 constant MAR_31_2023            = 1680220800; // 2023-03-31

    // Math
    uint256 constant MILLION = 10**6;
    uint256 constant WAD = 10**18;

    // Turn office hours off
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // Recognized Delegate Compensation February 2022 Distribution (Payout: 57,665 DAI)
        // https://forum.makerdao.com/t/recognized-delegate-compensation-breakdown-february-2022/13518
        DssExecLib.sendPaymentFromSurplusBuffer(FLIP_FLOP_FLAP_WALLET,  12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACK_LOOPS_WALLET, 12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(ULTRASCHUPPI_WALLET,    12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(MAKERMAN_WALLET,         8_512);
        DssExecLib.sendPaymentFromSurplusBuffer(ACRE_INVEST_WALLET,      6_494);
        DssExecLib.sendPaymentFromSurplusBuffer(MONETSUPPLY_WALLET,      5_072);
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTIN_CASE_WALLET,        927);
        DssExecLib.sendPaymentFromSurplusBuffer(GFX_LABS_WALLET,           660);

        // Core Units Budget DAI Transfers
        // https://mips.makerdao.com/mips/details/MIP40c3SP57
        DssExecLib.sendPaymentFromSurplusBuffer(CES_001_WALLET,            259_184);
        // https://mips.makerdao.com/mips/details/MIP40c3SP58
        DssExecLib.sendPaymentFromSurplusBuffer(IS_001_WALLET,             138_000);

        // Core Units Budget DAI Streams
        // https://mips.makerdao.com/mips/details/MIP40c3SP56
        // 2,760,000 DAI DssVest Stream to RISK-001 starting 2022-03-01 and ending 2023-02-28
        VEST.restrict(
            VEST.create(RISK_001_WALLET,     2_760_000 * WAD, MAR_01_2022, FEB_28_2023 - MAR_01_2022,            0, address(0))
        );
        // https://mips.makerdao.com/mips/details/MIP40c3SP57
        // 2,780,562 DAI DssVest Stream to CES-001 starting on 2022-04-01 and ending 2023-03-31
        VEST.restrict(
            VEST.create(CES_001_WALLET,      2_780_562 * WAD, APR_01_2022, MAR_31_2023 - APR_01_2022,            0, address(0))
        );
        // https://mips.makerdao.com/mips/details/MIP40c3SP58
        // 207,000 DAI DssVest Stream to IS-001 starting on 2022-03-01 and ending 2022-12-01
        VEST.restrict(
            VEST.create(IS_001_WALLET,         207_000 * WAD, MAR_01_2022, DEC_01_2022 - MAR_01_2022,            0, address(0))
        );

        // Revoke RISK-001 Budget DAI Stream
        // https://mips.makerdao.com/mips/details/MIP40c3SP56
        VEST.yank(8);

        // --- Open Market Committee Proposal ---
        // https://vote.makerdao.com/polling/QmPhbQ3B
        //
        // Increase WSTETH-A AutoLine (line) from 200 million DAI to 300 million DAI
        // Increase WSTETH-A Autoline (gap) from 20 million DAI to 30 million DAI.
        DssExecLib.setIlkAutoLineParameters("WSTETH-A", 300 * MILLION, 30 * MILLION, 6 hours);

        // Increase DIRECT-AAVEV2-DAI AutoLine (line) from 220 million DAI to 300 million DAI.
        // Increase DIRECT-AAVEV2-DAI AutoLine (gap) from 50 million DAI to 65 million DAI.
        DssExecLib.setIlkAutoLineParameters("DIRECT-AAVEV2-DAI", 300 * MILLION, 65 * MILLION, 12 hours);

        // Decrease DIRECT-AAVEV2-DAI Target Borrow Rate (bar) from 3.5% to 2.85%.
        DssExecLib.setD3MTargetInterestRate(DssExecLib.getChangelogAddress("MCD_JOIN_DIRECT_AAVEV2_DAI"), 285); // 2.85%
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
