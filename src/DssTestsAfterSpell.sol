pragma solidity ^0.5.12;

import "ds-test/test.sol";

import {Dai} from "dss/dai.sol";
import {Vat} from "dss/vat.sol";
import {Vow} from "dss/vow.sol";
import "erc20/erc20.sol";

contract TubLike {

}

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
    function execute(address, bytes memory) public;
}


contract Hevm {
    function warp(uint) public;
}

contract DssTestsAfterSpell is DSTest {
    Hevm hevm;

    Dai dai;
    Vat vat;
    Vow vow;
    ERC20 gov;
    ChiefLike chief;
    address manager;
    ProxyLike proxy;

    TubLike tub;

    DssInitSpell spell;

    uint constant RAD = 10 ** 45;

    function setUp() public {
        dai = Dai(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        vat = Vat(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
        vow = Vow(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
        chief = ChiefLike(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
        gov = ERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
        manager = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
        RegistryLike registry = RegistryLike(0x4678f0a6958e4D2Bc4F1BAF7Bc52E8F3564f3fE4);

        tub = TubLike(0x448a5065aeBB8E423F0896E6c5D525C040f59af3);

        spell = new DssInitSpell();

        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        hevm.warp(1574092700);

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

    function waitAndCast() public {
        hevm.warp(1574092800);
        spell.schedule();
        spell.cast();
    }

    function testSpellIsCasted() public {
        assertEq(vat.Line(), 0);
        (,,, uint line,) = vat.ilks("ETH-A");
        assertEq(line, 0);
        (,,, line,) = vat.ilks("BAT-A");
        assertEq(line, 0);
        (,,, line,) = vat.ilks("SAI");
        assertEq(line, 0);

        vote();
        waitAndCast();

        assertTrue(spell.done());
        assertEq(vat.Line(), 153000000 * RAD);
        (,,, line,) = vat.ilks("ETH-A");
        assertEq(line, 50000000 * RAD);
        (,,, line,) = vat.ilks("BAT-A");
        assertEq(line, 3000000 * RAD);
        (,,, line,) = vat.ilks("SAI");
        assertEq(line, 100000000 * RAD);
    }

    function testFailSpellSchedule() public {
        vote();
        spell.schedule();
    }

    // function createETHVault() public {
    //     vote();
    //     waitAndCast();

    // }

}

// Launch activation spell:

contract VatLike {
    function file(bytes32,uint) public;
    function file(bytes32,bytes32,uint) public;
}

contract PauseLike {
    function delay() public view returns (uint256);
    function plot(address, bytes32, bytes memory, uint256) public;
    function exec(address, bytes32, bytes memory, uint256) public;
}

contract SpellAction {
    uint constant RAD = 10 ** 45;

    function execute() public {
        VatLike(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B).file("Line", 153000000 * RAD);
        VatLike(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B).file("ETH-A", "line", 50000000 * RAD);
        VatLike(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B).file("BAT-A", "line", 3000000 * RAD);
        VatLike(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B).file("SAI", "line", 100000000 * RAD);
    }
}

contract DssInitSpell {
    PauseLike public pause = PauseLike(0xbE286431454714F511008713973d3B053A2d38f3);
    address   public action;
    bytes32   public tag;
    uint256   public eta;
    bytes     public sig;
    bool      public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
        require(now >= 1574092800, "launch-time-error");
        require(eta == 0, "spell-already-scheduled");
        eta = now + PauseLike(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        pause.exec(action, tag, sig, eta);
        done = true;
    }
}
