// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
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

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/d04bee8084c5724496ef72a0c06d00e2c7b8905e/governance/votes/Executive%20vote%20-%20April%202%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-04-02 MakerDAO Executive Spell | Hash: 0xdb1339f86f456759bc4ec97f49b7b10abb86d97bbb9f56577731efd715d978c9";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //

    uint256 constant THOUSAND = 10**3;
    uint256 constant MILLION = 10**6;
    uint256 constant BILLION = 10**9;

    // Core Units Budget Addresses
    address constant INTERIM_MULTISIG = 0x73f09254a81e1F835Ee442d1b3262c1f1d7A13ff;
    address constant RISK = 0xd98ef20520048a35EdA9A202137847A62120d2d9;

    // Disable Office Hours
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // Increase the COMP-A Maximum Debt Ceiling from 10M to 30M
        DssExecLib.setIlkAutoLineDebtCeiling("COMP-A", 30 * MILLION);

        // Increase the ZRX-A Maximum Debt Ceiling from 5M to 10M
        DssExecLib.setIlkAutoLineDebtCeiling("ZRX-A", 10 * MILLION);

        // Increase the YFI-A Maximum Debt Ceiling from 45M to 75M
        DssExecLib.setIlkAutoLineDebtCeiling("YFI-A", 75 * MILLION);

        // Increase the PSM-USDC-A Debt Ceiling from 1B to 2B
        DssExecLib.increaseIlkDebtCeiling("PSM-USDC-A", 1 * BILLION, true);

        // Provide Core Unit Budgets

        // Real-World Finance (Interim Multi-Sig)
        DssExecLib.sendPaymentFromSurplusBuffer(INTERIM_MULTISIG, 40 * THOUSAND);

        // Governance (Interim Multi-Sig)
        DssExecLib.sendPaymentFromSurplusBuffer(INTERIM_MULTISIG, 80 * THOUSAND);

        // Risk
        DssExecLib.sendPaymentFromSurplusBuffer(RISK, 100_500);
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
