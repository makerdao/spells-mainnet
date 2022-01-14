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

contract Wallets {

    mapping (bytes32 => address) public addr;

    constructor() public {
        addr["DUX"]                          = 0x5A994D8428CCEbCC153863CCdA9D2Be6352f89ad;
        addr["COM_WALLET"]                   = 0x1eE3ECa7aEF17D1e74eD7C447CcBA61aC76aDbA9;
        addr["FLIPFLOPFLAP"]                 = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
        addr["FEEDBLACKLOOPS"]               = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
        addr["ULTRASCHUPPI"]                 = 0x89C5d54C979f682F40b73a9FC39F338C88B434c6;
        addr["FIELDTECHNOLOGIES"]            = 0x0988E41C02915Fe1beFA78c556f946E5F20ffBD3;
        addr["MAKERMAN"]                     = 0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0;
        addr["ACREINVEST"]                   = 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D;
        addr["JUSTINCASE"]                   = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
        addr["GFXLABS"]                      = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;
        addr["GRO_WALLET"]                   = 0x7800C137A645c07132886539217ce192b9F0528e;
        addr["ORA_WALLET"]                   = 0x2d09B7b95f3F312ba6dDfB77bA6971786c5b50Cf;
        addr["PE_WALLET"]                    = 0xe2c16c308b843eD02B09156388Cb240cEd58C01c;
    }
}
