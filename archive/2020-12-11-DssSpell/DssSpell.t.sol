pragma solidity 0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";
import "./test/rates.sol";
import "./test/addresses_mainnet.sol";

import {DssSpell, SpellAction} from "./DssSpell.sol";

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
}

interface SpellLike {
    function done() external view returns (bool);
    function cast() external;
}

contract DssSpellTest is DSTest, DSMath {
    // populate with mainnet spell if needed
    address constant MAINNET_SPELL = address(0x58401b64CA6b91E346c87B057254F040990c4F98);
    // this needs to be updated
    uint256 constant SPELL_CREATED = 1607706839;

    // Previous spell; supply if there is a need to test prior to its cast()
    // function being called on mainnet.
    SpellLike constant PREV_SPELL =
        SpellLike(0xB70fB4eE900650DCaE5dD63Fd06E07F0b3a45d13);

    // Time to warp to in order to allow the previous spell to be cast;
    // ignored if PREV_SPELL is SpellLike(address(0)).
    uint256 constant PREV_SPELL_EXECUTION_TIME = 1607281234;

    struct CollateralValues {
        bool aL_enabled;
        uint256 aL_line;
        uint256 aL_gap;
        uint256 aL_ttl;
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
        address pause_authority;
        address osm_mom_authority;
        address flipper_mom_authority;
        uint256 ilk_count;
        mapping (bytes32 => CollateralValues) collaterals;
    }

    SystemValues afterSpell;

    Hevm hevm;
    Rates     rates = new Rates();
    Addresses addr  = new Addresses();

    // MAINNET ADDRESSES
    DSPauseAbstract        pause = DSPauseAbstract(    addr.addr("MCD_PAUSE"));
    address           pauseProxy =                     addr.addr("MCD_PAUSE_PROXY");
    DSChiefAbstract        chief = DSChiefAbstract(    addr.addr("MCD_ADM"));
    VatAbstract              vat = VatAbstract(        addr.addr("MCD_VAT"));
    VowAbstract              vow = VowAbstract(        addr.addr("MCD_VOW"));
    CatAbstract              cat = CatAbstract(        addr.addr("MCD_CAT"));
    PotAbstract              pot = PotAbstract(        addr.addr("MCD_POT"));
    JugAbstract              jug = JugAbstract(        addr.addr("MCD_JUG"));
    SpotAbstract            spot = SpotAbstract(       addr.addr("MCD_SPOT"));
    DSTokenAbstract          gov = DSTokenAbstract(    addr.addr("MCD_GOV"));
    EndAbstract              end = EndAbstract(        addr.addr("MCD_END"));
    IlkRegistryAbstract      reg = IlkRegistryAbstract(addr.addr("ILK_REGISTRY"));

    OsmMomAbstract        osmMom = OsmMomAbstract(     addr.addr("OSM_MOM"));
    FlipperMomAbstract   flipMom = FlipperMomAbstract( addr.addr("FLIPPER_MOM"));
    DssAutoLineAbstract autoLine = DssAutoLineAbstract(addr.addr("MCD_IAM_AUTO_LINE"));

    // Specific for this spell
    DSTokenAbstract          uni = DSTokenAbstract(    addr.addr("UNI"));
    GemJoinAbstract     joinUNIA = GemJoinAbstract(    addr.addr("MCD_JOIN_UNI_A"));
    FlipAbstract        flipUNIA = FlipAbstract(       addr.addr("MCD_FLIP_UNI_A"));
    OsmAbstract           pipUNI = OsmAbstract(        addr.addr("PIP_UNI"));
    MedianAbstract       medUNIA = MedianAbstract(     0x52f761908cC27B4D77AD7A329463cf08baf62153);

    DSTokenAbstract       renbtc = DSTokenAbstract(    addr.addr("RENBTC"));
    GemJoinAbstract  joinRENBTCA = GemJoinAbstract(    addr.addr("MCD_JOIN_RENBTC_A"));
    FlipAbstract     flipRENBTCA = FlipAbstract(       addr.addr("MCD_FLIP_RENBTC_A"));
    OsmAbstract        pipRENBTC = OsmAbstract(        addr.addr("PIP_RENBTC"));
    MedianAbstract     medRENBTC = MedianAbstract(     0xe0F30cb149fAADC7247E953746Be9BbBB6B5751f);
    //

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
        return rpow(duty, (365 * 24 * 60 * 60), RAY);
    }

    function expectedRate(uint256 percentValue) public pure returns (uint256) {
        return (10000 + percentValue) * (10 ** 23);
    }

    function diffCalc(
        uint256 expectedRate_,
        uint256 yearlyYield_
    ) public pure returns (uint256) {
        return (expectedRate_ > yearlyYield_) ?
            expectedRate_ - yearlyYield_ : yearlyYield_ - expectedRate_;
    }

    function castPreviousSpell() internal {
        SpellLike prevSpell = SpellLike(PREV_SPELL);
        // warp and cast previous spell so values are up-to-date to test against
        if (prevSpell != SpellLike(0) && !prevSpell.done()) {
            hevm.warp(PREV_SPELL_EXECUTION_TIME);
            prevSpell.cast();
        }
    }

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));

        spell = MAINNET_SPELL != address(0) ?
            DssSpell(MAINNET_SPELL) : new DssSpell();

        //
        // Test for all system configuration changes
        //
        afterSpell = SystemValues({
            pot_dsr:               0,                       // In basis points
            vat_Line:              160875 * MILLION / 100,  // In whole Dai units
            pause_delay:           48 hours,                // In seconds
            vow_wait:              156 hours,               // In seconds
            vow_dump:              250,                     // In whole Dai units
            vow_sump:              50000,                   // In whole Dai units
            vow_bump:              10000,                   // In whole Dai units
            vow_hump:              4 * MILLION,             // In whole Dai units
            cat_box:               15 * MILLION,            // In whole Dai units
            pause_authority:       address(chief),          // Pause authority
            osm_mom_authority:     address(chief),          // OsmMom authority
            flipper_mom_authority: address(chief),          // FlipperMom authority
            ilk_count:             20                       // Num expected in system
        });

        //
        // Test for all collateral based changes here
        //
        afterSpell.collaterals["ETH-A"] = CollateralValues({
            aL_enabled:   false,           // DssAutoLine is enabled?
            aL_line:      0 * MILLION,     // In whole Dai units
            aL_gap:       0 * MILLION,     // In whole Dai units
            aL_ttl:       0,               // In seconds
            line:         590 * MILLION,   // In whole Dai units
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
            aL_enabled:   true,
            aL_line:      50 * MILLION,
            aL_gap:       5 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,     // Not checked as there is auto line
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
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
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
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         485 * MILLION,
            dust:         500,
            pct:          0,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          10100,
            beg:          300,
            ttl:          6 hours,
            tau:          3 days,
            liquidations: 0
        });
        afterSpell.collaterals["USDC-B"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
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
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
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
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         135 * MILLION,
            dust:         500,
            pct:          0,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          10100,
            beg:          300,
            ttl:          6 hours,
            tau:          3 days,
            liquidations: 0
        });
        afterSpell.collaterals["KNC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
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
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
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
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
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
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
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
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         100 * MILLION,
            dust:         500,
            pct:          0,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          10100,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 0
        });
        afterSpell.collaterals["COMP-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
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
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
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
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
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
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
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
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         30 * MILLION,
            dust:         500,
            pct:          1000,
            chop:         1300,
            dunk:         50000,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["GUSD-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         5 * MILLION,
            dust:         500,
            pct:          0,
            chop:         1300,
            dunk:         50000,
            mat:          10100,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 0
        });
        afterSpell.collaterals["UNI-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         15 * MILLION,
            dust:         500,
            pct:          300,
            chop:         1300,
            dunk:         50000,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["RENBTC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         2 * MILLION,
            dust:         500,
            pct:          600,
            chop:         1300,
            dunk:         50000,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
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
            chief.lock(999999999999 ether);

            address[] memory slate = new address[](1);

            if (chief.live() == 0) {
                // Launch system
                slate[0] = address(0);
                chief.vote(slate);
                if (chief.hat() != address(0)) {
                    chief.lift(address(0));
                }
                assertEq(chief.live(), 0);
                assertTrue(!chief.isUserRoot(address(0)));
                chief.launch();
                assertEq(chief.live(), 1);
                assertTrue(chief.isUserRoot(address(0)));
            }

            assertTrue(!spell.done());

            slate[0] = address(spell);

            chief.vote(slate);
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

        // check Pause authority
        assertEq(pause.authority(), values.pause_authority);

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
            sumlines += line;
            (uint256 aL_line, uint256 aL_gap, uint256 aL_ttl,,) = autoLine.ilks(ilk);
            if (!values.collaterals[ilk].aL_enabled) {
                assertTrue(aL_line == 0);
                assertEq(line, normalizedTestLine);
                assertTrue((line >= RAD && line < BILLION * RAD) || line == 0);  // eq 0 or gt eq 1 RAD and lt 1B
            } else {
                assertTrue(aL_line > 0);
                assertEq(aL_line, values.collaterals[ilk].aL_line * RAD);
                assertEq(aL_gap, values.collaterals[ilk].aL_gap * RAD);
                assertEq(aL_ttl, values.collaterals[ilk].aL_ttl);
                assertTrue((aL_line >= RAD && aL_line < BILLION * RAD) || aL_line == 0);  // eq 0 or gt eq 1 RAD and lt 1B
            }
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
        assertEq(sumlines, values.vat_Line * RAD);
    }

    function testFailWrongDay() public {
        vote();
        scheduleWaitAndCastFailDay();
    }

    function testFailTooEarly() public {
        vote();
        scheduleWaitAndCastFailEarly();
    }

    function testFailTooLate() public {
        vote();
        scheduleWaitAndCastFailLate();
    }

    function testSpellIsCast() public {
        string memory description = new DssSpell().description();
        assertTrue(bytes(description).length > 0);
        // DS-Test can't handle strings directly, so cast to a bytes32.
        assertEq(stringToBytes32(spell.description()),
                stringToBytes32(description));

        if(address(spell) != address(MAINNET_SPELL)) {
            assertEq(spell.expiration(), (now + 30 days));
        } else {
            assertEq(spell.expiration(), (SPELL_CREATED + 30 days));
        }

        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        checkSystemValues(afterSpell);

        checkCollateralValues(afterSpell);

        // Verify that yearn has been approved on the YFI/USD OSM
        address YEARN_PROXY = 0x208EfCD7aad0b5DD49438E0b6A0f38E951A50E5f;
        assertEq(OsmAbstract(addr.addr("PIP_YFI")).bud(YEARN_PROXY), 1);

        // Verify DssAutoLine is authored to file the Vat
        assertEq(vat.wards(address(autoLine)), 1);
    }

    function testSpellIsCast_UNI_INTEGRATION() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        pipUNI.poke();
        hevm.warp(now + 3601);
        pipUNI.poke();
        spot.poke("UNI-A");

        // Add balance to the test address
        uint256 ilkAmt = 10 * THOUSAND * WAD;
        hevm.store(
            address(uni),
            keccak256(abi.encode(address(this), uint256(4))),
            bytes32(ilkAmt)
        );
        assertEq(uni.balanceOf(address(this)), ilkAmt);

        // Check median matches pip.src()
        assertEq(pipUNI.src(), address(medUNIA));

        // Authorization
        assertEq(joinUNIA.wards(pauseProxy), 1);
        assertEq(vat.wards(address(joinUNIA)), 1);
        assertEq(flipUNIA.wards(address(end)), 1);
        assertEq(flipUNIA.wards(address(flipMom)), 1);
        assertEq(pipUNI.wards(address(osmMom)), 1);
        assertEq(pipUNI.bud(address(spot)), 1);
        assertEq(pipUNI.bud(address(end)), 1);
        assertEq(MedianAbstract(pipUNI.src()).bud(address(pipUNI)), 1);

        // Join to adapter
        assertEq(vat.gem("UNI-A", address(this)), 0);
        uni.approve(address(joinUNIA), ilkAmt);
        joinUNIA.join(address(this), ilkAmt);
        assertEq(uni.balanceOf(address(this)), 0);
        assertEq(vat.gem("UNI-A", address(this)), ilkAmt);

        // Deposit collateral, generate DAI
        assertEq(vat.dai(address(this)), 0);
        vat.frob("UNI-A", address(this), address(this), address(this), int(ilkAmt), int(500 * WAD));
        assertEq(vat.gem("UNI-A", address(this)), 0);
        assertEq(vat.dai(address(this)), 500 * RAD);

        // Payback DAI, withdraw collateral
        vat.frob("UNI-A", address(this), address(this), address(this), -int(ilkAmt), -int(500 * WAD));
        assertEq(vat.gem("UNI-A", address(this)), ilkAmt);
        assertEq(vat.dai(address(this)), 0);

        // Withdraw from adapter
        joinUNIA.exit(address(this), ilkAmt);
        assertEq(uni.balanceOf(address(this)), ilkAmt);
        assertEq(vat.gem("UNI-A", address(this)), 0);

        // Generate new DAI to force a liquidation
        uni.approve(address(joinUNIA), ilkAmt);
        joinUNIA.join(address(this), ilkAmt);
        (,,uint256 spotV,,) = vat.ilks("UNI-A");
        // dart max amount of DAI
        vat.frob("UNI-A", address(this), address(this), address(this), int(ilkAmt), int(mul(ilkAmt, spotV) / RAY));
        hevm.warp(now + 1);
        jug.drip("UNI-A");
        assertEq(flipUNIA.kicks(), 0);
        cat.bite("UNI-A", address(this));
        assertEq(flipUNIA.kicks(), 1);
    }

    function testSpellIsCast_RENBTC_A_INTEGRATION() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        pipRENBTC.poke();
        hevm.warp(now + 3601);
        pipRENBTC.poke();
        spot.poke("RENBTC-A");

        // Add balance to the test address
        uint256 ilkAmt = 10**8;
        uint256 ilkAmt18 = ilkAmt * 10**10;
        hevm.store(
            address(renbtc),
            keccak256(abi.encode(address(this), uint256(102))),
            bytes32(ilkAmt)
        );
        assertEq(renbtc.balanceOf(address(this)), ilkAmt);

        // Check median matches pip.src()
        assertEq(pipRENBTC.src(), address(medRENBTC));

        // Authorization
        assertEq(joinRENBTCA.wards(pauseProxy), 1);
        assertEq(vat.wards(address(joinRENBTCA)), 1);
        assertEq(flipRENBTCA.wards(address(end)), 1);
        assertEq(flipRENBTCA.wards(address(flipMom)), 1);
        assertEq(pipRENBTC.wards(address(osmMom)), 1);
        assertEq(pipRENBTC.bud(address(spot)), 1);
        assertEq(pipRENBTC.bud(address(end)), 1);
        assertEq(MedianAbstract(pipRENBTC.src()).bud(address(pipRENBTC)), 1);

        // Join to adapter
        assertEq(vat.gem("RENBTC-A", address(this)), 0);
        renbtc.approve(address(joinRENBTCA), ilkAmt);
        joinRENBTCA.join(address(this), ilkAmt);
        assertEq(renbtc.balanceOf(address(this)), 0);
        assertEq(vat.gem("RENBTC-A", address(this)), ilkAmt18);

        // Deposit collateral, generate DAI
        assertEq(vat.dai(address(this)), 0);
        vat.frob("RENBTC-A", address(this), address(this), address(this), int(ilkAmt18), int(500 * WAD));
        assertEq(vat.gem("RENBTC-A", address(this)), 0);
        assertEq(vat.dai(address(this)), 500 * RAD);

        // Payback DAI, withdraw collateral
        vat.frob("RENBTC-A", address(this), address(this), address(this), -int(ilkAmt18), -int(500 * WAD));
        assertEq(vat.gem("RENBTC-A", address(this)), ilkAmt18);
        assertEq(vat.dai(address(this)), 0);

        // Withdraw from adapter
        joinRENBTCA.exit(address(this), ilkAmt);
        assertEq(renbtc.balanceOf(address(this)), ilkAmt);
        assertEq(vat.gem("RENBTC-A", address(this)), 0);

        // Generate new DAI to force a liquidation
        renbtc.approve(address(joinRENBTCA), ilkAmt);
        joinRENBTCA.join(address(this), ilkAmt);
        (,,uint256 spotV,,) = vat.ilks("RENBTC-A");
        // dart max amount of DAI
        vat.frob("RENBTC-A", address(this), address(this), address(this), int(ilkAmt18), int(mul(ilkAmt18, spotV) / RAY));
        hevm.warp(now + 1);
        jug.drip("RENBTC-A");
        assertEq(flipRENBTCA.kicks(), 0);
        cat.bite("RENBTC-A", address(this));
        assertEq(flipRENBTCA.kicks(), 1);
    }

    function testCastCost() public {
        vote();
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
        uint startGas = gasleft();
        spell.cast();
        uint endGas = gasleft();
        uint totalGas = startGas - endGas;

        assertTrue(spell.done());
        // Fail if cast is too expensive
        assertTrue(totalGas <= 8 * MILLION);
    }
}
