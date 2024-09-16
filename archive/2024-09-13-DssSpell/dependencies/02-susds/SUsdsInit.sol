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
import { SUsdsInstance } from "./SUsdsInstance.sol";

interface SUsdsLike {
    function version() external view returns (string memory);
    function getImplementation() external view returns (address);
    function usdsJoin() external view returns (address);
    function vat() external view returns (address);
    function usds() external view returns (address);
    function vow() external view returns (address);
    function file(bytes32, uint256) external;
    function drip() external returns (uint256);
}

interface UsdsJoinLike {
    function usds() external view returns (address);
}

struct SUsdsConfig {
    address usdsJoin;
    address usds;
    uint256 ssr;
}

library SUsdsInit {

    uint256 constant internal RAY                   = 10**27;
    uint256 constant internal RATES_ONE_HUNDRED_PCT = 1000000021979553151239153027;

    function init(
        DssInstance   memory dss,
        SUsdsInstance memory instance,
        SUsdsConfig   memory cfg
    ) internal {
        require(keccak256(abi.encodePacked(SUsdsLike(instance.sUsds).version())) == keccak256(abi.encodePacked("1")), "SUsdsInit/version-does-not-match");
        require(SUsdsLike(instance.sUsds).getImplementation() == instance.sUsdsImp, "SUsdsInit/imp-does-not-match");

        require(SUsdsLike(instance.sUsds).vat()      == address(dss.vat), "SUsdsInit/vat-does-not-match");
        require(SUsdsLike(instance.sUsds).usdsJoin() == cfg.usdsJoin,     "SUsdsInit/usdsJoin-does-not-match");
        require(SUsdsLike(instance.sUsds).usds()     == cfg.usds,         "SUsdsInit/usds-does-not-match");
        require(SUsdsLike(instance.sUsds).vow()      == address(dss.vow), "SUsdsInit/vow-does-not-match");

        require(cfg.ssr >= RAY && cfg.ssr <= RATES_ONE_HUNDRED_PCT, "SUsdsInit/ssr-out-of-boundaries");

        dss.vat.rely(instance.sUsds);

        SUsdsLike(instance.sUsds).drip();
        SUsdsLike(instance.sUsds).file("ssr", cfg.ssr);

        dss.chainlog.setAddress("SUSDS",     instance.sUsds);
        dss.chainlog.setAddress("SUSDS_IMP", instance.sUsdsImp);
    }
}
