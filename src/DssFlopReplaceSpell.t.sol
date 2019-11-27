pragma solidity ^0.5.12;

import "ds-test/test.sol";

import {Dai} from "dss/dai.sol";
import {Vat} from "dss/vat.sol";
import {Vow} from "dss/vow.sol";
import {ERC20} from "erc20/erc20.sol";

import {DssFlopReplaceSpell} from "./DssFlopReplaceSpell.sol";

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
}

contract ValueLike {
    function peek() public view returns (uint, bool);
}

contract OtcLike {
    function getPayAmount(address, address, uint) public view returns (uint);
}

contract Hevm {
    function warp(uint) public;
}

contract DssFlopReplaceSpellTest is DSTest {
    Hevm hevm;

    Dai dai = Dai(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    Vat vat = Vat(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    Vow vow = Vow(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
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

    TokenLike bat = TokenLike(0x0D8775F648430679A709E98d2b0Cb6250d2887EF);

    address saiPActions = 0x526af336D614adE5cc252A407062B8861aF998F5;
    TubLike tub = TubLike(0x448a5065aeBB8E423F0896E6c5D525C040f59af3);
    TokenLike sai = TokenLike(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);
    ValueLike pep = ValueLike(0x99041F808D598B782D5a3e498681C2452A31da08);

    OtcLike otc = OtcLike(0x39755357759cE0d7f32dC8dC45414CCa409AE24e);

    DssFlopReplaceSpell spell;

    uint constant RAD = 10 ** 45;

    function setUp() public {
        RegistryLike registry = RegistryLike(0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4);
        // spell = new DssFlopReplaceSpell();

        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        // hevm.warp(1574092700);

        proxy = registry.build();
    }

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

    function testFlopSpellIsCast() public {
        // spell = DssFlopReplaceSpell(0x30cfdb937E46E946b1038397f9Cd6fa231B90863);
        spell = new DssFlopReplaceSpell();
        assertEq(tub.pep(), 0x5C1fc813d9c1B5ebb93889B3d63bA24984CA44B7);
        assertEq(address(vow.flopper()), 0xBE00FE8Dfd9C079f1E5F5ad7AE9a3Ad2c571FCAC);

        vote();
        spell.cast();

        assertEq(tub.pep(), 0x99041F808D598B782D5a3e498681C2452A31da08);
        assertEq(address(vow.flopper()), 0x4D95A049d5B0b7d32058cd3F2163015747522e99);
        assertEq(vat.wards(0x4D95A049d5B0b7d32058cd3F2163015747522e99), 1);

        assertTrue(spell.done());
    }

}
