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
import { SkyInstance } from "./SkyInstance.sol";

interface SkyLike {
    function rely(address) external;
}

interface MkrSkyLike {
    function mkr() external view returns (address);
    function sky() external view returns (address);
    function rate() external view returns (uint256);
}

interface MkrLike {
    function authority() external view returns (address);
}

interface MkrAuthorityLike {
    function rely(address) external;
}

library SkyInit {
    function init(
        DssInstance memory dss,
        SkyInstance memory instance,
        uint256 rate
    ) internal {
        address mkr = dss.chainlog.getAddress("MCD_GOV");
        require(MkrSkyLike(instance.mkrSky).mkr()  == mkr,          "SkyInit/mkr-does-not-match");
        require(MkrSkyLike(instance.mkrSky).sky()  == instance.sky, "SkyInit/sky-does-not-match");
        require(MkrSkyLike(instance.mkrSky).rate() == rate,         "SkyInit/rate-does-not-match");

        SkyLike(instance.sky).rely(instance.mkrSky);
        MkrAuthorityLike(MkrLike(mkr).authority()).rely(instance.mkrSky);

        dss.chainlog.setAddress("SKY",     instance.sky);
        dss.chainlog.setAddress("MKR_SKY", instance.mkrSky);
    }
}
