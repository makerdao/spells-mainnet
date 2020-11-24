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

interface VoteProxyFactoryAbstract {
    function initiateLink(address) external;
    function approveLink(address) external returns (VoteProxyAbstract);
}

interface VoteProxyAbstract {
    function lock(uint256) external;
    function vote(address[] calldata) external;
}

contract Voter {
    function doApproveLink(VoteProxyFactoryAbstract voteProxyFactory, address cold) external returns (VoteProxyAbstract voteProxy) {
        voteProxy = voteProxyFactory.approveLink(cold);
    }

    function doVote(VoteProxyAbstract voteProxy, address[] calldata votes) external {
        voteProxy.vote(votes);
    }
}

contract DssSpellTest is DSTest, DSMath {
    // populate with mainnet spell if needed
    address constant MAINNET_SPELL = address(0);
    // this needs to be updated
    uint256 constant SPELL_CREATED = 0;

    // Previous spell; supply if there is a need to test prior to its cast() function being called on mainnet.
    SpellLike constant PREV_SPELL = SpellLike(0x823Ac093BC6C5D1cC48739d574aC0a8D09ffC565);
    // Time to warp to in order to allow the previous spell to be cast; ignored if PREV_SPELL is SpellLike(address(0)).
    uint256   constant PREV_SPELL_EXECUTION_TIME = 1612108914;

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
    DSPauseAbstract      pause = DSPauseAbstract(    addr.addr("MCD_PAUSE"));
    address         pauseProxy =                     addr.addr("MCD_PAUSE_PROXY");
    DSChiefAbstract   oldChief = DSChiefAbstract(    addr.addr("MCD_ADM"));
    DSChiefAbstract   newChief = DSChiefAbstract(    0x0a3f6849f78076aefaDf113F5BED87720274dDC0);
    VatAbstract            vat = VatAbstract(        addr.addr("MCD_VAT"));
    VowAbstract            vow = VowAbstract(        addr.addr("MCD_VOW"));
    CatAbstract            cat = CatAbstract(        addr.addr("MCD_CAT"));
    PotAbstract            pot = PotAbstract(        addr.addr("MCD_POT"));
    JugAbstract            jug = JugAbstract(        addr.addr("MCD_JUG"));
    SpotAbstract          spot = SpotAbstract(       addr.addr("MCD_SPOT"));
    DSTokenAbstract        gov = DSTokenAbstract(    addr.addr("MCD_GOV"));
    EndAbstract            end = EndAbstract(        addr.addr("MCD_END"));
    IlkRegistryAbstract    reg = IlkRegistryAbstract(addr.addr("ILK_REGISTRY"));

    OsmMomAbstract      osmMom = OsmMomAbstract(     addr.addr("OSM_MOM"));
    FlipperMomAbstract flipMom = FlipperMomAbstract( addr.addr("FLIPPER_MOM"));

    ChainlogAbstract  chainlog = ChainlogAbstract(   addr.addr("CHANGELOG"));

    address    makerDeployer06 = 0xda0fab060e6cc7b1C0AA105d29Bd50D71f036711;

    // Specific for this spell
    DSAuthAbstract saiMom      = DSAuthAbstract(     0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C);
    DSAuthAbstract saiTop      = DSAuthAbstract(     0x9b0ccf7C8994E19F39b2B4CF708e0A7DF65fA8a3);

    VoteProxyFactoryAbstract
              voteProxyFactory
                               = VoteProxyFactoryAbstract(
                                                     0x6FCD258af181B3221073A96dD90D1f7AE7eEc408);

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

        spell = MAINNET_SPELL != address(0) ? DssSpell(MAINNET_SPELL) : new DssSpell();

        //
        // Test for all system configuration changes
        //
        afterSpell = SystemValues({
            pot_dsr:               0,                       // In basis points
            vat_Line:              158175 * MILLION / 100,  // In whole Dai units
            pause_delay:           48 hours,                // In seconds
            vow_wait:              156 hours,               // In seconds
            vow_dump:              250,                     // In whole Dai units
            vow_sump:              50000,                   // In whole Dai units
            vow_bump:              10000,                   // In whole Dai units
            vow_hump:              4 * MILLION,             // In whole Dai units
            cat_box:               15 * MILLION,            // In whole Dai units
            pause_authority:       address(newChief),       // Pause authority
            osm_mom_authority:     address(newChief),       // OsmMom authority
            flipper_mom_authority: address(newChief),       // FlipperMom authority
            ilk_count:             18                       // Num expected in system
        });

        //
        // Test for all collateral based changes here
        //
        afterSpell.collaterals["ETH-A"] = CollateralValues({
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
        if (oldChief.hat() != address(spell)) {
            hevm.store(
                address(gov),
                keccak256(abi.encode(address(this), uint256(1))),
                bytes32(uint256(999999999999 ether))
            );
            gov.approve(address(oldChief), uint256(-1));
            oldChief.lock(999999999999 ether);

            assertTrue(!spell.done());

            address[] memory yays = new address[](1);
            yays[0] = address(spell);

            oldChief.vote(yays);
            oldChief.lift(address(spell));
        }
        assertEq(oldChief.hat(), address(spell));
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

   function testOnTime() public {
       vote();
       scheduleWaitAndCast();
   }

    // function testSpellIsCast() public {
    //     string memory description = new DssSpell().description();
    //     assertTrue(bytes(description).length > 0);
    //     // DS-Test can't handle strings directly, so cast to a bytes32.
    //     assertEq(stringToBytes32(spell.description()),
    //             stringToBytes32(description));

    //     if(address(spell) != address(MAINNET_SPELL)) {
    //         assertEq(spell.expiration(), (now + 4 days + 2 hours));
    //     } else {
    //         assertEq(spell.expiration(), (SPELL_CREATED + 4 days + 2 hours));
    //     }

    //     vote();
    //     scheduleWaitAndCast();
    //     assertTrue(spell.done());

    //     checkSystemValues(afterSpell);

    //     checkCollateralValues(afterSpell);
    // }

    function test_nextCastTime() public {
        hevm.warp(1606161600); // Nov 23, 3:00pm (could be cast Nov 26)

        vote();
        spell.schedule();

        uint256 monday_9am  = 1606744800; // Nov 30

        /*** Day tests */
        hevm.warp(monday_9am); // Monday, 9am
        assertEq(spell.nextCastTime(), monday_9am);

        hevm.warp(monday_9am - 1 days); // Sunday, 9am
        assertEq(spell.nextCastTime(), monday_9am);

        hevm.warp(monday_9am - 2 days); // Saturday, 9am
        assertEq(spell.nextCastTime(), monday_9am);

        hevm.warp(monday_9am - 3 days); // Friday, 9am
        assertEq(spell.nextCastTime(), monday_9am - 3 days); // Able to cast

        /*** Time tests ***/
        uint256 castTime;

        for(uint i = 0; i < 5; i++) {
            castTime = monday_9am + i * 1 days; // Next day at 9am
            hevm.warp(castTime - 1 seconds); // 8:59am
            assertEq(spell.nextCastTime(), castTime);

            hevm.warp(castTime + 7 hours + 1 seconds); // 4:01pm
            if (i < 4) {
                assertEq(spell.nextCastTime(), monday_9am + (i + 1) * 1 days); // Next day at 9am
            } else {
                assertEq(spell.nextCastTime(), monday_9am + 7 days); // Next monday at 9am (friday case)
            }
        }
    }

    function testFail_notScheduled() public {
        spell.nextCastTime();
    }

    function test_use_eta() public {
        hevm.warp(1606161600); // Nov 23, 3pm (could be cast Nov 26)

        vote();
        spell.schedule();

        uint castTime = spell.nextCastTime();
        assertEq(castTime, spell.eta()); // Nov 26, 3pm
    }

    function testRootExecuteSpell() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        DSTokenAbstract(oldChief.IOU()).approve(address(oldChief), uint256(-1));
        oldChief.free(999999999999 ether);
        gov.approve(address(newChief), uint256(-1));

        newChief.lock(80_000 ether);
        address[] memory slate = new address[](1);

        // Create spell for testing
        TestSpell testSpell = new TestSpell();

        // System not launched, lifted address doesn't get root access
        slate[0] = address(testSpell);
        newChief.vote(slate);
        newChief.lift(address(testSpell));
        assertTrue(!newChief.isUserRoot(address(testSpell)));

        // Launch system
        slate[0] = address(0);
        newChief.vote(slate);
        newChief.lift(address(0));
        assertEq(newChief.live(), 0);
        assertTrue(!newChief.isUserRoot(address(0)));
        newChief.launch();
        assertEq(newChief.live(), 1);
        assertTrue(newChief.isUserRoot(address(0)));

        // System launched, lifted address gets root access
        slate[0] = address(testSpell);
        newChief.vote(slate);
        newChief.lift(address(testSpell));
        assertTrue(newChief.isUserRoot(address(testSpell)));
        testSpell.schedule();
    }

    function testRootExecuteSpellViaVoteProxy() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        DSTokenAbstract(oldChief.IOU()).approve(address(oldChief), uint256(-1));
        oldChief.free(999999999999 ether);

        Voter voter = new Voter();
        voteProxyFactory.initiateLink(address(voter));
        VoteProxyAbstract voteProxy = voter.doApproveLink(voteProxyFactory, address(this));

        gov.approve(address(voteProxy), uint256(-1));

        voteProxy.lock(80_000 ether);
        address[] memory slate = new address[](1);

        // Create spell for testing
        TestSpell testSpell = new TestSpell();

        // System not launched, lifted address doesn't get root access
        slate[0] = address(testSpell);
        voteProxy.vote(slate);
        newChief.lift(address(testSpell));
        assertTrue(!newChief.isUserRoot(address(testSpell)));

        // Launch system
        slate[0] = address(0);
        voteProxy.vote(slate);
        newChief.lift(address(0));
        assertEq(newChief.live(), 0);
        assertTrue(!newChief.isUserRoot(address(0)));
        newChief.launch();
        assertEq(newChief.live(), 1);
        assertTrue(newChief.isUserRoot(address(0)));

        // System launched, lifted address gets root access
        slate[0] = address(testSpell);
        voteProxy.vote(slate);
        newChief.lift(address(testSpell));
        assertTrue(newChief.isUserRoot(address(testSpell)));
        testSpell.schedule();
    }

    function testFailExecuteSpellNotLaunched() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        DSTokenAbstract(oldChief.IOU()).approve(address(oldChief), uint256(-1));
        oldChief.free(999999999999 ether);
        gov.approve(address(newChief), uint256(-1));

        newChief.lock(80_000 ether);
        address[] memory slate = new address[](1);

        // Create spell for testing
        TestSpell testSpell = new TestSpell();

        // System not launched, lifted address doesn't get root access
        slate[0] = address(testSpell);
        newChief.vote(slate);
        newChief.lift(address(testSpell));
        testSpell.schedule();
    }

    function _runOldChief() internal {
        TestSpell testSpell = new TestSpell();

        address[] memory slate = new address[](1);
        slate[0] = address(testSpell);
        oldChief.vote(slate);
        oldChief.lift(address(testSpell));
        testSpell.schedule();
    }

    function testExecuteSpellOldChief() public {
        vote();
        _runOldChief();
    }

    function testFailExecuteSpellOldChief() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        _runOldChief();
    }

    function testMoms() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        DSTokenAbstract(oldChief.IOU()).approve(address(oldChief), uint256(-1));
        oldChief.free(999999999999 ether);
        gov.approve(address(newChief), uint256(-1));

        newChief.lock(80_000 ether);
        address[] memory slate = new address[](1);

        // Create spell for testing
        TestMomsSpell testMomsSpell = new TestMomsSpell();

        // System not launched, lifted address doesn't get root access
        slate[0] = address(testMomsSpell);
        newChief.vote(slate);
        newChief.lift(address(testMomsSpell));
        assertTrue(!newChief.isUserRoot(address(testMomsSpell)));

        // Launch system
        slate[0] = address(0);
        newChief.vote(slate);
        newChief.lift(address(0));
        newChief.launch();

        // System launched, lifted address gets root access
        slate[0] = address(testMomsSpell);
        newChief.vote(slate);
        newChief.lift(address(testMomsSpell));
        assertTrue(newChief.isUserRoot(address(testMomsSpell)));

        FlipAbstract flip = FlipAbstract(chainlog.getAddress("MCD_FLIP_ETH_A"));
        OsmAbstract   osm = OsmAbstract(chainlog.getAddress("PIP_ETH"));

        assertEq(flip.wards(address(cat)), 1);
        assertEq(osm.stopped(), 0);
        testMomsSpell.cast();
        assertEq(flip.wards(address(cat)), 0);
        assertEq(osm.stopped(), 1);
    }

    function testSAIcontractsAuthorityChange() public {
        assertEq(saiMom.authority(), address(oldChief));
        assertEq(saiTop.authority(), address(oldChief));
        vote();
        spell.schedule();
        assertEq(saiMom.authority(), address(0));
        assertEq(saiTop.authority(), address(0));
    }
}

contract SpellActionTest {
    function execute() external {
        // Random action to test authority
        VatAbstract(ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F).getAddress("MCD_VAT")).rely(address(123));
    }
}

contract TestSpell {
    DSPauseAbstract public pause =
        DSPauseAbstract(ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F).getAddress("MCD_PAUSE"));
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellActionTest());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }
}

contract TestMomsSpell {
    ChainlogAbstract chainlog = ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    FlipperMomAbstract public fMom =
        FlipperMomAbstract(chainlog.getAddress("FLIPPER_MOM"));

    OsmMomAbstract public oMom =
        OsmMomAbstract(chainlog.getAddress("OSM_MOM"));

    function cast() public {
        fMom.deny(chainlog.getAddress("MCD_FLIP_ETH_A"));
        oMom.stop("ETH-A");
    }
}
