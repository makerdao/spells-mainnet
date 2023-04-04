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

contract EsmExceptions {

    bytes32[] public exceptions;

    constructor() {
        exceptions = [           // Why?
            bytes32("MCD_ESD"),  // Self-referential
            "PROXY_DEPLOYER",    // Ecosystem tool
            "MCD_DAI"            // Governance can't mint
            // TODO MORE
        ];
    }

    function count() external view returns (uint256) {
        return exceptions.length;
    }

    function list() external view returns (bytes32[] memory) {
        return exceptions;
    }
}
