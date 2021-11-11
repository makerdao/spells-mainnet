pragma solidity 0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssSpell} from "./DssSpell.sol";

contract Hevm {
    function warp(uint256) public;
}

contract FlipMomLike {
    function setOwner(address) external;
    function setAuthority(address) external;
    function rely(address) external;
    function deny(address) external;
    function authority() public returns (address);
    function owner() public returns (address);
    function cat() public returns (address);
}

contract DssSpellTest is DSTest, DSMath {
    // populate with mainnet spell if needed
    address constant MAINNET_SPELL = address(0xd77ad957fcF536d13A17f5D1FfFA3987F83376cf);

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
        uint256 pauseDelay;
    }

    // If last week's spell was cast successfully, you can copy the
    //  the values from that week's `thisWeek` var into this week's
    //  `lastWeek` var. Or go back to the last successful executive.
    SystemValues lastWeek = SystemValues({
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
        saiPct: 7.5 * 1000,
        pauseDelay: 60 * 60 * 24
    });

    SystemValues thisWeek = SystemValues({
        dsr: 1000000000000000000000000000,
        dsrPct: 0 * 1000,
        lineETH: mul(100000000, RAD),
        dutyETH: 1000000000158153903837946257,
        pctETH: 0.5 * 1000,
        lineBAT: mul(3000000, RAD),
        dutyBAT: 1000000000158153903837946257,
        pctBAT: 0.5 * 1000,
        lineSAI: mul(10000000, RAD),
        lineGlobal: mul(113000000, RAD),
        saiCap: mul(20000000, WAD),
        saiFee: 1000000002293273137447730714,
        saiPct: 7.5 * 1000,
        pauseDelay: 60 * 60 * 4
    });

    Hevm hevm;

    // MAINNET ADDRESSES
    DSPauseAbstract pause   = DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address pauseProxy      = 0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
    DSChiefAbstract chief   = DSChiefAbstract(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    VatAbstract     vat     = VatAbstract(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    CatAbstract     cat     = CatAbstract(0x78F2c2AF65126834c51822F56Be0d7469D7A523E);
    VowAbstract     vow     = VowAbstract(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
    PotAbstract     pot     = PotAbstract(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    JugAbstract     jug     = JugAbstract(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    MKRAbstract     gov     = MKRAbstract(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    SaiTubAbstract  tub     = SaiTubAbstract(0x448a5065aeBB8E423F0896E6c5D525C040f59af3);
    FlipAbstract  eflip     = FlipAbstract(0xd8a04F5412223F513DC55F839574430f5EC15531);
    FlipAbstract  bflip     = FlipAbstract(0xaA745404d55f88C108A28c86abE7b5A1E7817c07);
    FlopAbstract   flop     = FlopAbstract(0x4D95A049d5B0b7d32058cd3F2163015747522e99);
    address  flipperMom     = 0x9BdDB99625A711bf9bda237044924E34E8570f75;

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

    function yearlyYield(uint256 duty) public pure returns (uint256) {
        return rpow(duty, (365 * 24 * 60 *60), RAY);
    }

    function expectedRate(uint256 percentValue) public pure returns (uint256) {
        return (100000 + percentValue) * (10 ** 22);
    }

    function diffCalc(uint256 expectedRate_, uint256 yearlyYield_) public pure returns (uint256) {
        return (expectedRate_ > yearlyYield_) ? expectedRate_ - yearlyYield_ : yearlyYield_ - expectedRate_;
    }

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        gov.mint(address(this), 300000 ether);

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
        hevm.warp(add(now, pause.delay()));
        spell.cast();
    }

    function testSpellIsCast() public {
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

        // Pause Delay
        assertEq(pause.delay(), lastWeek.pauseDelay);

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

        // Pause Delay
        assertEq(pause.delay(), thisWeek.pauseDelay);
    }

    function testWards() public {
        vote();
        scheduleWaitAndCast();

        assertEq(FlipMomLike(flipperMom).authority(), address(chief));
        assertEq(FlipMomLike(flipperMom).owner(), pauseProxy);
        assertEq(eflip.wards(flipperMom), 1);
        assertEq(bflip.wards(flipperMom), 1);
    }

    function testFailOnSetOwner() public {
        vote();
        scheduleWaitAndCast();

        FlipMomLike(flipperMom).setOwner(address(this));
    }

    function testFailOnSetAuthority() public {
        vote();
        scheduleWaitAndCast();

        FlipMomLike(flipperMom).setAuthority(address(this));
    }

    function testFailOnUnAuthRely_ETH_A() public {
        vote();
        scheduleWaitAndCast();

        FlipMomLike(flipperMom).rely(address(eflip));
    }

    function testFailOnUnAuthRely_BAT_A() public {
        vote();
        scheduleWaitAndCast();

        FlipMomLike(flipperMom).rely(address(bflip));
    }

    function testFailOnUnAuthDeny_ETH_A() public {
        vote();
        scheduleWaitAndCast();

        FlipMomLike(flipperMom).deny(address(eflip));
    }

    function testFailOnUnAuthDeny_BAT_A() public {
        vote();
        scheduleWaitAndCast();

        FlipMomLike(flipperMom).deny(address(bflip));
    }

    function testMomActuallyWorks() public {
        vote();
        scheduleWaitAndCast();

        address[] memory yays = new address[](1);
        yays[0] = address(this);
        chief.vote(yays);

        // become the hat
        chief.lift(address(this));

        assertEq(address(cat), FlipMomLike(flipperMom).cat());

        assertEq(eflip.wards(address(cat)), 1);
        FlipMomLike(flipperMom).deny(address(eflip));
        assertEq(eflip.wards(address(cat)), 0);
        FlipMomLike(flipperMom).rely(address(eflip));
        assertEq(eflip.wards(address(cat)), 1);

        assertEq(bflip.wards(address(cat)), 1);
        FlipMomLike(flipperMom).deny(address(bflip));
        assertEq(bflip.wards(address(cat)), 0);
        FlipMomLike(flipperMom).rely(address(bflip));
        assertEq(bflip.wards(address(cat)), 1);
    }
}
