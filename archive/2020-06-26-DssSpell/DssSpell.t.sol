pragma solidity 0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssSpell, SpellAction} from "./2020-06-26-DssSpell.sol";

contract Hevm {
    function warp(uint256) public;
}

contract MedianAbstract {
    function bud(address) public view returns (uint256);
}

contract DssSpellTest is DSTest, DSMath {
    // populate with mainnet spell if needed
    address constant MAINNET_SPELL = 0x9Ef95251233e0586bf3b17F14D31E2A756454a0D;
    uint256 constant SPELL_CREATED = 1593184883;

    struct CollateralValues {
        uint256 line;
        uint256 dust;
        uint256 duty;
        uint256 chop;
        uint256 lump;
        uint256 pct;
        uint256 mat;
        uint256 beg;
        uint48 ttl;
        uint48 tau;
    }

    struct SystemValues {
        uint256 dsr;
        uint256 dsrPct;
        uint256 Line;
        uint256 pauseDelay;
        mapping (bytes32 => CollateralValues) collaterals;
    }

    SystemValues beforeSpell;
    SystemValues afterSpell;

    Hevm hevm;

    // MAINNET ADDRESSES
    DSPauseAbstract pause       = DSPauseAbstract(  0xbE286431454714F511008713973d3B053A2d38f3);
    address pauseProxy          =                   0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
    DSChiefAbstract chief       = DSChiefAbstract(  0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    VatAbstract     vat         = VatAbstract(      0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    CatAbstract     cat         = CatAbstract(      0x78F2c2AF65126834c51822F56Be0d7469D7A523E);
    PotAbstract     pot         = PotAbstract(      0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    JugAbstract     jug         = JugAbstract(      0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    SpotAbstract    spot        = SpotAbstract(     0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);
    MKRAbstract     gov         = MKRAbstract(      0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    FlipAbstract    zFlip       = FlipAbstract(     0x08c89251FC058cC97d5bA5F06F95026C0A5CF9B0);
    GemJoinAbstract zJoin       = GemJoinAbstract(  0xc7e8Cd72BDEe38865b4F5615956eF47ce1a7e5D0);
    OsmAbstract     zPip        = OsmAbstract(      0x7382c066801E7Acb2299aC8562847B9883f5CD3c);
    FlipAbstract    kFlip       = FlipAbstract(     0xAbBCB9Ae89cDD3C27E02D279480C7fF33083249b);
    GemJoinAbstract kJoin       = GemJoinAbstract(  0x475F1a89C1ED844A08E8f6C50A00228b5E59E4A9);
    OsmAbstract     kPip        = OsmAbstract(      0xf36B79BD4C0904A5F350F1e4f776B81208c13069);
    EndAbstract     end         = EndAbstract(      0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5);
    address  flipperMom         =                   0x9BdDB99625A711bf9bda237044924E34E8570f75;
    address  osmMom             =                   0x76416A4d5190d071bfed309861527431304aA14f;

    FlipAbstract    saiflip =
        FlipAbstract(0x5432b2f3c0DFf95AA191C45E5cbd539E2820aE72);
    GemJoinAbstract saijoin =
        GemJoinAbstract(0xad37fd42185Ba63009177058208dd1be4b136e6b);

    DssSpell spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));
    
    uint256 constant THOUSAND   = 10 ** 3;
    uint256 constant MILLION    = 10 ** 6;
    uint256 constant WAD        = 10 ** 18;
    uint256 constant RAY        = 10 ** 27;
    uint256 constant RAD        = 10 ** 45;

    // not provided in DSMath
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

        spell = MAINNET_SPELL != address(0) ? DssSpell(MAINNET_SPELL) : new DssSpell();

        // Using the MkrAuthority test address, mint enough MKR to overcome the
        // current hat.
        gov.mint(address(this), 300000 ether);

        beforeSpell = SystemValues({
            dsr: 1000000000000000000000000000,
            dsrPct: 0 * 1000,
            Line: 185 * MILLION * RAD,
            pauseDelay: 12 * 60 * 60
        });

        beforeSpell.collaterals["ETH-A"] = CollateralValues({
            line: 140 * MILLION * RAD,
            dust: 20 * RAD,
            duty: 1000000000000000000000000000,
            pct: 0 * 1000,
            chop: 113 * RAY / 100,
            lump: 500 * WAD,
            mat: 150 * RAY / 100,
            beg: 103 * WAD / 100,
            ttl: 6 hours,
            tau: 6 hours
        });
        beforeSpell.collaterals["BAT-A"] = CollateralValues({
            line: 3 * MILLION * RAD,
            dust: 20 * RAD,
            duty: 1000000000000000000000000000,
            pct: 0 * 1000,
            chop: 113 * RAY / 100,
            lump: 50 * THOUSAND * WAD,
            mat: 150 * RAY / 100,
            beg: 103 * WAD / 100,
            ttl: 6 hours,
            tau: 6 hours
        });
        beforeSpell.collaterals["USDC-A"] = CollateralValues({
            line: 20 * MILLION * RAD,
            dust: 20 * RAD,
            duty: 1000000000236936036262880196,
            pct: 0.75 * 1000,
            chop: 113 * RAY / 100,
            lump: 50 * THOUSAND * WAD,
            mat: 120 * RAY / 100,
            beg: 103 * WAD / 100,
            ttl: 6 hours,
            tau: 3 days 
        });
        beforeSpell.collaterals["USDC-B"] = CollateralValues({
            line: 10 * MILLION * RAD,
            dust: 20 * RAD,
            duty: 1000000012857214317438491659,
            pct: 50 * 1000,
            chop: 113 * RAY / 100,
            lump: 50 * THOUSAND * WAD,
            mat: 120 * RAY / 100,
            beg: 103 * WAD / 100,
            ttl: 6 hours,
            tau: 3 days
        });
        beforeSpell.collaterals["WBTC-A"] = CollateralValues({
            line: 10 * MILLION * RAD,
            dust: 20 * RAD,
            duty: 1000000000315522921573372069,
            pct: 1 * 1000,
            chop: 113 * RAY / 100,
            lump: 1 * WAD,
            mat: 150 * RAY / 100,
            beg: 103 * WAD / 100,
            ttl: 6 hours,
            tau: 6 hours
        });
        beforeSpell.collaterals["TUSD-A"] = CollateralValues({
            line: 2 * MILLION * RAD,
            dust: 20 * RAD,
            duty: 1000000000000000000000000000,
            pct: 0 * 1000,
            chop: 113 * RAY / 100,
            lump: 50 * THOUSAND * WAD,
            mat: 120 * RAY / 100,
            beg: 103 * WAD / 100,
            ttl: 6 hours,
            tau: 3 days
        });

        afterSpell = SystemValues({
            dsr: 1000000000000000000000000000,
            dsrPct: 0 * 1000,
            Line: 195 * MILLION * RAD,
            pauseDelay: 12 * 60 * 60
        });
        afterSpell.collaterals["ETH-A"] = beforeSpell.collaterals["ETH-A"];
        afterSpell.collaterals["ETH-A"].duty = 1000000000079175551708715274;
        afterSpell.collaterals["ETH-A"].pct = 0.25 * 1000;
        afterSpell.collaterals["BAT-A"] = beforeSpell.collaterals["BAT-A"];
        afterSpell.collaterals["BAT-A"].duty = 1000000000079175551708715274;
        afterSpell.collaterals["BAT-A"].pct = 0.25 * 1000;
        afterSpell.collaterals["USDC-A"] = beforeSpell.collaterals["USDC-A"];
        afterSpell.collaterals["USDC-A"].duty = 1000000000315522921573372069;
        afterSpell.collaterals["USDC-A"].pct = 1 * 1000;
        afterSpell.collaterals["USDC-B"] = beforeSpell.collaterals["USDC-B"];
        afterSpell.collaterals["USDC-B"].duty = 1000000012910019978921115695;
        afterSpell.collaterals["USDC-B"].pct = 50.25 * 1000;
        afterSpell.collaterals["WBTC-A"] = beforeSpell.collaterals["WBTC-A"];
        afterSpell.collaterals["WBTC-A"].duty = 1000000000393915525145987602;
        afterSpell.collaterals["WBTC-A"].pct = 1.25 * 1000;
        afterSpell.collaterals["TUSD-A"] = beforeSpell.collaterals["TUSD-A"];
        afterSpell.collaterals["TUSD-A"].duty = 1000000000079175551708715274;
        afterSpell.collaterals["TUSD-A"].pct = 0.25 * 1000;

        afterSpell.collaterals["KNC-A"] = CollateralValues({
            line: 5 * MILLION * RAD,
            dust: 20 * RAD,
            duty: 1000000001319814647332759691,
            pct: 4.25 * 1000,
            chop: 113 * RAY / 100,
            lump: 50000 * WAD,
            mat: 175 * RAY / 100,
            beg: 103 * WAD / 100,
            ttl: 6 hours,
            tau: 6 hours
        });
        afterSpell.collaterals["ZRX-A"] = CollateralValues({
            line: 5 * MILLION * RAD,
            dust: 20 * RAD,
            duty: 1000000001319814647332759691,
            pct: 4.25 * 1000,
            chop: 113 * RAY / 100,
            lump: 100000 * WAD,
            mat: 175 * RAY / 100,
            beg: 103 * WAD / 100,
            ttl: 6 hours,
            tau: 6 hours
        });
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

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function checkSystemValues(SystemValues storage values) internal {
        // dsr
        assertEq(pot.dsr(), values.dsr);
        assertTrue(diffCalc(expectedRate(values.dsrPct), yearlyYield(values.dsr)) <= TOLERANCE);

        // Line
        assertEq(vat.Line(), values.Line);

        // Pause delay
        assertEq(pause.delay(), values.pauseDelay);
                        
    }

    function checkCollateralValues(bytes32 ilk, SystemValues storage values) internal {
        (uint duty,)  = jug.ilks(ilk);
        assertEq(duty,   values.collaterals[ilk].duty);
        assertTrue(diffCalc(expectedRate(values.collaterals[ilk].pct), yearlyYield(values.collaterals[ilk].duty)) <= TOLERANCE);

        (,,, uint256 line, uint256 dust) = vat.ilks(ilk);
        assertEq(line, values.collaterals[ilk].line);
        assertEq(dust, values.collaterals[ilk].dust);

        (, uint256 chop, uint256 lump) = cat.ilks(ilk);
        assertEq(chop, values.collaterals[ilk].chop);
        assertEq(lump, values.collaterals[ilk].lump);

        (,uint256 mat) = spot.ilks(ilk);
        assertEq(mat, values.collaterals[ilk].mat);

        (address flipper,,) = cat.ilks(ilk);
        FlipAbstract flip = FlipAbstract(flipper);
        assertEq(uint256(flip.beg()), values.collaterals[ilk].beg);
        assertEq(uint256(flip.ttl()), values.collaterals[ilk].ttl);
        assertEq(uint256(flip.tau()), values.collaterals[ilk].tau);
    }

    // this spell is intended to run as the MkrAuthority
    function canCall(address, address, bytes4) public pure returns (bool) {
        return true;
    }

    function testSpellIsCast() public {
        string memory description = new SpellAction().description();
        assertTrue(bytes(description).length > 0);
        // DS-Test can't handle strings directly, so cast to a bytes32.
        assertEq(stringToBytes32(spell.description()),
                stringToBytes32(description));

        if(address(spell) != address(MAINNET_SPELL)) {
            assertEq(spell.expiration(), (now + 30 days));
        } else {
            assertEq(spell.expiration(), (SPELL_CREATED + 30 days));
        }

        checkSystemValues(beforeSpell);

        checkCollateralValues("ETH-A", beforeSpell);
        checkCollateralValues("BAT-A", beforeSpell);
        checkCollateralValues("USDC-A", beforeSpell);
        checkCollateralValues("USDC-B", beforeSpell);
        checkCollateralValues("WBTC-A", beforeSpell);
        checkCollateralValues("TUSD-A", beforeSpell);

        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());
        checkSystemValues(afterSpell);

        checkCollateralValues("ETH-A", afterSpell);
        checkCollateralValues("BAT-A", afterSpell);
        checkCollateralValues("USDC-A", afterSpell);
        checkCollateralValues("USDC-B", afterSpell);
        checkCollateralValues("WBTC-A", afterSpell);
        checkCollateralValues("TUSD-A", afterSpell);
        checkCollateralValues("ZRX-A", afterSpell);
        checkCollateralValues("KNC-A", afterSpell);
    }

    function testSaiRemoval() public {
        bytes32 ilk = "SAI";
        (address spip, uint256 smat) = spot.ilks(ilk);
        assertEq(spip, 0x54003DBf6ae6CBa6DDaE571CcdC34d834b44Ab1e);

        (address sflip, uint256 cchop, uint256 clump) = cat.ilks(ilk);
        assertEq(sflip, address(saiflip));

        (uint256 vArt, uint256 vrate, uint256 vspot, uint256 vline, uint256 vdust)
          = vat.ilks(ilk);

        (uint256 jduty, uint256 jrho) = jug.ilks(ilk);
        // These are already 0 due to previous actions,
        //   they probabaly don't need to be called.
        assertEq(vline, 0);
        assertEq(vdust, 0);

        assertEq(saijoin.live(), 1);

        assertEq(vat.wards(address(saijoin)), 1);
        assertEq(saiflip.wards(address(cat)), 1);
        assertEq(saiflip.wards(address(end)), 1);
        assertEq(saiflip.wards(flipperMom), 0);

        vote();
        scheduleWaitAndCast();

        (spip, smat) = spot.ilks(ilk);
        assertEq(spip, address(0));
        assertEq(smat, 0);

        (sflip, cchop, clump) = cat.ilks(ilk);
        assertEq(sflip, address(0));
        assertEq(cchop, 0);
        assertEq(clump, 0);

        (vArt, vrate, vspot, vline, vdust) = vat.ilks(ilk);
        assertEq(vline, 0);
        assertEq(vdust, 0);
        assertEq(vspot, 0);

        (jduty, jrho) = jug.ilks(ilk);
        assertEq(jduty, 0);

        assertEq(saijoin.live(), 0);

        assertEq(vat.wards(address(saijoin)), 0);
        assertEq(saiflip.wards(address(cat)), 0);
        assertEq(saiflip.wards(address(end)), 0);
        assertEq(saiflip.wards(flipperMom), 0);
    }

    function testNewCollateralKNC() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        // Authorization
        assertEq(kJoin.wards(pauseProxy), 1);
        assertEq(vat.wards(address(kJoin)), 1);
        assertEq(kFlip.wards(address(cat)), 1);
        assertEq(kFlip.wards(address(end)), 1);
        assertEq(kFlip.wards(flipperMom), 1);
        assertEq(kPip.wards(osmMom), 1);
        assertEq(kPip.bud(address(spot)), 1);
        assertEq(kPip.bud(address(end)), 1);
        assertEq(MedianAbstract(kPip.src()).bud(address(kPip)), 1);
    }

    function testNewCollateralZRX() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        // Authorization
        assertEq(zJoin.wards(pauseProxy), 1);
        assertEq(vat.wards(address(zJoin)), 1);
        assertEq(zFlip.wards(address(cat)), 1);
        assertEq(zFlip.wards(address(end)), 1);
        assertEq(zFlip.wards(flipperMom), 1);
        assertEq(zPip.wards(osmMom), 1);
        assertEq(zPip.bud(address(spot)), 1);
        assertEq(zPip.bud(address(end)), 1);
        assertEq(MedianAbstract(zPip.src()).bud(address(zPip)), 1);
    }
}
