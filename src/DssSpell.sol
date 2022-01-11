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


contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/3224f50b0b5a9301831213ed858bc1d206de8e40/governance/votes/Executive%20vote%20-%20December%2010%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-01-14 MakerDAO Executive Spell | Hash: ";

    // --- Math ---
    uint256 constant MILLION = 10**6;

    // --- Ilks ---
    bytes32 constant UNIV2DAIETH_A  = "UNIV2DAIETH-A";
    bytes32 constant UNIV2USDCETH_A = "UNIV2USDCETH-A";
    bytes32 constant UNIV2WBTCDAI_A = "UNIV2WBTCDAI-A";
    bytes32 constant UNIV2WBTCETH_A = "UNIV2WBTCETH-A";
    bytes32 constant UNIV2UNIETH_A  = "UNIV2UNIETH-A";

    // --- Wallet addresses ---

    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {

        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();

        // ----------------------------- Delegate Compensation -----------------------------
        // https://forum.makerdao.com/t/delegate-compensation-breakdown-december-2021/12462

        DssExecLib.sendPaymentFromSurplusBuffer(FLIP_FLOP_FLAP_WALLET, 12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(SCHUPPI_WALLET, 12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACK_LOOPS_WALLET, 12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(MAKERMAN_WALLET, 8_597);
        DssExecLib.sendPaymentFromSurplusBuffer(ACRE_INVEST_WALLET, 2_203);
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTIN_CASE_WALLET, 791);
        DssExecLib.sendPaymentFromSurplusBuffer(GFX_LABS_WALLET, 699);

        // ----------------------------- Optimism Dai Recovery -----------------------------
        // https://vote.makerdao.com/polling/Qmcfb72e
        // forum: https://forum.makerdao.com/t/signal-request-should-makerdao-assist-in-recovering-dai-locked-on-optimism-escrow/12307

        // Optimism L1 Escrow Address
        L1EscrowLike(L1_ESCROW).approve(MCD_DAI, address(this), 10 * MILLION);
        TokenLike(MCD_DAI).transferFrom(L1_ESCROW, LOST_SOME_DAI_WALLET, 10 * MILLION);

        // ---------------------- Dust Parameter Updates for LP Tokens ---------------------
        // https://vote.makerdao.com/polling/QmUSfhmF


        DssExecLib.setIlkMinVaultAmount("UNIV2DAIETH-A", 60_000);
        DssExecLib.setIlkMinVaultAmount("UNIV2USDCETH-A", 60_000);
        DssExecLib.setIlkMinVaultAmount("UNIV2WBTCDAI-A", 60_000);

        DssExecLib.setIlkMinVaultAmount("UNIV2WBTCETH-A", 25_000);
        DssExecLib.setIlkMinVaultAmount("UNIV2UNIETH-A", 25_000);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
