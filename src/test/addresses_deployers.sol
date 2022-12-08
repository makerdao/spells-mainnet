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

pragma solidity ^0.6.12;

contract Deployers {

    address[] public addr;

    //                      NAME                ADDRESS                                      FIRST TX DATE ("NAME")

    // Known Team Deployers
    address public constant PE_01              = 0xda0fab060e6cc7b1C0AA105d29Bd50D71f036711; //2020-11-17 ("PE-01")
    address public constant PE_02              = 0xDA0FaB0700A4389F6E6679aBAb1692B4601ce9bf; //2021-02-02 ("PE-02")
    address public constant PE_03              = 0xdA0C0de01d90A5933692Edf03c7cE946C7c50445; //2021-02-26 ("PE-03")
    address public constant PE_07              = 0xDa0c0De020F80d43dde58c2653aa73d28Df1fBe1; //2022-07-28 ("PE-07")
    address public constant PE_CURRENT         = 0xC1E6d8136441FC66612Df3584007f7CB68765e5D; //2022-09-21 ("PE_CURRENT")
    address public constant CES_03             = 0xb27B6fa77D7FBf3C1BD34B0f7DA59b39D3DB0f7e; //2022-04-27 ("CES-03")
    address public constant ORACLES_1          = 0x1f42e41A34B71606FcC60b4e624243b365D99745; //2021-09-14 ("ORACLES_1")
    address public constant ORACLES_2          = 0x39aBD7819E5632Fa06D2ECBba45Dca5c90687EE3; //2022-10-26 ("ORACLES_2")
    
    // Unlabelled Team Deployers
    address public constant CES_2022_10_26     = 0x45Ea4FADf8Db54DF5a96774167547893e0b4D6A5; //2022-10-26 (New CES)
    address public constant ORACLES_2021_07_20 = 0x4D6fbF888c374D7964D56144dE0C0cFBd49750D3; //2021-07-20 Oracles (NO MATCH IN GOERLI)
    
    // Unknown Team Deployers
    address public constant UNKNOWN_2019_06_27 = 0xdDb108893104dE4E1C6d0E47c42237dB4E617ACc; //2019-06-27 (NO MATCH IN GOERLI)
    address public constant UNKNOWN_2020_09_03 = 0xDa0FaB05039809e63C5D068c897c3e602fA97457; //2020-09-03 (NO MATCH IN GOERLI)
    address public constant UNKNOWN_2017_04_10 = 0x0048d6225D1F3eA4385627eFDC5B4709Cab4A21c; //2017-04-10 (NO MATCH IN GOERLI)
    address public constant UNKNOWN_2020_10_09 = 0xd200790f62c8da69973e61d4936cfE4f356ccD07; //2020-10-09 (NO MATCH IN GOERLI)
    address public constant UNKNOWN_2021_09_20 = 0x075da589886BA445d7c7e81c472059dE7AE65250; //2021-09-20 (NO MATCH IN GOERLI)
    address public constant STARKNET_01 = 0x7f06941997C7778E7B734fE55f7353f554B06d7d;
        
    constructor() public {
        addr = [
            PE_01,
            PE_02,
            PE_03,
            PE_07,
            PE_CURRENT,
            CES_03,
            ORACLES_1,
            ORACLES_2,
            CES_2022_10_26,
            ORACLES_2021_07_20,
            UNKNOWN_2019_06_27,
            UNKNOWN_2020_09_03,
            UNKNOWN_2017_04_10,
            UNKNOWN_2020_10_09, 
            UNKNOWN_2021_09_20,
            UNKNOWN_2022_05_10,
        ];
    }

    function count() external view returns (uint256) {
        return addr.length;
    }
}
