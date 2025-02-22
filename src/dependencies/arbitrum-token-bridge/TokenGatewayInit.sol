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

import { DssInstance } from "dss-test/MCD.sol";
import { L2TokenGatewayInstance } from "./L2TokenGatewayInstance.sol";
import { L1TokenGatewayInstance } from "./L1TokenGatewayInstance.sol";
import { L2TokenGatewaySpell } from "./L2TokenGatewaySpell.sol";

interface L1TokenGatewayLike {
    function l1ToL2Token(address) external view returns (address);
    function isOpen() external view returns (uint256);
    function counterpartGateway() external view returns (address);
    function l1Router() external view returns (address);
    function inbox() external view returns (address);
    function version() external view returns (string memory);
    function getImplementation() external view returns (address);
    function file(bytes32, address) external;
    function registerToken(address, address) external;
}

interface L1RelayLike {
    function relay(
        address target,
        bytes calldata targetData,
        uint256 l1CallValue,
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 maxSubmissionCost
    ) external payable;
}

interface EscrowLike {
    function approve(address, address, uint256) external;
}

interface L1RouterLike {
    function counterpartGateway() external view returns (address);
}

struct MessageParams {
    uint256 maxGas;
    uint256 gasPriceBid;
    uint256 maxSubmissionCost;
}

struct GatewaysConfig {
    address l1Router;
    address inbox;
    address[] l1Tokens;
    address[] l2Tokens;
    uint256[] maxWithdraws;
    MessageParams xchainMsg;
}

library TokenGatewayInit {
    function initGateways(
        DssInstance memory            dss,
        L1TokenGatewayInstance memory l1GatewayInstance,
        L2TokenGatewayInstance memory l2GatewayInstance,
        GatewaysConfig memory         cfg
    ) internal {
        L1TokenGatewayLike l1Gateway = L1TokenGatewayLike(l1GatewayInstance.gateway);
        L1RelayLike       l1GovRelay = L1RelayLike(dss.chainlog.getAddress("ARBITRUM_GOV_RELAY"));
        EscrowLike            escrow = EscrowLike(dss.chainlog.getAddress("ARBITRUM_ESCROW"));
        L1RouterLike        l1Router = L1RouterLike(cfg.l1Router);

        // sanity checks
        require(keccak256(bytes(l1Gateway.version())) == keccak256("1"), "TokenGatewayInit/version-does-not-match");
        require(l1Gateway.getImplementation() == l1GatewayInstance.gatewayImp, "TokenGatewayInit/imp-does-not-match");
        require(l1Gateway.isOpen() == 1, "TokenGatewayInit/not-open");
        require(l1Gateway.counterpartGateway() == l2GatewayInstance.gateway, "TokenGatewayInit/counterpart-gateway-mismatch");
        require(l1Gateway.l1Router() == cfg.l1Router, "TokenGatewayInit/l1-router-mismatch");
        require(l1Gateway.inbox() == cfg.inbox, "TokenGatewayInit/inbox-mismatch");
        require(cfg.l1Tokens.length == cfg.l2Tokens.length, "TokenGatewayInit/token-arrays-mismatch");
        require(cfg.maxWithdraws.length == cfg.l2Tokens.length, "TokenGatewayInit/max-withdraws-length-mismatch");

        uint256 l1CallValue = cfg.xchainMsg.maxSubmissionCost + cfg.xchainMsg.maxGas * cfg.xchainMsg.gasPriceBid;

        // not strictly necessary (as the retryable ticket creation would otherwise fail)
        // but makes the eth balance requirement more explicit
        require(address(l1GovRelay).balance >= l1CallValue, "TokenGatewayInit/insufficient-relay-balance");

        l1Gateway.file("escrow", address(escrow));

        for (uint256 i; i < cfg.l1Tokens.length; ++i) {
            (address l1Token, address l2Token) = (cfg.l1Tokens[i], cfg.l2Tokens[i]);
            require(l1Token != address(0), "TokenGatewayInit/invalid-l1-token");
            require(l2Token != address(0), "TokenGatewayInit/invalid-l2-token");
            require(cfg.maxWithdraws[i] > 0, "TokenGatewayInit/max-withdraw-not-set");
            require(l1Gateway.l1ToL2Token(l1Token) == address(0), "TokenGatewayInit/existing-l1-token");

            l1Gateway.registerToken(l1Token, l2Token);
            escrow.approve(l1Token, l1GatewayInstance.gateway, type(uint256).max);
        }

        l1GovRelay.relay({
            target:            l2GatewayInstance.spell,
            targetData:        abi.encodeCall(L2TokenGatewaySpell.init, (
                l2GatewayInstance.gateway,
                l2GatewayInstance.gatewayImp,
                l1GatewayInstance.gateway,
                l1Router.counterpartGateway(),
                cfg.l1Tokens,
                cfg.l2Tokens,
                cfg.maxWithdraws
            )),
            l1CallValue:       l1CallValue,
            maxGas:            cfg.xchainMsg.maxGas,
            gasPriceBid:       cfg.xchainMsg.gasPriceBid,
            maxSubmissionCost: cfg.xchainMsg.maxSubmissionCost
        });

        dss.chainlog.setAddress("ARBITRUM_TOKEN_BRIDGE",     l1GatewayInstance.gateway);
        dss.chainlog.setAddress("ARBITRUM_TOKEN_BRIDGE_IMP", l1GatewayInstance.gatewayImp);
    }
}
