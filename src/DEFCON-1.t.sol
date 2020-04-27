pragma solidity 0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssSpell, SpellAction} from "./DEFCON-1.sol";

contract Hevm { function warp(uint) public; }

contract DssSpellTest is DSTest, DSMath {

    // Replace with mainnet spell address to test against live
    address constant MAINNET_SPELL = address(0);
    uint256 constant public T2020_07_01_1200UTC = 1593604800;

    struct SystemValues {
        uint256 dsr;
        uint256 dsrPct;
        uint256 lineETH;
        uint256 dutyETH;
        uint256 pctETH;
        uint48  tauETH;
        uint256 lineUSDC;
        uint256 dutyUSDC;
        uint256 pctUSDC;
        uint48  tauUSDC;
        uint256 lineBAT;
        uint256 dutyBAT;
        uint256 pctBAT;
        uint48  tauBAT;
        uint256 lineWBTC;
        uint256 dutyWBTC;
        uint256 pctWBTC;
        uint48  tauWBTC;
        uint256 lineSAI;
        uint256 lineGlobal;
        uint256 saiCap;
        uint256 saiFee;
        uint256 saiPct;
    }

    // If last week's spell was cast successfully, you can copy the
    //  the values from that week's `afterSpell` var into this week's
    //  `beforeSpell` var. Or go back to the last successful executive.
    SystemValues beforeSpell = SystemValues({
        dsr: 1000000000000000000000000000,
        dsrPct: 0 * 1000,
        lineETH: mul(90000000, RAD),
        dutyETH: 1000000000158153903837946257,
        pctETH: 0.5 * 1000,
        tauETH: 6 hours,
        lineUSDC: mul(20000000, RAD),
        dutyUSDC: 1000000004706367499604668374,
        pctUSDC: 16 * 1000,
        tauUSDC: 3 days,
        lineBAT: mul(3000000, RAD),
        dutyBAT: 1000000000158153903837946257,
        pctBAT: 0.5 * 1000,
        tauBAT: 6 hours,
        lineWBTC: mul(3000000, RAD),
        dutyWBTC: 1000000000158153903837946257,
        pctWBTC: 0.5 * 1000,
        tauWBTC: 6 hours,
        lineSAI: mul(10000000, RAD),
        lineGlobal: mul(123000000, RAD),
        saiCap: mul(20000000, WAD),
        saiFee: 1000000002293273137447730714,
        saiPct: 7.5 * 1000
    });

    SystemValues afterSpell = SystemValues({
        dsr: 1000000000000000000000000000,
        dsrPct: 0 * 1000,
        lineETH: mul(90000000, RAD),
        dutyETH: 1000000000000000000000000000,
        pctETH: 0 * 1000,
        tauETH: 24 hours,
        lineUSDC: mul(40000000, RAD),
        dutyUSDC: 1000000012857214317438491659,
        pctUSDC: 50 * 1000,
        tauUSDC: 3 days,
        lineBAT: mul(3000000, RAD),
        dutyBAT: 1000000000000000000000000000,
        pctBAT: 0 * 1000,
        tauBAT: 24 hours,
        lineWBTC: mul(3000000, RAD),
        dutyWBTC: 1000000000000000000000000000,
        pctWBTC: 0 * 1000,
        tauWBTC: 24 hours,
        lineSAI: mul(10000000, RAD),
        lineGlobal: mul(143000000, RAD),
        saiCap: mul(20000000, WAD),
        saiFee: 1000000002293273137447730714,
        saiPct: 7.5 * 1000
    });

    Hevm hevm;

    DSPauseAbstract pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    DSChiefAbstract chief =
        DSChiefAbstract(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    VatAbstract     vat =
        VatAbstract(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    CatAbstract     cat =
        CatAbstract(0x78F2c2AF65126834c51822F56Be0d7469D7A523E);
    PotAbstract     pot =
        PotAbstract(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    JugAbstract     jug =
        JugAbstract(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    MKRAbstract     gov =
        MKRAbstract(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    SaiTubAbstract  tub =
        SaiTubAbstract(0x448a5065aeBB8E423F0896E6c5D525C040f59af3);
    FlipAbstract  eflip =
        FlipAbstract(0xd8a04F5412223F513DC55F839574430f5EC15531);
    FlipAbstract  bflip =
        FlipAbstract(0xaA745404d55f88C108A28c86abE7b5A1E7817c07);
    FlipAbstract  btcflip =
        FlipAbstract(address(0)); // TODO: Update
    FlipAbstract  uflip =
        FlipAbstract(0xE6ed1d09a19Bd335f051d78D5d22dF3bfF2c28B1);

    DssSpell spell;

    // this spell is intended to run as the MkrAuthority
    function canCall(address, address, bytes4) public pure returns (bool) {
        return true;
    }

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
        // Using the MkrAuthority test address, mint enough MKR to overcome the
        // current hat.
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

    function waitAndCast() public {
        hevm.warp(add(now, pause.delay()));
        spell.cast();
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
            assertEq(spell.expiration(), (T2020_07_01_1200UTC));
        }

        // (ETH-A, USDC-A, BAT-A, WBTC-A, DSR)
        (uint dutyETH,)  = jug.ilks("ETH-A");
        (uint dutyUSDC,) = jug.ilks("USDC-A");
        (uint dutyBAT,)  = jug.ilks("BAT-A");
        (uint dutyWBTC,)  = jug.ilks("WBTC-A");
        assertEq(dutyETH,   beforeSpell.dutyETH);
        assertTrue(diffCalc(expectedRate(beforeSpell.pctETH), yearlyYield(beforeSpell.dutyETH)) <= TOLERANCE);
        assertEq(dutyUSDC,   beforeSpell.dutyUSDC);
        assertTrue(diffCalc(expectedRate(beforeSpell.pctUSDC), yearlyYield(beforeSpell.dutyUSDC)) <= TOLERANCE);
        assertEq(dutyBAT,   beforeSpell.dutyBAT);
        assertTrue(diffCalc(expectedRate(beforeSpell.pctBAT), yearlyYield(beforeSpell.dutyBAT)) <= TOLERANCE);
        assertEq(dutyWBTC,   beforeSpell.dutyWBTC);
        assertTrue(diffCalc(expectedRate(beforeSpell.pctWBTC), yearlyYield(beforeSpell.dutyWBTC)) <= TOLERANCE);
        assertEq(pot.dsr(), beforeSpell.dsr);
        assertTrue(diffCalc(expectedRate(beforeSpell.dsrPct), yearlyYield(beforeSpell.dsr)) <= TOLERANCE);

        // ETH-A line
        (,,, uint256 lineETH,) = vat.ilks("ETH-A");
        assertEq(lineETH, beforeSpell.lineETH);

        // USDC-A line
        (,,, uint256 lineUSDC,) = vat.ilks("USDC-A");
        assertEq(lineUSDC, beforeSpell.lineUSDC);

        // BAT-A line
        (,,, uint256 lineBAT,) = vat.ilks("BAT-A");
        assertEq(lineBAT, beforeSpell.lineBAT);

        // WBTC-A line
        (,,, uint256 lineWBTC,) = vat.ilks("WBTC-A");
        assertEq(lineWBTC, beforeSpell.lineWBTC);

        // SAI line
        (,,, uint256 lineSAI,) = vat.ilks("SAI");
        assertEq(lineSAI, beforeSpell.lineSAI);

        // Line
        assertEq(vat.Line(), beforeSpell.lineGlobal);

        // SCD DC
        assertEq(tub.cap(), beforeSpell.saiCap);

        // SCD Fee
        assertEq(tub.fee(), beforeSpell.saiFee);
        assertTrue(diffCalc(expectedRate(beforeSpell.saiPct), yearlyYield(beforeSpell.saiFee)) <= TOLERANCE);

        // flip tau amount precheck
        assertEq(uint256(eflip.tau()), beforeSpell.tauETH);
        assertEq(uint256(uflip.tau()), beforeSpell.tauUSDC);
        assertEq(uint256(bflip.tau()), beforeSpell.tauBAT);
        assertEq(uint256(btcflip.tau()), beforeSpell.tauWBTC);

        vote();

        scheduleWaitAndCast();

        // spell done
        assertTrue(spell.done());

        // dsr
        assertEq(pot.dsr(), afterSpell.dsr);
        assertTrue(diffCalc(expectedRate(afterSpell.dsrPct), yearlyYield(afterSpell.dsr)) <= TOLERANCE);

        // (ETH-A, USDC-A, BAT-A, WBTC-A)
        (dutyETH,)  = jug.ilks("ETH-A");
        (dutyUSDC,) = jug.ilks("USDC-A");
        (dutyBAT,)  = jug.ilks("BAT-A");
        (dutyWBTC,) = jug.ilks("WBTC-A");
        assertEq(dutyETH, afterSpell.dutyETH);
        assertTrue(diffCalc(expectedRate(afterSpell.pctETH), yearlyYield(afterSpell.dutyETH)) <= TOLERANCE);
        assertEq(dutyUSDC, afterSpell.dutyUSDC);
        assertTrue(diffCalc(expectedRate(afterSpell.pctUSDC), yearlyYield(afterSpell.dutyUSDC)) <= TOLERANCE);
        assertEq(dutyBAT, afterSpell.dutyBAT);
        assertTrue(diffCalc(expectedRate(afterSpell.pctBAT), yearlyYield(afterSpell.dutyBAT)) <= TOLERANCE);
        assertEq(dutyWBTC, afterSpell.dutyWBTC);
        assertTrue(diffCalc(expectedRate(afterSpell.pctWBTC), yearlyYield(afterSpell.dutyWBTC)) <= TOLERANCE);

        // ETH-A line
        (,,, lineETH,) = vat.ilks("ETH-A");
        assertEq(lineETH, afterSpell.lineETH);

        // USDC-A line
        (,,, lineUSDC,) = vat.ilks("USDC-A");
        assertEq(lineUSDC, afterSpell.lineUSDC);

        // BAT-A line
        (,,, lineBAT,) = vat.ilks("BAT-A");
        assertEq(lineBAT, afterSpell.lineBAT);

        // WBTC-A line
        (,,, lineWBTC,) = vat.ilks("WBTC-A");
        assertEq(lineWBTC, afterSpell.lineWBTC);

        // SAI line
        (,,, lineSAI,) = vat.ilks("SAI");
        assertEq(lineSAI, afterSpell.lineSAI);

        // Line
        assertEq(vat.Line(), afterSpell.lineGlobal);

        // SCD DC
        assertEq(tub.cap(), afterSpell.saiCap);

        // SCD Fee
        assertEq(tub.fee(), afterSpell.saiFee);
        assertTrue(diffCalc(expectedRate(afterSpell.saiPct), yearlyYield(afterSpell.saiFee)) <= TOLERANCE);

        // flip tau amount
        assertEq(uint256(eflip.tau()), afterSpell.tauETH);
        assertEq(uint256(uflip.tau()), afterSpell.tauUSDC);
        assertEq(uint256(bflip.tau()), afterSpell.tauBAT);
        assertEq(uint256(btcflip.tau()), afterSpell.tauwbtc);

    }

    function testCircuitBreaker() public {
        spell = MAINNET_SPELL != address(0) ?
            DssSpell(MAINNET_SPELL) : new DssSpell();

        // collateral liquidations enabled/disabled
        assertEq(eflip.wards(address(cat)), 1);
        assertEq(bflip.wards(address(cat)), 1);
        assertEq(btcflip.wards(address(cat)), 1);
        assertEq(uflip.wards(address(cat)), 0);

        vote();
        spell.schedule();

        // collateral liquidations enabled/disabled
        assertEq(eflip.wards(address(cat)), 0);
        assertEq(bflip.wards(address(cat)), 0);
        assertEq(btcflip.wards(address(cat)), 0);
        assertEq(uflip.wards(address(cat)), 0);

        waitAndCast();

        // collateral liquidations enabled/disabled
        assertEq(eflip.wards(address(cat)), 1);
        assertEq(bflip.wards(address(cat)), 1);
        assertEq(btcflip.wards(address(cat)), 1);
        assertEq(uflip.wards(address(cat)), 0);
    }

}
