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

contract Deployers {

    address[] public addr;

    constructor() public {
        addr = [
            0xdDb108893104dE4E1C6d0E47c42237dB4E617ACc,
            0xDa0FaB05039809e63C5D068c897c3e602fA97457,
            0xda0fab060e6cc7b1C0AA105d29Bd50D71f036711,
            0xDA0FaB0700A4389F6E6679aBAb1692B4601ce9bf,
            0x0048d6225D1F3eA4385627eFDC5B4709Cab4A21c,
            0xd200790f62c8da69973e61d4936cfE4f356ccD07,
            0xdA0C0de01d90A5933692Edf03c7cE946C7c50445,
            0x4D6fbF888c374D7964D56144dE0C0cFBd49750D3,  // Oracles
            0x1f42e41A34B71606FcC60b4e624243b365D99745,  // Oracles
            0x075da589886BA445d7c7e81c472059dE7AE65250   // Used for Optimism & Arbitrum bridge contracts
        ];
    }

    function count() external view returns (uint256) {
        return addr.length;
    }
}
