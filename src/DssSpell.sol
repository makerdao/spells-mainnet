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

import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol";

interface TokenLike {
    function transferFrom(address, address, uint256) external returns (bool);
}

interface L1EscrowLike {
    function approve(address, address, uint256) external;
}


contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/master/governance/votes/Executive%20vote%20-%20January%2014%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-01-14 MakerDAO Executive Spell | Hash: 0x648463c383a85878ec3db7a15296baa321a881b380579879735704b5cf998a9a";

    // --- Math ---
    uint256 constant MILLION = 10 ** 6;
    uint256 constant WAD     = 10 ** 18;

    // --- Ilks ---
    bytes32 constant UNIV2WBTCETH_A = "UNIV2WBTCETH-A";
    bytes32 constant UNIV2UNIETH_A  = "UNIV2UNIETH-A";
    bytes32 constant UNIV2DAIETH_A  = "UNIV2DAIETH-A";
    bytes32 constant UNIV2USDCETH_A = "UNIV2USDCETH-A";
    bytes32 constant UNIV2WBTCDAI_A = "UNIV2WBTCDAI-A";

    // --- Wallet addresses ---
    address constant FLIP_FLOP_FLAP_WALLET  = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address constant FEEDBLACK_LOOPS_WALLET = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address constant SCHUPPI_WALLET         = 0x89C5d54C979f682F40b73a9FC39F338C88B434c6;
    address constant MAKERMAN_WALLET        = 0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0;
    address constant ACRE_INVEST_WALLET     = 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D;
    address constant JUSTIN_CASE_WALLET     = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
    address constant GFX_LABS_WALLET        = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;

    // --- Optimism Recovery Mainnet Addresses
    address immutable MCD_DAI             = DssExecLib.dai();
    address immutable OPTIMISM_ESCROW     = DssExecLib.getChangelogAddress("OPTIMISM_ESCROW");
    address constant LOST_SOME_DAI_WALLET = 0xc9b48B787141595156d9a7aca4BC7De1Ca7b5eF6;

    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {

        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();

        // ----------------------------- Delegate Compensation -----------------------------
        // https://forum.makerdao.com/t/delegate-compensation-breakdown-december-2021/12462

        DssExecLib.sendPaymentFromSurplusBuffer(FLIP_FLOP_FLAP_WALLET, 12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACK_LOOPS_WALLET, 12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(SCHUPPI_WALLET, 12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(MAKERMAN_WALLET, 8_597);
        DssExecLib.sendPaymentFromSurplusBuffer(ACRE_INVEST_WALLET, 2_203);
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTIN_CASE_WALLET, 791);
        DssExecLib.sendPaymentFromSurplusBuffer(GFX_LABS_WALLET, 699);

        // ---------------------- Dust Parameter Updates for LP Tokens ---------------------
        // https://vote.makerdao.com/polling/QmUSfhmF


        DssExecLib.setIlkMinVaultAmount(UNIV2WBTCETH_A, 25_000);
        DssExecLib.setIlkMinVaultAmount(UNIV2UNIETH_A, 25_000);

        DssExecLib.setIlkMinVaultAmount(UNIV2DAIETH_A, 60_000);
        DssExecLib.setIlkMinVaultAmount(UNIV2USDCETH_A, 60_000);
        DssExecLib.setIlkMinVaultAmount(UNIV2WBTCDAI_A, 60_000);

        // ----------------------------- Optimism Dai Recovery -----------------------------
        // https://vote.makerdao.com/polling/Qmcfb72e
        // forum: https://forum.makerdao.com/t/signal-request-should-makerdao-assist-in-recovering-dai-locked-on-optimism-escrow/12307

        // Optimism L1 Escrow Address
        L1EscrowLike(OPTIMISM_ESCROW).approve(MCD_DAI, address(this), 10 * MILLION * WAD);
        TokenLike(MCD_DAI).transferFrom(OPTIMISM_ESCROW, LOST_SOME_DAI_WALLET, 10 * MILLION * WAD);

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
