// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
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

pragma solidity 0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssSpell, SpellAction} from "./2020-06-22-DssSpell.sol";

contract Hevm { function warp(uint) public; }

contract DssSpellTest is DSTest, DSMath {

    // Replace with mainnet spell address and creation timestamp to test against live
    address constant MAINNET_SPELL = address(0x1D51ca29E35b6Ce30167F634Dd21376Da1341D9b);
    uint256 constant SPELL_CREATED = 1592839443;

    Hevm hevm;

    DSPauseAbstract             pause = DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    DSChiefAbstract             chief = DSChiefAbstract(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    MKRAbstract                   gov = MKRAbstract(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);

    DssSpell spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));

        spell = MAINNET_SPELL != address(0) ? DssSpell(MAINNET_SPELL) : new DssSpell();

        // Using the MkrAuthority test address, mint enough MKR to overcome the
        // current hat.
        gov.mint(address(this), 300000 ether);
    }

    function vote() private {
        if (chief.hat() != address(spell)) {
            gov.approve(address(chief), uint256(-1));
            chief.lock(sub(gov.balanceOf(address(this)), 1 ether));

            assertTrue(!spell.done());

            address[] memory yays = new address[](1);
            yays[0] = address(spell);

            chief.vote(yays);
            chief.lift(address(spell));
        }
        assertEq(chief.hat(), address(spell));
    }

    function waitAndCast() public {
        hevm.warp(now + pause.delay());
        spell.cast();
    }

    function scheduleWaitAndCast() public {
        spell.schedule();
        hevm.warp(now + pause.delay());
        spell.cast();
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        assembly {
        result := mload(add(source, 32))
        }
    }

    // this spell is intended to run as the MkrAuthority
    function canCall(address, address, bytes4) public pure returns (bool) {
        return true;
    }

    function testSpellIsCast() public {
        // Test description
        string memory description = new SpellAction().description();
        assertTrue(bytes(description).length > 0);
        // DS-Test can't handle strings directly, so cast to a bytes32.
        assertEq(stringToBytes32(spell.description()),
            stringToBytes32(description));

        // Test expiration
        if(address(spell) != address(MAINNET_SPELL)) {
            assertEq(spell.expiration(), (now + 4 days + 2 hours));
        } else {
            assertEq(spell.expiration(), (SPELL_CREATED + 4 days + 2 hours));
        }
        // -------------------
        vote();
        scheduleWaitAndCast();
        // spell done
        assertTrue(spell.done());
        // -------------------
    }
}
