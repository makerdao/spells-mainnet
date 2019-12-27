pragma solidity ^0.5.12;

import "ds-test/test.sol";

import {Dai} from "dss/dai.sol";
import {Vat} from "dss/vat.sol";
import {Vow} from "dss/vow.sol";
import {Pot} from "dss/pot.sol";
import {ERC20} from "erc20/erc20.sol";

import {DssDecember27Spell} from "./DssDecember27Spell.sol";

contract ChiefLike {
    function hat() public view returns (address);
    function lock(uint) public;
    function vote(address[] memory) public;
    function lift(address) public;
}

contract RegistryLike {
    function build() public returns (ProxyLike);
}

contract ProxyLike {
    function execute(address, bytes memory) public payable;
}

contract TokenLike {
    function balanceOf(address) public view returns (uint);
    function approve(address, uint) public;
}

contract ManagerLike {
    function urns(uint) public view returns (address);
}

contract TubLike {
    function ink(bytes32) public view returns (uint);
    function per() public view returns (uint);
    function rap(bytes32) public returns (uint);
    function tab(bytes32) public returns (uint);
    function pep() external returns (address);
    function cap() external view returns (uint);
    function fee() external view returns (uint);
}

contract ValueLike {
    function peek() public view returns (uint, bool);
}

contract OtcLike {
    function getPayAmount(address, address, uint) public view returns (uint);
}

contract FlopLike {
    function wards(address) external returns(uint256);
    function ttl() external returns(uint256);
    function beg() external returns(uint256);
    function pad() external returns(uint256);
    function tau() external returns(uint256);

    function file(bytes32,uint) external;

    function rely(address) external;
    function deny(address) external;
    function dent(uint,uint,uint) external;
    function deal(uint) external;
    function yank(uint) external;
    function cage() external;
    function live() external returns(uint256);
}

contract WardsLike {
    function wards(address) external returns(uint256);
    function rely(address) public;
    function deny(address) public;
}

contract Hevm {
    function warp(uint) public;
}

contract DssDecember27SpellTest is DSTest {
    Hevm hevm;

    Dai dai = Dai(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    Vat vat = Vat(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    Vow vow = Vow(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
    Pot pot = Pot(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    ERC20 gov = ERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    ChiefLike chief = ChiefLike(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    ProxyLike proxy;
    address proxyActions = 0x82ecD135Dce65Fbc6DbdD0e4237E0AF93FFD5038;
    address migrationPActions = 0xe4B22D484958E582098A98229A24e8A43801b674;
    address migration = 0xc73e0383F3Aff3215E6f04B0331D58CeCf0Ab849;
    address manager = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address jug = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address ethJoin = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;
    address batJoin = 0x3D0B1912B66114d4096F48A8CEe3A56C231772cA;
    address daiJoin = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;

    TubLike tub = TubLike(0x448a5065aeBB8E423F0896E6c5D525C040f59af3);

    DssDecember27Spell spell;

    uint constant RAD = 10 ** 45;

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

    function testDecember27SpellIsCast() public {
        spell = DssDecember27Spell(0x94c19E029F5A1A115F3B99aD87da24D33E60A0E1);
        // spell = new DssDecember27Spell();
        assertEq(tub.cap(), 95000000 * 10 ** 18);
        assertEq(vat.Line(), 178000000 * RAD);
        (,,,uint line,) = vat.ilks("ETH-A");
        assertEq(line, 75000000 * RAD);

        vote();
        spell.cast();

        (,,,line,) = vat.ilks("ETH-A");
        assertTrue(spell.done());
        assertEq(tub.cap(), 70000000 * 10 ** 18);
        assertEq(vat.Line(), 203000000 * RAD);
        assertEq(line, 100000000 * RAD);
    }

}