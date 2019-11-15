pragma solidity ^0.5.12;

import "ds-test/test.sol";

import {Dai} from "dss/dai.sol";
import {Vat} from "dss/vat.sol";
import {Vow} from "dss/vow.sol";
import {Flopper} from "dss/flop.sol";
import {Flapper} from "dss/flap.sol";
import {DSToken} from "ds-token/ds-token.sol";

import {MkrAuthority} from "mkr-authority";

contract Hevm {
    function warp(uint) public;
}

// multisig = 0x8EE7D9235e01e6B42345120b5d270bdB763624C7

contract MultiSig {
    DSToken gov;

    constructor(address gov_) public {
        gov = DSToken(gov_);
    }
    function setAuthority(address auth) public {
        gov.setAuthority(auth);
    }
}

contract MkrAuthorityTest is DSTest {
    Hevm hevm;

    Dai dai     = Dai(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    Vat vat     = Vat(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    Vow vow     = Vow(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
    Flopper flop = Flopper(0xbe00fe8dfd9c079f1e5f5ad7ae9a3ad2c571fcac);
    Flapper flap = Flapper(0xdfe0fb1be2a52cdbf8fb962d5701d7fd0902db9f);
    DSToken gov = DSToken(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);

    MkrAuthority mkrauth;

    // TODO: This can be removed once the spell is cast
    DssLaunchSpell spell = DssLaunchSpell(0xF44113760c4f70aFeEb412C63bC713B13E6e202E);

    uint constant RAD = 10 ** 45;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(1574092700);

        mkrauth = new MkrAuthority();

        // TODO: This can be removed once the spell is cast
        castSpell();
    }

    // TODO: This can be removed once the spell is cast
    function castSpell() private {
        gov.approve(address(chief), uint256(-1));
        chief.lock(gov.balanceOf(address(this)));

        assertTrue(!spell.done());

        address[] memory vote = new address[](1);
        vote[0] = address(spell);

        chief.vote(vote);
        chief.lift(address(spell));
        assertEq(chief.hat(), address(spell));
        // Let's push the time to the launch moment
        hevm.warp(1574092800);
        spell.cast();
    }

    function addMkrAuth() private {}

    function setupDebtAuction() public {}

    function setupSurplusAuction() public {}

    function testFail_cannotDealFlop() public {}
    function testFail_cannotDealFlap() public {}

    function test_canDealFlop_new() public {}
    function test_canDealFlap_new() public {}

    function test_canDealFlop_stuck() public {}
    function test_canDealFlap_stuck() public {}
}
