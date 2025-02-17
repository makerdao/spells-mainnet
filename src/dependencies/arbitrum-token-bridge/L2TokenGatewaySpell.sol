// SPDX-FileCopyrightText: © 2024 Dai Foundation <www.daifoundation.org>
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

interface L2TokenGatewayLike {
    function isOpen() external view returns (uint256);
    function counterpartGateway() external view returns (address);
    function l2Router() external view returns (address);
    function version() external view returns (string memory);
    function getImplementation() external view returns (address);
    function upgradeToAndCall(address, bytes memory) external;
    function rely(address) external;
    function deny(address) external;
    function close() external;
    function registerToken(address, address) external;
    function setMaxWithdraw(address, uint256) external;
}

interface AuthLike {
    function rely(address usr) external;
}

// A reusable L2 spell to be used by the L2GovernanceRelay to exert admin control over L2TokenGateway
contract L2TokenGatewaySpell {
    L2TokenGatewayLike public immutable l2Gateway;

    constructor(address l2Gateway_) {
        l2Gateway = L2TokenGatewayLike(l2Gateway_);
    }

    function upgradeToAndCall(address newImp, bytes memory data) external { l2Gateway.upgradeToAndCall(newImp, data); }
    function rely(address usr) external { l2Gateway.rely(usr); }
    function deny(address usr) external { l2Gateway.deny(usr); }
    function close() external { l2Gateway.close(); }

    function registerTokens(address[] memory l1Tokens, address[] memory l2Tokens) public {
        for (uint256 i; i < l2Tokens.length;) {
            l2Gateway.registerToken(l1Tokens[i], l2Tokens[i]);
            AuthLike(l2Tokens[i]).rely(address(l2Gateway));
            unchecked { ++i; }
        }
    }

    function setMaxWithdraws(address[] memory l2Tokens, uint256[] memory maxWithdraws) public {
        for (uint256 i; i < l2Tokens.length;) {
            l2Gateway.setMaxWithdraw(l2Tokens[i], maxWithdraws[i]);
            unchecked { ++i; }
        }
    }

    function init(
        address l2Gateway_,
        address l2GatewayImp,
        address counterpartGateway,
        address l2Router,
        address[] calldata l1Tokens,
        address[] calldata l2Tokens,
        uint256[] calldata maxWithdraws
    ) external {
        // sanity checks
        require(address(l2Gateway) == l2Gateway_, "L2TokenGatewaySpell/l2-gateway-mismatch");
        require(keccak256(bytes(l2Gateway.version())) == keccak256("1"), "L2TokenGatewaySpell/version-does-not-match");
        require(l2Gateway.getImplementation() == l2GatewayImp, "L2TokenGatewaySpell/imp-does-not-match");
        require(l2Gateway.isOpen() == 1, "L2TokenGatewaySpell/not-open");
        require(l2Gateway.counterpartGateway() == counterpartGateway, "L2TokenGatewaySpell/counterpart-gateway-mismatch");
        require(l2Gateway.l2Router() == l2Router, "L2TokenGatewaySpell/l2-router-mismatch");

        registerTokens(l1Tokens, l2Tokens);
        setMaxWithdraws(l2Tokens, maxWithdraws);
    }
}
