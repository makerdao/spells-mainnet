// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
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
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../DssSpell.t.base.sol";

contract ConfigStarknet {

    StarknetValues starknetValues;

    struct StarknetValues {
        address core_implementation;
        uint256 dai_bridge_isOpen;
        uint256 dai_bridge_ceiling;
        uint256 dai_bridge_maxDeposit;
        uint256 l2_dai_bridge;
    }

    function setValues() public {
        starknetValues = StarknetValues({
            core_implementation:       0x2B3B750f1f10c85c8A6D476Fc209A8DC7E4Ca3F8,
            dai_bridge_isOpen:         1,        // 1 open, 0 closed
            dai_bridge_ceiling:        200_000,  // Whole Dai Units
            dai_bridge_maxDeposit:     1000,     // Whole Dai Units
            l2_dai_bridge:             0x075ac198e734e289a6892baa8dd14b21095f13bf8401900f5349d5569c3f6e60
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
    function escrow() external returns (address);
    function l2DaiBridge() external returns (uint256);
}

interface StarknetGovRelayLike {
    function wards(address) external returns (uint256);
    function starkNet() external returns (address);
}

interface StarknetCoreLike {
    function implementation() external returns (address);
    function isNotFinalized() external returns (bool);
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

        assertEq(escrowMom.owner(),     addr.addr("MCD_PAUSE_PROXY"), "StarknetTest/pause-proxy-not-owner-on-escrow-mom");
        assertEq(escrowMom.authority(), addr.addr("MCD_ADM"),         "StarknetTest/chief-not-authority-on-escrow-mom");
        assertEq(escrowMom.escrow(),    addr.addr("STARKNET_ESCROW"), "StarknetTest/unexpected-escrow-on-escrow-mom");
        assertEq(escrowMom.token(),     addr.addr("MCD_DAI"),         "StarknetTest/unexpected-dai-on-escrow-mom");
    }

    function checkStarknetEscrow() public {
        StarknetEscrowLike escrow = StarknetEscrowLike(addr.addr("STARKNET_ESCROW"));

        assertEq(escrow.wards(addr.addr("MCD_PAUSE_PROXY")),     1, "StarknetTest/pause-proxy-not-ward-on-escrow");
        assertEq(escrow.wards(addr.addr("MCD_ESM")),             1, "StarknetTest/esm-not-ward-on-escrow");
        assertEq(escrow.wards(addr.addr("STARKNET_ESCROW_MOM")), 1, "StarknetTest/escrow-mom-not-ward-on-escrow");

        DaiLike dai = DaiLike(addr.addr("MCD_DAI"));

        assertEq(dai.allowance(addr.addr("STARKNET_ESCROW"), addr.addr("STARKNET_DAI_BRIDGE")), uint256(-1), "StarknetTest/unexpected-escrow-allowance");
    }

    function checkStarknetDaiBridge() public {
        StarknetDaiBridgeLike daiBridge = StarknetDaiBridgeLike(addr.addr("STARKNET_DAI_BRIDGE"));

        assertEq(daiBridge.isOpen(),     starknetValues.dai_bridge_isOpen,           "StarknetTestError/dai-bridge-isOpen-unexpected");
        assertEq(daiBridge.ceiling(),    starknetValues.dai_bridge_ceiling * WAD,    "StarknetTestError/dai-bridge-ceiling-unexpected");
        assertEq(daiBridge.maxDeposit(), starknetValues.dai_bridge_maxDeposit * WAD, "StarknetTestError/dai-bridge-maxDeposit-unexpected");

        assertEq(daiBridge.dai(),      addr.addr("MCD_DAI"),         "StarknetTest/dai-bridge-dai");
        assertEq(daiBridge.starkNet(), addr.addr("STARKNET_CORE"),   "StarknetTest/dai-bridge-core");
        assertEq(daiBridge.escrow(),   addr.addr("STARKNET_ESCROW"), "StarknetTest/dai-bridge-escrow");

        assertEq(daiBridge.wards(addr.addr("MCD_PAUSE_PROXY")), 1, "StarknetTest/pause-proxy-not-ward-on-dai-bridge");
        assertEq(daiBridge.wards(addr.addr("MCD_ESM")),         1, "StarknetTest/esm-not-ward-on-dai-bridge");

        assertEq(daiBridge.l2DaiBridge(), starknetValues.l2_dai_bridge, "StarknetTest/wrong-l2-dai-bridge-on-dai-bridge");
    }

    function checkStarknetGovRelay() public {
        StarknetGovRelayLike govRelay = StarknetGovRelayLike(addr.addr("STARKNET_GOV_RELAY"));

        assertEq(govRelay.wards(addr.addr("MCD_PAUSE_PROXY")), 1, "StarknetTest/pause-proxy-not-ward-on-gov-relay");
        assertEq(govRelay.wards(addr.addr("MCD_ESM")),         1, "StarknetTest/esm-not-ward-on-gov-relay");

        assertEq(govRelay.starkNet(), addr.addr("STARKNET_CORE"), "StarknetTest/unexpected-starknet-core-on-gov-relay");
    }

    function checkStarknetCore() public {
        StarknetCoreLike core = StarknetCoreLike(addr.addr("STARKNET_CORE"));

        // Starknet Core is currently out of scope.
        // It is updating frequently and the implementation is not ready to be
        //    brought into our simulation tests yet.
        //assertEq(core.implementation(), starknetValues.core_implementation, "StarknetTest/core-implementation");

        assertTrue(core.isNotFinalized());
    }
}
