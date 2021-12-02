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
pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";
import "dss-interfaces/dss/VestAbstract.sol";

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/Executive%20vote%20-%20November%2026,%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-12-3 MakerDAO Executive Spell | Hash: ";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //

    // --- Rates ---
    uint256 constant ZERO_PCT_RATE            = 1000000000000000000000000000;
    uint256 constant ONE_FIVE_PCT_RATE        = 1000000000472114805215157978;

    // --- Math ---
    uint256 constant MILLION                  = 10 ** 6;
    uint256 constant RAD                      = 10 ** 45;


    // --- Wallets + Dates ---
    address constant COM_WALLET     = 0x1eE3ECa7aEF17D1e74eD7C447CcBA61aC76aDbA9;


    // --- Delegate Wallets ----
    address constant FLIP_FLOP_FLAP         = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address constant FEEDBLACK_LOOPS    = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address constant ULTRA_SCHUPPI         = 0x89C5d54C979f682F40b73a9FC39F338C88B434c6;
    address constant FIELD_TECHNOLOGIES_INC = 0x0988E41C02915Fe1beFA78c556f946E5F20ffBD3;

    uint256 constant DEC_01_2021    = 1638316800;
    uint256 constant DEC_31_2021    = 1640908800;
    uint256 constant JAN_01_2022    = 1640995200;
    uint256 constant APR_30_2022    = 1651276800;
    uint256 constant JUN_30_2022    = 1656547200;
    uint256 constant AUG_01_2022    = 1659312000;
    uint256 constant NOV_30_2022    = 1669766400;
    uint256 constant DEC_31_2022    = 1672444800;
    uint256 constant SEP_01_2024    = 1725148800;

    function actions() public override {
     

       
        // ------------------------------ Core Unit Budget Distribution -----------------------------
        // https://mips.makerdao.com/mips/details/MIP39c2SP8
        DssExecLib.sendPaymentFromSurplusBuffer(COM_WALLET, 27_058);

        // ------------------------------- Delegate Payments ----------------------------------------
        DssExecLib.sendPaymentFromSurplusBuffer(FLIP_FLOP_FLAP, 12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACK_LOOPS, 12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(ULTRA_SCHUPPI, 8093);
        DssExecLib.sendPaymentFromSurplusBuffer(FIELD_TECHNOLOGIES_INC, 3690);



      
        //DssExecLib.setChangelogVersion("1.9.11");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
