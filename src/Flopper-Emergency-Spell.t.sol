pragma solidity ^0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssSpell} from "./Flopper-Emergency-Spell.sol";

contract Hevm {
    function warp(uint256) public;
}

contract MkrAuthorityAbstract {
    function wards(address) public returns (uint256);
    function rely(address) public;
    function deny(address) public;
    function canCall(address, address, bytes4) public returns (bool);
}

contract DssSpellTest is DSTest, DSMath {
    // populate with mainnet spell if needed
    address constant MAINNET_SPELL = address(0);

    Hevm hevm;

    // MAINNET ADDRESSES
    DSPauseAbstract      pause      = DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address              pauseProxy = 0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
    DSChiefAbstract      chief      = DSChiefAbstract(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    VowAbstract          vow        = VowAbstract(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
    MKRAbstract          gov        = MKRAbstract(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    FlopAbstract         flop       = FlopAbstract(0x4D95A049d5B0b7d32058cd3F2163015747522e99);
    MkrAuthorityAbstract govGuard   = MkrAuthorityAbstract(0x6eEB68B2C7A918f36B78E2DB80dcF279236DDFb8);

    DssSpell spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));
    
    uint256 constant THOUSAND = 10**3;
    uint256 constant MILLION = 10**6;
    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;
    uint256 constant RAD = 10**45;

    bytes4 constant mintSig = bytes4(keccak256(abi.encodePacked('mint(address,uint256)')));

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        gov.mint(address(this), uint256(-1) - gov.totalSupply());

        spell = MAINNET_SPELL != address(0) ? DssSpell(MAINNET_SPELL) : new DssSpell();
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
        hevm.warp(now + pause.delay());
        spell.cast();
    }

    function testSpellIsCast() public {
        // Values (Pre-Cast)
        assertEq(vow.sump(), (50 * THOUSAND) * RAD);
        assertEq(vow.dump(), 250 * WAD);
        assertEq(flop.pad(), 12 * (WAD / 10));
        assertEq(flop.beg(), 103 * (WAD / 100));
        assertEq(uint256(flop.ttl()), 6 hours);
        assertEq(uint256(flop.tau()), 3 days);

        // Authorization (Pre-Cast)
        assertEq(flop.wards(address(vow)), 1);
        assertEq(govGuard.wards(address(flop)), 1);
        assertTrue(govGuard.canCall(address(flop), address(0), mintSig));

        vote();
        scheduleWaitAndCast();

        // spell done
        assertTrue(spell.done());

        // Values (Post-Cast)
        assertEq(vow.sump(), (50 * THOUSAND) * RAD);
        assertEq(vow.dump(), 250 * WAD);
        assertEq(flop.pad(), 12 * (WAD / 10));
        assertEq(flop.beg(), 103 * (WAD / 100));
        assertEq(uint256(flop.ttl()), 6 hours);
        assertEq(uint256(flop.tau()), 3 days);

        // Authorization (Post-Cast)
        assertEq(flop.wards(address(vow)), 0);
        assertEq(govGuard.wards(address(flop)), 0);
        assertTrue(!govGuard.canCall(address(flop), address(0), mintSig));
    }

    function testFailCanOnlyCastOnce() public {
        vote();
        scheduleWaitAndCast();
        spell.cast();
    }

    function testFailCannotCastAfterExpiration() public {
        vote();
        hevm.warp(now + 30 days + 1);
        spell.schedule();
    }
}
