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

interface SkyLike {
    function mint(address, uint256) external;
}

interface MkrSkyLike {
    function mkr() external view returns (address);
    function sky() external view returns (address);
    function rate() external view returns (uint256);
}

interface MkrLike {
    function authority() external view returns (address);
    function totalSupply() external view returns (uint256);
}

interface MkrAuthorityLike {
    function deny(address) external;
}

library SkyInit {

    // Note that we assume the fee is 0 initially, hence we don't set it explicitly
    function updateMkrSky(
        DssInstance memory dss,
        address mkrSky
    ) internal {
        address oldMkrSky = dss.chainlog.getAddress("MKR_SKY");
        address mkr  = MkrSkyLike(oldMkrSky).mkr();
        address sky  = MkrSkyLike(oldMkrSky).sky();
        uint256 rate = MkrSkyLike(oldMkrSky).rate();

        require(MkrSkyLike(mkrSky).mkr()  == mkr);
        require(MkrSkyLike(mkrSky).sky()  == sky);
        require(MkrSkyLike(mkrSky).rate() == rate);

        // Block the sky=>mkr direction for the old converter
        MkrAuthorityLike(MkrLike(mkr).authority()).deny(oldMkrSky);

        // Mint SKY to facilitate conversions
        SkyLike(sky).mint(mkrSky, MkrLike(mkr).totalSupply() * rate);

        dss.chainlog.setAddress("MKR_SKY_LEGACY", oldMkrSky);
        dss.chainlog.setAddress("MKR_SKY", mkrSky);
    }
}
