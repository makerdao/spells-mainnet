pragma solidity 0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssSpell, SpellAction} from "./UnstickFlopsSpell.sol";

contract Hevm { function warp(uint) public; }

contract DssSpellTest is DSTest, DSMath {

    // Replace with mainnet spell address to test against live
    address constant MAINNET_SPELL = 0xD74cC5Fce54B1797f688E4f6a5681006Fc077bd4;

    struct SystemValues {
        uint256 dsr;
        uint256 dsrPct;
        uint256 lineETH;
        uint256 dutyETH;
        uint256 pctETH;
        uint256 lineUSDC;
        uint256 dutyUSDC;
        uint256 pctUSDC;
        uint256 lineBAT;
        uint256 dutyBAT;
        uint256 pctBAT;
        uint256 lineSAI;
        uint256 lineGlobal;
        uint256 saiCap;
        uint256 saiFee;
        uint256 saiPct;
    }

    Hevm hevm;

    DSPauseAbstract pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    DSChiefAbstract chief =
        DSChiefAbstract(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    VatAbstract     vat =
        VatAbstract(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    VowAbstract     vow =
        VowAbstract(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
    FlopAbstract    flop =
        FlopAbstract(0x4D95A049d5B0b7d32058cd3F2163015747522e99);
    MKRAbstract     gov =
        MKRAbstract(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);

    DssSpell spell;

    // this spell is intended to run as the MkrAuthority
    function canCall(address, address, bytes4) public returns (bool) {
        return true;
    }

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        // mint enough MKR to overcome the current hat.
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

        // warp to 2020-03-27 1200 EDT
        hevm.warp(1585324800);

        spell.cast();
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        assembly {
        result := mload(add(source, 32))
        }
    }

    function testSpellIsCast() public {

        spell = MAINNET_SPELL != address(0) ?
            DssSpell(MAINNET_SPELL) : new DssSpell();

        // Test description
        string memory description = new SpellAction().description();
        assertTrue(bytes(description).length > 0);
        // DS-Test can't handle strings directly, so cast to a bytes32.
        assertEq(stringToBytes32(spell.description()),
            stringToBytes32(description));

        // Test expiration
        // TODO fix this for deployed contract
        if(address(spell) != address(MAINNET_SPELL)) {
            assertEq(spell.expiration(), (now + 30 days));
        }

        uint256 pre_debt  = vat.debt();
        uint256 pre_vice  = vat.vice();
        uint256 pre_Awe   = vat.sin(address(vow));
        uint256 pre_joy   = vat.dai(address(vow));
        uint256 pre_Ash   = vow.Ash();
        uint256 pre_Sin   = vow.Sin();
        uint256 pre_kicks = flop.kicks();

        vote();
        scheduleWaitAndCast();

        // spell done
        assertTrue(spell.done());

        assertEq(vat.debt(), sub(pre_debt, pre_joy));
        assertEq(vat.vice(), sub(pre_vice, pre_joy));
        assertEq(vat.sin(address(vow)), sub(pre_Awe, pre_joy));
        assertEq(vat.dai(address(vow)), 0);
        assertEq(vow.Sin(), pre_Sin);

        uint256 nFlops = sub(pre_Ash, pre_joy) / vow.sump();

        assertEq(vow.Ash(), mul(nFlops, vow.sump()));
        assertEq(flop.kicks(), add(pre_kicks, nFlops));
    }

    function testFailNotAfter1400EDT() public {
        spell = MAINNET_SPELL != address(0) ?
            DssSpell(MAINNET_SPELL) : new DssSpell();
        vote();
        spell.schedule();

        // warp to 2020-03-27 1401 EDT
        hevm.warp(1585332001);

        spell.cast();
    }

    function testFailNotOnSaturday() public {
        spell = MAINNET_SPELL != address(0) ?
            DssSpell(MAINNET_SPELL) : new DssSpell();
        vote();
        spell.schedule();

        // warp to 2020-03-28 1200 EDT
        hevm.warp(1585411200);

        spell.cast();
    }

    function testFailNotOnSunday() public {
        spell = MAINNET_SPELL != address(0) ?
            DssSpell(MAINNET_SPELL) : new DssSpell();
        vote();
        spell.schedule();

        // warp to 2020-03-29 1200 EDT
        hevm.warp(1585497600);

        spell.cast();
    }

    function testMondayIsOkay() public {
        spell = MAINNET_SPELL != address(0) ?
            DssSpell(MAINNET_SPELL) : new DssSpell();
        vote();
        spell.schedule();

        // warp to 2020-03-30 1200 EDT
        hevm.warp(1585584000);

        spell.cast();
    }
}
