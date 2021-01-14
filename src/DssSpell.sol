// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity 0.6.11;

import "dss-exec-lib/DssAction.sol";

contract SpellAction is DssAction {

    string public constant description = "TODO";

    /**
        @dev constructor (required)
        @param lib         address of the DssExecLib contract
        @param officeHours true if officehours enabled
    */
    constructor(address lib, bool officeHours) public DssAction(lib, officeHours) {

    }

    function actions() public override {

    }

    /* TODO
    *Whitelist Gnosis: 0xD5885fbCb9a8a8244746010a3BC6F1C6e0269777*
    BTCUSD OSM = 0xf185d0682d50819263941e5f4EacC763CC5C6C42
    LINKUSD OSM = 0x9B0C694C6939b5EA9584e9b61C7815E8d97D9cC7
    COMPUSD OSM = 0xBED0879953E633135a48a157718Aa791AC0108E4
    YFIUSD OSM = 0x5F122465bCf86F45922036970Be6DD7F58820214
    ZRXUSD OSM = 0x7382c066801E7Acb2299aC8562847B9883f5CD3c

    *Whitelist Set:*
    AAVEUSD MED = 0xe62872DFEbd323b03D27946f8e2491B454a69811
    Whitelist Addr = 0x8b1C079f8192706532cC0Bf0C02dcC4fF40d045D

    LRCUSD MED = 0xcCe92282d9fe310F4c232b0DA9926d5F24611C7B
    Whitelist Addr = 0x1D5d9a2DDa0843eD9D8a9Bddc33F1fca9f9C64a0

    YFIUSD MED = 0x89AC26C0aFCB28EC55B6CD2F6b7DAD867Fa24639
    Whitelist Addr = 0x1686d01Bd776a1C2A3cCF1579647cA6D39dd2465


    ZRXUSD MED = 0x956ecD6a9A9A0d84e8eB4e6BaaC09329E202E55e
    Whitelist Addr = 0xFF60D1650696238F81BE53D23b3F91bfAAad938f

    UNIUSD MED = 0x52f761908cc27b4d77ad7a329463cf08baf62153
    Whitelist Addr = 0x3c3Afa479d8C95CF0E1dF70449Bb5A14A3b7Af67
    */

    // RATES

    // FLAP Parameters

    // Surplus buffer

}
