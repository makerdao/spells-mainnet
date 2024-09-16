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
import { UsdsInstance } from "./UsdsInstance.sol";

interface UsdsLike {
    function rely(address) external;
    function version() external view returns (string memory);
    function getImplementation() external view returns (address);
}

interface UsdsJoinLike {
    function usds() external view returns (address);
    function vat() external view returns (address);
}

interface DaiUsdsLike {
    function daiJoin() external view returns (address);
    function usdsJoin() external view returns (address);
}

library UsdsInit {

    function init(
        DssInstance memory dss,
        UsdsInstance memory instance
    ) internal {
        require(keccak256(bytes(UsdsLike(instance.usds).version())) == keccak256("1"), "UsdsInit/version-does-not-match");
        require(UsdsLike(instance.usds).getImplementation() == instance.usdsImp, "UsdsInit/imp-does-not-match");

        require(UsdsJoinLike(instance.usdsJoin).vat() == address(dss.vat), "UsdsInit/vat-does-not-match");
        require(UsdsJoinLike(instance.usdsJoin).usds() == instance.usds, "UsdsInit/usds-does-not-match");

        address daiJoin = dss.chainlog.getAddress("MCD_JOIN_DAI");
        require(DaiUsdsLike(instance.daiUsds).daiJoin() == daiJoin, "UsdsInit/daiJoin-does-not-match");
        require(DaiUsdsLike(instance.daiUsds).usdsJoin() == instance.usdsJoin, "UsdsInit/usdsJoin-does-not-match");

        UsdsLike(instance.usds).rely(instance.usdsJoin);

        dss.chainlog.setAddress("USDS",      instance.usds);
        dss.chainlog.setAddress("USDS_IMP",  instance.usdsImp);
        dss.chainlog.setAddress("USDS_JOIN", instance.usdsJoin);
        dss.chainlog.setAddress("DAI_USDS",  instance.daiUsds);
    }
}
