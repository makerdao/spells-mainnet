pragma solidity ^0.5.12;

import "ds-test/test.sol";

import {Dai} from "dss/dai.sol";
import {Vat} from "dss/vat.sol";
import {Vow} from "dss/vow.sol";
import {Pot} from "dss/pot.sol";
import {ERC20} from "erc20/erc20.sol";

import {DssIncreaseDelay24Spell} from "./DssIncreaseDelay24Spell.sol";

contract ChiefLike {
    function hat() public view returns (address);
    function lock(uint) public;
    function vote(address[] memory) public;
    function lift(address) public;
}

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

contract DssIncreaseDelay24SpellTest is DSTest {
    Hevm hevm;

    PauseLike public pause =
        PauseLike(0xbE286431454714F511008713973d3B053A2d38f3);
    ERC20 gov = ERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    ChiefLike chief = ChiefLike(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    DssIncreaseDelay24Spell spell;

    function vote() private {
        gov.approve(address(chief), uint256(-1));
        chief.lock(gov.balanceOf(address(this)));

        assertTrue(!spell.done());

        address[] memory vote = new address[](1);
        vote[0] = address(spell);

        chief.vote(vote);
        chief.lift(address(spell));
        assertEq(chief.hat(), address(spell));
    }

    function testIncreaseDelay24SpellIsCast() public {
        spell = DssIncreaseDelay24Spell(0x1A7D50b73ACf1D2b4073Ca5F94890A3C05C01401);
        // spell = new DssIncreaseDelay24Spell();

        assertEq(pause.delay(), 0);

        vote();
        spell.cast();

        assertEq(pause.delay(), 60 * 60 * 24);
    }

}