pragma solidity ^0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssSpell} from "./2020-03-06-DssSpell.sol";

contract Hevm {
    function warp(uint) public;
}

contract DssSpellTest is DSTest, DSMath {

    struct SystemValues {
        uint256 dsr;
        uint256 lineETH;
        uint256 dutyETH;
        uint256 lineBAT;
        uint256 dutyBAT;
        uint256 lineSAI;
        uint256 lineGlobal;
        uint256 saiCap;
        uint256 saiFee;
    }

    // If last week's spell was cast successfully, you can copy the
    //  the values from that week's `thisWeek` var into this week's
    //  `lastWeek` var. Or go back to the last successful executive.
    // (8%, 150m, 8%, 150m, 8%, 150m, 150m, 25m, 9.5%)
    SystemValues lastWeek = SystemValues({
        dsr: 1000000002440418608258400030,
        lineETH: mul(150000000, RAD),
        dutyETH: 1000000002440418608258400030,
        lineBAT: mul(150000000, RAD),
        dutyBAT: 1000000002440418608258400030,
        lineSAI: mul(30000000, RAD),
        lineGlobal: mul(183000000, RAD),
        saiCap: mul(30000000, WAD),
        saiFee: 1000000002877801985002875644
    });

    // These are the values that should be reflected in the system
    //  after this spell is cast.
    // (7%, 150m, 8%, 150m, 8%, 150m, 150m, 25m, 9.5%)
    SystemValues thisWeek = SystemValues({
        dsr: 1000000002145441671308778766,
        lineETH: mul(150000000, RAD),
        dutyETH: 1000000002440418608258400030,
        lineBAT: mul(150000000, RAD),
        dutyBAT: 1000000002440418608258400030,
        lineSAI: mul(30000000, RAD),
        lineGlobal: mul(183000000, RAD),
        saiCap: mul(30000000, WAD),
        saiFee: 1000000002877801985002875644
    });

    Hevm hevm;

    DSPauseAbstract pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    DSChiefAbstract chief =
        DSChiefAbstract(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    VatAbstract     vat = VatAbstract(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    VowAbstract     vow = VowAbstract(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
    PotAbstract     pot = PotAbstract(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    JugAbstract     jug = JugAbstract(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    MKRAbstract     gov = MKRAbstract(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    SaiTubAbstract  tub = SaiTubAbstract(0x448a5065aeBB8E423F0896E6c5D525C040f59af3);

    DssSpell spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    // not provided in DSMath
    uint constant RAD = 10 ** 45;

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        // Using the Flopper test address, mint enough MKR to overcome the current hat.
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
        hevm.warp(add(now, pause.delay()));
        spell.cast();
    }

    function testSpellIsCast() public {

        //spell = DssSpell(0x489...);
        spell = new DssSpell();

        // (ETH-A, BAT-A, DSR)
        (uint dutyETH,) = jug.ilks("ETH-A");
        (uint dutyBAT,) = jug.ilks("BAT-A");
        assertEq(dutyETH,   lastWeek.dutyETH);
        assertEq(dutyBAT,   lastWeek.dutyBAT);
        assertEq(pot.dsr(), lastWeek.dsr);

        // ETH-A line
        (,,, uint256 lineETH,) = vat.ilks("ETH-A");
        assertEq(lineETH, lastWeek.lineETH);

        // SAI line
        (,,, uint256 lineSAI,) = vat.ilks("SAI");
        assertEq(lineSAI, lastWeek.lineSAI);

        // Line
        assertEq(vat.Line(), lastWeek.lineGlobal);

        // SCD DC
        assertEq(tub.cap(), lastWeek.saiCap);

        // SCD Fee
        assertEq(tub.fee(), lastWeek.saiFee);

        vote();
        scheduleWaitAndCast();

        // spell done
        assertTrue(spell.done());

        // dsr = 8.75%
        assertEq(pot.dsr(), thisWeek.dsr);

        // (ETH-A, BAT-A) = (9%, 9%)
        (dutyETH,) = jug.ilks("ETH-A");
        (dutyBAT,) = jug.ilks("BAT-A");
        assertEq(dutyETH, thisWeek.dutyETH);
        assertEq(dutyBAT, thisWeek.dutyBAT);

        // ETH-A line = 125mm
        (,,, lineETH,) = vat.ilks("ETH-A");
        assertEq(lineETH, thisWeek.lineETH);

        // SAI line = 30mm
        (,,, lineSAI,) = vat.ilks("SAI");
        assertEq(lineSAI, thisWeek.lineSAI);

        // Line = 158mm
        assertEq(vat.Line(), thisWeek.lineGlobal);

        // SCD DC = 30mm
        assertEq(tub.cap(), thisWeek.saiCap);

        // SCD Fee = 10%
        assertEq(tub.fee(), thisWeek.saiFee);
    }

}
