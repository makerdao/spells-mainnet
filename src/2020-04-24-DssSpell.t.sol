// Copyright (C) 2020, The Maker Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssSpell, SpellAction} from "./2020-04-24-DssSpell.sol";

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
        uint256 matETH;
        uint48  tauETH;
        uint256 lineUSDC;
        uint256 dutyUSDC;
        uint256 pctUSDC;
        uint256 matUSDC;
        uint48  tauUSDC;
        uint256 lineBAT;
        uint256 dutyBAT;
        uint256 pctBAT;
        uint256 matBAT;
        uint48  tauBAT;
        uint256 lineSAI;
        uint256 lineGlobal;
        uint256 saiCap;
        uint256 saiFee;
        uint256 saiPct;
        uint256 pauseDelay;
    }

    // If last week's spell was cast successfully, you can copy the
    //  the values from that week's `afterSpell` var into this week's
    //  `beforeSpell` var. Or go back to the last successful executive.
    SystemValues beforeSpell = SystemValues({
        dsr: 1000000000000000000000000000,
        dsrPct: 0 * 1000,
        lineETH: mul(90000000, RAD),
        dutyETH: 1000000000000000000000000000,
        pctETH: 0 * 1000,
        matETH: mul(150, RAY) / 100,
        tauETH: 6 hours,
        lineUSDC: mul(20000000, RAD),
        dutyUSDC: 1000000002440418608258400030,
        pctUSDC: 8 * 1000,
        matUSDC: mul(125, RAY) / 100,
        tauUSDC: 3 days,
        lineBAT: mul(3000000, RAD),
        dutyBAT: 1000000000000000000000000000,
        pctBAT: 0 * 1000,
        matBAT: mul(150, RAY) / 100,
        tauBAT: 6 hours,
        lineSAI: mul(0, RAD),
        lineGlobal: mul(113000000, RAD),
        saiCap: mul(20000000, WAD),
        saiFee: 1000000002586884420913935572,
        saiPct: 8.5 * 1000,
        pauseDelay: 4 * 60 * 60
    });

    SystemValues afterSpell = SystemValues({
        dsr: 1000000000000000000000000000,
        dsrPct: 0 * 1000,
        lineETH: mul(100000000, RAD),
        dutyETH: 1000000000000000000000000000,
        pctETH: 0 * 1000,
        matETH: mul(150, RAY) / 100,
        tauETH: 6 hours,
        lineUSDC: mul(20000000, RAD),
        dutyUSDC: 1000000001847694957439350562,
        pctUSDC: 6 * 1000,
        matUSDC: mul(120, RAY) / 100,
        tauUSDC: 3 days,
        lineBAT: mul(3000000, RAD),
        dutyBAT: 1000000000000000000000000000,
        pctBAT: 0 * 1000,
        matBAT: mul(150, RAY) / 100,
        tauBAT: 6 hours,
        lineSAI: mul(0, RAD),
        lineGlobal: mul(123000000, RAD),
        saiCap: mul(20000000, WAD),
        saiFee: 1000000002586884420913935572,
        saiPct: 8.5 * 1000,
        pauseDelay: 12 * 60 * 60
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
    SpotAbstract   spot =
        SpotAbstract(0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);
    MKRAbstract     gov =
        MKRAbstract(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    SaiTubAbstract  tub =
        SaiTubAbstract(0x448a5065aeBB8E423F0896E6c5D525C040f59af3);
    FlipAbstract  eflip =
        FlipAbstract(0xd8a04F5412223F513DC55F839574430f5EC15531);
    FlipAbstract  bflip =
        FlipAbstract(0xaA745404d55f88C108A28c86abE7b5A1E7817c07);
    FlipAbstract  uflip =
        FlipAbstract(0xE6ed1d09a19Bd335f051d78D5d22dF3bfF2c28B1);
    SaiTopAbstract  top =
        SaiTopAbstract(0x9b0ccf7C8994E19F39b2B4CF708e0A7DF65fA8a3);
    OsmAbstract     ethusd = 
        OsmAbstract(0x64DE91F5A373Cd4c28de3600cB34C7C6cE410C85);
    OsmAbstract     btcusd = 
        OsmAbstract(0xe0F30cb149fAADC7247E953746Be9BbBB6B5751f);

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

    function diffCalc(uint256 expectedRate_, uint256 yearlyYield_) public pure returns (uint256) {
        return (expectedRate_ > yearlyYield_) ? expectedRate_ - yearlyYield_ : yearlyYield_ - expectedRate_;
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

        // (ETH-A, USDC-A, BAT-A, DSR)
        (uint dutyETH,)  = jug.ilks("ETH-A");
        (uint dutyUSDC,) = jug.ilks("USDC-A");
        (uint dutyBAT,)  = jug.ilks("BAT-A");
        assertEq(dutyETH,   beforeSpell.dutyETH);
        assertTrue(diffCalc(expectedRate(beforeSpell.pctETH), yearlyYield(beforeSpell.dutyETH)) <= TOLERANCE);
        assertEq(dutyUSDC,   beforeSpell.dutyUSDC);
        assertTrue(diffCalc(expectedRate(beforeSpell.pctUSDC), yearlyYield(beforeSpell.dutyUSDC)) <= TOLERANCE);
        assertEq(dutyBAT,   beforeSpell.dutyBAT);
        assertTrue(diffCalc(expectedRate(beforeSpell.pctBAT), yearlyYield(beforeSpell.dutyBAT)) <= TOLERANCE);
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

        // SAI line
        (,,, uint256 lineSAI,) = vat.ilks("SAI");
        assertEq(lineSAI, beforeSpell.lineSAI);

        // Line
        assertEq(vat.Line(), beforeSpell.lineGlobal);

        // ETH-A mat
        (,uint256 matETH) = spot.ilks("ETH-A");
        assertEq(matETH, beforeSpell.matETH);

        // USDC-A mat
        (,uint256 matUSDC) = spot.ilks("USDC-A");
        assertEq(matUSDC, beforeSpell.matUSDC);

        // BAT-A mat
        (,uint256 matBAT) = spot.ilks("BAT-A");
        assertEq(matBAT, beforeSpell.matBAT);

        // SCD DC
        assertEq(tub.cap(), beforeSpell.saiCap);

        // SCD Fee
        assertEq(tub.fee(), beforeSpell.saiFee);
        assertTrue(diffCalc(expectedRate(beforeSpell.saiPct), yearlyYield(beforeSpell.saiFee)) <= TOLERANCE);

        // flip tau amount precheck
        assertEq(uint256(eflip.tau()), beforeSpell.tauETH);
        assertEq(uint256(uflip.tau()), beforeSpell.tauUSDC);
        assertEq(uint256(bflip.tau()), beforeSpell.tauBAT);

        // Pause delay
        assertEq(pause.delay(), beforeSpell.pauseDelay);

        // Oracles
        assertEq(ethusd.bud(0x97C3e595e8f80169266B5534e4d7A1bB58BB45ab), 0);
        assertEq(btcusd.bud(0xbf63446ecF3341e04c6569b226a57860B188edBc), 0);
        assertEq(btcusd.bud(0x538038E526517680735568f9C5342c6E68bbDA12), 0);

        vote();

        scheduleWaitAndCast();

        // spell done
        assertTrue(spell.done());

        // dsr
        assertEq(pot.dsr(), afterSpell.dsr);
        assertTrue(diffCalc(expectedRate(afterSpell.dsrPct), yearlyYield(afterSpell.dsr)) <= TOLERANCE);

        // (ETH-A, USDC-A, BAT-A)
        (dutyETH,)  = jug.ilks("ETH-A");
        (dutyUSDC,) = jug.ilks("USDC-A");
        (dutyBAT,)  = jug.ilks("BAT-A");
        assertEq(dutyETH, afterSpell.dutyETH);
        assertTrue(diffCalc(expectedRate(afterSpell.pctETH), yearlyYield(afterSpell.dutyETH)) <= TOLERANCE);
        assertEq(dutyUSDC, afterSpell.dutyUSDC);
        assertTrue(diffCalc(expectedRate(afterSpell.pctUSDC), yearlyYield(afterSpell.dutyUSDC)) <= TOLERANCE);
        assertEq(dutyBAT, afterSpell.dutyBAT);
        assertTrue(diffCalc(expectedRate(afterSpell.pctBAT), yearlyYield(afterSpell.dutyBAT)) <= TOLERANCE);

        // ETH-A line
        (,,, lineETH,) = vat.ilks("ETH-A");
        assertEq(lineETH, afterSpell.lineETH);

        // USDC-A line
        (,,, lineUSDC,) = vat.ilks("USDC-A");
        assertEq(lineUSDC, afterSpell.lineUSDC);

        // BAT-A line
        (,,, lineBAT,) = vat.ilks("BAT-A");
        assertEq(lineBAT, afterSpell.lineBAT);

        // SAI line
        (,,, lineSAI,) = vat.ilks("SAI");
        assertEq(lineSAI, afterSpell.lineSAI);

        // Line
        assertEq(vat.Line(), afterSpell.lineGlobal);

        // ETH-A mat
        (, matETH) = spot.ilks("ETH-A");
        assertEq(matETH, afterSpell.matETH);

        // USDC-A mat
        (, matUSDC) = spot.ilks("USDC-A");
        assertEq(matUSDC, afterSpell.matUSDC);

        // BAT-A mat
        (, matBAT) = spot.ilks("BAT-A");
        assertEq(matBAT, afterSpell.matBAT);

        // SCD DC
        assertEq(tub.cap(), afterSpell.saiCap);

        // SCD Fee
        assertEq(tub.fee(), afterSpell.saiFee);
        assertTrue(diffCalc(expectedRate(afterSpell.saiPct), yearlyYield(afterSpell.saiFee)) <= TOLERANCE);

        // Pause delay
        assertEq(pause.delay(), afterSpell.pauseDelay);

        // Oracles
        assertEq(ethusd.bud(0x97C3e595e8f80169266B5534e4d7A1bB58BB45ab), 1);
        assertEq(btcusd.bud(0xbf63446ecF3341e04c6569b226a57860B188edBc), 1);
        assertEq(btcusd.bud(0x538038E526517680735568f9C5342c6E68bbDA12), 1);

        // flip tau amount
        assertEq(uint256(eflip.tau()), afterSpell.tauETH);
        assertEq(uint256(uflip.tau()), afterSpell.tauUSDC);
        assertEq(uint256(bflip.tau()), afterSpell.tauBAT);
    }

    function testSaiSlayer() public {
        spell = MAINNET_SPELL != address(0) ?
            DssSpell(MAINNET_SPELL) : new DssSpell();
        
        vote();
        assertEq(top.owner(), address(0));
        spell.schedule();
        assertEq(top.owner(), address(spell.saiSlayer()));
        
        hevm.warp(1589299200);

        assertEq(top.caged(), 0);
        spell.saiSlayer().cage();
        assertEq(top.caged(), now);
    }

    function testFailSaiSlayerNoTimePassed() public {
        spell = MAINNET_SPELL != address(0) ?
            DssSpell(MAINNET_SPELL) : new DssSpell();
        
        vote();
        assertEq(top.owner(), address(0));
        spell.schedule();
        assertEq(top.owner(), address(spell.saiSlayer()));
        
        hevm.warp(1589299199);

        spell.saiSlayer().cage();
    }

    function testFailSaiSlayerNoOwnership() public {
        spell = MAINNET_SPELL != address(0) ?
            DssSpell(MAINNET_SPELL) : new DssSpell();
        
        hevm.warp(1589299200);

        spell.saiSlayer().cage();
    }

    function testNewMKRFeed() public {
        spell = MAINNET_SPELL != address(0) ?
            DssSpell(MAINNET_SPELL) : new DssSpell();

        vote();
        assertEq(tub.pep(), 0x99041F808D598B782D5a3e498681C2452A31da08);
        spell.schedule();
        assertEq(tub.pep(), address(spell.newMkrOracle()));
    }
}
