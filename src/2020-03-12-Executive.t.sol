pragma solidity 0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssSpell, SpellAction} from "./2020-03-12-Executive.sol";

contract Hevm { function warp(uint) public; }

contract DssSpellTest is DSTest, DSMath {

    // Replace with mainnet spell address to test against live
    address constant MAINNET_SPELL = address(0);

    struct SystemValues {
        uint256 dsr;
        uint256 dsrPct;
        uint256 lineETH;
        uint256 dutyETH;
        uint256 pctETH;
        uint256 lineBAT;
        uint256 dutyBAT;
        uint256 pctBAT;
        uint256 lineSAI;
        uint256 lineGlobal;
        uint256 saiCap;
        uint256 saiFee;
        uint256 saiPct;
    }

    // If last week's spell was cast successfully, you can copy the
    //  the values from that week's `thisWeek` var into this week's
    //  `lastWeek` var. Or go back to the last successful executive.
    SystemValues lastWeek = SystemValues({
        dsr: 1000000002440418608258400030,
        dsrPct: 8 * 1000,
        lineETH: mul(150000000, RAD),
        dutyETH: 1000000002440418608258400030,
        pctETH: 8 * 1000,
        lineBAT: mul(3000000, RAD),
        dutyBAT: 1000000002440418608258400030,
        pctBAT: 8 * 1000,
        lineSAI: mul(30000000, RAD),
        lineGlobal: mul(183000000, RAD),
        saiCap: mul(30000000, WAD),
        saiFee: 1000000002877801985002875644,
        saiPct: 9.5 * 1000
    });

    SystemValues thisWeek = SystemValues({
        dsr: 1000000001243680656318820312,
        dsrPct: 4 * 1000,
        lineETH: mul(100000000, RAD),
        dutyETH: 1000000001243680656318820312,
        pctETH: 4 * 1000,
        lineBAT: mul(3000000, RAD),
        dutyBAT: 1000000001243680656318820312,
        pctBAT: 4 * 1000,
        lineSAI: mul(10000000, RAD),
        lineGlobal: mul(113000000, RAD),
        saiCap: mul(25000000, WAD),
        saiFee: 1000000002293273137447730714,
        saiPct: 7.5 * 1000
    });

    Hevm hevm;

    DSPauseAbstract pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    DSChiefAbstract chief =
        DSChiefAbstract(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    VatAbstract     vat = VatAbstract(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    CatAbstract     cat = CatAbstract(0x78F2c2AF65126834c51822F56Be0d7469D7A523E);
    VowAbstract     vow = VowAbstract(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
    PotAbstract     pot = PotAbstract(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    JugAbstract     jug = JugAbstract(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    MKRAbstract     gov = MKRAbstract(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    SaiTubAbstract  tub = SaiTubAbstract(0x448a5065aeBB8E423F0896E6c5D525C040f59af3);
    FlipAbstract  eflip = FlipAbstract(0xd8a04F5412223F513DC55F839574430f5EC15531);
    FlipAbstract  bflip = FlipAbstract(0xaA745404d55f88C108A28c86abE7b5A1E7817c07);
    FlopAbstract   flop = FlopAbstract(0x4D95A049d5B0b7d32058cd3F2163015747522e99);

    DssSpell spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    // not provided in DSMath
    uint constant RAD = 10 ** 45;
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
    // 10^-5 (tenth of a basis point) as a RAY
    uint256 TOLERANCE = 10 ** 22;

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

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        assembly {
        result := mload(add(source, 32))
        }
    }

    function yearlyYield(uint256 duty) public pure returns (uint256) {
        return rpow(duty, (365 * 24 * 60 *60), RAY);
    }

    function expectedRate(uint256 percentValue) public pure returns (uint256) {
        return (100000 + percentValue) * (10 ** 22);
    }

    function diffCalc(uint256 expectedRate, uint256 yearlyYield) public pure returns (uint256) {
        return (expectedRate > yearlyYield) ? expectedRate - yearlyYield : yearlyYield - expectedRate;
    }

    function testSpellIsCast() public {

        spell = MAINNET_SPELL != address(0) ? DssSpell(MAINNET_SPELL) : new DssSpell();

        // Test description
        string memory description = new SpellAction().description();
        assertTrue(bytes(description).length > 0);
        // DS-Test can't handle strings directllipTAUy, so cast to a bytes32.
        assertEq(stringToBytes32(spell.description()),
            stringToBytes32(description));

        // Test expiration
        // TODO fix this for deployed contract
        if(address(spell) != address(MAINNET_SPELL)) {
            assertEq(spell.expiration(), (now + 30 days));
        }

        // (ETH-A, BAT-A, DSR)
        (uint dutyETH,) = jug.ilks("ETH-A");
        (uint dutyBAT,) = jug.ilks("BAT-A");
        assertEq(dutyETH,   lastWeek.dutyETH);
        assertTrue(diffCalc(expectedRate(lastWeek.pctETH), yearlyYield(lastWeek.dutyETH)) <= TOLERANCE);
        assertEq(dutyBAT,   lastWeek.dutyBAT);
        assertTrue(diffCalc(expectedRate(lastWeek.pctBAT), yearlyYield(lastWeek.dutyBAT)) <= TOLERANCE);
        assertEq(pot.dsr(), lastWeek.dsr);
        assertTrue(diffCalc(expectedRate(lastWeek.dsrPct), yearlyYield(lastWeek.dsr)) <= TOLERANCE);

        // ETH-A line
        (,,, uint256 lineETH,) = vat.ilks("ETH-A");
        assertEq(lineETH, lastWeek.lineETH);

        // BAT-A line
        (,,, uint256 lineBAT,) = vat.ilks("BAT-A");
        assertEq(lineBAT, lastWeek.lineBAT);

        // SAI line
        (,,, uint256 lineSAI,) = vat.ilks("SAI");
        assertEq(lineSAI, lastWeek.lineSAI);

        // Line
        assertEq(vat.Line(), lastWeek.lineGlobal);

        // SCD DC
        assertEq(tub.cap(), lastWeek.saiCap);

        // SCD Fee
        assertEq(tub.fee(), lastWeek.saiFee);
        assertTrue(diffCalc(expectedRate(lastWeek.saiPct), yearlyYield(lastWeek.saiFee)) <= TOLERANCE);

        vote();
        scheduleWaitAndCast();

        // spell done
        assertTrue(spell.done());

        // dsr
        assertEq(pot.dsr(), thisWeek.dsr);
        assertTrue(diffCalc(expectedRate(thisWeek.dsrPct), yearlyYield(thisWeek.dsr)) <= TOLERANCE);

        // (ETH-A, BAT-A)
        (dutyETH,) = jug.ilks("ETH-A");
        (dutyBAT,) = jug.ilks("BAT-A");
        assertEq(dutyETH, thisWeek.dutyETH);
        assertTrue(diffCalc(expectedRate(thisWeek.pctETH), yearlyYield(thisWeek.dutyETH)) <= TOLERANCE);
        assertEq(dutyBAT, thisWeek.dutyBAT);
        assertTrue(diffCalc(expectedRate(thisWeek.pctETH), yearlyYield(thisWeek.dutyETH)) <= TOLERANCE);

        // ETH-A line
        (,,, lineETH,) = vat.ilks("ETH-A");
        assertEq(lineETH, thisWeek.lineETH);

        // BAT-A line
        (,,, lineBAT,) = vat.ilks("BAT-A");
        assertEq(lineBAT, thisWeek.lineBAT);

        // SAI line
        (,,, lineSAI,) = vat.ilks("SAI");
        assertEq(lineSAI, thisWeek.lineSAI);

        // Line
        assertEq(vat.Line(), thisWeek.lineGlobal);

        // SCD DC
        assertEq(tub.cap(), thisWeek.saiCap);

        // SCD Fee
        assertEq(tub.fee(), thisWeek.saiFee);
        assertTrue(diffCalc(expectedRate(thisWeek.saiPct), yearlyYield(thisWeek.saiFee)) <= TOLERANCE);

    }

    function testFlopDelay() public {
        spell = MAINNET_SPELL != address(0) ? DssSpell(MAINNET_SPELL) : new DssSpell();

        // Vow Flop Delay precheck
        assertEq(vow.wait(), 172800);

        vote();
        scheduleWaitAndCast();

        // Vow Flop Delay
        assertEq(vow.wait(), 561600);
    }

    function testFlipTTL() public {
        spell = MAINNET_SPELL != address(0) ? DssSpell(MAINNET_SPELL) : new DssSpell();

        // Vow hump amount precheck
        assertEq(uint256(eflip.ttl()), 600);
        assertEq(uint256(bflip.ttl()), 600);

        vote();
        scheduleWaitAndCast();

        // Vow hump amount
        assertEq(uint256(eflip.ttl()), 6 hours);
        assertEq(uint256(bflip.ttl()), 6 hours);
    }

    function testCatLump() public {
        spell = MAINNET_SPELL != address(0) ? DssSpell(MAINNET_SPELL) : new DssSpell();

        // Cat lump amount precheck
        (,, uint256 lump) = cat.ilks("ETH-A");
        assertEq(lump, 50 * 10**18);

        vote();
        scheduleWaitAndCast();

        // Cat lump amount
        (,, lump) = cat.ilks("ETH-A");
        assertEq(lump, 500 * 10**18);
    }

    function testFlopTTL() public {
        spell = MAINNET_SPELL != address(0) ? DssSpell(MAINNET_SPELL) : new DssSpell();

        // Vow hump amount precheck
        assertEq(uint256(flop.ttl()), 600);

        vote();
        scheduleWaitAndCast();

        // Vow hump amount
        assertEq(uint256(flop.ttl()), 6 hours);
    }
}
