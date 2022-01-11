// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.6.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "dss-interfaces/Interfaces.sol";

import "./test/rates.sol";
import "./test/addresses_mainnet.sol";
import "./test/addresses_deployers.sol";
import "./test/addresses_wallets.sol";
import "./test/config.sol";

import {DssSpell} from "./DssSpell.sol";

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
    function load(address,bytes32) external view returns (bytes32);
}

interface DssExecSpellLike {
    function done() external view returns (bool);
    function eta() external view returns (uint256);
    function cast() external;
    function nextCastTime() external returns (uint256);
}

interface DirectDepositLike is GemJoinAbstract {
    function file(bytes32, uint256) external;
    function exec() external;
    function tau() external view returns (uint256);
    function bar() external view returns (uint256);
    function king() external view returns (address);
}

contract DssSpellTestBase is Config, DSTest, DSMath {

    struct SpellValues {
        address deployed_spell;
        uint256 deployed_spell_created;
        address previous_spell;
        bool    office_hours_enabled;
        uint256 expiration_threshold;
    }

    SpellValues  spellValues;

    Hevm hevm;

    Rates          rates = new Rates();
    Addresses       addr = new Addresses();
    Deployers  deployers = new Deployers();
    Wallets      wallets = new Wallets();

    // ADDRESSES
    ChainlogAbstract    chainLog = ChainlogAbstract(   addr.addr("CHANGELOG"));
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

    OsmMomAbstract           osmMom = OsmMomAbstract(     addr.addr("OSM_MOM"));
    FlipperMomAbstract      flipMom = FlipperMomAbstract( addr.addr("FLIPPER_MOM"));
    ClipperMomAbstract      clipMom = ClipperMomAbstract( addr.addr("CLIPPER_MOM"));
    DssAutoLineAbstract    autoLine = DssAutoLineAbstract(addr.addr("MCD_IAM_AUTO_LINE"));
    LerpFactoryAbstract lerpFactory = LerpFactoryAbstract(addr.addr("LERP_FAB"));
    VestAbstract            vestDai = VestAbstract(       addr.addr("MCD_VEST_DAI"));

    DssSpell spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    // uint256 constant HUNDRED    = 10 ** 2;  // provided by collaterals
    // uint256 constant THOUSAND   = 10 ** 3;  // provided by collaterals
    // uint256 constant MILLION    = 10 ** 6;  // provided by collaterals
    // uint256 constant BILLION    = 10 ** 9;  // provided by collaterals
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

    // not provided in DSTest
    function assertEqApprox(uint256 _a, uint256 _b, uint256 _tolerance) internal {
        uint256 a = _a;
        uint256 b = _b;
        if (a < b) {
            uint256 tmp = a;
            a = b;
            b = tmp;
        }
        if (a - b > _tolerance) {
            emit log_bytes32("Error: Wrong `uint' value");
            emit log_named_uint("  Expected", _b);
            emit log_named_uint("    Actual", _a);
            fail();
        }
    }

    // Not currently used
    // function bytes32ToStr(bytes32 _bytes32) internal pure returns (string memory) {
    //     bytes memory bytesArray = new bytes(32);
    //     for (uint256 i; i < 32; i++) {
    //         bytesArray[i] = _bytes32[i];
    //     }
    //     return string(bytesArray);
    // }

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
        DssExecSpellLike prevSpell = DssExecSpellLike(spellValues.previous_spell);
        // warp and cast previous spell so values are up-to-date to test against
        if (prevSpell != DssExecSpellLike(0) && !prevSpell.done()) {
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
            deployed_spell_created:         1639162896,        // use get-created-timestamp.sh if deployed
            previous_spell:                 address(0),        // supply if there is a need to test prior to its cast() function being called on-chain.
            office_hours_enabled:           false,              // true if officehours is expected to be enabled in the spell
            expiration_threshold:           weekly_expiration  // (weekly_expiration,monthly_expiration) if weekly or monthly spell
        });
        spellValues.deployed_spell_created = spellValues.deployed_spell != address(0) ? spellValues.deployed_spell_created : block.timestamp;
        castPreviousSpell();
        spell = spellValues.deployed_spell != address(0) ?
            DssSpell(spellValues.deployed_spell) : new DssSpell();

        //
        // Test for all system configuration changes
        //
        afterSpell = SystemValues({
            line_offset:           500 * MILLION,           // Offset between the global line against the sum of local lines
            pot_dsr:               1,                       // In basis points
            pause_delay:           48 hours,                // In seconds
            vow_wait:              156 hours,               // In seconds
            vow_dump:              250,                     // In whole Dai units
            vow_sump:              50 * THOUSAND,           // In whole Dai units
            vow_bump:              30 * THOUSAND,           // In whole Dai units
            vow_hump_min:          60 * MILLION,            // In whole Dai units
            vow_hump_max:          90 * MILLION,            // In whole Dai units
            flap_beg:              400,                     // in basis points
            flap_ttl:              30 minutes,              // in seconds
            flap_tau:              72 hours,                // in seconds
            cat_box:               20 * MILLION,            // In whole Dai units
            dog_Hole:              100 * MILLION,           // In whole Dai units
            pause_authority:       address(chief),          // Pause authority
            osm_mom_authority:     address(chief),          // OsmMom authority
            flipper_mom_authority: address(chief),          // FlipperMom authority
            clipper_mom_authority: address(chief),          // ClipperMom authority
            ilk_count:             48                       // Num expected in system
        });

        setCollateralValues();
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
            giveTokens(gov, 999999999999 ether);
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
        assertEq(pot.dsr(), expectedDSRRate, "TestError/pot-dsr-expected-value");
        assertTrue(
            pot.dsr() >= RAY && pot.dsr() < 1000000021979553151239153027,
            "TestError/pot-dsr-range"
        );
        assertTrue(
            diffCalc(expectedRate(values.pot_dsr), yearlyYield(expectedDSRRate)) <= TOLERANCE,
            "TestError/pot-dsr-rates-table"
        );

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
            assertTrue(dog.Hole() >= MILLION * RAD && dog.Hole() <= 200 * MILLION * RAD, "TestError/dog-Hole-range");
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
            assertTrue((dust >= RAD && dust < 100 * THOUSAND * RAD) || dust == 0, string(abi.encodePacked("TestError/vat-dust-range-", ilk))); // eq 0 or gt eq 1 and lt 100k
            }

            {
            (,uint256 mat) = spotter.ilks(ilk);
            // Convert BP to system expected value
            uint256 normalizedTestMat = (values.collaterals[ilk].mat * 10**23);
            if (values.collaterals[ilk].lerp) {
                assertTrue(mat <= normalizedTestMat, string(abi.encodePacked("TestError/vat-lerping-mat-", ilk)));
                assertTrue(mat >= RAY && mat <= 300 * RAY, string(abi.encodePacked("TestError/vat-mat-range-lerp-", ilk)));
            } else {
                assertEq(mat, normalizedTestMat, string(abi.encodePacked("TestError/vat-mat-", ilk)));
                assertTrue(mat >= RAY && mat < 10 * RAY, string(abi.encodePacked("TestError/vat-mat-range-", ilk)));    // cr eq 100% and lt 1000%
            }
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
                assertTrue(flipper != address(0), string(abi.encodePacked("TestError/invalid-flip-address-", ilk)));
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
                assertTrue(hole == 0 || hole >= RAD && hole <= 100 * MILLION * RAD, string(abi.encodePacked("TestError/dog-hole-range-", ilk)));
                }
                (address clipper,,,) = dog.ilks(ilk);
                assertTrue(clipper != address(0), string(abi.encodePacked("TestError/invalid-clip-address-", ilk)));
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
        assertEq(sumlines + values.line_offset * RAD, vat.Line(), "TestError/vat-Line");
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
        //       once the PIP uint256 size is increased
        assertTrue(price <= (10 ** 14) * WAD);

        return price;
    }

    function getUNIV2LPPrice(address pip) internal returns (uint256) {
        // hevm.load is to pull the price from the LP Oracle storage bypassing the whitelist
        uint256 price = uint256(hevm.load(
            pip,
            bytes32(uint256(3))
        )) & uint128(-1);   // Price is in the second half of the 32-byte storage slot

        // Price is bounded in the spot by around 10^23
        // Give a 10^9 buffer for price appreciation over time
        // Note: This currently can't be hit due to the uint112, but we want to backstop
        //       once the PIP uint256 size is increased
        assertTrue(price <= (10 ** 14) * WAD);

        return price;
    }

    function giveTokens(DSTokenAbstract token, uint256 amount) internal {
        // Edge case - balance is already set for some reason
        if (token.balanceOf(address(this)) == amount) return;

        for (uint256 i = 0; i < 200; i++) {
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
        assertTrue(false, "TestError/GiveTokens-slot-not-found");
    }

    function giveAuth(address _base, address target) internal {
        WardsAbstract base = WardsAbstract(_base);

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
        ClipAbstract clip,
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
        assertEq(clip.wards(address(end)), 1);
        assertEq(clip.wards(address(clipMom)), 1);
        if (_isOSM) {
            assertEq(OsmAbstract(pip).wards(address(osmMom)), 1);
            assertEq(OsmAbstract(pip).bud(address(spotter)), 1);
            assertEq(OsmAbstract(pip).bud(address(clip)), 1);
            assertEq(OsmAbstract(pip).bud(address(clipMom)), 1);
            assertEq(OsmAbstract(pip).bud(address(end)), 1);
            assertEq(MedianAbstract(OsmAbstract(pip).src()).bud(pip), 1);
            assertEq(OsmMomAbstract(osmMom).osms(_ilk), pip);
        }

        (,,,, uint256 dust) = vat.ilks(_ilk);
        dust /= RAY;
        uint256 amount = 2 * dust * 10**token.decimals() / (_isOSM ? getOSMPrice(pip) : uint256(DSValueAbstract(pip).read()));
        uint256 amount18 = token.decimals() == 18 ? amount : amount * 10**(18 - token.decimals());
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
        assertEq(vat.gem(_ilk, address(this)), amount18);

        // Tick the fees forward so that art != dai in wad units
        hevm.warp(block.timestamp + 1);
        jug.drip(_ilk);

        // Deposit collateral, generate DAI
        (,uint256 rate,,,) = vat.ilks(_ilk);
        assertEq(vat.dai(address(this)), 0);
        vat.frob(_ilk, address(this), address(this), address(this), int256(amount18), int256(divup(mul(RAY, dust), rate)));
        assertEq(vat.gem(_ilk, address(this)), 0);
        assertTrue(vat.dai(address(this)) >= dust * RAY);
        assertTrue(vat.dai(address(this)) <= (dust + 1) * RAY);

        // Payback DAI, withdraw collateral
        vat.frob(_ilk, address(this), address(this), address(this), -int256(amount18), -int256(divup(mul(RAY, dust), rate)));
        assertEq(vat.gem(_ilk, address(this)), amount18);
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
        vat.frob(_ilk, address(this), address(this), address(this), int256(amount18), int256(mul(amount18, spot) / rate));
        hevm.warp(block.timestamp + 1);
        jug.drip(_ilk);
        assertEq(clip.kicks(), 0);
        if (_checkLiquidations) {
            dog.bark(_ilk, address(this), address(this));
            assertEq(clip.kicks(), 1);
        }

        // Dump all dai for next run
        vat.move(address(this), address(0x0), vat.dai(address(this)));
    }

    function checkUNILPIntegration(
        bytes32 _ilk,
        GemJoinAbstract join,
        ClipAbstract clip,
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
        assertEq(clip.wards(address(end)), 1);
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
        assertEq(clip.kicks(), 0);
        if (_checkLiquidations) {
            dog.bark(_ilk, address(this), address(this));
            assertEq(clip.kicks(), 1);
        }

        // Dump all dai for next run
        vat.move(address(this), address(0x0), vat.dai(address(this)));
    }

    function checkPsmIlkIntegration(
        bytes32 _ilk,
        GemJoinAbstract join,
        ClipAbstract clip,
        address pip,
        PsmAbstract psm,
        uint256 tin,
        uint256 tout
    ) public {
        DSTokenAbstract token = DSTokenAbstract(join.gem());

        assertTrue(pip != address(0));

        spotter.poke(_ilk);

        // Authorization
        assertEq(join.wards(pauseProxy), 1);
        assertEq(join.wards(address(psm)), 1);
        assertEq(psm.wards(pauseProxy), 1);
        assertEq(vat.wards(address(join)), 1);
        assertEq(clip.wards(address(end)), 1);

        // Check toll in/out
        assertEq(psm.tin(), tin);
        assertEq(psm.tout(), tout);

        uint256 amount = 1000 * (10 ** token.decimals());
        giveTokens(token, amount);

        // Approvals
        token.approve(address(join), amount);
        dai.approve(address(psm), uint256(-1));

        // Convert all TOKEN to DAI
        psm.sellGem(address(this), amount);
        amount -= amount * tin / WAD;
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(dai.balanceOf(address(this)), amount * (10 ** (18 - token.decimals())));

        // Convert all DAI to TOKEN
        amount -= amount * tout / WAD;
        psm.buyGem(address(this), amount);
        assertEq(dai.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(address(this)), amount);

        // Dump all dai for next run
        vat.move(address(this), address(0x0), vat.dai(address(this)));
    }

    function checkDirectIlkIntegration(
        bytes32 _ilk,
        DirectDepositLike join,
        ClipAbstract clip,
        address pip,
        uint256 bar,
        uint256 tau
    ) public {
        DSTokenAbstract token = DSTokenAbstract(join.gem());
        assertTrue(pip != address(0));

        spotter.poke(_ilk);

        // Authorization
        assertEq(join.wards(pauseProxy), 1);
        assertEq(vat.wards(address(join)), 1);
        assertEq(clip.wards(address(end)), 1);
        assertEq(join.wards(address(esm)), 1);             // Required in case of gov. attack
        assertEq(join.wards(addr.addr("DIRECT_MOM")), 1);  // Zero-delay shutdown for Aave gov. attack

        // Check the bar/tau/king are set correctly
        assertEq(join.bar(), bar);
        assertEq(join.tau(), tau);
        assertEq(join.king(), pauseProxy);

        // Set the target bar to be super low to max out the debt ceiling
        giveAuth(address(join), address(this));
        join.file("bar", 1 * RAY / 10000);     // 0.01%
        join.deny(address(this));
        join.exec();

        // Module should be maxed out
        (,,, uint256 line,) = vat.ilks(_ilk);
        (uint256 ink, uint256 art) = vat.urns(_ilk, address(join));
        assertEq(ink*RAY, line);
        assertEq(art*RAY, line);
        assertGe(token.balanceOf(address(join)), ink - 1);         // Allow for small rounding error

        // Disable the module
        giveAuth(address(join), address(this));
        join.file("bar", 0);
        join.deny(address(this));
        join.exec();

        // Module should clear out
        (ink, art) = vat.urns(_ilk, address(join));
        assertLe(ink, 1);
        assertLe(art, 1);
        assertEq(token.balanceOf(address(join)), 0);
    }

    function checkDaiVest(uint256 _index, address _wallet, uint256 _start, uint256 _end, uint256 _amount) public {
        assertEq(vestDai.usr(_index), _wallet);
        assertEq(vestDai.bgn(_index), _start);
        assertEq(vestDai.fin(_index), _end);
        assertEq(vestDai.tot(_index), _amount * WAD);
    }

    function getMat(bytes32 _ilk) internal view returns (uint256 mat) {
        (, mat) = spotter.ilks(_ilk);
    }

    function checkIlkLerpOffboarding(bytes32 _ilk, bytes32 _lerp, uint256 _startMat, uint256 _endMat) public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        LerpAbstract lerp = LerpAbstract(lerpFactory.lerps(_lerp));

        hevm.warp(block.timestamp + lerp.duration() / 2);
        assertEq(getMat(_ilk), _startMat * RAY / 100);
        lerp.tick();
        assertEqApprox(getMat(_ilk), ((_startMat + _endMat) / 2) * RAY / 100, RAY / 100);

        hevm.warp(block.timestamp + lerp.duration());
        lerp.tick();
        assertEq(getMat(_ilk), _endMat * RAY / 100);
    }

    function checkIlkLerpIncreaseMatOffboarding(bytes32 _ilk, bytes32 _oldLerp, bytes32 _newLerp, uint256 _newEndMat) public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        LerpFactoryAbstract OLD_LERP_FAB = LerpFactoryAbstract(0x00B416da876fe42dd02813da435Cc030F0d72434);
        LerpAbstract oldLerp = LerpAbstract(OLD_LERP_FAB.lerps(_oldLerp));

        uint256 t = (block.timestamp - oldLerp.startTime()) * WAD / oldLerp.duration();
        uint256 tickMat = oldLerp.end() * t / WAD + oldLerp.start() - oldLerp.start() * t / WAD;
        assertEq(getMat(_ilk), tickMat);
        assertEq(spotter.wards(address(oldLerp)), 0);

        LerpAbstract newLerp = LerpAbstract(lerpFactory.lerps(_newLerp));

        hevm.warp(block.timestamp + newLerp.duration() / 2);
        assertEq(getMat(_ilk), tickMat);
        newLerp.tick();
        assertEqApprox(getMat(_ilk), (tickMat + _newEndMat * RAY / 100) / 2, RAY / 100);

        hevm.warp(block.timestamp + newLerp.duration());
        newLerp.tick();
        assertEq(getMat(_ilk), _newEndMat * RAY / 100);
    }

    function getExtcodesize(address target) public view returns (uint256 exsize) {
        assembly {
            exsize := extcodesize(target)
        }
    }

    function getBytecodeMetadataLength(address a) internal view returns (uint256 length) {
        // The Solidity compiler encodes the metadata length in the last two bytes of the contract bytecode.
        assembly {
            let ptr  := mload(0x40)
            let size := extcodesize(a)
            if iszero(lt(size, 2)) {
                extcodecopy(a, ptr, sub(size, 2), 2)
                length := mload(ptr)
                length := shr(240, length)
                length := add(length, 2)  // the two bytes used to specify the length are not counted in the length
            }
            // We'll return zero if the bytecode is shorter than two bytes.
        }
    }

    function checkWards(address _addr, string memory contractName) internal {
        for (uint256 i = 0; i < deployers.count(); i ++) {
            (bool ok, bytes memory data) = _addr.call(
                abi.encodeWithSignature("wards(address)", deployers.addr(i))
            );
            if (!ok || data.length != 32) return;
            uint256 ward = abi.decode(data, (uint256));
            if (ward > 0) {
                emit Log("Bad auth", deployers.addr(i), contractName);
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
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

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
}
