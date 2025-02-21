// SPDX-FileCopyrightText: © 2025 Dai Foundation <www.daifoundation.org>
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

pragma solidity >=0.8.0;

import { DssInstance } from "dss-test/MCD.sol";

interface GemLike {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address, uint256) external;
}

interface PoolLike {
    function getReserves() external view returns (uint112, uint112, uint32);
    function burn(address) external;
    function sync() external;
}

interface PipLike {
    function src() external view returns (address);
}

interface MedianizerLike {
    function read() external view returns (bytes32);
    function kiss(address) external;
    function diss(address) external;
}

interface FlapperLike {
    function pair() external view returns (address);
}

library UniV2PoolWithdraw {

    // Note: `usdsToLeave` is protocol owned USDS to leave. An equivalent amount worth of SKY will also be left in the pool.
    //       The function assumes that this amount is chosen with caution, since if the protocol does not own it in the pool at the time of execution the entire spell will revert.
    //       If needed, an upper layer can pass a minimum between a desired amount and the owned amount at the time of execution.
    function withdraw(
        DssInstance memory dss,
        uint256 usdsToLeave
    ) internal {
        address pProxy               = dss.chainlog.getAddress("MCD_PAUSE_PROXY");
        address pairUsdsSky          = FlapperLike(dss.chainlog.getAddress("MCD_FLAP")).pair();
        MedianizerLike mkrMedianizer = MedianizerLike(PipLike(dss.chainlog.getAddress("PIP_MKR")).src());

        PoolLike(pairUsdsSky).sync();

        // Sanity check for Uniswap vs oracle
        mkrMedianizer.kiss(pProxy);
        uint256 medianizerPrice = uint256(mkrMedianizer.read()) / 24_000; // Assume par is 1
        mkrMedianizer.diss(pProxy);

        (uint256 skyReserve, uint256 usdsReserve,) = PoolLike(pairUsdsSky).getReserves();
        uint256 uniPrice = usdsReserve * 1e18 / skyReserve;

        require(
            uniPrice < medianizerPrice * 102 / 100 && uniPrice > medianizerPrice * 98 / 100,
            "UniV2PoolWithdraw/sanity-check-failed"
        );

        uint256 lpsToLeave = GemLike(pairUsdsSky).totalSupply() * usdsToLeave / usdsReserve;
        uint256 lpsToBurn = GemLike(pairUsdsSky).balanceOf(pProxy) - lpsToLeave;

        GemLike(pairUsdsSky).transfer(pairUsdsSky, lpsToBurn);
        PoolLike(pairUsdsSky).burn(pProxy);
    }
}
