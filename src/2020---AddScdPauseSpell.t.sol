pragma solidity ^0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssSpell} from "./2020---AddScdPauseSpell.sol";

contract Hevm {
    function warp(uint) public;
}

contract TestDelaySpell {

}

contract DssSpellTest is DSTest, DSMath {
    Hevm hevm;

    DSPauseAbstract public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    MKRAbstract gov = MKRAbstract(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    DSChiefAbstract chief = DSChiefAbstract(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    address pause_proxy = 0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
    address constant public SAIMOM = 0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C;
    address constant public SAITOP = 0x9b0ccf7C8994E19F39b2B4CF708e0A7DF65fA8a3;

    DssSpell spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        // Using the Flopper test address, mint enough MKR to overcome the current hat.
        gov.mint(address(this), 1000001 ether);
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

    function scheduleWaitAndCast() private {
        spell.schedule();
        hevm.warp(add(now, pause.delay()));
        spell.cast();
    }

    function testAddPauseToScd() public {
        spell = new DssSpell();
        // spell = DssSpell(0xDD4Aa99077C5e976AFc22060EEafBBd1ba34eae9);

        assertTrue(SaiMomAbstract(SAIMOM).owner() == address(0x0));
        assertTrue(SaiMomAbstract(SAIMOM).authority() == address(chief));
        assertTrue(SaiTopAbstract(SAITOP).owner() == address(0x0));
        assertTrue(SaiTopAbstract(SAITOP).authority() == address(chief));

        vote();
        scheduleWaitAndCast();

        assertTrue(SaiMomAbstract(SAIMOM).owner() == address(pause_proxy));
        assertTrue(SaiMomAbstract(SAIMOM).authority() == address(0x0));
        assertTrue(SaiTopAbstract(SAITOP).owner() == address(pause_proxy));
        assertTrue(SaiTopAbstract(SAITOP).authority() == address(0x0));

        // assert that the pause is set for SCD
        assertEq(
            DSPauseAbstract(
                DSPauseProxyAbstract(
                    SaiMomAbstract(SAIMOM).owner() // is pause_proxy
                ).owner() // is pause
            ).delay()
            , 60 * 60 * 24
        );
    }

    // non-authorized call to osm_mom.stop() should fail
    // function testFailCanCall() public {
    //     spell = new DssSpell();
    //     // spell = DssSpell(0xDD4Aa99077C5e976AFc22060EEafBBd1ba34eae9);

    //     assertEq(pause.delay(), 0);

    //     vote();
    //     spell.cast();

    //     // test that the new pause delay is 24 hours
    //     assertEq(pause.delay(), 60 * 60 * 24);

    //     // just make sure the hat can call osm_mom.stop()
    //     // address[] memory vote = new address[](1);
    //     // vote[0] = address(0x1);

    //     // chief.vote(vote);
    //     // chief.lift(address(0x1));
    //     // assertEq(chief.hat(), address(0x1));
    //     // assertEq(osm_mom.authority(), address(chief));

    //     // osm_mom.stop('ETH-A');
    // }
}
