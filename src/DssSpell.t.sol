// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.6.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "dss-interfaces/Interfaces.sol";
import "./test/rates.sol";
import "./test/addresses_mainnet.sol";

import {DssSpell} from "./DssSpell.sol";

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
    function load(address,bytes32) external view returns (bytes32);
}

interface SpellLike {
    function done() external view returns (bool);
    function eta() external view returns (uint256);
    function cast() external;
    function nextCastTime() external returns (uint256);
}

interface AuthLike {
    function wards(address) external view returns (uint256);
}

// Specific for this spell
interface TokenCompatibleUSDT {
    function approve(address, uint256) external;
}
//

contract DssSpellTest is DSTest, DSMath {

    struct SpellValues {
        address deployed_spell;
        uint256 deployed_spell_created;
        address previous_spell;
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
        uint256 pct;
        uint256 mat;
        bytes32 liqType;
        bool    liqOn;
        uint256 chop;
        uint256 cat_dunk;
        uint256 flip_beg;
        uint48  flip_ttl;
        uint48  flip_tau;
        uint256 flipper_mom;
        uint256 dog_hole;
        uint256 clip_buf;
        uint256 clip_tail;
        uint256 clip_cusp;
        uint256 clip_chip;
        uint256 clip_tip;
        uint256 clipper_mom;
        uint256 cm_tolerance;
        uint256 calc_tau;
        uint256 calc_step;
        uint256 calc_cut;
    }

    struct SystemValues {
        uint256 pot_dsr;
        uint256 pause_delay;
        uint256 vow_wait;
        uint256 vow_dump;
        uint256 vow_sump;
        uint256 vow_bump;
        uint256 vow_hump_min;
        uint256 vow_hump_max;
        uint256 flap_beg;
        uint256 flap_ttl;
        uint256 flap_tau;
        uint256 cat_box;
        uint256 dog_Hole;
        address pause_authority;
        address osm_mom_authority;
        address flipper_mom_authority;
        address clipper_mom_authority;
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
    DogAbstract              dog = DogAbstract(        addr.addr("MCD_DOG"));
    PotAbstract              pot = PotAbstract(        addr.addr("MCD_POT"));
    JugAbstract              jug = JugAbstract(        addr.addr("MCD_JUG"));
    SpotAbstract         spotter = SpotAbstract(       addr.addr("MCD_SPOT"));
    DaiAbstract              dai = DaiAbstract(        addr.addr("MCD_DAI"));
    DaiJoinAbstract      daiJoin = DaiJoinAbstract(    addr.addr("MCD_JOIN_DAI"));
    DSTokenAbstract          gov = DSTokenAbstract(    addr.addr("MCD_GOV"));
    EndAbstract              end = EndAbstract(        addr.addr("MCD_END"));
    ESMAbstract              esm = ESMAbstract(        addr.addr("MCD_ESM"));
    IlkRegistryAbstract      reg = IlkRegistryAbstract(addr.addr("ILK_REGISTRY"));
    FlapAbstract            flap = FlapAbstract(       addr.addr("MCD_FLAP"));

    OsmMomAbstract        osmMom = OsmMomAbstract(     addr.addr("OSM_MOM"));
    FlipperMomAbstract   flipMom = FlipperMomAbstract( addr.addr("FLIPPER_MOM"));
    ClipperMomAbstract   clipMom = ClipperMomAbstract( addr.addr("CLIPPER_MOM"));
    DssAutoLineAbstract autoLine = DssAutoLineAbstract(addr.addr("MCD_IAM_AUTO_LINE"));

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
    event Log(string message, address deployer, string contractName);

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
    function divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(x, sub(y, 1)) / y;
    }

    function bytes32ToStr(bytes32 _bytes32) internal pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
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
            if (prevSpell.eta() == 0) {
                vote(address(prevSpell));
                scheduleWaitAndCast(address(prevSpell));
            }
            else {
                // jump to nextCastTime to be a little more forgiving on the spell execution time
                hevm.warp(prevSpell.nextCastTime());
                prevSpell.cast();
            }
        }
    }

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));

        //
        // Test for spell-specific parameters
        //
        spellValues = SpellValues({
            deployed_spell:                 address(0),        // populate with deployed spell if deployed
            deployed_spell_created:         1622215614,        // use get-created-timestamp.sh if deployed
            previous_spell:                 address(0x8EFE2c82bD31B67fa262c0D364773629f6EA828A),        // supply if there is a need to test prior to its cast() function being called on-chain.
            office_hours_enabled:           true,              // true if officehours is expected to be enabled in the spell
            expiration_threshold:           weekly_expiration  // (weekly_expiration,monthly_expiration) if weekly or monthly spell
        });
        spellValues.deployed_spell_created = spellValues.deployed_spell != address(0) ? spellValues.deployed_spell_created : block.timestamp;
        spell = spellValues.deployed_spell != address(0) ?
            DssSpell(spellValues.deployed_spell) : new DssSpell();

        //
        // Test for all system configuration changes
        //
        afterSpell = SystemValues({
            pot_dsr:               1,                       // In basis points
            pause_delay:           48 hours,                // In seconds
            vow_wait:              156 hours,               // In seconds
            vow_dump:              250,                     // In whole Dai units
            vow_sump:              50 * THOUSAND,           // In whole Dai units
            vow_bump:              30 * THOUSAND,           // In whole Dai units
            vow_hump_min:          30 * MILLION,            // In whole Dai units
            vow_hump_max:          60 * MILLION,            // In whole Dai units
            flap_beg:              400,                     // in basis points
            flap_ttl:              1 hours,                 // in seconds
            flap_tau:              72 hours,                // in seconds
            cat_box:               20 * MILLION,            // In whole Dai units
            dog_Hole:              100 * MILLION,           // In whole Dai units
            pause_authority:       address(chief),          // Pause authority
            osm_mom_authority:     address(chief),          // OsmMom authority
            flipper_mom_authority: address(chief),          // FlipperMom authority
            clipper_mom_authority: address(chief),          // ClipperMom authority
            ilk_count:             35                       // Num expected in system
        });

        //
        // Test for all collateral based changes here
        //
        afterSpell.collaterals["ETH-A"] = CollateralValues({
            aL_enabled:   true,            // DssAutoLine is enabled?
            aL_line:      15 * BILLION,  // In whole Dai units
            aL_gap:       80 * MILLION,    // In whole Dai units
            aL_ttl:       12 hours,        // In seconds
            line:         0 * MILLION,     // In whole Dai units  // Not checked here as there is auto line
            dust:         5 * THOUSAND,    // In whole Dai units
            pct:          550,             // In basis points
            mat:          15000,           // In basis points
            liqType:      "clip",          // "" or "flip" or "clip"
            liqOn:        true,            // If liquidations are enabled
            chop:         1300,            // In basis points
            cat_dunk:     0,               // In whole Dai units
            flip_beg:     0,               // In basis points
            flip_ttl:     0,               // In seconds
            flip_tau:     0,               // In seconds
            flipper_mom:  0,               // 1 if circuit breaker enabled
            dog_hole:     22 * MILLION,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900
        });
        afterSpell.collaterals["ETH-B"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      50 * MILLION,
            aL_gap:       5 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,     // Not checked as there is auto line
            dust:         15 * THOUSAND,
            pct:          1000,
            mat:          13000,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     8 * MILLION,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900
        });
        afterSpell.collaterals["ETH-C"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      2000 * MILLION,
            aL_gap:       100 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          300,
            mat:          17500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     5 * MILLION,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900
        });
        afterSpell.collaterals["BAT-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      7 * MILLION,
            aL_gap:       1 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          500,
            mat:          15000,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     1 * MILLION + 500 * THOUSAND,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900
        });
        afterSpell.collaterals["USDC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          0,
            mat:          10100,
            liqType:      "clip",
            liqOn:        false,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     0,
            clip_buf:     10500,
            clip_tail:    220 minutes,
            clip_cusp:    9000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  0,
            cm_tolerance: 9500,
            calc_tau:     0,
            calc_step:    120,
            calc_cut:     9990
        });
        afterSpell.collaterals["USDC-B"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          5000,
            mat:          12000,
            liqType:      "clip",
            liqOn:        false,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     0,
            clip_buf:     10500,
            clip_tail:    220 minutes,
            clip_cusp:    9000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  0,
            cm_tolerance: 9500,
            calc_tau:     0,
            calc_step:    120,
            calc_cut:     9990
        });
        afterSpell.collaterals["WBTC-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      750 * MILLION,
            aL_gap:       15 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          450,
            mat:          15000,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     15 * MILLION,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900
        });
        afterSpell.collaterals["TUSD-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          100,
            mat:          10100,
            liqType:      "clip",
            liqOn:        false,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     0,
            clip_buf:     10500,
            clip_tail:    220 minutes,
            clip_cusp:    9000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  0,
            cm_tolerance: 9500,
            calc_tau:     0,
            calc_step:    120,
            calc_cut:     9990
        });
        afterSpell.collaterals["KNC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          500,
            mat:          17500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     500 * THOUSAND,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900
        });
        afterSpell.collaterals["ZRX-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      10 * MILLION,
            aL_gap:       1 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          400,
            mat:          17500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     1 * MILLION,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900
        });
        afterSpell.collaterals["MANA-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      5 * MILLION,
            aL_gap:       1 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          300,
            mat:          17500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     1 * MILLION,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900
        });
        afterSpell.collaterals["USDT-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         0,
            dust:         5 * THOUSAND,
            pct:          800,
            mat:          15000,
            liqType:      "clip",
            liqOn:        false,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     0,
            clip_buf:     10500,
            clip_tail:    220 minutes,
            clip_cusp:    9000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  0,
            cm_tolerance: 9500,
            calc_tau:     0,
            calc_step:    120,
            calc_cut:     9990
        });
        afterSpell.collaterals["PAXUSD-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          100,
            mat:          10100,
            liqType:      "clip",
            liqOn:        false,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     0,
            clip_buf:     10500,
            clip_tail:    220 minutes,
            clip_cusp:    9000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  0,
            cm_tolerance: 9500,
            calc_tau:     0,
            calc_step:    120,
            calc_cut:     9990
        });
        afterSpell.collaterals["COMP-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      30 * MILLION,
            aL_gap:       2 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          300,
            mat:          17500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     2 * MILLION,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900
        });
        afterSpell.collaterals["LRC-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      5 * MILLION,
            aL_gap:       1 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          400,
            mat:          17500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     500 * THOUSAND,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900
        });
        afterSpell.collaterals["LINK-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      140 * MILLION,
            aL_gap:       7 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          500,
            mat:          17500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     6 * MILLION,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900
        });
        afterSpell.collaterals["BAL-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      30 * MILLION,
            aL_gap:       3 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          200,
            mat:          17500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     3 * MILLION,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900
        });
        afterSpell.collaterals["YFI-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      90 * MILLION,
            aL_gap:       5 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          550,
            mat:          17500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     5 * MILLION,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900
        });
        afterSpell.collaterals["GUSD-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         5 * MILLION,
            dust:         5 * THOUSAND,
            pct:          0,
            mat:          10100,
            liqType:      "clip",
            liqOn:        false,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     0,
            clip_buf:     10500,
            clip_tail:    220 minutes,
            clip_cusp:    9000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  0,
            cm_tolerance: 9500,
            calc_tau:     0,
            calc_step:    120,
            calc_cut:     9990
        });
        afterSpell.collaterals["UNI-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      50 * MILLION,
            aL_gap:       3 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          300,
            mat:          17500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     5 * MILLION,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900
        });
        afterSpell.collaterals["RENBTC-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      10 * MILLION,
            aL_gap:       1 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          500,
            mat:          17500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     3 * MILLION,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900
        });
        afterSpell.collaterals["AAVE-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      50 * MILLION,
            aL_gap:       5 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          300,
            mat:          17500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     5 * MILLION,
            clip_buf:     13000,
            clip_tail:    140 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    90,
            calc_cut:     9900
        });
        afterSpell.collaterals["UNIV2DAIETH-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      50 * MILLION,
            aL_gap:       5 * MILLION,
            aL_ttl:       12 hours,
            line:         0,
            dust:         5 * THOUSAND,
            pct:          350,
            mat:          12500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     5 * MILLION,
            clip_buf:     11500,
            clip_tail:    215 minutes,
            clip_cusp:    6000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 7000,
            calc_tau:     0,
            calc_step:    125,
            calc_cut:     9950
        });
        afterSpell.collaterals["PSM-USDC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         3 * BILLION,
            dust:         0,
            pct:          0,
            mat:          10000,
            liqType:      "clip",
            liqOn:        false,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     0,
            clip_buf:     10500,
            clip_tail:    220 minutes,
            clip_cusp:    9000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  0,
            cm_tolerance: 9500,
            calc_tau:     0,
            calc_step:    120,
            calc_cut:     9990
        });
        afterSpell.collaterals["UNIV2WBTCETH-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      20 * MILLION,
            aL_gap:       3 * MILLION,
            aL_ttl:       12 hours,
            line:         0,
            dust:         5 * THOUSAND,
            pct:          450,
            mat:          15000,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     5 * MILLION,
            clip_buf:     13000,
            clip_tail:    200 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    130,
            calc_cut:     9900
        });
        afterSpell.collaterals["UNIV2USDCETH-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      50 * MILLION,
            aL_gap:       5 * MILLION,
            aL_ttl:       12 hours,
            line:         0,
            dust:         5 * THOUSAND,
            pct:          450,
            mat:          12500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     5 * MILLION,
            clip_buf:     11500,
            clip_tail:    215 minutes,
            clip_cusp:    6000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 7000,
            calc_tau:     0,
            calc_step:    125,
            calc_cut:     9950
        });
        afterSpell.collaterals["UNIV2DAIUSDC-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      50 * MILLION,
            aL_gap:       10 * MILLION,
            aL_ttl:       12 hours,
            line:         0,
            dust:         5 * THOUSAND,
            pct:          100,
            mat:          10500,
            liqType:      "clip",
            liqOn:        false,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     0,
            clip_buf:     10500,
            clip_tail:    220 minutes,
            clip_cusp:    9000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  0,
            cm_tolerance: 9500,
            calc_tau:     0,
            calc_step:    120,
            calc_cut:     9990
        });
        afterSpell.collaterals["UNIV2ETHUSDT-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      10 * MILLION,
            aL_gap:       2 * MILLION,
            aL_ttl:       12 hours,
            line:         0,
            dust:         5 * THOUSAND,
            pct:          500,
            mat:          14000,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     5 * MILLION,
            clip_buf:     11500,
            clip_tail:    215 minutes,
            clip_cusp:    6000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 7000,
            calc_tau:     0,
            calc_step:    125,
            calc_cut:     9950
        });
        afterSpell.collaterals["UNIV2LINKETH-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      20 * MILLION,
            aL_gap:       2 * MILLION,
            aL_ttl:       12 hours,
            line:         0,
            dust:         5 * THOUSAND,
            pct:          400,
            mat:          16500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     3 * MILLION,
            clip_buf:     13000,
            clip_tail:    200 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    130,
            calc_cut:     9900
        });
        afterSpell.collaterals["UNIV2UNIETH-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      20 * MILLION,
            aL_gap:       3 * MILLION,
            aL_ttl:       12 hours,
            line:         0,
            dust:         5 * THOUSAND,
            pct:          500,
            mat:          16500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     3 * MILLION,
            clip_buf:     13000,
            clip_tail:    200 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    130,
            calc_cut:     9900
        });
        afterSpell.collaterals["UNIV2WBTCDAI-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      20 * MILLION,
            aL_gap:       3 * MILLION,
            aL_ttl:       12 hours,
            line:         0,
            dust:         5 * THOUSAND,
            pct:          0,
            mat:          12500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     5 * MILLION,
            clip_buf:     11500,
            clip_tail:    215 minutes,
            clip_cusp:    6000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 7000,
            calc_tau:     0,
            calc_step:    125,
            calc_cut:     9950
        });
        afterSpell.collaterals["UNIV2AAVEETH-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      20 * MILLION,
            aL_gap:       2 * MILLION,
            aL_ttl:       12 hours,
            line:         0,
            dust:         5 * THOUSAND,
            pct:          400,
            mat:          16500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     3 * MILLION,
            clip_buf:     13000,
            clip_tail:    200 minutes,
            clip_cusp:    4000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 5000,
            calc_tau:     0,
            calc_step:    130,
            calc_cut:     9900
        });
        afterSpell.collaterals["UNIV2DAIUSDT-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      10 * MILLION,
            aL_gap:       2 * MILLION,
            aL_ttl:       12 hours,
            line:         0,
            dust:         5 * THOUSAND,
            pct:          300,
            mat:          12500,
            liqType:      "clip",
            liqOn:        true,
            chop:         1300,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     5 * MILLION,
            clip_buf:     10500,
            clip_tail:    220 minutes,
            clip_cusp:    9000,
            clip_chip:    10,
            clip_tip:     300,
            clipper_mom:  1,
            cm_tolerance: 9500,
            calc_tau:     0,
            calc_step:    120,
            calc_cut:     9990
        });
        afterSpell.collaterals["RWA001-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         1 * THOUSAND,
            dust:         0,
            pct:          300,
            mat:          10000,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0
        });
        afterSpell.collaterals["RWA002-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         5 * MILLION,
            dust:         0,
            pct:          350,
            mat:          10500,
            liqType:      "",
            liqOn:        false,
            chop:         0,
            cat_dunk:     0,
            flip_beg:     0,
            flip_ttl:     0,
            flip_tau:     0,
            flipper_mom:  0,
            dog_hole:     0,
            clip_buf:     0,
            clip_tail:    0,
            clip_cusp:    0,
            clip_chip:    0,
            clip_tip:     0,
            clipper_mom:  0,
            cm_tolerance: 0,
            calc_tau:     0,
            calc_step:    0,
            calc_cut:     0
        });

        castPreviousSpell();
    }

    function scheduleWaitAndCastFailDay() public {
        spell.schedule();

        uint256 castTime = block.timestamp + pause.delay();
        uint256 day = (castTime / 1 days + 3) % 7;
        if (day < 5) {
            castTime += 5 days - day * 86400;
        }

        hevm.warp(castTime);
        spell.cast();
    }

    function scheduleWaitAndCastFailEarly() public {
        spell.schedule();

        uint256 castTime = block.timestamp + pause.delay() + 24 hours;
        uint256 hour = castTime / 1 hours % 24;
        if (hour >= 14) {
            castTime -= hour * 3600 - 13 hours;
        }

        hevm.warp(castTime);
        spell.cast();
    }

    function scheduleWaitAndCastFailLate() public {
        spell.schedule();

        uint256 castTime = block.timestamp + pause.delay();
        uint256 hour = castTime / 1 hours % 24;
        if (hour < 21) {
            castTime += 21 hours - hour * 3600;
        }

        hevm.warp(castTime);
        spell.cast();
    }

    function vote(address spell_) internal {
        if (chief.hat() != spell_) {
            hevm.store(
                address(gov),
                keccak256(abi.encode(address(this), uint256(1))),
                bytes32(uint256(999999999999 ether))
            );
            gov.approve(address(chief), uint256(-1));
            chief.lock(999999999999 ether);

            address[] memory slate = new address[](1);

            assertTrue(!DssSpell(spell_).done());

            slate[0] = spell_;

            chief.vote(slate);
            chief.lift(spell_);
        }
        assertEq(chief.hat(), spell_);
    }

    function scheduleWaitAndCast(address spell_) public {
        DssSpell(spell_).schedule();

        hevm.warp(DssSpell(spell_).nextCastTime());

        DssSpell(spell_).cast();
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
            pot.dsr() >= RAY && pot.dsr() < 1000000021979553151239153027,
            "TestError/pot-dsr-range"
        );
        assertTrue(diffCalc(expectedRate(values.pot_dsr), yearlyYield(expectedDSRRate)) <= TOLERANCE);

        {
        // Line values in RAD
        assertTrue(
            (vat.Line() >= RAD && vat.Line() < 100 * BILLION * RAD) ||
            vat.Line() == 0,
            "TestError/vat-Line-range"
        );
        }

        // Pause delay
        assertEq(pause.delay(), values.pause_delay, "TestError/pause-delay");

        // wait
        assertEq(vow.wait(), values.vow_wait, "TestError/vow-wait");
        {
        // dump values in WAD
        uint256 normalizedDump = values.vow_dump * WAD;
        assertEq(vow.dump(), normalizedDump, "TestError/vow-dump");
        assertTrue(
            (vow.dump() >= WAD && vow.dump() < 2 * THOUSAND * WAD) ||
            vow.dump() == 0,
            "TestError/vow-dump-range"
        );
        }
        {
        // sump values in RAD
        uint256 normalizedSump = values.vow_sump * RAD;
        assertEq(vow.sump(), normalizedSump, "TestError/vow-sump");
        assertTrue(
            (vow.sump() >= RAD && vow.sump() < 500 * THOUSAND * RAD) ||
            vow.sump() == 0,
            "TestError/vow-sump-range"
        );
        }
        {
        // bump values in RAD
        uint256 normalizedBump = values.vow_bump * RAD;
        assertEq(vow.bump(), normalizedBump, "TestError/vow-bump");
        assertTrue(
            (vow.bump() >= RAD && vow.bump() < HUNDRED * THOUSAND * RAD) ||
            vow.bump() == 0,
            "TestError/vow-bump-range"
        );
        }
        {
        // hump values in RAD
        uint256 normalizedHumpMin = values.vow_hump_min * RAD;
        uint256 normalizedHumpMax = values.vow_hump_max * RAD;
        assertTrue(vow.hump() >= normalizedHumpMin && vow.hump() <= normalizedHumpMax, "TestError/vow-hump-min-max");
        assertTrue(
            (vow.hump() >= RAD && vow.hump() < HUNDRED * MILLION * RAD) ||
            vow.hump() == 0,
            "TestError/vow-hump-range"
        );
        }

        // box value in RAD
        {
            uint256 normalizedBox = values.cat_box * RAD;
            assertEq(cat.box(), normalizedBox, "TestError/cat-box");
            assertTrue(cat.box() >= MILLION * RAD && cat.box() <= 50 * MILLION * RAD, "TestError/cat-box-range");
        }

        // Hole value in RAD
        {
            uint256 normalizedHole = values.dog_Hole * RAD;
            assertEq(dog.Hole(), normalizedHole, "TestError/dog-Hole");
            assertTrue(dog.Hole() >= MILLION * RAD && dog.Hole() <= 50 * MILLION * RAD, "TestError/dog-Hole-range");
        }

        // check Pause authority
        assertEq(pause.authority(), values.pause_authority, "TestError/pause-authority");

        // check OsmMom authority
        assertEq(osmMom.authority(), values.osm_mom_authority, "TestError/osmMom-authority");

        // check FlipperMom authority
        assertEq(flipMom.authority(), values.flipper_mom_authority, "TestError/flipperMom-authority");

        // check ClipperMom authority
        assertEq(clipMom.authority(), values.clipper_mom_authority, "TestError/clipperMom-authority");

        // check number of ilks
        assertEq(reg.count(), values.ilk_count, "TestError/ilks-count");

        // flap
        // check beg value
        uint256 normalizedTestBeg = (values.flap_beg + 10000)  * 10**14;
        assertEq(flap.beg(), normalizedTestBeg, "TestError/flap-beg");
        assertTrue(flap.beg() >= WAD && flap.beg() <= 110 * WAD / 100, "TestError/flap-beg-range"); // gte 0% and lte 10%
        // Check flap ttl and sanity checks
        assertEq(flap.ttl(), values.flap_ttl, "TestError/flap-ttl");
        assertTrue(flap.ttl() > 0 && flap.ttl() < 86400, "TestError/flap-ttl-range"); // gt 0 && lt 1 day
        // Check flap tau and sanity checks
        assertEq(flap.tau(), values.flap_tau, "TestError/flap-tau");
        assertTrue(flap.tau() > 0 && flap.tau() < 2678400, "TestError/flap-tau-range"); // gt 0 && lt 1 month
        assertTrue(flap.tau() >= flap.ttl(), "TestError/flap-tau-ttl");
    }

    function checkCollateralValues(SystemValues storage values) internal {
        uint256 sumlines;
        bytes32[] memory ilks = reg.list();
        for(uint256 i = 0; i < ilks.length; i++) {
            bytes32 ilk = ilks[i];
            (uint256 duty,)  = jug.ilks(ilk);

            assertEq(duty, rates.rates(values.collaterals[ilk].pct), string(abi.encodePacked("TestError/jug-duty-", ilk)));
            // make sure duty is less than 1000% APR
            // bc -l <<< 'scale=27; e( l(10.00)/(60 * 60 * 24 * 365) )'
            // 1000000073014496989316680335
            assertTrue(duty >= RAY && duty < 1000000073014496989316680335, string(abi.encodePacked("TestError/jug-duty-range-", ilk)));  // gt 0 and lt 1000%
            assertTrue(
                diffCalc(expectedRate(values.collaterals[ilk].pct), yearlyYield(rates.rates(values.collaterals[ilk].pct))) <= TOLERANCE,
                string(abi.encodePacked("TestError/rates-", ilk))
            );
            assertTrue(values.collaterals[ilk].pct < THOUSAND * THOUSAND, string(abi.encodePacked("TestError/pct-max-", ilk)));   // check value lt 1000%
            {
            (,,, uint256 line, uint256 dust) = vat.ilks(ilk);
            // Convert whole Dai units to expected RAD
            uint256 normalizedTestLine = values.collaterals[ilk].line * RAD;
            sumlines += line;
            (uint256 aL_line, uint256 aL_gap, uint256 aL_ttl,,) = autoLine.ilks(ilk);
            if (!values.collaterals[ilk].aL_enabled) {
                assertTrue(aL_line == 0, string(abi.encodePacked("TestError/al-Line-not-zero-", ilk)));
                assertEq(line, normalizedTestLine, string(abi.encodePacked("TestError/vat-line-", ilk)));
                assertTrue((line >= RAD && line < 10 * BILLION * RAD) || line == 0, string(abi.encodePacked("TestError/vat-line-range-", ilk)));  // eq 0 or gt eq 1 RAD and lt 10B
            } else {
                assertTrue(aL_line > 0, string(abi.encodePacked("TestError/al-Line-is-zero-", ilk)));
                assertEq(aL_line, values.collaterals[ilk].aL_line * RAD, string(abi.encodePacked("TestError/al-line-", ilk)));
                assertEq(aL_gap, values.collaterals[ilk].aL_gap * RAD, string(abi.encodePacked("TestError/al-gap-", ilk)));
                assertEq(aL_ttl, values.collaterals[ilk].aL_ttl, string(abi.encodePacked("TestError/al-ttl-", ilk)));
                assertTrue((aL_line >= RAD && aL_line < 20 * BILLION * RAD) || aL_line == 0, string(abi.encodePacked("TestError/al-line-range-", ilk))); // eq 0 or gt eq 1 RAD and lt 10B
            }
            uint256 normalizedTestDust = values.collaterals[ilk].dust * RAD;
            assertEq(dust, normalizedTestDust, string(abi.encodePacked("TestError/vat-dust-", ilk)));
            assertTrue((dust >= RAD && dust < 20 * THOUSAND * RAD) || dust == 0, string(abi.encodePacked("TestError/vat-dust-range-", ilk))); // eq 0 or gt eq 1 and lt 10k
            }

            {
            (,uint256 mat) = spotter.ilks(ilk);
            // Convert BP to system expected value
            uint256 normalizedTestMat = (values.collaterals[ilk].mat * 10**23);
            assertEq(mat, normalizedTestMat, string(abi.encodePacked("TestError/vat-mat-", ilk)));
            assertTrue(mat >= RAY && mat < 10 * RAY, string(abi.encodePacked("TestError/vat-mat-range-", ilk)));    // cr eq 100% and lt 1000%
            }

            if (values.collaterals[ilk].liqType == "flip") {
                {
                assertEq(reg.class(ilk), 2, string(abi.encodePacked("TestError/reg-class-", ilk)));
                (bool ok, bytes memory val) = reg.xlip(ilk).call(abi.encodeWithSignature("cat()"));
                assertTrue(ok, string(abi.encodePacked("TestError/reg-xlip-cat-", ilk)));
                assertEq(abi.decode(val, (address)), address(cat), string(abi.encodePacked("TestError/reg-xlip-cat-", ilk)));
                }
                {
                (, uint256 chop, uint256 dunk) = cat.ilks(ilk);
                // Convert BP to system expected value
                uint256 normalizedTestChop = (values.collaterals[ilk].chop * 10**14) + WAD;
                assertEq(chop, normalizedTestChop, string(abi.encodePacked("TestError/cat-chop-", ilk)));
                // make sure chop is less than 100%
                assertTrue(chop >= WAD && chop < 2 * WAD, string(abi.encodePacked("TestError/cat-chop-range-", ilk)));   // penalty gt eq 0% and lt 100%

                // Convert whole Dai units to expected RAD
                uint256 normalizedTestDunk = values.collaterals[ilk].cat_dunk * RAD;
                assertEq(dunk, normalizedTestDunk, string(abi.encodePacked("TestError/cat-dunk-", ilk)));
                assertTrue(dunk >= RAD && dunk < MILLION * RAD, string(abi.encodePacked("TestError/cat-dunk-range-", ilk)));

                (address flipper,,) = cat.ilks(ilk);
                FlipAbstract flip = FlipAbstract(flipper);
                // Convert BP to system expected value
                uint256 normalizedTestBeg = (values.collaterals[ilk].flip_beg + 10000)  * 10**14;
                assertEq(uint256(flip.beg()), normalizedTestBeg, string(abi.encodePacked("TestError/flip-beg-", ilk)));
                assertTrue(flip.beg() >= WAD && flip.beg() <= 110 * WAD / 100, string(abi.encodePacked("TestError/flip-beg-range-", ilk))); // gte 0% and lte 10%
                assertEq(uint256(flip.ttl()), values.collaterals[ilk].flip_ttl, string(abi.encodePacked("TestError/flip-ttl-", ilk)));
                assertTrue(flip.ttl() >= 600 && flip.ttl() < 10 hours, string(abi.encodePacked("TestError/flip-ttl-range-", ilk)));         // gt eq 10 minutes and lt 10 hours
                assertEq(uint256(flip.tau()), values.collaterals[ilk].flip_tau, string(abi.encodePacked("TestError/flip-tau-", ilk)));
                assertTrue(flip.tau() >= 600 && flip.tau() <= 3 days, string(abi.encodePacked("TestError/flip-tau-range-", ilk)));          // gt eq 10 minutes and lt eq 3 days

                assertEq(flip.wards(address(flipMom)), values.collaterals[ilk].flipper_mom, string(abi.encodePacked("TestError/flip-flipperMom-auth-", ilk)));

                assertEq(flip.wards(address(cat)), values.collaterals[ilk].liqOn ? 1 : 0, string(abi.encodePacked("TestError/flip-liqOn-", ilk)));
                assertEq(flip.wards(address(pauseProxy)), 1, string(abi.encodePacked("TestError/flip-pause-proxy-auth-", ilk))); // Check pause_proxy ward
                }
            }
            if (values.collaterals[ilk].liqType == "clip") {
                {
                assertEq(reg.class(ilk), 1, string(abi.encodePacked("TestError/reg-class-", ilk)));
                (bool ok, bytes memory val) = reg.xlip(ilk).call(abi.encodeWithSignature("dog()"));
                assertTrue(ok, string(abi.encodePacked("TestError/reg-xlip-dog-", ilk)));
                assertEq(abi.decode(val, (address)), address(dog), string(abi.encodePacked("TestError/reg-xlip-dog-", ilk)));
                }
                {
                (, uint256 chop, uint256 hole,) = dog.ilks(ilk);
                // Convert BP to system expected value
                uint256 normalizedTestChop = (values.collaterals[ilk].chop * 10**14) + WAD;
                assertEq(chop, normalizedTestChop, string(abi.encodePacked("TestError/dog-chop-", ilk)));
                // make sure chop is less than 100%
                assertTrue(chop >= WAD && chop < 2 * WAD, string(abi.encodePacked("TestError/dog-chop-range-", ilk)));   // penalty gt eq 0% and lt 100%

                // Convert whole Dai units to expected RAD
                uint256 normalizedTesthole = values.collaterals[ilk].dog_hole * RAD;
                assertEq(hole, normalizedTesthole, string(abi.encodePacked("TestError/dog-hole-", ilk)));
                assertTrue(hole == 0 || hole >= RAD && hole <= 30 * MILLION * RAD, string(abi.encodePacked("TestError/dog-hole-range-", ilk)));
                }
                (address clipper,,,) = dog.ilks(ilk);
                ClipAbstract clip = ClipAbstract(clipper);
                {
                // Convert BP to system expected value
                uint256 normalizedTestBuf = values.collaterals[ilk].clip_buf * 10**23;
                assertEq(uint256(clip.buf()), normalizedTestBuf, string(abi.encodePacked("TestError/clip-buf-", ilk)));
                assertTrue(clip.buf() >= RAY && clip.buf() <= 2 * RAY, string(abi.encodePacked("TestError/clip-buf-range-", ilk))); // gte 0% and lte 100%
                assertEq(uint256(clip.tail()), values.collaterals[ilk].clip_tail, string(abi.encodePacked("TestError/clip-tail-", ilk)));
                assertTrue(clip.tail() >= 1200 && clip.tail() < 10 hours, string(abi.encodePacked("TestError/clip-tail-range-", ilk))); // gt eq 20 minutes and lt 10 hours
                uint256 normalizedTestCusp = (values.collaterals[ilk].clip_cusp)  * 10**23;
                assertEq(uint256(clip.cusp()), normalizedTestCusp, string(abi.encodePacked("TestError/clip-cusp-", ilk)));
                assertTrue(clip.cusp() >= RAY / 10 && clip.cusp() < RAY, string(abi.encodePacked("TestError/clip-cusp-range-", ilk))); // gte 10% and lt 100%
                assertTrue(rmul(clip.buf(), clip.cusp()) <= RAY, string(abi.encodePacked("TestError/clip-buf-cusp-limit-", ilk)));
                uint256 normalizedTestChip = (values.collaterals[ilk].clip_chip)  * 10**14;
                assertEq(uint256(clip.chip()), normalizedTestChip, string(abi.encodePacked("TestError/clip-chip-", ilk)));
                assertTrue(clip.chip() < 1 * WAD / 100, string(abi.encodePacked("TestError/clip-chip-range-", ilk))); // lt 1%
                uint256 normalizedTestTip = values.collaterals[ilk].clip_tip * RAD;
                assertEq(uint256(clip.tip()), normalizedTestTip, string(abi.encodePacked("TestError/clip-tip-", ilk)));
                assertTrue(clip.tip() == 0 || clip.tip() >= RAD && clip.tip() <= 300 * RAD, string(abi.encodePacked("TestError/clip-tip-range-", ilk)));

                assertEq(clip.wards(address(clipMom)), values.collaterals[ilk].clipper_mom, string(abi.encodePacked("TestError/clip-clipperMom-auth-", ilk)));

                assertEq(clipMom.tolerance(address(clip)), values.collaterals[ilk].cm_tolerance * RAY / 10000, string(abi.encodePacked("TestError/clipperMom-tolerance-", ilk)));

                if (values.collaterals[ilk].liqOn) {
                    assertEq(clip.stopped(), 0, string(abi.encodePacked("TestError/clip-liqOn-", ilk)));
                } else {
                    assertTrue(clip.stopped() > 0, string(abi.encodePacked("TestError/clip-liqOn-", ilk)));
                }

                assertEq(clip.wards(address(pauseProxy)), 1, string(abi.encodePacked("TestError/clip-pause-proxy-auth-", ilk))); // Check pause_proxy ward
                }
                {
                    (bool exists, bytes memory value) = clip.calc().call(abi.encodeWithSignature("tau()"));
                    assertEq(exists ? abi.decode(value, (uint256)) : 0, values.collaterals[ilk].calc_tau, string(abi.encodePacked("TestError/calc-tau-", ilk)));
                    (exists, value) = clip.calc().call(abi.encodeWithSignature("step()"));
                    assertEq(exists ? abi.decode(value, (uint256)) : 0, values.collaterals[ilk].calc_step, string(abi.encodePacked("TestError/calc-step-", ilk)));
                    if (exists) {
                       assertTrue(abi.decode(value, (uint256)) > 0, string(abi.encodePacked("TestError/calc-step-is-zero-", ilk)));
                    }
                    (exists, value) = clip.calc().call(abi.encodeWithSignature("cut()"));
                    uint256 normalizedTestCut = values.collaterals[ilk].calc_cut * 10**23;
                    assertEq(exists ? abi.decode(value, (uint256)) : 0, normalizedTestCut, string(abi.encodePacked("TestError/calc-cut-", ilk)));
                    if (exists) {
                       assertTrue(abi.decode(value, (uint256)) > 0 && abi.decode(value, (uint256)) < RAY, string(abi.encodePacked("TestError/calc-cut-range-", ilk)));
                    }
                }
            }
            if (reg.class(ilk) < 3) {
                {
                GemJoinAbstract join = GemJoinAbstract(reg.join(ilk));
                assertEq(join.wards(address(pauseProxy)), 1, string(abi.encodePacked("TestError/join-pause-proxy-auth-", ilk))); // Check pause_proxy ward
                }
            }
        }
        //       actual    expected
        assertEq(sumlines, vat.Line(), "TestError/vat-Line");
    }

    function getOSMPrice(address pip) internal returns (uint256) {
        // hevm.load is to pull the price from the LP Oracle storage bypassing the whitelist
        uint256 price = uint256(hevm.load(
            pip,
            bytes32(uint256(3))
        )) & uint128(-1);   // Price is in the second half of the 32-byte storage slot

        // Price is bounded in the spot by around 10^23
        // Give a 10^9 buffer for price appreciation over time
        // Note: This currently can't be hit due to the uint112, but we want to backstop
        //       once the PIP uint size is increased
        assertTrue(price <= (10 ** 14) * WAD);

        return price;
    }

    function getUNIV2LPPrice(address pip) internal returns (uint256) {
        // hevm.load is to pull the price from the LP Oracle storage bypassing the whitelist
        uint256 price = uint256(hevm.load(
            pip,
            bytes32(uint256(6))
        )) & uint128(-1);   // Price is in the second half of the 32-byte storage slot

        // Price is bounded in the spot by around 10^23
        // Give a 10^9 buffer for price appreciation over time
        // Note: This currently can't be hit due to the uint112, but we want to backstop
        //       once the PIP uint size is increased
        assertTrue(price <= (10 ** 14) * WAD);

        return price;
    }

    function giveTokens(DSTokenAbstract token, uint256 amount) internal {
        // Edge case - balance is already set for some reason
        if (token.balanceOf(address(this)) == amount) return;

        for (int i = 0; i < 200; i++) {
            // Scan the storage for the balance storage slot
            bytes32 prevValue = hevm.load(
                address(token),
                keccak256(abi.encode(address(this), uint256(i)))
            );
            hevm.store(
                address(token),
                keccak256(abi.encode(address(this), uint256(i))),
                bytes32(amount)
            );
            if (token.balanceOf(address(this)) == amount) {
                // Found it
                return;
            } else {
                // Keep going after restoring the original value
                hevm.store(
                    address(token),
                    keccak256(abi.encode(address(this), uint256(i))),
                    prevValue
                );
            }
        }

        // We have failed if we reach here
        assertTrue(false);
    }

    function giveAuth(address _base, address target) internal {
        AuthLike base = AuthLike(_base);

        // Edge case - ward is already set
        if (base.wards(target) == 1) return;

        for (int i = 0; i < 100; i++) {
            // Scan the storage for the ward storage slot
            bytes32 prevValue = hevm.load(
                address(base),
                keccak256(abi.encode(target, uint256(i)))
            );
            hevm.store(
                address(base),
                keccak256(abi.encode(target, uint256(i))),
                bytes32(uint256(1))
            );
            if (base.wards(target) == 1) {
                // Found it
                return;
            } else {
                // Keep going after restoring the original value
                hevm.store(
                    address(base),
                    keccak256(abi.encode(target, uint256(i))),
                    prevValue
                );
            }
        }

        // We have failed if we reach here
        assertTrue(false);
    }

	function checkIlkIntegration(
        bytes32 _ilk,
        GemJoinAbstract join,
        FlipAbstract flip,
        address pip,
        bool _isOSM,
        bool _checkLiquidations,
        bool _transferFee
    ) public {
        DSTokenAbstract token = DSTokenAbstract(join.gem());

        if (_isOSM) OsmAbstract(pip).poke();
        hevm.warp(block.timestamp + 3601);
        if (_isOSM) OsmAbstract(pip).poke();
        spotter.poke(_ilk);

        // Authorization
        assertEq(join.wards(pauseProxy), 1);
        assertEq(vat.wards(address(join)), 1);
        assertEq(flip.wards(address(end)), 1);
        assertEq(flip.wards(address(flipMom)), 1);
        if (_isOSM) {
            assertEq(OsmAbstract(pip).wards(address(osmMom)), 1);
            assertEq(OsmAbstract(pip).bud(address(spotter)), 1);
            assertEq(OsmAbstract(pip).bud(address(end)), 1);
            assertEq(MedianAbstract(OsmAbstract(pip).src()).bud(pip), 1);
        }

        (,,,, uint256 dust) = vat.ilks(_ilk);
        dust /= RAY;
        uint256 amount = 2 * dust * WAD / (_isOSM ? getOSMPrice(pip) : uint256(DSValueAbstract(pip).read()));
        giveTokens(token, amount);

        assertEq(token.balanceOf(address(this)), amount);
        assertEq(vat.gem(_ilk, address(this)), 0);
        token.approve(address(join), amount);
        join.join(address(this), amount);
        assertEq(token.balanceOf(address(this)), 0);
        if (_transferFee) {
            amount = vat.gem(_ilk, address(this));
            assertTrue(amount > 0);
        }
        assertEq(vat.gem(_ilk, address(this)), amount);

        // Tick the fees forward so that art != dai in wad units
        hevm.warp(block.timestamp + 1);
        jug.drip(_ilk);

        // Deposit collateral, generate DAI
        (,uint256 rate,,,) = vat.ilks(_ilk);
        assertEq(vat.dai(address(this)), 0);
        vat.frob(_ilk, address(this), address(this), address(this), int(amount), int(divup(mul(RAY, dust), rate)));
        assertEq(vat.gem(_ilk, address(this)), 0);
        assertTrue(vat.dai(address(this)) >= dust * RAY);
        assertTrue(vat.dai(address(this)) <= (dust + 1) * RAY);

        // Payback DAI, withdraw collateral
        vat.frob(_ilk, address(this), address(this), address(this), -int(amount), -int(divup(mul(RAY, dust), rate)));
        assertEq(vat.gem(_ilk, address(this)), amount);
        assertEq(vat.dai(address(this)), 0);

        // Withdraw from adapter
        join.exit(address(this), amount);
        if (_transferFee) {
            amount = token.balanceOf(address(this));
        }
        assertEq(token.balanceOf(address(this)), amount);
        assertEq(vat.gem(_ilk, address(this)), 0);

        // Generate new DAI to force a liquidation
        token.approve(address(join), amount);
        join.join(address(this), amount);
        if (_transferFee) {
            amount = vat.gem(_ilk, address(this));
        }
        // dart max amount of DAI
        (,,uint256 spot,,) = vat.ilks(_ilk);
        vat.frob(_ilk, address(this), address(this), address(this), int(amount), int(mul(amount, spot) / rate));
        hevm.warp(block.timestamp + 1);
        jug.drip(_ilk);
        assertEq(flip.kicks(), 0);
        if (_checkLiquidations) {
            cat.bite(_ilk, address(this));
            assertEq(flip.kicks(), 1);
        }

        // Dump all dai for next run
        vat.move(address(this), address(0x0), vat.dai(address(this)));
    }

	function checkUNIV2LPIntegration(
        bytes32 _ilk,
        GemJoinAbstract join,
        FlipAbstract flip,
        LPOsmAbstract pip,
        address _medianizer1,
        address _medianizer2,
        bool _isMedian1,
        bool _isMedian2,
        bool _checkLiquidations
    ) public {
        DSTokenAbstract token = DSTokenAbstract(join.gem());

        pip.poke();
        hevm.warp(block.timestamp + 3601);
        pip.poke();
        spotter.poke(_ilk);

        // Check medianizer sources
        assertEq(pip.src(), address(token));
        assertEq(pip.orb0(), _medianizer1);
        assertEq(pip.orb1(), _medianizer2);

        // Authorization
        assertEq(join.wards(pauseProxy), 1);
        assertEq(vat.wards(address(join)), 1);
        assertEq(flip.wards(address(end)), 1);
        assertEq(flip.wards(address(flipMom)), 1);
        assertEq(pip.wards(address(osmMom)), 1);
        assertEq(pip.bud(address(spotter)), 1);
        assertEq(pip.bud(address(end)), 1);
        if (_isMedian1) assertEq(MedianAbstract(_medianizer1).bud(address(pip)), 1);
        if (_isMedian2) assertEq(MedianAbstract(_medianizer2).bud(address(pip)), 1);

        (,,,, uint256 dust) = vat.ilks(_ilk);
        dust /= RAY;
        uint256 amount = 2 * dust * WAD / getUNIV2LPPrice(address(pip));
        giveTokens(token, amount);

        assertEq(token.balanceOf(address(this)), amount);
        assertEq(vat.gem(_ilk, address(this)), 0);
        token.approve(address(join), amount);
        join.join(address(this), amount);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(vat.gem(_ilk, address(this)), amount);

        // Tick the fees forward so that art != dai in wad units
        hevm.warp(block.timestamp + 1);
        jug.drip(_ilk);

        // Deposit collateral, generate DAI
        (,uint256 rate,,,) = vat.ilks(_ilk);
        assertEq(vat.dai(address(this)), 0);
        vat.frob(_ilk, address(this), address(this), address(this), int(amount), int(divup(mul(RAY, dust), rate)));
        assertEq(vat.gem(_ilk, address(this)), 0);
        assertTrue(vat.dai(address(this)) >= dust * RAY && vat.dai(address(this)) <= (dust + 1) * RAY);

        // Payback DAI, withdraw collateral
        vat.frob(_ilk, address(this), address(this), address(this), -int(amount), -int(divup(mul(RAY, dust), rate)));
        assertEq(vat.gem(_ilk, address(this)), amount);
        assertEq(vat.dai(address(this)), 0);

        // Withdraw from adapter
        join.exit(address(this), amount);
        assertEq(token.balanceOf(address(this)), amount);
        assertEq(vat.gem(_ilk, address(this)), 0);

        // Generate new DAI to force a liquidation
        token.approve(address(join), amount);
        join.join(address(this), amount);
        // dart max amount of DAI
        (,,uint256 spot,,) = vat.ilks(_ilk);
        vat.frob(_ilk, address(this), address(this), address(this), int(amount), int(mul(amount, spot) / rate));
        hevm.warp(block.timestamp + 1);
        jug.drip(_ilk);
        assertEq(flip.kicks(), 0);
        if (_checkLiquidations) {
            cat.bite(_ilk, address(this));
            assertEq(flip.kicks(), 1);
        }

        // Dump all dai for next run
        vat.move(address(this), address(0x0), vat.dai(address(this)));
    }

    function getExtcodesize(address target) public view returns (uint256 exsize) {
        assembly {
            exsize := extcodesize(target)
        }
    }

    function testSpellIsCast_GENERAL() public {
        string memory description = new DssSpell().description();
        assertTrue(bytes(description).length > 0, "TestError/spell-description-length");
        // DS-Test can't handle strings directly, so cast to a bytes32.
        assertEq(stringToBytes32(spell.description()),
                stringToBytes32(description), "TestError/spell-description");

        if(address(spell) != address(spellValues.deployed_spell)) {
            assertEq(spell.expiration(), block.timestamp + spellValues.expiration_threshold, "TestError/spell-expiration");
        } else {
            assertEq(spell.expiration(), spellValues.deployed_spell_created + spellValues.expiration_threshold, "TestError/spell-expiration");

            // If the spell is deployed compare the on-chain bytecode size with the generated bytecode size.
            //   extcodehash doesn't match, potentially because it's address-specific, avenue for further research.
            address depl_spell = spellValues.deployed_spell;
            address code_spell = address(new DssSpell());
            assertEq(getExtcodesize(depl_spell), getExtcodesize(code_spell), "TestError/spell-codesize");
        }

        assertTrue(spell.officeHours() == spellValues.office_hours_enabled, "TestError/spell-office-hours");

        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        checkSystemValues(afterSpell);

        checkCollateralValues(afterSpell);
    }

    function testNewChainlogValues() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        ChainlogAbstract chainLog = ChainlogAbstract(addr.addr("CHANGELOG"));

        assertEq(chainLog.getAddress("MCD_CLIP_USDC_A"), addr.addr("MCD_CLIP_USDC_A"));
        assertEq(chainLog.getAddress("MCD_CLIP_CALC_USDC_A"), addr.addr("MCD_CLIP_CALC_USDC_A"));
        try chainLog.getAddress("MCD_FLIP_USDC_A") returns (address) {
            assertTrue(false);
        } catch {}

        assertEq(chainLog.getAddress("MCD_CLIP_USDC_B"), addr.addr("MCD_CLIP_USDC_B"));
        assertEq(chainLog.getAddress("MCD_CLIP_CALC_USDC_B"), addr.addr("MCD_CLIP_CALC_USDC_B"));
        try chainLog.getAddress("MCD_FLIP_USDC_B") returns (address) {
            assertTrue(false);
        } catch {}

        assertEq(chainLog.getAddress("MCD_CLIP_TUSD_A"), addr.addr("MCD_CLIP_TUSD_A"));
        assertEq(chainLog.getAddress("MCD_CLIP_CALC_TUSD_A"), addr.addr("MCD_CLIP_CALC_TUSD_A"));
        try chainLog.getAddress("MCD_FLIP_TUSD_A") returns (address) {
            assertTrue(false);
        } catch {}

        assertEq(chainLog.getAddress("MCD_CLIP_USDT_A"), addr.addr("MCD_CLIP_USDT_A"));
        assertEq(chainLog.getAddress("MCD_CLIP_CALC_USDT_A"), addr.addr("MCD_CLIP_CALC_USDT_A"));
        try chainLog.getAddress("MCD_FLIP_USDT_A") returns (address) {
            assertTrue(false);
        } catch {}

        assertEq(chainLog.getAddress("MCD_CLIP_PAXUSD_A"), addr.addr("MCD_CLIP_PAXUSD_A"));
        assertEq(chainLog.getAddress("MCD_CLIP_CALC_PAXUSD_A"), addr.addr("MCD_CLIP_CALC_PAXUSD_A"));
        try chainLog.getAddress("MCD_FLIP_PAXUSD_A") returns (address) {
            assertTrue(false);
        } catch {}

        assertEq(chainLog.getAddress("MCD_CLIP_GUSD_A"), addr.addr("MCD_CLIP_GUSD_A"));
        assertEq(chainLog.getAddress("MCD_CLIP_CALC_GUSD_A"), addr.addr("MCD_CLIP_CALC_GUSD_A"));
        try chainLog.getAddress("MCD_FLIP_GUSD_A") returns (address) {
            assertTrue(false);
        } catch {}

        assertEq(chainLog.getAddress("MCD_CLIP_PSM_USDC_A"), addr.addr("MCD_CLIP_PSM_USDC_A"));
        assertEq(chainLog.getAddress("MCD_CLIP_CALC_PSM_USDC_A"), addr.addr("MCD_CLIP_CALC_PSM_USDC_A"));
        try chainLog.getAddress("MCD_FLIP_PSM_USDC_A") returns (address) {
            assertTrue(false);
        } catch {}

        assertEq(chainLog.getAddress("MCD_CLIP_UNIV2DAIUSDC_A"), addr.addr("MCD_CLIP_UNIV2DAIUSDC_A"));
        assertEq(chainLog.getAddress("MCD_CLIP_CALC_UNIV2DAIUSDC_A"), addr.addr("MCD_CLIP_CALC_UNIV2DAIUSDC_A"));
        try chainLog.getAddress("MCD_FLIP_UNIV2DAIUSDC_A") returns (address) {
            assertTrue(false);
        } catch {}
    }

    // function testCollateralIntegrations() public {
    //     vote(address(spell));
    //     spell.schedule();
    //     hevm.warp(spell.nextCastTime());
    //     spell.cast();
    //     assertTrue(spell.done());

    //     // Insert new collateral tests here
    // }

    function testFailWrongDay() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote(address(spell));
            scheduleWaitAndCastFailDay();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testFailTooEarly() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote(address(spell));
            scheduleWaitAndCastFailEarly();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testFailTooLate() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote(address(spell));
            scheduleWaitAndCastFailLate();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testOnTime() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
    }

    function testCastCost() public {
        vote(address(spell));
        spell.schedule();

        hevm.warp(spell.nextCastTime());
        uint256 startGas = gasleft();
        spell.cast();
        uint256 endGas = gasleft();
        uint256 totalGas = startGas - endGas;

        assertTrue(spell.done());
        // Fail if cast is too expensive
        assertTrue(totalGas <= 10 * MILLION);
    }

    function test_nextCastTime() public {
        hevm.warp(1606161600); // Nov 23, 20 UTC (could be cast Nov 26)

        vote(address(spell));
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

            for(uint256 i = 0; i < 5; i++) {
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

    function testFail_notScheduled() public view {
        spell.nextCastTime();
    }

    function test_use_eta() public {
        hevm.warp(1606161600); // Nov 23, 20 UTC (could be cast Nov 26)

        vote(address(spell));
        spell.schedule();

        uint256 castTime = spell.nextCastTime();
        assertEq(castTime, spell.eta());
    }

    // function test_OSMs() public {
    //     vote(address(spell));
    //     spell.schedule();
    //     hevm.warp(spell.nextCastTime());
    //     spell.cast();
    //     assertTrue(spell.done());

    //     // Track OSM authorizations here

    //     address YEARN_PROXY = 0x208EfCD7aad0b5DD49438E0b6A0f38E951A50E5f;
    //     assertEq(OsmAbstract(addr.addr("PIP_YFI")).bud(YEARN_PROXY), 1);

    //     // Gnosis
    //     address GNOSIS = 0xD5885fbCb9a8a8244746010a3BC6F1C6e0269777;
    //     assertEq(OsmAbstract(addr.addr("PIP_WBTC")).bud(GNOSIS), 1);
    //     assertEq(OsmAbstract(addr.addr("PIP_LINK")).bud(GNOSIS), 1);
    //     assertEq(OsmAbstract(addr.addr("PIP_COMP")).bud(GNOSIS), 1);
    //     assertEq(OsmAbstract(addr.addr("PIP_YFI")).bud(GNOSIS), 1);
    //     assertEq(OsmAbstract(addr.addr("PIP_ZRX")).bud(GNOSIS), 1);

    //     // Instadapp
    //     address INSTADAPP = 0xDF3CDd10e646e4155723a3bC5b1191741DD90333;
    //     assertEq(OsmAbstract(addr.addr("PIP_ETH")).bud(INSTADAPP), 1);
    // }

    // function test_Medianizers() public {
    //     vote(address(spell));
    //     spell.schedule();
    //     hevm.warp(spell.nextCastTime());
    //     spell.cast();
    //     assertTrue(spell.done());

    //     // Track Median authorizations here

    //     address SET_AAVE    = 0x8b1C079f8192706532cC0Bf0C02dcC4fF40d045D;
    //     address AAVEUSD_MED = OsmAbstract(addr.addr("PIP_AAVE")).src();
    //     assertEq(MedianAbstract(AAVEUSD_MED).bud(SET_AAVE), 1);

    //     address SET_LRC     = 0x1D5d9a2DDa0843eD9D8a9Bddc33F1fca9f9C64a0;
    //     address LRCUSD_MED  = OsmAbstract(addr.addr("PIP_LRC")).src();
    //     assertEq(MedianAbstract(LRCUSD_MED).bud(SET_LRC), 1);

    //     address SET_YFI     = 0x1686d01Bd776a1C2A3cCF1579647cA6D39dd2465;
    //     address YFIUSD_MED  = OsmAbstract(addr.addr("PIP_YFI")).src();
    //     assertEq(MedianAbstract(YFIUSD_MED).bud(SET_YFI), 1);

    //     address SET_ZRX     = 0xFF60D1650696238F81BE53D23b3F91bfAAad938f;
    //     address ZRXUSD_MED  = OsmAbstract(addr.addr("PIP_ZRX")).src();
    //     assertEq(MedianAbstract(ZRXUSD_MED).bud(SET_ZRX), 1);

    //     address SET_UNI     = 0x3c3Afa479d8C95CF0E1dF70449Bb5A14A3b7Af67;
    //     address UNIUSD_MED  = OsmAbstract(addr.addr("PIP_UNI")).src();
    //     assertEq(MedianAbstract(UNIUSD_MED).bud(SET_UNI), 1);
    // }

    address[] deployerAddresses = [
        0xdDb108893104dE4E1C6d0E47c42237dB4E617ACc,
        0xDa0FaB05039809e63C5D068c897c3e602fA97457,
        0xda0fab060e6cc7b1C0AA105d29Bd50D71f036711,
        0xDA0FaB0700A4389F6E6679aBAb1692B4601ce9bf,
        0x0048d6225D1F3eA4385627eFDC5B4709Cab4A21c,
        0xd200790f62c8da69973e61d4936cfE4f356ccD07,
        0xdA0C0de01d90A5933692Edf03c7cE946C7c50445
    ];

    function checkWards(address _addr, string memory contractName) internal {
        for (uint256 i = 0; i < deployerAddresses.length; i ++) {
            (bool ok, bytes memory data) = _addr.call(
                abi.encodeWithSignature("wards(address)", deployerAddresses[i])
            );
            if (!ok || data.length != 32) return;
            uint256 ward = abi.decode(data, (uint256));
            if (ward > 0) {
                emit Log("Bad auth", deployerAddresses[i], contractName);
                fail();
            }
        }
    }

    function checkSource(address _addr, string memory contractName) internal {
        (bool ok, bytes memory data) =
            _addr.call(abi.encodeWithSignature("src()"));
        if (!ok || data.length != 32) return;
        address source = abi.decode(data, (address));
        string memory sourceName = string(
            abi.encodePacked("source of ", contractName)
        );
        checkWards(source, sourceName);
    }

    function checkAuth(bool onlySource) internal {
        vote(address(spell));
        spell.schedule();
        hevm.warp(spell.nextCastTime());
        spell.cast();
        assertTrue(spell.done());
        ChainlogAbstract chainLog = ChainlogAbstract(addr.addr("CHANGELOG"));
        bytes32[] memory contractNames = chainLog.list();
        for(uint256 i = 0; i < contractNames.length; i++) {
            address _addr = chainLog.getAddress(contractNames[i]);
            string memory contractName = string(
                abi.encodePacked(contractNames[i])
            );
            if (onlySource) checkSource(_addr, contractName);
            else checkWards(_addr, contractName);
        }
    }

    function test_auth() public {
        checkAuth(false);
    }

    function test_auth_in_sources() public {
        checkAuth(true);
    }

    function checkIlkClipper(bytes32 ilk, GemJoinAbstract join, FlipAbstract flipper, ClipAbstract clipper, address calc, OsmAbstract pip) internal {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // Contracts set
        assertEq(dog.vat(), address(vat));
        assertEq(dog.vow(), address(vow));
        {
        (address clip,,,) = dog.ilks(ilk);
        assertEq(clip, address(clipper));
        }
        assertEq(clipper.ilk(), ilk);
        assertEq(clipper.vat(), address(vat));
        assertEq(clipper.vow(), address(vow));
        assertEq(clipper.dog(), address(dog));
        assertEq(clipper.spotter(), address(spotter));
        assertEq(clipper.calc(), calc);

        // Authorization
        assertEq(flipper.wards(address(cat))    , 0);
        assertEq(flipper.wards(address(flipMom)), 0);
        assertEq(vat.wards(address(clipper))    , 1);
        assertEq(dog.wards(address(clipper))    , 1);
        assertEq(clipper.wards(address(dog))    , 1);
        assertEq(clipper.wards(address(end))    , 1);
        // assertEq(clipper.wards(address(clipMom)), 1); // This is actually checked in the GENERAL test
        assertEq(clipper.wards(address(esm)), 1);

        try pip.bud(address(clipMom)) returns (uint256 bud) {
            assertEq(bud, 1);
        } catch {}
        try pip.bud(address(clipper)) returns (uint256 bud) {
            assertEq(bud, 1);
        } catch {}

        // Force max Hole
        hevm.store(
            address(dog),
            bytes32(uint256(4)),
            bytes32(uint256(-1))
        );

        // Force max debt ceiling for ilk
        hevm.store(
            address(vat),
            bytes32(uint256(keccak256(abi.encode(bytes32(ilk), uint256(2)))) + 3),
            bytes32(uint256(-1))
        );

        if (ilk != "PSM-USDC-A") {
            // ----------------------- Check Clipper can't actually be triggered -----------------------
            uint256 ilkAmt;

            {
            // Generate new DAI to force a liquidation
            uint256 rate;
            int256 art;
            {
            uint256 spot;
            uint256 dust;
            (,rate, spot,, dust) = vat.ilks(ilk);
            art = int256(dust * 2 / rate);
            ilkAmt = dust * 2 / spot;
            }

            {
            DSTokenAbstract token = DSTokenAbstract(join.gem());
            uint256 tknAmt =  ilkAmt / 10 ** (18 - join.dec()) + 1;
            ilkAmt = tknAmt * 10 ** (18 - join.dec());
            giveTokens(token, tknAmt);
            assertEq(token.balanceOf(address(this)), tknAmt);

            // Join to adapter
            assertEq(vat.gem(ilk, address(this)), 0);
            TokenCompatibleUSDT(address(token)).approve(address(join), tknAmt);
            join.join(address(this), tknAmt);
            assertEq(token.balanceOf(address(this)), 0);
            assertEq(vat.gem(ilk, address(this)), ilkAmt);
            }

            // dart max amount of DAI
            vat.frob(ilk, address(this), address(this), address(this), int256(ilkAmt), art);
            hevm.warp(block.timestamp + 1);
            jug.drip(ilk);
            assertEq(clipper.kicks(), 0);
            try dog.bark(ilk, address(this), address(this)) { assertTrue(false, "Liq 2.0 should be disabled"); } catch {}
            // assertEq(clipper.kicks(), 1);
            assertEq(clipper.kicks(), 0);
        }

        // (, rate,,,) = vat.ilks(ilk);
        // uint256 debt = mul(mul(rate, uint256(art)), dog.chop(ilk)) / WAD;
        // hevm.store(
        //     address(vat),
        //     keccak256(abi.encode(address(this), uint256(5))),
        //     bytes32(debt)
        // );
        // assertEq(vat.dai(address(this)), debt);
        // assertEq(vat.gem(ilk, address(this)), 0);

        // hevm.warp(block.timestamp + 20 minutes);
        // (, uint256 tab, uint256 lot, address usr,, uint256 top) = clipper.sales(1);

        // assertEq(usr, address(this));
        // assertEq(tab, debt);
        // assertEq(lot, ilkAmt);
        // assertTrue(mul(lot, top) > tab); // There is enough collateral to cover the debt at current price

        // vat.hope(address(clipper));
        // clipper.take(1, lot, top, address(this), bytes(""));
        }

        // {
        // (, uint256 tab, uint256 lot, address usr,,) = clipper.sales(1);
        // assertEq(usr, address(0));
        // assertEq(tab, 0);
        // assertEq(lot, 0);
        // assertEq(vat.dai(address(this)), 0);
        // assertEq(vat.gem(ilk, address(this)), ilkAmt); // What was purchased + returned back as it is the owner of the vault
        // }

        // ----------------------- Check ClipperMom doens't work -----------------------

        // clipperMom is an authority-based contract, so here we set the Chieftain's hat
        //  to the current contract to simulate governance authority.
        hevm.store(
            address(chief),
            bytes32(uint256(12)),
            bytes32(uint256(address(this)))
        );

        assertEq(clipper.stopped(), 3);
        try clipMom.setBreaker(address(clipper), 0, 0) { assertTrue(false, "ClipperMom shouldn't be available for this ilk"); } catch {}

        // assertEq(clipper.stopped(), 0);
        // clipMom.setBreaker(address(clipper), 1, 0);
        // assertEq(clipper.stopped(), 1);
        // clipMom.setBreaker(address(clipper), 2, 0);
        // assertEq(clipper.stopped(), 2);
        // clipMom.setBreaker(address(clipper), 3, 0);
        // assertEq(clipper.stopped(), 3);
        // clipMom.setBreaker(address(clipper), 0, 0);
        // assertEq(clipper.stopped(), 0);

        // hevm.warp(clipMom.locked(address(clipper)) + 1);

        // // Hacking nxt price to 0x123 (and making it valid)
        // bytes32 hackedValue = 0x0000000000000000000000000000000100000000000000000000000000000123;

        // hevm.store(address(pip), bytes32(uint256(4)), hackedValue);
        // // Price is hacked, anyone can trip the breaker
        // clipMom.tripBreaker(address(clipper));
        // assertEq(clipper.stopped(), 2);

        // clipMom.setBreaker(address(clipper), 0, 0);
        // assertEq(clipper.stopped(), 0);

        // // ----------------------- Check End works with the Clipper -----------------------

        // {
        // uint256 rate;
        // int256 art;
        // {
        // uint256 spot;
        // (,rate, spot,,) = vat.ilks(ilk);
        // art = int256(mul(ilkAmt, spot) / rate);
        // }

        // vat.frob(ilk, address(this), address(this), address(this), int256(ilkAmt), art);
        // hevm.warp(block.timestamp + 1);
        // jug.drip(ilk);

        // dog.bark(ilk, address(this), address(this));
        // assertEq(clipper.kicks(), 2);

        // // Give authority to cage the system
        // giveAuth(address(end), address(this));
        // assertEq(end.wards(address(this)), 1);

        // end.cage();
        // end.cage(ilk);

        // (,,, address usr,,) = clipper.sales(2);
        // assertTrue(usr != address(0));

        // end.snip(ilk, 2);
        // (,,, usr,,) = clipper.sales(2);
        // assertTrue(usr == address(0));

        // end.skim(ilk, address(this));
        // end.free(ilk);

        // hevm.warp(block.timestamp + end.wait());
        // vow.heal(min(vat.dai(address(vow)), sub(sub(vat.sin(address(vow)), vow.Sin()), vow.Ash())));

        // // Removing the surplus to allow continuing the execution.
        // hevm.store(
        //     address(vat),
        //     keccak256(abi.encode(address(vow), uint256(5))),
        //     bytes32(uint256(0))
        // );

        // end.thaw();
        // end.flow(ilk);

        // uint256 daiToRedeem = vat.dai(address(this)) / RAY;
        // assertTrue(daiToRedeem > 0);

        // vat.hope(address(end));
        // end.pack(daiToRedeem);

        // end.cash(ilk, daiToRedeem);
        // }
    }

    function testSpellIsCast_USDC_A_clip() public {
        checkIlkClipper(
            "USDC-A",
            GemJoinAbstract(addr.addr("MCD_JOIN_USDC_A")),
            FlipAbstract(addr.addr("MCD_FLIP_USDC_A")),
            ClipAbstract(addr.addr("MCD_CLIP_USDC_A")),
            addr.addr("MCD_CLIP_CALC_USDC_A"),
            OsmAbstract(addr.addr("PIP_USDC"))
        );
    }

    function testSpellIsCast_USDC_B_clip() public {
        checkIlkClipper(
            "USDC-B",
            GemJoinAbstract(addr.addr("MCD_JOIN_USDC_B")),
            FlipAbstract(addr.addr("MCD_FLIP_USDC_B")),
            ClipAbstract(addr.addr("MCD_CLIP_USDC_B")),
            addr.addr("MCD_CLIP_CALC_USDC_B"),
            OsmAbstract(addr.addr("PIP_USDC"))
        );
    }

    function testSpellIsCast_TUSD_A_clip() public {
        checkIlkClipper(
            "TUSD-A",
            GemJoinAbstract(addr.addr("MCD_JOIN_TUSD_A")),
            FlipAbstract(addr.addr("MCD_FLIP_TUSD_A")),
            ClipAbstract(addr.addr("MCD_CLIP_TUSD_A")),
            addr.addr("MCD_CLIP_CALC_TUSD_A"),
            OsmAbstract(addr.addr("PIP_TUSD"))
        );
    }

    function testSpellIsCast_USDT_A_clip() public {
        checkIlkClipper(
            "USDT-A",
            GemJoinAbstract(addr.addr("MCD_JOIN_USDT_A")),
            FlipAbstract(addr.addr("MCD_FLIP_USDT_A")),
            ClipAbstract(addr.addr("MCD_CLIP_USDT_A")),
            addr.addr("MCD_CLIP_CALC_USDT_A"),
            OsmAbstract(addr.addr("PIP_USDT"))
        );
    }

    function testSpellIsCast_PAXUSD_A_clip() public {
        checkIlkClipper(
            "PAXUSD-A",
            GemJoinAbstract(addr.addr("MCD_JOIN_PAXUSD_A")),
            FlipAbstract(addr.addr("MCD_FLIP_PAXUSD_A")),
            ClipAbstract(addr.addr("MCD_CLIP_PAXUSD_A")),
            addr.addr("MCD_CLIP_CALC_PAXUSD_A"),
            OsmAbstract(addr.addr("PIP_PAXUSD"))
        );
    }

    function testSpellIsCast_GUSD_A_clip() public {
        checkIlkClipper(
            "GUSD-A",
            GemJoinAbstract(addr.addr("MCD_JOIN_GUSD_A")),
            FlipAbstract(addr.addr("MCD_FLIP_GUSD_A")),
            ClipAbstract(addr.addr("MCD_CLIP_GUSD_A")),
            addr.addr("MCD_CLIP_CALC_GUSD_A"),
            OsmAbstract(addr.addr("PIP_GUSD"))
        );
    }

    function testSpellIsCast_PSM_USDC_A_clip() public {
        checkIlkClipper(
            "PSM-USDC-A",
            GemJoinAbstract(addr.addr("MCD_JOIN_PSM_USDC_A")),
            FlipAbstract(addr.addr("MCD_FLIP_PSM_USDC_A")),
            ClipAbstract(addr.addr("MCD_CLIP_PSM_USDC_A")),
            addr.addr("MCD_CLIP_CALC_PSM_USDC_A"),
            OsmAbstract(addr.addr("PIP_USDC"))
        );
    }

    function testSpellIsCast_UNIV2DAIUSDC_A_clip() public {
        checkIlkClipper(
            "UNIV2DAIUSDC-A",
            GemJoinAbstract(addr.addr("MCD_JOIN_UNIV2DAIUSDC_A")),
            FlipAbstract(addr.addr("MCD_FLIP_UNIV2DAIUSDC_A")),
            ClipAbstract(addr.addr("MCD_CLIP_UNIV2DAIUSDC_A")),
            addr.addr("MCD_CLIP_CALC_UNIV2DAIUSDC_A"),
            OsmAbstract(addr.addr("PIP_UNIV2DAIUSDC"))
        );
    }
}
