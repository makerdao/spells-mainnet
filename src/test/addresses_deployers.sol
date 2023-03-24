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

pragma solidity 0.8.16;

contract Deployers {

    address[] public addr;

    constructor() {
        addr = [
            0xdDb108893104dE4E1C6d0E47c42237dB4E617ACc,
            0xDa0FaB05039809e63C5D068c897c3e602fA97457,
            0xda0fab060e6cc7b1C0AA105d29Bd50D71f036711,
            0xDA0FaB0700A4389F6E6679aBAb1692B4601ce9bf,
            0x0048d6225D1F3eA4385627eFDC5B4709Cab4A21c,
            0xd200790f62c8da69973e61d4936cfE4f356ccD07,
            0x92723e0bF280942B98bf2d1e832Bde9A3Bd2F2c2,  // Chainlog Deployer
            0xdA0C0de01d90A5933692Edf03c7cE946C7c50445,  // Old PE
            0xDa0c0De020F80d43dde58c2653aa73d28Df1fBe1,  // Old PE
            0xC1E6d8136441FC66612Df3584007f7CB68765e5D,  // PE
            0xa22A61c233d7242728b4255420063c92fc1AEBb9,  // PE
            0x4D6fbF888c374D7964D56144dE0C0cFBd49750D3,  // Oracles
            0x1f42e41A34B71606FcC60b4e624243b365D99745,  // Oracles
            0x075da589886BA445d7c7e81c472059dE7AE65250,  // Used for Optimism & Arbitrum bridge contracts
            0x7f06941997C7778E7B734fE55f7353f554B06d7d,  // Starknet
            0xb27B6fa77D7FBf3C1BD34B0f7DA59b39D3DB0f7e,  // CES
            0x39aBD7819E5632Fa06D2ECBba45Dca5c90687EE3,  // Oracles from 2022-10-26
            0x45Ea4FADf8Db54DF5a96774167547893e0b4D6A5,  // CES from 2022-10-26
            0x5C82d7Eafd66d7f5edC2b844860BfD93C3B0474f   // CES from 2022-12-09
        ];
    }

    function count() external view returns (uint256) {
        return addr.length;
    }
}
