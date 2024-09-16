// SPDX-FileCopyrightText: © 2023 Dai Foundation <www.daifoundation.org>
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
    function approve(address, uint256) external;
    function transfer(address, uint256) external;
}

interface PoolLike {
    function mint(address) external;
    function burn(address) external;
    function getReserves() external view returns (uint112, uint112, uint32);
}

interface DaiUsdsLike {
    function daiToUsds(address, uint256) external;
}

interface MkrSkyLike {
    function mkrToSky(address, uint256) external;
}

interface PipLike {
    function read() external view returns (bytes32);
    function kiss(address) external;
    function diss(address) external;
}

library UniV2PoolMigratorInit {
    function init(
        DssInstance memory dss,
        address pairDaiMkr,
        address pairUsdsSky
    ) internal {
        // Using pProxy instead of address(this) as otherwise won't work in tests, in real execution should be same address
        address pProxy = dss.chainlog.getAddress("MCD_PAUSE_PROXY");

        require(GemLike(pairUsdsSky).totalSupply() == 0, "UniV2PoolMigratorInit/sanity-check-1-failed");

        // Sanity check for Uniswap vs oracle price. This is completely unnecessary but acts as a separate safety layer.
        {
        PipLike mkrPip = PipLike(dss.chainlog.getAddress("PIP_MKR"));
        mkrPip.kiss(pProxy);
        uint256 pipPrice = uint256(mkrPip.read()); // Assume par is 1
        mkrPip.diss(pProxy);

        (uint256 daiReserve, uint256 mkrReserve, ) = PoolLike(pairDaiMkr).getReserves();
        uint256 uniPrice = daiReserve * 1e18 / mkrReserve;

        require(
            uniPrice < pipPrice * 102 / 100 && uniPrice > pipPrice * 98 / 100,
            "UniV2PoolMigratorInit/sanity-check-2-failed"
        );
        }

        GemLike dai = GemLike(dss.chainlog.getAddress("MCD_DAI"));
        GemLike mkr = GemLike(dss.chainlog.getAddress("MCD_GOV"));

        uint256 daiAmtPrev = dai.balanceOf(pProxy);
        uint256 mkrAmtPrev = mkr.balanceOf(pProxy);

        GemLike(pairDaiMkr).transfer(pairDaiMkr, GemLike(pairDaiMkr).balanceOf(pProxy));
        PoolLike(pairDaiMkr).burn(pProxy);

        DaiUsdsLike daiUsds = DaiUsdsLike(dss.chainlog.getAddress("DAI_USDS"));
        MkrSkyLike   mkrSky = MkrSkyLike(dss.chainlog.getAddress("MKR_SKY"));

        uint256 daiAmt = dai.balanceOf(pProxy) - daiAmtPrev;
        uint256 mkrAmt = mkr.balanceOf(pProxy) - mkrAmtPrev;
        dai.approve(address(daiUsds), daiAmt);
        mkr.approve(address(mkrSky), mkrAmt);
        daiUsds.daiToUsds(pairUsdsSky, daiAmt);
        mkrSky.mkrToSky(pairUsdsSky, mkrAmt);
        PoolLike(pairUsdsSky).mint(pProxy);

        require(GemLike(pairUsdsSky).balanceOf(pProxy) > 0, "UniV2PoolMigratorInit/sanity-check-3-failed");
    }
}
