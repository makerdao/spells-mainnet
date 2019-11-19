pragma solidity ^0.5.12;

import "ds-test/test.sol";

import {Dai} from "dss/dai.sol";
import {Vat} from "dss/vat.sol";
import {Vow} from "dss/vow.sol";
import {Flopper} from "dss/flop.sol";
import {Flapper} from "dss/flap.sol";

import {MkrAuthority} from "mkr-authority/MkrAuthority.sol";

/**
 * Must be executed from the Multisig address.
 * Use ./test-mkr-authority.sh to test
 */

contract Hevm {
    function warp(uint) public;
}

contract ChiefLike {
    function hat() public view returns (address);
    function lock(uint) public;
    function vote(address[] memory) public;
    function lift(address) public;
}

contract MkrLike {
    function setAuthority(address whom) external;
    function setOwner(address whom) external;
    function owner() external returns(address);
    function authority() external returns(address);
    function approve(address, uint256) external returns(bool);
    function balanceOf(address) external returns(uint256);
}

contract MkrAuthorityTest is DSTest {
    Hevm hevm;

    Dai dai     = Dai(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    Vat vat     = Vat(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    Vow vow     = Vow(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
    Flopper flop = Flopper(0xBE00FE8Dfd9C079f1E5F5ad7AE9a3Ad2c571FCAC);
    Flapper flap = Flapper(0xdfE0fb1bE2a52CDBf8FB962D5701d7fd0902db9f);

    MkrLike gov     = MkrLike(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    ChiefLike chief = ChiefLike(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);

    MkrAuthority mkrauth;

    uint constant RAD = 10 ** 45;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(1574092700);

        mkrauth = new MkrAuthority();
    }

    function setupDebtAuction() public {}

    function setupSurplusAuction() public {}

    function test_canAddMkrAuth() public {
        assertTrue(gov.authority() == address(0));
        gov.setAuthority(address(mkrauth));
        assertTrue(gov.authority() == address(mkrauth));
    }

    function testFail_cannotDealFlop() public {}
    function testFail_cannotDealFlap() public {}

    function test_canDealFlop_new() public {}
    function test_canDealFlap_new() public {}

    function test_canDealFlop_stuck() public {}
    function test_canDealFlap_stuck() public {}
}
