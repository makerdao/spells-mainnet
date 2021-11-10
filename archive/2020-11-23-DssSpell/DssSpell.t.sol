pragma solidity 0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";
import "./test/rates.sol";

import {DssSpell, SpellAction} from "./DssSpell.sol";

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
}

interface MedianizerV1Abstract {
    function authority() external view returns (address);
    function owner() external view returns (address);
    function peek() external view returns (uint256, bool);
    function poke() external;
}

interface SpellLike {
    function done() external view returns (bool);
    function cast() external;
}

contract DssSpellTest is DSTest, DSMath {
    // populate with mainnet spell if needed
    address constant MAINNET_SPELL = address(0xA2652eb43674bc9cfC517a6FA4CEcE391e29c2d3);
    // this needs to be updated
    uint256 constant SPELL_CREATED = 1606152054;

    struct CollateralValues {
        uint256 line;
        uint256 dust;
        uint256 chop;
        uint256 dunk;
        uint256 pct;
        uint256 mat;
        uint256 beg;
        uint48 ttl;
        uint48 tau;
        uint256 liquidations;
    }

    struct SystemValues {
        uint256 pot_dsr;
        uint256 vat_Line;
        uint256 pause_delay;
        uint256 vow_wait;
        uint256 vow_dump;
        uint256 vow_sump;
        uint256 vow_bump;
        uint256 vow_hump;
        uint256 cat_box;
        address osm_mom_authority;
        address flipper_mom_authority;
        uint256 ilk_count;
        mapping (bytes32 => CollateralValues) collaterals;
    }

    SystemValues afterSpell;

    Hevm hevm;
    Rates rates;

    // MAINNET ADDRESSES
    DSPauseAbstract      pause = DSPauseAbstract(    0xbE286431454714F511008713973d3B053A2d38f3);
    address         pauseProxy =                     0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
    DSChiefAbstract      chief = DSChiefAbstract(    0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    VatAbstract            vat = VatAbstract(        0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    VowAbstract            vow = VowAbstract(        0xA950524441892A31ebddF91d3cEEFa04Bf454466);
    CatAbstract            cat = CatAbstract(        0xa5679C04fc3d9d8b0AaB1F0ab83555b301cA70Ea);
    PotAbstract            pot = PotAbstract(        0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    JugAbstract            jug = JugAbstract(        0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    SpotAbstract          spot = SpotAbstract(       0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);

    DSTokenAbstract        gov = DSTokenAbstract(    0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    EndAbstract            end = EndAbstract(        0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5);
    IlkRegistryAbstract    reg = IlkRegistryAbstract(0x8b4ce5DCbb01e0e1f0521cd8dCfb31B308E52c24);

    OsmMomAbstract      osmMom = OsmMomAbstract(     0x76416A4d5190d071bfed309861527431304aA14f);
    FlipperMomAbstract flipMom = FlipperMomAbstract( 0xc4bE7F74Ee3743bDEd8E0fA218ee5cf06397f472);

    ChainlogAbstract chainlog  = ChainlogAbstract(   0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    address    makerDeployer06 = 0xda0fab060e6cc7b1C0AA105d29Bd50D71f036711;

    

    DssSpell spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    uint256 constant HUNDRED    = 10 ** 2;
    uint256 constant THOUSAND   = 10 ** 3;
    uint256 constant MILLION    = 10 ** 6;
    uint256 constant BILLION    = 10 ** 9;
    uint256 constant WAD        = 10 ** 18;
    uint256 constant RAY        = 10 ** 27;
    uint256 constant RAD        = 10 ** 45;

    event Debug(uint256 index, uint256 val);
    event Debug(uint256 index, address addr);
    event Debug(uint256 index, bytes32 what);

    // not provided in DSMath
    function rpow(uint256 x, uint256 n, uint256 b) internal pure returns (uint256 z) {
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
        return (10000 + percentValue) * (10 ** 23);
    }

    function diffCalc(uint256 expectedRate_, uint256 yearlyYield_) public pure returns (uint256) {
        return (expectedRate_ > yearlyYield_) ? expectedRate_ - yearlyYield_ : yearlyYield_ - expectedRate_;
    }

    // Previous spell; supply if there is a need to test prior to its cast() function being called on mainnet.
    SpellLike constant PREV_SPELL = SpellLike(0x8D602692eE4b5f0ec33A22fe6547822377FDCc4c);

    // Time to warp to in order to allow the previous spell to be cast; ignored if PREV_SPELL is SpellLike(address(0)).
    uint256   constant PREV_SPELL_EXECUTION_TIME = 1612108914;

    function castPreviousSpell() internal {
        // warp and cast previous spell so values are up-to-date to test against
        if (PREV_SPELL != SpellLike(0) && !PREV_SPELL.done()) {
            hevm.warp(PREV_SPELL_EXECUTION_TIME);
            PREV_SPELL.cast();
        }
    }

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        rates = new Rates();

        spell = MAINNET_SPELL != address(0) ? DssSpell(MAINNET_SPELL) : new DssSpell();

        //
        // Test for all system configuration changes
        //
        afterSpell = SystemValues({
            pot_dsr:               0,                       // In basis points
            vat_Line:              148175 * MILLION / 100,  // In whole Dai units
            pause_delay:           72 hours,                // In seconds
            vow_wait:              156 hours,               // In seconds
            vow_dump:              250,                     // In whole Dai units
            vow_sump:              50000,                   // In whole Dai units
            vow_bump:              10000,                   // In whole Dai units
            vow_hump:              4 * MILLION,             // In whole Dai units
            cat_box:               15 * MILLION,            // In whole Dai units
            osm_mom_authority:     address(0),              // OsmMom authority
            flipper_mom_authority: address(0),              // FlipperMom authority
            ilk_count:             18                       // Num expected in system
        });

        //
        // Test for all collateral based changes here
        //
        afterSpell.collaterals["ETH-A"] = CollateralValues({
            line:         490 * MILLION,   // In whole Dai units
            dust:         500,             // In whole Dai units
            pct:          200,             // In basis points
            chop:         1300,            // In basis points
            dunk:         50 * THOUSAND,   // In whole Dai units
            mat:          15000,           // In basis points
            beg:          300,             // In basis points
            ttl:          6 hours,         // In seconds
            tau:          6 hours,         // In seconds
            liquidations: 1                // 1 if enabled
        });
        afterSpell.collaterals["ETH-B"] = CollateralValues({
            line:         10 * MILLION,
            dust:         500,
            pct:          400,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          13000,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["BAT-A"] = CollateralValues({
            line:         10 * MILLION,
            dust:         500,
            pct:          400,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          15000,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["USDC-A"] = CollateralValues({
            line:         485 * MILLION,
            dust:         500,
            pct:          400,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          10100,
            beg:          300,
            ttl:          6 hours,
            tau:          3 days,
            liquidations: 0
        });
        afterSpell.collaterals["USDC-B"] = CollateralValues({
            line:         30 * MILLION,
            dust:         500,
            pct:          5000,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          12000,
            beg:          300,
            ttl:          6 hours,
            tau:          3 days,
            liquidations: 0
        });
        afterSpell.collaterals["WBTC-A"] = CollateralValues({
            line:         160 * MILLION,
            dust:         500,
            pct:          400,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          15000,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["TUSD-A"] = CollateralValues({
            line:         135 * MILLION,
            dust:         500,
            pct:          400,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          10100,
            beg:          300,
            ttl:          6 hours,
            tau:          3 days,
            liquidations: 0
        });
        afterSpell.collaterals["KNC-A"] = CollateralValues({
            line:         5 * MILLION,
            dust:         500,
            pct:          400,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["ZRX-A"] = CollateralValues({
            line:         5 * MILLION,
            dust:         500,
            pct:          400,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["MANA-A"] = CollateralValues({
            line:         250 * THOUSAND,
            dust:         500,
            pct:          1200,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["USDT-A"] = CollateralValues({
            line:         25 * MILLION / 10,
            dust:         500,
            pct:          800,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          15000,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["PAXUSD-A"] = CollateralValues({
            line:         100 * MILLION,
            dust:         500,
            pct:          400,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          10100,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 0
        });
        afterSpell.collaterals["COMP-A"] = CollateralValues({
            line:         7 * MILLION,
            dust:         500,
            pct:          300,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["LRC-A"] = CollateralValues({
            line:         3 * MILLION,
            dust:         500,
            pct:          300,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["LINK-A"] = CollateralValues({
            line:         10 * MILLION,
            dust:         500,
            pct:          200,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["BAL-A"] = CollateralValues({
            line:         4 * MILLION,
            dust:         500,
            pct:          500,
            chop:         1300,
            dunk:         50000,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["YFI-A"] = CollateralValues({
            line:         20 * MILLION,
            dust:         500,
            pct:          400,
            chop:         1300,
            dunk:         50000,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["GUSD-A"] = CollateralValues({
            line:         5 * MILLION,
            dust:         500,
            pct:          400,
            chop:         1300,
            dunk:         50000,
            mat:          10100,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 0
        });
    }

    function scheduleWaitAndCastFailDay() public {
        spell.schedule();

        uint256 castTime = now + pause.delay();
        uint256 day = (castTime / 1 days + 3) % 7;
        if (day < 5) {
            castTime += 5 days - day * 86400;
        }

        hevm.warp(castTime);
        spell.cast();
    }

    function scheduleWaitAndCastFailEarly() public {
        spell.schedule();

        uint256 castTime = now + pause.delay() + 24 hours;
        uint256 hour = castTime / 1 hours % 24;
        if (hour >= 14) {
            castTime -= hour * 3600 - 13 hours;
        }

        hevm.warp(castTime);
        spell.cast();
    }

    function scheduleWaitAndCastFailLate() public {
        spell.schedule();

        uint256 castTime = now + pause.delay();
        uint256 hour = castTime / 1 hours % 24;
        if (hour < 21) {
            castTime += 21 hours - hour * 3600;
        }

        hevm.warp(castTime);
        spell.cast();
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

        uint256 castTime = now + pause.delay();

        castPreviousSpell();

        if(spell.officeHours()) {
            uint256 day = (castTime / 1 days + 3) % 7;
            if(day >= 5) {
                castTime += 7 days - day * 86400;
            }

            uint256 hour = castTime / 1 hours % 24;
            if (hour >= 21) {
                castTime += 24 hours - hour * 3600 + 14 hours;
            } else if (hour < 14) {
                castTime += 14 hours - hour * 3600;
            }
        }

        hevm.warp(castTime);
        spell.cast();
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function checkSystemValues(SystemValues storage values) internal {
        // dsr
        uint256 expectedDSRRate = rates.rates(values.pot_dsr);
        // make sure dsr is less than 100% APR
        // bc -l <<< 'scale=27; e( l(2.00)/(60 * 60 * 24 * 365) )'
        // 1000000021979553151239153027
        assertTrue(
            pot.dsr() >= RAY && pot.dsr() < 1000000021979553151239153027
        );
        assertTrue(diffCalc(expectedRate(values.pot_dsr), yearlyYield(expectedDSRRate)) <= TOLERANCE);

        {
        // Line values in RAD
        uint256 normalizedLine = values.vat_Line * RAD;
        assertEq(vat.Line(), normalizedLine);
        assertTrue(
            (vat.Line() >= RAD && vat.Line() < 100 * BILLION * RAD) ||
            vat.Line() == 0
        );
        }

        // Pause delay
        assertEq(pause.delay(), values.pause_delay);

        // wait
        assertEq(vow.wait(), values.vow_wait);

        {
        // dump values in WAD
        uint256 normalizedDump = values.vow_dump * WAD;
        assertEq(vow.dump(), normalizedDump);
        assertTrue(
            (vow.dump() >= WAD && vow.dump() < 2 * THOUSAND * WAD) ||
            vow.dump() == 0
        );
        }
        {
        // sump values in RAD
        uint256 normalizedSump = values.vow_sump * RAD;
        assertEq(vow.sump(), normalizedSump);
        assertTrue(
            (vow.sump() >= RAD && vow.sump() < 500 * THOUSAND * RAD) ||
            vow.sump() == 0
        );
        }
        {
        // bump values in RAD
        uint normalizedBump = values.vow_bump * RAD;
        assertEq(vow.bump(), normalizedBump);
        assertTrue(
            (vow.bump() >= RAD && vow.bump() < HUNDRED * THOUSAND * RAD) ||
            vow.bump() == 0
        );
        }
        {
        // hump values in RAD
        uint256 normalizedHump = values.vow_hump * RAD;
        assertEq(vow.hump(), normalizedHump);
        assertTrue(
            (vow.hump() >= RAD && vow.hump() < HUNDRED * MILLION * RAD) ||
            vow.hump() == 0
        );
        }

        // box values in RAD
        {
            uint256 normalizedBox = values.cat_box * RAD;
            assertEq(cat.box(), normalizedBox);
        }

        // check OsmMom authority
        assertEq(osmMom.authority(), values.osm_mom_authority);

        // check FlipperMom authority
        assertEq(flipMom.authority(), values.flipper_mom_authority);

        // check number of ilks
        assertEq(reg.count(), values.ilk_count);
    }

    function checkCollateralValues(SystemValues storage values) internal {
        uint256 sumlines;
        bytes32[] memory ilks = reg.list();
        for(uint256 i = 0; i < ilks.length; i++) {
            bytes32 ilk = ilks[i];
            (uint256 duty,)  = jug.ilks(ilk);

            assertEq(duty, rates.rates(values.collaterals[ilk].pct));
            // make sure duty is less than 1000% APR
            // bc -l <<< 'scale=27; e( l(10.00)/(60 * 60 * 24 * 365) )'
            // 1000000073014496989316680335
            assertTrue(duty >= RAY && duty < 1000000073014496989316680335);  // gt 0 and lt 1000%
            assertTrue(diffCalc(expectedRate(values.collaterals[ilk].pct), yearlyYield(rates.rates(values.collaterals[ilk].pct))) <= TOLERANCE);
            assertTrue(values.collaterals[ilk].pct < THOUSAND * THOUSAND);   // check value lt 1000%
            {
            (,,, uint256 line, uint256 dust) = vat.ilks(ilk);
            // Convert whole Dai units to expected RAD
            uint256 normalizedTestLine = values.collaterals[ilk].line * RAD;
            sumlines += values.collaterals[ilk].line;
            assertEq(line, normalizedTestLine);
            assertTrue((line >= RAD && line < BILLION * RAD) || line == 0);  // eq 0 or gt eq 1 RAD and lt 1B
            uint256 normalizedTestDust = values.collaterals[ilk].dust * RAD;
            assertEq(dust, normalizedTestDust);
            assertTrue((dust >= RAD && dust < 10 * THOUSAND * RAD) || dust == 0); // eq 0 or gt eq 1 and lt 10k
            }
            {
            (, uint256 chop, uint256 dunk) = cat.ilks(ilk);
            // Convert BP to system expected value
            uint256 normalizedTestChop = (values.collaterals[ilk].chop * 10**14) + WAD;
            assertEq(chop, normalizedTestChop);
            // make sure chop is less than 100%
            assertTrue(chop >= WAD && chop < 2 * WAD);   // penalty gt eq 0% and lt 100%
            // Convert whole Dai units to expected RAD
            uint256 normalizedTestDunk = values.collaterals[ilk].dunk * RAD;
            assertEq(dunk, normalizedTestDunk);
            // put back in after LIQ-1.2
            assertTrue(dunk >= RAD && dunk < MILLION * RAD);
            }
            {
            (,uint256 mat) = spot.ilks(ilk);
            // Convert BP to system expected value
            uint256 normalizedTestMat = (values.collaterals[ilk].mat * 10**23);
            assertEq(mat, normalizedTestMat);
            assertTrue(mat >= RAY && mat < 10 * RAY);    // cr eq 100% and lt 1000%
            }
            {
            (address flipper,,) = cat.ilks(ilk);
            FlipAbstract flip = FlipAbstract(flipper);
            // Convert BP to system expected value
            uint256 normalizedTestBeg = (values.collaterals[ilk].beg + 10000)  * 10**14;
            assertEq(uint256(flip.beg()), normalizedTestBeg);
            assertTrue(flip.beg() >= WAD && flip.beg() < 105 * WAD / 100);  // gt eq 0% and lt 5%
            assertEq(uint256(flip.ttl()), values.collaterals[ilk].ttl);
            assertTrue(flip.ttl() >= 600 && flip.ttl() < 10 hours);         // gt eq 10 minutes and lt 10 hours
            assertEq(uint256(flip.tau()), values.collaterals[ilk].tau);
            assertTrue(flip.tau() >= 600 && flip.tau() <= 3 days);          // gt eq 10 minutes and lt eq 3 days

            assertEq(flip.wards(address(cat)), values.collaterals[ilk].liquidations);  // liquidations == 1 => on
            assertEq(flip.wards(address(makerDeployer06)), 0); // Check deployer denied
            assertEq(flip.wards(address(pauseProxy)), 1); // Check pause_proxy ward
            }
            {
            GemJoinAbstract join = GemJoinAbstract(reg.join(ilk));
            assertEq(join.wards(address(makerDeployer06)), 0); // Check deployer denied
            assertEq(join.wards(address(pauseProxy)), 1); // Check pause_proxy ward
            }
        }
        assertEq(sumlines, values.vat_Line);
    }

//    function testFailWrongDay() public {
//        vote();
//        scheduleWaitAndCastFailDay();
//    }

//    function testFailTooEarly() public {
//        vote();
//        scheduleWaitAndCastFailEarly();
//    }

//    function testFailTooLate() public {
//        vote();
//        scheduleWaitAndCastFailLate();
//    }

    function testSpellIsCast() public {
        string memory description = new DssSpell().description();
        assertTrue(bytes(description).length > 0);
        // DS-Test can't handle strings directly, so cast to a bytes32.
        assertEq(stringToBytes32(spell.description()),
                stringToBytes32(description));

        if(address(spell) != address(MAINNET_SPELL)) {
            assertEq(spell.expiration(), (now + 4 days + 2 hours));
        } else {
            assertEq(spell.expiration(), (SPELL_CREATED + 4 days + 2 hours));
        }

        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        checkSystemValues(afterSpell);

        checkCollateralValues(afterSpell);
    }
}
