pragma solidity 0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";
import "lib/dss-interfaces/src/dss/MKRAbstract.sol";

import {DssSpell, SpellAction} from "./2020-08-07-DssSpell.sol";

contract Hevm {
    function warp(uint256) public;
    function store(address,bytes32,bytes32) public;
}

contract DssSpellTest is DSTest, DSMath {
    // populate with mainnet spell if needed
    address constant MAINNET_SPELL = address(0);
    uint256 constant SPELL_CREATED = 1596746308;

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
    DSPauseAbstract      pause = DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address         pauseProxy =                 0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
    DSChiefAbstract      chief = DSChiefAbstract(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    VatAbstract            vat = VatAbstract(    0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    CatAbstract            cat = CatAbstract(    0x78F2c2AF65126834c51822F56Be0d7469D7A523E);
    PotAbstract            pot = PotAbstract(    0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    JugAbstract            jug = JugAbstract(    0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    SpotAbstract          spot = SpotAbstract(   0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);

    FlipAbstract   tusd_a_flip = FlipAbstract(   0x04C42fAC3e29Fd27118609a5c36fD0b3Cb8090b3);

    DSTokenAbstract        gov = DSTokenAbstract(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    EndAbstract            end = EndAbstract(    0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5);
    DSTokenAbstract       weth = DSTokenAbstract(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    GemJoinAbstract   wethJoin = GemJoinAbstract(0x2F0b23f53734252Bda2277357e97e1517d6B042A);


    DssSpell spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    // Not provided in DSMath
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

        beforeSpell = SystemValues({
            dsr: 1000000000000000000000000000,
            dsrPct: 0 * 1000,
            Line: 568 * MILLION * RAD,
            pauseDelay: 12 * 60 * 60
        });

        beforeSpell.collaterals["ETH-A"] = CollateralValues({
            line: 340 * MILLION * RAD,
            dust: 20 * RAD,
            duty: 1000000000000000000000000000,
            pct:  0 * 1000,
            chop: 113 * RAY / 100,
            lump: 500 * WAD,
            mat:  150 * RAY / 100,
            beg:  103 * WAD / 100,
            ttl:  6 hours,
            tau:  6 hours
        });
        beforeSpell.collaterals["BAT-A"] = CollateralValues({
            line: 5 * MILLION * RAD,
            dust: 20 * RAD,
            duty: 1000000000000000000000000000,
            pct:  0 * 1000,
            chop: 113 * RAY / 100,
            lump: 50 * THOUSAND * WAD,
            mat:  150 * RAY / 100,
            beg:  103 * WAD / 100,
            ttl:  6 hours,
            tau:  6 hours
        });
        beforeSpell.collaterals["USDC-A"] = CollateralValues({
            line: 140 * MILLION * RAD,
            dust: 20 * RAD,
            duty: 1000000000000000000000000000,
            pct:  0,
            chop: 113 * RAY / 100,
            lump: 50 * THOUSAND * WAD,
            mat:  110 * RAY / 100,
            beg:  103 * WAD / 100,
            ttl:  6 hours,
            tau:  3 days
        });
        beforeSpell.collaterals["USDC-B"] = CollateralValues({
            line: 30 * MILLION * RAD,
            dust: 20 * RAD,
            duty: 1000000012000140727767957524,
            pct:  46 * 1000,
            chop: 113 * RAY / 100,
            lump: 50 * THOUSAND * WAD,
            mat:  120 * RAY / 100,
            beg:  103 * WAD / 100,
            ttl:  6 hours,
            tau:  3 days
        });
        beforeSpell.collaterals["WBTC-A"] = CollateralValues({
            line: 40 * MILLION * RAD,
            dust: 20 * RAD,
            duty: 1000000000000000000000000000,
            pct:  0,
            chop: 113 * RAY / 100,
            lump: 1 * WAD,
            mat:  150 * RAY / 100,
            beg:  103 * WAD / 100,
            ttl:  6 hours,
            tau:  6 hours
        });
        beforeSpell.collaterals["TUSD-A"] = CollateralValues({
            line: 2 * MILLION * RAD,
            dust: 20 * RAD,
            duty: 1000000000000000000000000000,
            pct:  0 * 1000,
            chop: 113 * RAY / 100,
            lump: 50 * THOUSAND * WAD,
            mat:  120 * RAY / 100,
            beg:  103 * WAD / 100,
            ttl:  6 hours,
            tau:  3 days
        });
        beforeSpell.collaterals["KNC-A"] = CollateralValues({
            line: 5 * MILLION * RAD,
            dust: 20 * RAD,
            duty: 1000000000000000000000000000,
            pct:  0,
            chop: 113 * RAY / 100,
            lump: 50 * THOUSAND * WAD,
            mat:  175 * RAY / 100,
            beg:  103 * WAD / 100,
            ttl:  6 hours,
            tau:  6 hours
        });
        beforeSpell.collaterals["ZRX-A"] = CollateralValues({
            line: 5 * MILLION * RAD,
            dust: 20 * RAD,
            duty: 1000000000000000000000000000,
            pct:  0,
            chop: 113 * RAY / 100,
            lump: 100 * THOUSAND * WAD,
            mat:  175 * RAY / 100,
            beg:  103 * WAD / 100,
            ttl:  6 hours,
            tau:  6 hours
        });
        beforeSpell.collaterals["MANA-A"] = CollateralValues({
            line: 1 * MILLION * RAD,
            dust: 20 * RAD,
            duty: 1000000002440418608258400030,
            pct:  8 * 1000,
            chop: 113 * RAY / 100,
            lump: 500 * THOUSAND * WAD,
            mat:  175 * RAY / 100,
            beg:  103 * WAD / 100,
            ttl:  6 hours,
            tau:  6 hours
        });


        afterSpell = SystemValues({
            dsr: 1000000000000000000000000000,
            dsrPct: 0 * 1000,
            Line: 608 * MILLION * RAD,
            pauseDelay: 12 * 60 * 60
        });

        // ETH-A
        afterSpell.collaterals["ETH-A"] = beforeSpell.collaterals["ETH-A"];
        afterSpell.collaterals["ETH-A"].lump = 100 * WAD;

        // WBTC-A
        afterSpell.collaterals["WBTC-A"] = beforeSpell.collaterals["WBTC-A"];
        afterSpell.collaterals["WBTC-A"].line = 80 * MILLION * WAD;

        // KNC-A no change
        afterSpell.collaterals["KNC-A"]  = beforeSpell.collaterals["KNC-A"];
        // ZRX-A no change
        afterSpell.collaterals["ZRX-A"]  = beforeSpell.collaterals["ZRX-A"];
        // MANA-A no change
        afterSpell.collaterals["MANA-A"] = beforeSpell.collaterals["MANA-A"];
        // USDC-A no change
        afterSpell.collaterals["USDC-A"] = beforeSpell.collaterals["USDC-A"];
        // USDC-B no change
        afterSpell.collaterals["USDC-B"] = beforeSpell.collaterals["USDC-B"];
        // BAT-A no change
        afterSpell.collaterals["BAT-A"] = beforeSpell.collaterals["BAT-A"];
        // TUSD-A no change
        afterSpell.collaterals["TUSD-A"] = beforeSpell.collaterals["TUSD-A"];

    }

    function vote() private {
        if (chief.hat() != address(spell)) {
            hevm.store(
                address(gov),
                keccak256(abi.encode(address(this), uint256(1))),
                bytes32(uint256(999999999999 ether))
            );
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

        checkCollateralValues("ETH-A",  beforeSpell);
        checkCollateralValues("BAT-A",  beforeSpell);
        checkCollateralValues("USDC-A", beforeSpell);
        checkCollateralValues("USDC-B", beforeSpell);
        checkCollateralValues("WBTC-A", beforeSpell);
        checkCollateralValues("TUSD-A", beforeSpell);
        checkCollateralValues("ZRX-A",  beforeSpell);
        checkCollateralValues("KNC-A",  beforeSpell);
        checkCollateralValues("MANA-A", beforeSpell);

        //assertEq(tusd_a_flip.wards(address(cat)), 1);

        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        checkSystemValues(afterSpell);

        checkCollateralValues("ETH-A",  afterSpell);
        checkCollateralValues("BAT-A",  afterSpell);
        checkCollateralValues("USDC-A", afterSpell);
        checkCollateralValues("USDC-B", afterSpell);
        checkCollateralValues("WBTC-A", afterSpell);
        checkCollateralValues("TUSD-A", afterSpell);
        checkCollateralValues("ZRX-A",  afterSpell);
        checkCollateralValues("KNC-A",  afterSpell);
        checkCollateralValues("MANA-A", afterSpell);

        // Check liquidations off on TUSD
        // Next week!
        //assertEq(tusd_a_flip.wards(address(cat)), 0);
    }

    function try_bite() internal returns (bool ok) {
        (ok,) = address(cat).call(abi.encodeWithSignature("bite(bytes32,address)", bytes32("ETH-A"), address(this)));
    }

    function testFixLiquidation() public {
        uint256 wethAmount = 500 ether;
        uint256 daiAmount = 102471 * 10 ** 45;

        // Giving WETH balance
        hevm.store(
            address(weth),
            keccak256(abi.encode(address(this), uint256(3))),
            bytes32(wethAmount)
        );
        assertEq(weth.balanceOf(address(this)), wethAmount);
        //

        weth.approve(address(wethJoin), uint256(-1));
        wethJoin.join(address(this), wethAmount);

        (, uint256 rate,,,) = vat.ilks("ETH-A");

        vat.frob("ETH-A", address(this), address(this), address(this), int(wethAmount), int(daiAmount / rate));

        // Setting the spot value to the lowest to make all the vaults unsafe
        hevm.store(
            address(vat),
            bytes32(uint256(keccak256(abi.encode(bytes32("ETH-A"), uint256(2)))) + 2),
            bytes32(uint256(1))
        );
        //

        assertTrue(!try_bite());

        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        assertTrue(try_bite());
    }
}
