pragma solidity ^0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssDeployFlipperMom} from "./DssDeployFlipperMom.sol";

contract Hevm {
    function warp(uint256) public;
}

contract DssSpellTest is DSTest, DSMath {
    // populate with mainnet spell if needed
    address constant MAINNET_SPELL = address(0); 

    // -------------------------------------------
    // ------------ MAINNET ADDRESSES ------------
    // -------------------------------------------
    // DSPauseAbstract pause = DSPauseAbstract(
    //     0xbE286431454714F511008713973d3B053A2d38f3
    // );
    // DSChiefAbstract chief = DSChiefAbstract(
    //     0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2
    // );
    // MKRAbstract gov = MkrAbstract(
    //     0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2
    // );
    
    // -------------------------------------------
    // ------------- KOVAN ADDRESSES -------------
    // -------------------------------------------
    DSPauseAbstract pause = DSPauseAbstract(
        0x8754E6ecb4fe68DaA5132c2886aB39297a5c7189
    );
    DSChiefAbstract chief = DSChiefAbstract(
        0xbBFFC76e94B34F72D96D054b31f6424249c1337d
    );
    MKRAbstract gov = MKRAbstract(
        0xAaF64BFCC32d0F15873a02163e7E500671a4ffcD
    );
    
    DssReplaceFlipper spell;

    Hevm hevm;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
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

    function scheduleWaitAndCast() public {
        spell.schedule();
        hevm.warp(add(now, pause.delay()));
        spell.cast();
    }

    function testSpellIsCast() public {
        spell = MAINNET_SPELL != 
            address(0) ? DssReplaceFlipper(MAINNET_SPELL) : 
            new DssReplaceFlipper();

        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());
    }
}
