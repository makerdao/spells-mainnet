// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.11;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";
import "./test/rates.sol";
import "./test/addresses_mainnet.sol";

import {DssSpell} from "./DssSpell.sol";

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
}

interface SpellLike {
    function done() external view returns (bool);
    function cast() external;
}

interface ChainLogLike {
    function list() external returns (bytes32[] memory);
    function getAddress(bytes32 _key) external returns (address addr);
}

interface AuthLike {
    function wards(address addr) external returns (uint auth);
}

contract DssSpellTest is DSTest, DSMath {

    struct SpellValues {
        address deployed_spell;
        uint256 deployed_spell_created;
        address previous_spell;
        uint256 previous_spell_execution_time;
        bool    office_hours_enabled;
        uint256 expiration_threshold;
    }

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
        uint48  ttl;
        uint48  tau;
        uint256 liquidations;
        uint256 flipper_mom;
    }

    struct SystemValues {
        uint256 pot_dsr;
        uint256 pause_delay;
        uint256 vow_wait;
        uint256 vow_dump;
        uint256 vow_sump;
        uint256 vow_bump;
        uint256 vow_hump;
        uint256 flap_beg;
        uint256 flap_ttl;
        uint256 flap_tau;
        uint256 cat_box;
        address pause_authority;
        address osm_mom_authority;
        address flipper_mom_authority;
        uint256 ilk_count;
        mapping (bytes32 => CollateralValues) collaterals;
    }

    SystemValues afterSpell;
    SpellValues  spellValues;

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
    DaiAbstract              dai = DaiAbstract(        addr.addr("MCD_DAI"));
    DaiJoinAbstract      daiJoin = DaiJoinAbstract(    addr.addr("MCD_DAI_JOIN"));
    DSTokenAbstract          gov = DSTokenAbstract(    addr.addr("MCD_GOV"));
    EndAbstract              end = EndAbstract(        addr.addr("MCD_END"));
    IlkRegistryAbstract      reg = IlkRegistryAbstract(addr.addr("ILK_REGISTRY"));
    FlapAbstract            flap = FlapAbstract(       addr.addr("MCD_FLAP"));

    OsmMomAbstract        osmMom = OsmMomAbstract(     addr.addr("OSM_MOM"));
    FlipperMomAbstract   flipMom = FlipperMomAbstract( addr.addr("FLIPPER_MOM"));
    DssAutoLineAbstract autoLine = DssAutoLineAbstract(addr.addr("MCD_IAM_AUTO_LINE"));

    // Specific for this spell

    address    makerDeployer06 = 0xda0fab060e6cc7b1C0AA105d29Bd50D71f036711;

    DssSpell   spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    uint256 constant HUNDRED    = 10 ** 2;
    uint256 constant THOUSAND   = 10 ** 3;
    uint256 constant MILLION    = 10 ** 6;
    uint256 constant BILLION    = 10 ** 9;
    // uint256 constant WAD        = 10 ** 18; // provided by ds-math
    // uint256 constant RAY        = 10 ** 27; // provided by ds-math
    uint256 constant RAD        = 10 ** 45;

    uint256 constant monthly_expiration = 4 days;
    uint256 constant weekly_expiration = 30 days;

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
        SpellLike prevSpell = SpellLike(spellValues.previous_spell);
        // warp and cast previous spell so values are up-to-date to test against
        if (prevSpell != SpellLike(0) && !prevSpell.done()) {
            hevm.warp(spellValues.previous_spell_execution_time);
            prevSpell.cast();
        }
    }

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));

        //
        // Test for spell-specific parameters
        //
        spellValues = SpellValues({
            deployed_spell:                 address(0xEc0E742322F942a61fCD203334a33760A2D3A2e1),        // populate with deployed spell if deployed
            deployed_spell_created:         1611938970,        // use get-created-timestamp.sh if deployed
            previous_spell:                 address(0),        // supply if there is a need to test prior to its cast() function being called on-chain.
            previous_spell_execution_time:  0,                 // Time to warp to in order to allow the previous spell to be cast ignored if PREV_SPELL is SpellLike(address(0)).
            office_hours_enabled:           false,             // true if officehours is expected to be enabled in the spell
            expiration_threshold:           weekly_expiration  // (weekly_expiration,monthly_expiration) if weekly or monthly spell
        });
        spell = spellValues.deployed_spell != address(0) ?
            DssSpell(spellValues.deployed_spell) : new DssSpell();

        //
        // Test for all system configuration changes
        //
        afterSpell = SystemValues({
            pot_dsr:               0,                       // In basis points
            pause_delay:           48 hours,                // In seconds
            vow_wait:              156 hours,               // In seconds
            vow_dump:              250,                     // In whole Dai units
            vow_sump:              50000,                   // In whole Dai units
            vow_bump:              10000,                   // In whole Dai units
            vow_hump:              10 * MILLION,            // In whole Dai units
            flap_beg:              104 * WAD / 100,         // in (1 + pct) * WAD
            flap_ttl:              1 hours,                 // in seconds
            flap_tau:              72 hours,                // in seconds
            cat_box:               15 * MILLION,            // In whole Dai units
            pause_authority:       address(chief),          // Pause authority
            osm_mom_authority:     address(chief),          // OsmMom authority
            flipper_mom_authority: address(chief),          // FlipperMom authority
            ilk_count:             25                       // Num expected in system
        });

        //
        // Test for all collateral based changes here
        //
        afterSpell.collaterals["ETH-A"] = CollateralValues({
            aL_enabled:   true,            // DssAutoLine is enabled?
            aL_line:      1500 * MILLION,  // In whole Dai units
            aL_gap:       30 * MILLION,    // In whole Dai units
            aL_ttl:       12 hours,        // In seconds
            line:         0 * MILLION,     // In whole Dai units  // Not checked here as there is auto line
            dust:         2000,            // In whole Dai units
            pct:          350,             // In basis points
            chop:         1300,            // In basis points
            dunk:         50 * THOUSAND,   // In whole Dai units
            mat:          15000,           // In basis points
            beg:          300,             // In basis points
            ttl:          6 hours,         // In seconds
            tau:          6 hours,         // In seconds
            liquidations: 1,               // 1 if enabled
            flipper_mom:  1                // 1 if circuit breaker enabled
        });
        afterSpell.collaterals["ETH-B"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      50 * MILLION,
            aL_gap:       5 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,     // Not checked as there is auto line
            dust:         2000,
            pct:          650,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          13000,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["BAT-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         2 * MILLION,
            dust:         2000,
            pct:          800,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          15000,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["USDC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         555 * MILLION,
            dust:         2000,
            pct:          0,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          10100,
            beg:          300,
            ttl:          6 hours,
            tau:          3 days,
            liquidations: 0,
            flipper_mom:  0
        });
        afterSpell.collaterals["USDC-B"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         30 * MILLION,
            dust:         2000,
            pct:          5000,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          12000,
            beg:          300,
            ttl:          6 hours,
            tau:          3 days,
            liquidations: 0,
            flipper_mom:  0
        });
        afterSpell.collaterals["WBTC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         210 * MILLION,
            dust:         2000,
            pct:          400,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          15000,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["TUSD-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         0 * MILLION,
            dust:         2000,
            pct:          0,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          10100,
            beg:          300,
            ttl:          6 hours,
            tau:          3 days,
            liquidations: 0,
            flipper_mom:  0
        });
        afterSpell.collaterals["KNC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         5 * MILLION,
            dust:         2000,
            pct:          200,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["ZRX-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         5 * MILLION,
            dust:         2000,
            pct:          200,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["MANA-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         1 * MILLION,
            dust:         2000,
            pct:          500,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["USDT-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         25 * MILLION / 10,
            dust:         2000,
            pct:          800,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          15000,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["PAXUSD-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         100 * MILLION,
            dust:         2000,
            pct:          0,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          10100,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 0,
            flipper_mom:  0
        });
        afterSpell.collaterals["COMP-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         7 * MILLION,
            dust:         2000,
            pct:          200,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["LRC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         3 * MILLION,
            dust:         2000,
            pct:          300,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["LINK-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         20 * MILLION,
            dust:         2000,
            pct:          200,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["BAL-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         4 * MILLION,
            dust:         2000,
            pct:          200,
            chop:         1300,
            dunk:         50000,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["YFI-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         30 * MILLION,
            dust:         2000,
            pct:          600,
            chop:         1300,
            dunk:         50000,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["GUSD-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         5 * MILLION,
            dust:         2000,
            pct:          0,
            chop:         1300,
            dunk:         50000,
            mat:          10100,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 0,
            flipper_mom:  0
        });
        afterSpell.collaterals["UNI-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         15 * MILLION,
            dust:         2000,
            pct:          300,
            chop:         1300,
            dunk:         50000,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["RENBTC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         2 * MILLION,
            dust:         2000,
            pct:          600,
            chop:         1300,
            dunk:         50000,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["AAVE-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         10 * MILLION,
            dust:         2000,
            pct:          400,
            chop:         1300,
            dunk:         50000,
            mat:          17500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["UNIV2DAIETH-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         3 * MILLION,
            dust:         2000,
            pct:          100,
            chop:         1300,
            dunk:         50000,
            mat:          12500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["PSM-USDC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         500 * MILLION,
            dust:         0,
            pct:          0,
            chop:         1300,
            dunk:         50000,
            mat:          10000,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 0,
            flipper_mom:  1
        });
        afterSpell.collaterals["UNIV2WBTCETH-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         3 * MILLION,
            dust:         2000,
            pct:          200,
            chop:         1300,
            dunk:         50000,
            mat:          15000,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["UNIV2USDCETH-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         3 * MILLION,
            dust:         2000,
            pct:          100,
            chop:         1300,
            dunk:         50000,
            mat:          12500,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1,
            flipper_mom:  1
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

        hevm.warp(spell.nextCastTime());

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

        // flap
        // check beg value
        assertEq(flap.beg(), values.flap_beg);
        assertTrue(flap.beg() >= WAD && flap.beg() < 3 * WAD);
        // Check flap ttl and sanity checks
        assertEq(flap.ttl(), values.flap_ttl);
        assertTrue(flap.ttl() > 0 && flap.ttl() < 86400); // gt 0 && lt 1 day
        // Check flap tau and sanity checks
        assertEq(flap.tau(), values.flap_tau);
        assertTrue(flap.tau() > 0 && flap.tau() < 2678400); // gt 0 && lt 1 month
        assertTrue(flap.tau() >= flap.ttl());
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
            if (ilk == "PSM-USDC-A") {
                // Block can be removed when PSM hits max line
                assertTrue(aL_line == 0);
                assertTrue(line <= normalizedTestLine); // Amount should be lteq test line
                assertTrue((line >= RAD && line < 10 * BILLION * RAD) || line == 0);  // eq 0 or gt eq 1 RAD and lt 10B
            } else if (!values.collaterals[ilk].aL_enabled) {
                assertTrue(aL_line == 0);
                assertEq(line, normalizedTestLine);
                assertTrue((line >= RAD && line < 10 * BILLION * RAD) || line == 0);  // eq 0 or gt eq 1 RAD and lt 10B
            } else {
                assertTrue(aL_line > 0);
                assertEq(aL_line, values.collaterals[ilk].aL_line * RAD);
                assertEq(aL_gap, values.collaterals[ilk].aL_gap * RAD);
                assertEq(aL_ttl, values.collaterals[ilk].aL_ttl);
                assertTrue((aL_line >= RAD && aL_line < 10 * BILLION * RAD) || aL_line == 0); // eq 0 or gt eq 1 RAD and lt 10B
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

            assertEq(flip.wards(address(flipMom)), values.collaterals[ilk].flipper_mom);

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
        // NOTE: Remove the range check when the lerp is complete
        // Sum lines is not going to equal vat.Line() for the next 12 weeks
        assertTrue(vat.Line() <= sumlines + 500 * MILLION * RAD && sumlines <= vat.Line());
    }

    function testFailWrongDay() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote();
            scheduleWaitAndCastFailDay();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testFailTooEarly() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote();
            scheduleWaitAndCastFailEarly();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testFailTooLate() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote();
            scheduleWaitAndCastFailLate();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testOnTime() public {
        vote();
        scheduleWaitAndCast();
    }

    function testSpellIsCast() public {
        string memory description = new DssSpell().description();
        assertTrue(bytes(description).length > 0);
        // DS-Test can't handle strings directly, so cast to a bytes32.
        assertEq(stringToBytes32(spell.description()),
                stringToBytes32(description));

        if(address(spell) != address(spellValues.deployed_spell)) {
            assertEq(spell.expiration(), (now + spellValues.expiration_threshold));
        } else {
            assertEq(spell.expiration(), (spellValues.deployed_spell_created + spellValues.expiration_threshold));
        }

        castPreviousSpell();
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        checkSystemValues(afterSpell);

        checkCollateralValues(afterSpell);
    }

    function testCastCost() public {
        vote();
        spell.schedule();

        castPreviousSpell();

        hevm.warp(spell.nextCastTime());
        uint startGas = gasleft();
        spell.cast();
        uint endGas = gasleft();
        uint totalGas = startGas - endGas;

        assertTrue(spell.done());
        // Fail if cast is too expensive
        assertTrue(totalGas <= 8 * MILLION);
    }

    function test_nextCastTime() public {
        hevm.warp(1606161600); // Nov 23, 20 UTC (could be cast Nov 26)

        vote();
        spell.schedule();

        uint256 monday_1400_UTC = 1606744800; // Nov 30, 2020
        uint256 monday_2100_UTC = 1606770000; // Nov 30, 2020

        // Day tests
        hevm.warp(monday_1400_UTC);                                    // Monday,   14:00 UTC
        assertEq(spell.nextCastTime(), monday_1400_UTC);               // Monday,   14:00 UTC

        if (spell.officeHours()) {
            hevm.warp(monday_1400_UTC - 1 days);                       // Sunday,   14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_1400_UTC - 2 days);                       // Saturday, 14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_1400_UTC - 3 days);                       // Friday,   14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC - 3 days);  // Able to cast

            hevm.warp(monday_2100_UTC);                                // Monday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC + 1 days);  // Tuesday,  14:00 UTC

            hevm.warp(monday_2100_UTC - 1 days);                       // Sunday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_2100_UTC - 2 days);                       // Saturday, 21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_2100_UTC - 3 days);                       // Friday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            // Time tests
            uint256 castTime;

            for(uint i = 0; i < 5; i++) {
                castTime = monday_1400_UTC + i * 1 days; // Next day at 14:00 UTC
                hevm.warp(castTime - 1 seconds); // 13:59:59 UTC
                assertEq(spell.nextCastTime(), castTime);

                hevm.warp(castTime + 7 hours + 1 seconds); // 21:00:01 UTC
                if (i < 4) {
                    assertEq(spell.nextCastTime(), monday_1400_UTC + (i + 1) * 1 days); // Next day at 14:00 UTC
                } else {
                    assertEq(spell.nextCastTime(), monday_1400_UTC + 7 days); // Next monday at 14:00 UTC (friday case)
                }
            }
        }
    }

    function testFail_notScheduled() public {
        spell.nextCastTime();
    }

    function test_use_eta() public {
        hevm.warp(1606161600); // Nov 23, 20 UTC (could be cast Nov 26)

        vote();
        spell.schedule();

        uint castTime = spell.nextCastTime();
        assertEq(castTime, spell.eta());
    }

    function test_OSMs() public {
        vote();
        spell.schedule();
        castPreviousSpell();
        hevm.warp(spell.nextCastTime());
        spell.cast();
        assertTrue(spell.done());

        // Track OSM authorizations here

        address YEARN_PROXY = 0x208EfCD7aad0b5DD49438E0b6A0f38E951A50E5f;
        assertEq(OsmAbstract(addr.addr("PIP_YFI")).bud(YEARN_PROXY), 1);

        // Gnosis
        address GNOSIS = 0xD5885fbCb9a8a8244746010a3BC6F1C6e0269777;
        assertEq(OsmAbstract(addr.addr("PIP_WBTC")).bud(GNOSIS), 1);
        assertEq(OsmAbstract(addr.addr("PIP_LINK")).bud(GNOSIS), 1);
        assertEq(OsmAbstract(addr.addr("PIP_COMP")).bud(GNOSIS), 1);
        assertEq(OsmAbstract(addr.addr("PIP_YFI")).bud(GNOSIS), 1);
        assertEq(OsmAbstract(addr.addr("PIP_ZRX")).bud(GNOSIS), 1);

        // Instadapp
        address INSTADAPP = 0xDF3CDd10e646e4155723a3bC5b1191741DD90333;
        assertEq(OsmAbstract(addr.addr("PIP_ETH")).bud(INSTADAPP), 1);
    }

    function test_Medianizers() public {
        vote();
        spell.schedule();
        castPreviousSpell();
        hevm.warp(spell.nextCastTime());
        spell.cast();
        assertTrue(spell.done());

        // Track Median authorizations here

        address SET_AAVE    = 0x8b1C079f8192706532cC0Bf0C02dcC4fF40d045D;
        address AAVEUSD_MED = OsmAbstract(addr.addr("PIP_AAVE")).src();
        assertEq(MedianAbstract(AAVEUSD_MED).bud(SET_AAVE), 1);

        address SET_LRC     = 0x1D5d9a2DDa0843eD9D8a9Bddc33F1fca9f9C64a0;
        address LRCUSD_MED  = OsmAbstract(addr.addr("PIP_LRC")).src();
        assertEq(MedianAbstract(LRCUSD_MED).bud(SET_LRC), 1);

        address SET_YFI     = 0x1686d01Bd776a1C2A3cCF1579647cA6D39dd2465;
        address YFIUSD_MED  = OsmAbstract(addr.addr("PIP_YFI")).src();
        assertEq(MedianAbstract(YFIUSD_MED).bud(SET_YFI), 1);

        address SET_ZRX     = 0xFF60D1650696238F81BE53D23b3F91bfAAad938f;
        address ZRXUSD_MED  = OsmAbstract(addr.addr("PIP_ZRX")).src();
        assertEq(MedianAbstract(ZRXUSD_MED).bud(SET_ZRX), 1);

        address SET_UNI     = 0x3c3Afa479d8C95CF0E1dF70449Bb5A14A3b7Af67;
        address UNIUSD_MED  = OsmAbstract(addr.addr("PIP_UNI")).src();
        assertEq(MedianAbstract(UNIUSD_MED).bud(SET_UNI), 1);
    }

    event Log(string message, address deployer, bytes32 contractName);

    function hasWards(address addr) internal returns (bool) {
        (bool ok, bytes memory data) = addr
            .call(abi.encodeWithSignature("wards(address)", 0x0));
        return ok && data.length == 32;
    }

    address[] evilAddresses = [
        0xdDb108893104dE4E1C6d0E47c42237dB4E617ACc,
        0xDa0FaB05039809e63C5D068c897c3e602fA97457,
        0xda0fab060e6cc7b1C0AA105d29Bd50D71f036711,
        0xDA0FaB0700A4389F6E6679aBAb1692B4601ce9bf
    ];

    function hasBadAuth(address addr, bytes32 contractName) internal {
        for (uint i = 0; i < evilAddresses.length; i ++) {
            if (AuthLike(addr).wards(evilAddresses[i]) > 0) {
                emit Log("Bad auth", evilAddresses[i], contractName);
                fail();
            }
        }
    }

    function test_wards() public {
        vote();
        spell.schedule();
        castPreviousSpell();
        hevm.warp(spell.nextCastTime());
        spell.cast();
        assertTrue(spell.done());
        ChainLogLike chainLog = ChainLogLike(addr.addr("CHANGELOG"));
        bytes32[] memory contractNames = chainLog.list();
        for(uint i = 0; i < contractNames.length; i++) {
            try chainLog.getAddress(contractNames[i]) returns (address addr) {
                if (hasWards(addr)) {
                    hasBadAuth(addr, contractNames[i]);
                }
            } catch Error(string memory reason) {
                if (keccak256(bytes(reason))
                    != keccak256(bytes("dss-chain-log/invalid-key"))) {
                    revert(reason);
                }
            }
        }
    }

}
