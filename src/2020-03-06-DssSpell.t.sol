pragma solidity ^0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssSpell} from "./2020-03-06-DssSpell.sol";

contract Hevm {
    function warp(uint) public;
}

contract DssSpellTest is DSTest, DSMath {

    // Replace with mainnet spell address to test against live
    address constant MAINNET_SPELL = address(0);

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
    string constant DESCRIPTION = "2020-03-06 Weekly Executive: DSR spread adjustment";

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

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        assembly {
        result := mload(add(source, 32))
        }
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

        spell = MAINNET_SPELL != address(0) ? DssSpell(MAINNET_SPELL) : new DssSpell();

        // Test expiration
        assertEq(spell.expiration(), (now + 30 days));

        // DS-Test can't handle strings directly, so cast to a bytes32.
        assertEq(stringToBytes32(spell.description()),
            stringToBytes32(DESCRIPTION));

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

        // dsr
        assertEq(pot.dsr(), thisWeek.dsr);

        // (ETH-A, BAT-A)
        (dutyETH,) = jug.ilks("ETH-A");
        (dutyBAT,) = jug.ilks("BAT-A");
        assertEq(dutyETH, thisWeek.dutyETH);
        assertEq(dutyBAT, thisWeek.dutyBAT);

        // ETH-A line
        (,,, lineETH,) = vat.ilks("ETH-A");
        assertEq(lineETH, thisWeek.lineETH);

        // SAI line
        (,,, lineSAI,) = vat.ilks("SAI");
        assertEq(lineSAI, thisWeek.lineSAI);

        // Line
        assertEq(vat.Line(), thisWeek.lineGlobal);

        // SCD DC
        assertEq(tub.cap(), thisWeek.saiCap);

        // SCD Fee
        assertEq(tub.fee(), thisWeek.saiFee);
    }

    function rpow(uint x, uint n, uint b) internal pure returns (uint z) {
      assembly {
        switch x case 0 {switch n case 0 {z := b} default {z := 0}}
        default {
          switch mod(n, 2) case 0 { z := b } default { z := x }
          let half := div(b, 2)  // for rounding.
          for { n := div(n, 2) } n { n := div(n,2) } {
            let xx := mul(x, x)
            if iszero(eq(div(xx, x), x)) { revert(0,0) }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) { revert(0,0) }
            x := div(xxRound, b)
            if mod(n,2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) { revert(0,0) }
              z := div(zxRound, b)
            }
          }
        }
      }
    }

    function testSpellRates() public {
        // 10^-5 (tenth of a basis point) as a RAY
        uint TOLERANCE = 10 ** 22;
        uint yearlyYield;
        uint expected;
        uint diff;


        // SAI fee
        yearlyYield = rpow(thisWeek.saiFee, 365 * 24 * 60 * 60, RAY);

        // 9.5% => rate=1.095e27 after a year if it starts at ONE := RAY := 10 ** 27
        expected = 1095 * 10 ** 24;

        // Depending on rounding, rpow may over- or under- estimate the value
        diff = (expected > yearlyYield) ? expected - yearlyYield : yearlyYield - expected;
        assertTrue(diff <= TOLERANCE);


        // DSR
        yearlyYield = rpow(thisWeek.dsr, 365 * 24 * 60 * 60, RAY);

        // 7% => chi=1.07e27 after a year if it starts at ONE := RAY := 10 ** 27
        expected = 107 * 10 ** 25;

        // Depending on rounding, rpow may over- or under- estimate the value
        diff = (expected > yearlyYield) ? expected - yearlyYield : yearlyYield - expected;
        assertTrue(diff <= TOLERANCE);


        // ETH-A duty
        yearlyYield = rpow(thisWeek.dutyETH, 365 * 24 * 60 * 60, RAY);

        // 8% => rate=1.07e27 after a year if it starts at ONE := RAY := 10 ** 27
        expected = 108 * 10 ** 25;

        // Depending on rounding, rpow may over- or under- estimate the value
        diff = (expected > yearlyYield) ? expected - yearlyYield : yearlyYield - expected;
        assertTrue(diff <= TOLERANCE);


        // BAT-A duty
        yearlyYield = rpow(thisWeek.dutyBAT, 365 * 24 * 60 * 60, RAY);

        // 8% => rate=1.07e27 after a year if it starts at ONE := RAY := 10 ** 27
        expected = 108 * 10 ** 25;

        // Depending on rounding, rpow may over- or under- estimate the value
        diff = (expected > yearlyYield) ? expected - yearlyYield : yearlyYield - expected;
        assertTrue(diff <= TOLERANCE);
    }
}
