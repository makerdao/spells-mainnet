// SPDX-License-Identifier: GPL-3.0-or-later
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

contract Wallets {

    mapping (bytes32 => address) public addr_wallet;

    constructor() public {
        addr_wallet["DUX"]                          = 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad;
        addr_wallet["COM_WALLET"]                   = 0x1eE3ECa7aEF17D1e74eD7C447CcBA61aC76aDbA9;
        addr_wallet["FLIPFLOPFLAP"]                 = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
        addr_wallet["FEEDBLACKLOOPS"]               = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
        addr_wallet["ULTRASCHUPPI"]                 = 0x89C5d54C979f682F40b73a9FC39F338C88B434c6;
        addr_wallet["FIELDTECHNOLOGIES"]            = 0x0988E41C02915Fe1beFA78c556f946E5F20ffBD3;
        addr_wallet["GRO_WALLET"]                   = 0x7800C137A645c07132886539217ce192b9F0528e;
        addr_wallet["ORA_WALLET"]                   = 0x2d09B7b95f3F312ba6dDfB77bA6971786c5b50Cf;
        addr_wallet["PE_WALLET"]                    = 0xe2c16c308b843eD02B09156388Cb240cEd58C01c;
    }
}
