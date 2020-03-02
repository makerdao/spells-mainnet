pragma solidity ^0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssFebruary7Spell} from "./DssFebruary7Spell.sol";

contract TubLike {
    function ink(bytes32) public view returns (uint);
    function per() public view returns (uint);
    function rap(bytes32) public returns (uint);
    function tab(bytes32) public returns (uint);
    function pep() external returns (address);
    function cap() external view returns (uint);
    function fee() external view returns (uint);
}

contract Hevm {
    function warp(uint) public;
}

contract DssFebruary7SpellTest is DSTest, DSMath {
    Hevm hevm;

    DSPauseAbstract pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    DSChiefAbstract chief =
        DSChiefAbstract(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    VatAbstract vat = VatAbstract(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    VowAbstract vow = VowAbstract(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
    PotAbstract pot = PotAbstract(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    JugAbstract jug = JugAbstract(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    MKRAbstract gov = MKRAbstract(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    TubLike     tub = TubLike(0x448a5065aeBB8E423F0896E6c5D525C040f59af3);

    DssFebruary7Spell spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    // not provided in DSMath
    uint constant RAD = 10 ** 45;

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
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

    function scheduleWaitAndCast() public {
        spell.schedule();
        hevm.warp(add(now, pause.delay()));
        spell.cast();
    }

    function testSpell20200207IsCast() public {
        spell = DssFebruary7Spell(0x8E5F3abC36dA63142275202454c11237F47DD170);
        // spell = new DssFebruary7Spell();

        // (ETH-A, BAT-A, DSR) = (9%, 9%, 8.75%)
        (uint dutyETH,) = jug.ilks("ETH-A");
        (uint dutyBAT,) = jug.ilks("BAT-A");
        assertEq(dutyETH,   1000000002732676825177582095);
        assertEq(dutyBAT,   1000000002732676825177582095);
        assertEq(pot.dsr(), 1000000002659864411854984565);

        // SCD Fee = 10%
        assertEq(tub.fee(), 1000000003022265980097387650);

        vote();
        scheduleWaitAndCast();

        // spell done
        assertTrue(spell.done());

        // dsr = 7.5%
        assertEq(pot.dsr(), 1000000002293273137447730714);

        // (ETH-A, BAT-A) = (8%, 8%)
        (dutyETH,) = jug.ilks("ETH-A");
        (dutyBAT,) = jug.ilks("BAT-A");
        assertEq(dutyETH, 1000000002440418608258400030);
        assertEq(dutyBAT, 1000000002440418608258400030);

        // SCD Fee = 9%
        assertEq(tub.fee(), 1000000002732676825177582095);
    }

}
