// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2022 Dai Foundation
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
pragma solidity 0.6.12;

import "../DssSpell.t.base.sol";
import "dss-interfaces/Interfaces.sol";

contract ConfigStarknet {

    StarknetValues starknetValues;

    struct StarknetValues {
        address core_implementation;
        uint256 dai_bridge_isOpen;
        uint256 dai_bridge_ceiling;
        uint256 dai_bridge_maxDeposit;
    }

    function setValues() public {
        starknetValues = StarknetValues({
            core_implementation:       0xDC109C4a1A3084Ed15A97692FBEF3e1FB32A6955,
            dai_bridge_isOpen:         1,        // 1 open, 0 closed
            dai_bridge_ceiling:        200_000,  // Whole Dai Units
            dai_bridge_maxDeposit:     50        // Whole Dai Units
        });
    }
}

interface StarknetEscrowMomLike {
    function owner() external returns (address);
    function authority() external returns (address);
    function escrow() external returns (address);
    function token() external returns (address);
}

interface StarknetEscrowLike {
    function wards(address) external returns(uint256);
}

interface StarknetDaiBridgeLike {
    function wards(address) external returns(uint256);
    function isOpen() external returns (uint256);
    function ceiling() external returns (uint256);
    function maxDeposit() external returns (uint256);
    function dai() external returns (address);
    function starkNet() external returns (address);
}

interface StarknetGovRelayLike {
    function wards(address) external returns (uint256);
    function starkNet() external returns (address);
}

interface StarknetCoreLike {
    function PROXY_VERSION() external returns (string memory);
    function getUpgradeActivationDelay() external returns (uint256);
    function implementation() external returns (address);
    function isNotFinalized() external returns (address);
    function configHash() external returns (uint256);
    function identify() external returns (string memory);
    function isFinalized() external returns (bool);
    function isFrozen() external returns (bool);
    function isOperator(address) external returns (bool);
    function l1ToL2MessageCancellations(bytes32) external returns (uint256);
    function l1ToL2MessageNonce() external returns (uint256);
    function l1ToL2Messages(bytes32) external returns (uint256);
    function l2ToL1Messages(bytes32) external returns (uint256);
    function proxyIsGovernor(address) external returns (bool);
    function messageCancellationDelay() external returns (uint256);
    function programHash() external returns (uint256);
    function starknetIsGovernor(address) external returns (address);
    function stateBlockNumber() external returns (int256);
    function stateRoot() external returns (uint256);
}

interface DaiLike {
    function allowance(address, address) external view returns (uint256);
}

contract StarknetTests is DssSpellTestBase, ConfigStarknet {

    function testStarknet() public {
        setValues();

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        checkStarknetEscrowMom();
        checkStarknetEscrow();
        checkStarknetDaiBridge();
        checkStarknetGovRelay();
        checkStarknetCore();
    }

    function checkStarknetEscrowMom() public {
        StarknetEscrowMomLike escrowMom = StarknetEscrowMomLike(addr.addr("STARKNET_ESCROW_MOM"));

        assertEq(escrowMom.owner(), addr.addr("MCD_PAUSE_PROXY"));
        assertEq(escrowMom.authority(), addr.addr("MCD_ADM"));
        assertEq(escrowMom.escrow(), addr.addr("STARKNET_ESCROW"));
        assertEq(escrowMom.token(), addr.addr("MCD_DAI"));
    }

    function checkStarknetEscrow() public {
        StarknetEscrowLike escrow = StarknetEscrowLike(addr.addr("STARKNET_ESCROW"));

        assertEq(escrow.wards(addr.addr("MCD_PAUSE_PROXY")), 1);
        assertEq(escrow.wards(addr.addr("MCD_ESM")), 1);
        assertEq(escrow.wards(addr.addr("STARKNET_ESCROW_MOM")), 1);

        DaiLike dai = DaiLike(addr.addr("MCD_DAI"));

        assertEq(dai.allowance(addr.addr("STARKNET_ESCROW"), addr.addr("STARKNET_DAI_BRIDGE")), uint256(-1));
    }

    function checkStarknetDaiBridge() public {
        StarknetDaiBridgeLike daiBridge = StarknetDaiBridgeLike(addr.addr("STARKNET_DAI_BRIDGE"));

        assertEq(daiBridge.isOpen(), starknetValues.dai_bridge_isOpen, "StarknetTestError/dai-bridge-isOpen-unexpected");
        assertEq(daiBridge.ceiling(), starknetValues.dai_bridge_ceiling * WAD, "StarknetTestError/dai-bridge-ceiling-unexpected");
        assertEq(daiBridge.maxDeposit(), starknetValues.dai_bridge_maxDeposit * WAD, "StarknetTestError/dai-bridge-maxDeposit-unexpected");

        assertEq(daiBridge.dai(), addr.addr("MCD_DAI"));
        assertEq(daiBridge.starkNet(), addr.addr("STARKNET_CORE"));
        assertEq(daiBridge.wards(addr.addr("MCD_PAUSE_PROXY")), 1);
        assertEq(daiBridge.wards(addr.addr("MCD_ESM")), 1);
    }

    function checkStarknetGovRelay() public {
        StarknetGovRelayLike govRelay = StarknetGovRelayLike(addr.addr("STARKNET_GOV_RELAY"));

        assertEq(govRelay.wards(addr.addr("MCD_PAUSE_PROXY")), 1);
        assertEq(govRelay.wards(addr.addr("MCD_ESM")), 1);
        assertEq(govRelay.starkNet(), addr.addr("STARKNET_CORE"));
    }

    function checkStarknetCore() public {
        StarknetCoreLike core = StarknetCoreLike(addr.addr("STARKNET_CORE"));

        assertEq(core.implementation(), starknetValues.core_implementation);

        // TODO more assertions here
    }
}
