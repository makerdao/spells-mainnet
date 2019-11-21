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

contract PauseLike {
    function delay() public view returns (uint256);
    function plot(address, bytes32, bytes memory, uint256) public;
    function exec(address, bytes32, bytes memory, uint256) public;
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

contract VatLike {
    function rely(address) public;
    function wards(address) public returns(uint256);
    function Line() public returns(uint256);
}

contract TakeOverSpellAction {
    address constant multisig = 0x8EE7D9235e01e6B42345120b5d270bdB763624C7;
    address constant vat = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    function execute() public {
        VatLike(vat).rely(multisig);
        require(VatLike(vat).wards(multisig) == 1, "Vat/is-ward-now");
    }
}

contract TakeOverSpell {
    PauseLike public pause =
        PauseLike(0xbE286431454714F511008713973d3B053A2d38f3);
    address   public action;
    bytes32   public tag;
    bytes     public sig;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new TakeOverSpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function cast() public {
        pause.plot(action, tag, sig, now);
        pause.exec(action, tag, sig, now);
    }
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

    uint256  constant RAD = 10 ** 45;
    uint256  constant ONE = 1.00E18;

    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        // hevm.warp(1574092700);
        // hevm.warp(now);

        mkrauth = new MkrAuthority();
    }

    function masterChief() private {
        gov.approve(address(chief), uint256(-1));
        chief.lock(gov.balanceOf(address(this)));
        address[] memory vote = new address[](1);

        TakeOverSpell spell = new TakeOverSpell();

        vote[0] = address(spell);
        chief.vote(vote);
        chief.lift(address(spell));
        assertEq(chief.hat(), address(spell));
        spell.cast();
        assertEq(vat.wards(address(this)), 1);
    }

    function setupMkrAuth() private {
        gov.setAuthority(address(mkrauth));
        mkrauth.rely(address(flop));
    }

    function setupFlop() private returns(uint) {
        masterChief(); // Allows `vat.suck`
        uint256 surplus = vat.dai(address(vow));
        uint256 Sin = vow.Sin();
        uint256 Ash = vow.Ash();
        uint256 sump = vow.sump();
        vat.suck(address(vow), address(this), surplus + sump + Ash + Sin);
        vow.heal(surplus);
        // assertTrue(vat.dai(address(vow)) == 0);
        // assertTrue(vat.dai(address(this)) == surplus + sump + Ash + Sin);
        // uint256 sin = vat.sin(address(vow));
        // emit log_named_uint("surp", vat.dai(address(vow)));
        // emit log_named_uint("debt", sin);
        // emit log_named_uint("sump", sump);
        // emit log_named_uint("Sin ", Sin);
        // emit log_named_uint("Ash ", Ash);
        // emit log_named_uint("debt", sin - Sin - Ash);
        // assertTrue(sump <= sin - Sin - Ash);
        return vow.flop();
    }

    function bidFlop(uint256 id) private {
        vat.hope(address(flop));
        uint256 bid = vow.sump();
        uint256 lot = 1;
        emit log_named_uint('lot', lot);
        emit log_named_uint('bid', bid);
        flop.dent(id, lot, bid);
    }

    function setupDebtAuction() private {}

    function setupSurplusAuction() private {}

    function test_canAddMkrAuth() public {
        assertTrue(gov.authority() == address(0));
        setupMkrAuth();
        assertTrue(gov.authority() == address(mkrauth));
    }

    function test_canRemoveOwner() public {
        assertTrue(gov.owner() == address(this));
        gov.setOwner(address(0));
        assertTrue(gov.owner() == address(0));
    }

    function testFail_cannotDealFlop() public {
        assertTrue(gov.authority() == address(0));
        uint flopId = setupFlop();
        bidFlop(flopId);
        hevm.warp(uint48(now) + flop.ttl() + 1);

        flop.deal(flopId);
    }

    function testFail_cannotDealFlap() public {}

    function test_canDealFlop_new() public {
        setupMkrAuth();

        uint flopId = setupFlop();
        bidFlop(flopId);
        hevm.warp(uint48(now) + flop.ttl() + 1);

        flop.deal(flopId);
    }

    function test_canDealFlap_new() public {}

    function test_canDealFlop_stuck() public {
        assertTrue(gov.authority() == address(0));
        uint flopId = setupFlop();
        bidFlop(flopId);
        hevm.warp(uint48(now) + flop.ttl() + 1);

        setupMkrAuth();

        flop.deal(flopId);
    }

    function test_canDealFlap_stuck() public {}
}
