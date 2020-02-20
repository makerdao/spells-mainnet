pragma solidity ^0.5.12;

import "ds-test/test.sol";

import {Dai} from "dss/dai.sol";
import {Vat} from "dss/vat.sol";
import {Vow} from "dss/vow.sol";
import {Pot} from "dss/pot.sol";
import {ERC20} from "erc20/erc20.sol";
import {DSChief} from "ds-chief/chief.sol";

import {DssFebruary21Spell} from "./DssFebruary21Spell.sol";

contract ProxyLike {
    function execute(address, bytes memory) public payable;
}

contract TokenLike {
    function balanceOf(address) public view returns (uint);
    function approve(address, uint) public;
}

contract PauseLike {
    function delay() external view returns (uint256);
    function setDelay(uint256) external;
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external;
}

contract Hevm {
    function warp(uint) public;
}

contract SaiMomLike {
    function setOwner(address) external;
    function owner() external view returns(address);
    function setFee(uint256) external;
}

contract TubLike {
    function fee() external view returns (uint);
}

contract SaiTopLike {
    function setOwner(address) external;
    function owner() external view returns(address);
}

contract TestDelaySpell {

}

contract DssFebruary21Test is DSTest {
    Hevm hevm;

    PauseLike public pause =
        PauseLike(0xbE286431454714F511008713973d3B053A2d38f3);
    ERC20 gov = ERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    DSChief chief = DSChief(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    address pause_proxy = 0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
    address constant public SAIMOM = 0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C;
    address constant public SAITOP = 0x9b0ccf7C8994E19F39b2B4CF708e0A7DF65fA8a3;

    DssFebruary21Spell spell;

    function vote() private {
        uint balance = gov.balanceOf(address(this));
        DSChief(address(this)).lock(balance);
        // deposits[address(this)] = add(deposits[address(this)], balance);
        // addWeight(balance, votes[address(this)]);
        // assertEq(this.deposits(address(this)), balance);
        // assertEq(this.approvals(address(spell)), 0);
        uint currentHat = DSChief(address(this)).approvals(DSChief(address(this)).hat());
        emit log_named_uint("bal", balance);
        emit log_named_uint("hat", currentHat);

        assertTrue(!spell.done());

        address[] memory vote = new address[](1);
        vote[0] = address(spell);

        DSChief(address(this)).vote(vote);
        assertEq(DSChief(address(this)).approvals(address(spell)), balance);
        assertTrue(DSChief(address(this)).approvals(DSChief(address(this)).hat()) < balance);
        // chief.lift(address(spell));
        // assertEq(chief.hat(), address(spell));
    }

    function testFeb21IncreaseDelay() public {
        spell = new DssFebruary21Spell();
        // spell = DssFebruary21Spell(0xDD4Aa99077C5e976AFc22060EEafBBd1ba34eae9);

        assertEq(pause.delay(), 0);
        assertTrue(SaiMomLike(SAIMOM).owner() == address(0x0));
        assertTrue(SaiTopLike(SAITOP).owner() == address(0x0));

        vote();
        // spell.cast();

        // test that the new pause delay is 24 hours
        // assertEq(pause.delay(), 60 * 60 * 24);

        // assertTrue(SaiMomLike(SAIMOM).owner() == address(pause_proxy));
        // assertTrue(SaiTopLike(SAITOP).owner() == address(pause_proxy));

        // just make sure the hat can call osm_mom.stop()
        // address[] memory vote = new address[](1);
        // TestDelaySpell testSpell = new TestDelayScdSpell();
        // vote[0] = address(testSpell);

        // chief.vote(vote);
        // chief.lift(address(this));

        // hevm.warp(now + 60 * 60 * 24);

        // spell.cast();
        // assertEq(TubLike(tub).fee(), testSpell.newFee());
    }

    // non-authorized call to osm_mom.stop() should fail
    // function testFailCanCall() public {
    //     spell = new DssFebruary21Spell();
    //     // spell = DssFebruary21Spell(0xDD4Aa99077C5e976AFc22060EEafBBd1ba34eae9);

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
