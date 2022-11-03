// SPDX-FileCopyrightText: © 2020 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
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

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "dss-interfaces/Interfaces.sol";

import "./test/rates.sol";
import "./test/addresses_mainnet.sol";
import "./test/addresses_deployers.sol";
import "./test/addresses_wallets.sol";
import "./test/config.sol";

import {DssSpell} from "./DssSpell.sol";

struct TeleportGUID {
    bytes32 sourceDomain;
    bytes32 targetDomain;
    bytes32 receiver;
    bytes32 operator;
    uint128 amount;
    uint80 nonce;
    uint48 timestamp;
}

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
    function load(address,bytes32) external view returns (bytes32);
    function addr(uint) external returns (address);
    function sign(uint, bytes32) external returns (uint8, bytes32, bytes32);
    function startPrank(address) external;
    function stopPrank() external;
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

interface FlapLike is FlapAbstract {
    function fill() external view returns (uint256);
    function lid() external view returns (uint256);
}

interface CropperLike {
    function getOrCreateProxy(address usr) external returns (address urp);
    function join(address crop, address usr, uint256 val) external;
    function exit(address crop, address usr, uint256 val) external;
    function frob(bytes32 ilk, address u, address v, address w, int256 dink, int256 dart) external;
}

interface CropJoinLike {
    function wards(address) external view returns (uint256);
    function gem() external view returns (address);
    function bonus() external view returns (address);
}

interface CurveLPOsmLike is LPOsmAbstract {
    function orbs(uint256) external view returns (address);
}

interface CureLike {
    function tCount() external view returns (uint256);
    function srcs(uint256) external view returns (address);
    function live() external view returns (uint256);
    function tell() external view returns (uint256);
    function cage() external;
    function load(address) external;
}

interface TeleportJoinLike {
    function wards(address) external view returns (uint256);
    function fees(bytes32) external view returns (address);
    function line(bytes32) external view returns (uint256);
    function debt(bytes32) external view returns (int256);
    function vow() external view returns (address);
    function vat() external view returns (address);
    function daiJoin() external view returns (address);
    function ilk() external view returns (bytes32);
    function domain() external view returns (bytes32);
}

interface TeleportFeeLike {
    function fee() external view returns (uint256);
    function ttl() external view returns (uint256);
}

interface TeleportOracleAuthLike {
    function wards(address) external view returns (uint256);
    function signers(address) external view returns (uint256);
    function teleportJoin() external view returns (address);
    function threshold() external view returns (uint256);
    function addSigners(address[] calldata) external;
    function getSignHash(TeleportGUID calldata) external pure returns (bytes32);
    function requestMint(
        TeleportGUID calldata,
        bytes calldata,
        uint256,
        uint256
    ) external returns (uint256, uint256);
}

interface TeleportRouterLike {
    function wards(address) external view returns (uint256);
    function file(bytes32, bytes32, address) external;
    function gateways(bytes32) external view returns (address);
    function domains(address) external view returns (bytes32);
    function numDomains() external view returns (uint256);
    function dai() external view returns (address);
    function requestMint(
        TeleportGUID calldata,
        uint256,
        uint256
    ) external returns (uint256, uint256);
    function settle(bytes32, uint256) external;
}

interface TeleportBridgeLike {
    function l1Escrow() external view returns (address);
    function l1TeleportRouter() external view returns (address);
    function l1Token() external view returns (address);
    function l2TeleportGateway() external view returns (address);
}

interface OptimismTeleportBridgeLike is TeleportBridgeLike {
    function messenger() external view returns (address);
}

interface ArbitrumTeleportBridgeLike is TeleportBridgeLike {
    function inbox() external view returns (address);
}

contract DssSpellTestBase is Config, DSTest, DSMath {
    Hevm hevm;

    Rates         rates = new Rates();
    Addresses      addr = new Addresses();
    Deployers deployers = new Deployers();
    Wallets     wallets = new Wallets();

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
    CureLike                cure = CureLike(           addr.addr("MCD_CURE"));
    IlkRegistryAbstract      reg = IlkRegistryAbstract(addr.addr("ILK_REGISTRY"));
    FlapLike                flap = FlapLike(           addr.addr("MCD_FLAP"));
    CropperLike          cropper = CropperLike(        addr.addr("MCD_CROPPER"));

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

    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function concat(string memory a, bytes32 b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, bytes32ToStr(b)));
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

        setValues(address(chief));

        spellValues.deployed_spell_created = spellValues.deployed_spell != address(0) ? spellValues.deployed_spell_created : block.timestamp;
        castPreviousSpell();
        spell = spellValues.deployed_spell != address(0) ?
            DssSpell(spellValues.deployed_spell) : new DssSpell();
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
            giveTokens(address(gov), 999999999999 ether);
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
            (vow.hump() >= RAD && vow.hump() < THOUSAND * MILLION * RAD) ||
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

        // ESM min in WAD
        {
            uint256 normalizedMin = values.esm_min * WAD;
            assertEq(esm.min(), normalizedMin, "TestError/esm-min");
            assertTrue(esm.min() > WAD && esm.min() < 200 * THOUSAND * WAD, "TestError/esm-min-range");
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
        // Check flap lid and sanity checks
        uint256 normalizedLid = values.flap_lid * RAD;
        assertEq(flap.lid(), normalizedLid, "TestError/flap-lid");
        assertTrue(flap.lid() > 0 && flap.lid() <= MILLION * RAD, "TestError/flap-lid-range");
    }

    function checkCollateralValues(SystemValues storage values) internal {
        uint256 sumlines;
        bytes32[] memory ilks = reg.list();
        for(uint256 i = 0; i < ilks.length; i++) {
            bytes32 ilk = ilks[i];
            (uint256 duty,)  = jug.ilks(ilk);

            assertEq(duty, rates.rates(values.collaterals[ilk].pct), concat("TestError/jug-duty-", ilk));
            // make sure duty is less than 1000% APR
            // bc -l <<< 'scale=27; e( l(10.00)/(60 * 60 * 24 * 365) )'
            // 1000000073014496989316680335
            assertTrue(duty >= RAY && duty < 1000000073014496989316680335, concat("TestError/jug-duty-range-", ilk));  // gt 0 and lt 1000%
            assertTrue(
                diffCalc(expectedRate(values.collaterals[ilk].pct), yearlyYield(rates.rates(values.collaterals[ilk].pct))) <= TOLERANCE,
                concat("TestError/rates-", ilk)
            );
            assertTrue(values.collaterals[ilk].pct < THOUSAND * THOUSAND, concat("TestError/pct-max-", ilk));   // check value lt 1000%
            {
            (,,, uint256 line, uint256 dust) = vat.ilks(ilk);
            // Convert whole Dai units to expected RAD
            uint256 normalizedTestLine = values.collaterals[ilk].line * RAD;
            sumlines += line;
            (uint256 aL_line, uint256 aL_gap, uint256 aL_ttl,,) = autoLine.ilks(ilk);
            if (!values.collaterals[ilk].aL_enabled) {
                assertTrue(aL_line == 0, concat("TestError/al-Line-not-zero-", ilk));
                assertEq(line, normalizedTestLine, concat("TestError/vat-line-", ilk));
                assertTrue((line >= RAD && line < 10 * BILLION * RAD) || line == 0, concat("TestError/vat-line-range-", ilk));  // eq 0 or gt eq 1 RAD and lt 10B
            } else {
                assertTrue(aL_line > 0, concat("TestError/al-Line-is-zero-", ilk));
                assertEq(aL_line, values.collaterals[ilk].aL_line * RAD, concat("TestError/al-line-", ilk));
                assertEq(aL_gap, values.collaterals[ilk].aL_gap * RAD, concat("TestError/al-gap-", ilk));
                assertEq(aL_ttl, values.collaterals[ilk].aL_ttl, concat("TestError/al-ttl-", ilk));
                assertTrue((aL_line >= RAD && aL_line < 20 * BILLION * RAD) || aL_line == 0, concat("TestError/al-line-range-", ilk)); // eq 0 or gt eq 1 RAD and lt 10B
            }
            uint256 normalizedTestDust = values.collaterals[ilk].dust * RAD;
            assertEq(dust, normalizedTestDust, concat("TestError/vat-dust-", ilk));
            assertTrue((dust >= RAD && dust < 100 * THOUSAND * RAD) || dust == 0, concat("TestError/vat-dust-range-", ilk)); // eq 0 or gt eq 1 and lt 100k
            }

            {
            (address pip, uint256 mat) = spotter.ilks(ilk);
            if (pip != address(0)) {
                // Convert BP to system expected value
                uint256 normalizedTestMat = (values.collaterals[ilk].mat * 10**23);
                if ( values.collaterals[ilk].lerp ) {
                    assertTrue(mat <= normalizedTestMat, concat("TestError/vat-lerping-mat-", ilk));
                    assertTrue(mat >= RAY && mat <= 300 * RAY, concat("TestError/vat-mat-range-", ilk));  // cr gt 100% and lt 30000%
                } else {
                    assertEq(mat, normalizedTestMat, concat("TestError/vat-mat-", ilk));
                    assertTrue(mat >= RAY && mat < 10 * RAY, concat("TestError/vat-mat-range-", ilk));    // cr gt 100% and lt 1000%
                }
            }
            }

            if (values.collaterals[ilk].liqType == "flip") {
                {
                assertEq(reg.class(ilk), 2, concat("TestError/reg-class-", ilk));
                (bool ok, bytes memory val) = reg.xlip(ilk).call(abi.encodeWithSignature("cat()"));
                assertTrue(ok, concat("TestError/reg-xlip-cat-", ilk));
                assertEq(abi.decode(val, (address)), address(cat), concat("TestError/reg-xlip-cat-", ilk));
                }
                {
                (, uint256 chop, uint256 dunk) = cat.ilks(ilk);
                // Convert BP to system expected value
                uint256 normalizedTestChop = (values.collaterals[ilk].chop * 10**14) + WAD;
                assertEq(chop, normalizedTestChop, concat("TestError/cat-chop-", ilk));
                // make sure chop is less than 100%
                assertTrue(chop >= WAD && chop < 2 * WAD, concat("TestError/cat-chop-range-", ilk));   // penalty gt eq 0% and lt 100%

                // Convert whole Dai units to expected RAD
                uint256 normalizedTestDunk = values.collaterals[ilk].cat_dunk * RAD;
                assertEq(dunk, normalizedTestDunk, concat("TestError/cat-dunk-", ilk));
                assertTrue(dunk >= RAD && dunk < MILLION * RAD, concat("TestError/cat-dunk-range-", ilk));

                (address flipper,,) = cat.ilks(ilk);
                assertTrue(flipper != address(0), concat("TestError/invalid-flip-address-", ilk));
                FlipAbstract flip = FlipAbstract(flipper);
                // Convert BP to system expected value
                uint256 normalizedTestBeg = (values.collaterals[ilk].flip_beg + 10000)  * 10**14;
                assertEq(uint256(flip.beg()), normalizedTestBeg, concat("TestError/flip-beg-", ilk));
                assertTrue(flip.beg() >= WAD && flip.beg() <= 110 * WAD / 100, concat("TestError/flip-beg-range-", ilk)); // gte 0% and lte 10%
                assertEq(uint256(flip.ttl()), values.collaterals[ilk].flip_ttl, concat("TestError/flip-ttl-", ilk));
                assertTrue(flip.ttl() >= 600 && flip.ttl() < 10 hours, concat("TestError/flip-ttl-range-", ilk));         // gt eq 10 minutes and lt 10 hours
                assertEq(uint256(flip.tau()), values.collaterals[ilk].flip_tau, concat("TestError/flip-tau-", ilk));
                assertTrue(flip.tau() >= 600 && flip.tau() <= 3 days, concat("TestError/flip-tau-range-", ilk));          // gt eq 10 minutes and lt eq 3 days

                assertEq(flip.wards(address(flipMom)), values.collaterals[ilk].flipper_mom, concat("TestError/flip-flipperMom-auth-", ilk));

                assertEq(flip.wards(address(cat)), values.collaterals[ilk].liqOn ? 1 : 0, concat("TestError/flip-liqOn-", ilk));
                assertEq(flip.wards(address(end)), 1, concat("TestError/flip-end-auth-", ilk));
                assertEq(flip.wards(address(pauseProxy)), 1, concat("TestError/flip-pause-proxy-auth-", ilk)); // Check pause_proxy ward
                }
            }
            if (values.collaterals[ilk].liqType == "clip") {
                {
                assertEq(reg.class(ilk), 1, concat("TestError/reg-class-", ilk));
                (bool ok, bytes memory val) = reg.xlip(ilk).call(abi.encodeWithSignature("dog()"));
                assertTrue(ok, concat("TestError/reg-xlip-dog-", ilk));
                assertEq(abi.decode(val, (address)), address(dog), concat("TestError/reg-xlip-dog-", ilk));
                }
                {
                (, uint256 chop, uint256 hole,) = dog.ilks(ilk);
                // Convert BP to system expected value
                uint256 normalizedTestChop = (values.collaterals[ilk].chop * 10**14) + WAD;
                assertEq(chop, normalizedTestChop, concat("TestError/dog-chop-", ilk));
                // make sure chop is less than 100%
                assertTrue(chop >= WAD && chop < 2 * WAD, concat("TestError/dog-chop-range-", ilk));   // penalty gt eq 0% and lt 100%

                // Convert whole Dai units to expected RAD
                uint256 normalizedTesthole = values.collaterals[ilk].dog_hole * RAD;
                assertEq(hole, normalizedTesthole, concat("TestError/dog-hole-", ilk));
                assertTrue(hole == 0 || hole >= RAD && hole <= 100 * MILLION * RAD, concat("TestError/dog-hole-range-", ilk));
                }
                (address clipper,,,) = dog.ilks(ilk);
                assertTrue(clipper != address(0), concat("TestError/invalid-clip-address-", ilk));
                ClipAbstract clip = ClipAbstract(clipper);
                {
                // Convert BP to system expected value
                uint256 normalizedTestBuf = values.collaterals[ilk].clip_buf * 10**23;
                assertEq(uint256(clip.buf()), normalizedTestBuf, concat("TestError/clip-buf-", ilk));
                assertTrue(clip.buf() >= RAY && clip.buf() <= 2 * RAY, concat("TestError/clip-buf-range-", ilk)); // gte 0% and lte 100%
                assertEq(uint256(clip.tail()), values.collaterals[ilk].clip_tail, concat("TestError/clip-tail-", ilk));
                if (ilk == "TUSD-A") { // long tail liquidation
                    assertTrue(clip.tail() >= 1200 && clip.tail() < 30 days, concat("TestError/TUSD-clip-tail-range-", ilk)); // gt eq 20 minutes and lt 10 hours
                } else {
                    assertTrue(clip.tail() >= 1200 && clip.tail() < 10 hours, concat("TestError/clip-tail-range-", ilk)); // gt eq 20 minutes and lt 10 hours
                } // gt eq 20 minutes and lt 10 hours
                uint256 normalizedTestCusp = (values.collaterals[ilk].clip_cusp)  * 10**23;
                assertEq(uint256(clip.cusp()), normalizedTestCusp, concat("TestError/clip-cusp-", ilk));
                assertTrue(clip.cusp() >= RAY / 10 && clip.cusp() < RAY, concat("TestError/clip-cusp-range-", ilk)); // gte 10% and lt 100%
                assertTrue(rmul(clip.buf(), clip.cusp()) <= RAY, concat("TestError/clip-buf-cusp-limit-", ilk));
                uint256 normalizedTestChip = (values.collaterals[ilk].clip_chip)  * 10**14;
                assertEq(uint256(clip.chip()), normalizedTestChip, concat("TestError/clip-chip-", ilk));
                assertTrue(clip.chip() < 1 * WAD / 100, concat("TestError/clip-chip-range-", ilk)); // lt 1%
                uint256 normalizedTestTip = values.collaterals[ilk].clip_tip * RAD;
                assertEq(uint256(clip.tip()), normalizedTestTip, concat("TestError/clip-tip-", ilk));
                assertTrue(clip.tip() == 0 || clip.tip() >= RAD && clip.tip() <= 500 * RAD, concat("TestError/clip-tip-range-", ilk));

                assertEq(clip.wards(address(clipMom)), values.collaterals[ilk].clipper_mom, concat("TestError/clip-clipperMom-auth-", ilk));

                assertEq(clipMom.tolerance(address(clip)), values.collaterals[ilk].cm_tolerance * RAY / 10000, concat("TestError/clipperMom-tolerance-", ilk));

                if (values.collaterals[ilk].liqOn) {
                    assertEq(clip.stopped(), 0, concat("TestError/clip-liqOn-", ilk));
                } else {
                    assertTrue(clip.stopped() > 0, concat("TestError/clip-liqOn-", ilk));
                }

                assertEq(clip.wards(address(end)), 1, concat("TestError/clip-end-auth-", ilk));
                assertEq(clip.wards(address(pauseProxy)), 1, concat("TestError/clip-pause-proxy-auth-", ilk)); // Check pause_proxy ward
                }
                {
                    (bool exists, bytes memory value) = clip.calc().call(abi.encodeWithSignature("tau()"));
                    assertEq(exists ? abi.decode(value, (uint256)) : 0, values.collaterals[ilk].calc_tau, concat("TestError/calc-tau-", ilk));
                    (exists, value) = clip.calc().call(abi.encodeWithSignature("step()"));
                    assertEq(exists ? abi.decode(value, (uint256)) : 0, values.collaterals[ilk].calc_step, concat("TestError/calc-step-", ilk));
                    if (exists) {
                        assertTrue(abi.decode(value, (uint256)) > 0, concat("TestError/calc-step-is-zero-", ilk));
                    }
                    (exists, value) = clip.calc().call(abi.encodeWithSignature("cut()"));
                    uint256 normalizedTestCut = values.collaterals[ilk].calc_cut * 10**23;
                    assertEq(exists ? abi.decode(value, (uint256)) : 0, normalizedTestCut, concat("TestError/calc-cut-", ilk));
                    if (exists) {
                        assertTrue(abi.decode(value, (uint256)) > 0 && abi.decode(value, (uint256)) < RAY, concat("TestError/calc-cut-range-", ilk));
                    }
                }
            }
            if (reg.class(ilk) < 3) {
                {
                GemJoinAbstract join = GemJoinAbstract(reg.join(ilk));
                assertEq(join.wards(address(pauseProxy)), 1, concat("TestError/join-pause-proxy-auth-", ilk)); // Check pause_proxy ward
                }
            }
        }
        //       actual                               expected
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

    function giveTokens(address token, uint256 amount) internal {
        // Edge case - balance is already set for some reason
        if (GemAbstract(token).balanceOf(address(this)) == amount) return;

        // Scan the storage for the balance storage slot
        for (uint256 i = 0; i < 200; i++) {
            // Solidity-style storage layout for maps
            {
                bytes32 prevValue = hevm.load(
                    address(token),
                    keccak256(abi.encode(address(this), uint256(i)))
                );

                hevm.store(
                    address(token),
                    keccak256(abi.encode(address(this), uint256(i))),
                    bytes32(amount)
                );
                if (GemAbstract(token).balanceOf(address(this)) == amount) {
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

            // Vyper-style storage layout for maps
            {
                bytes32 prevValue = hevm.load(
                    address(token),
                    keccak256(abi.encode(uint256(i), address(this)))
                );

                hevm.store(
                    address(token),
                    keccak256(abi.encode(uint256(i), address(this))),
                    bytes32(amount)
                );
                if (GemAbstract(token).balanceOf(address(this)) == amount) {
                    // Found it
                    return;
                } else {
                    // Keep going after restoring the original value
                    hevm.store(
                        address(token),
                        keccak256(abi.encode(uint256(i), address(this))),
                        prevValue
                    );
                }
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
        GemAbstract token = GemAbstract(join.gem());

        if (_isOSM) OsmAbstract(pip).poke();
        hevm.warp(block.timestamp + 3601);
        if (_isOSM) OsmAbstract(pip).poke();
        spotter.poke(_ilk);

        // Authorization
        assertEq(join.wards(pauseProxy), 1, concat("TestError/checkIlkIntegration-pauseProxy-not-auth-on-join-", _ilk));
        assertEq(vat.wards(address(join)), 1, concat("TestError/checkIlkIntegration-join-not-auth-on-vat-", _ilk));
        assertEq(vat.wards(address(clip)), 1, concat("TestError/checkIlkIntegration-clip-not-auth-on-vat-", _ilk));
        assertEq(dog.wards(address(clip)), 1, concat("TestError/checkIlkIntegration-clip-not-auth-on-dog-", _ilk));
        assertEq(clip.wards(address(dog)), 1, concat("TestError/checkIlkIntegration-dog-not-auth-on-clip-", _ilk));
        assertEq(clip.wards(address(end)), 1, concat("TestError/checkIlkIntegration-end-not-auth-on-clip-", _ilk));
        assertEq(clip.wards(address(clipMom)), 1, concat("TestError/checkIlkIntegration-clipMom-not-auth-on-clip-", _ilk));
        assertEq(clip.wards(address(esm)), 1, concat("TestError/checkIlkIntegration-esm-not-auth-on-clip-", _ilk));
        if (_isOSM) {
            assertEq(OsmAbstract(pip).wards(address(osmMom)), 1, concat("TestError/checkIlkIntegration-osmMom-not-auth-on-pip-", _ilk));
            assertEq(OsmAbstract(pip).bud(address(spotter)), 1, concat("TestError/checkIlkIntegration-spot-not-bud-on-pip-", _ilk));
            assertEq(OsmAbstract(pip).bud(address(clip)), 1, concat("TestError/checkIlkIntegration-spot-not-bud-on-pip-", _ilk));
            assertEq(OsmAbstract(pip).bud(address(clipMom)), 1, concat("TestError/checkIlkIntegration-spot-not-bud-on-pip-", _ilk));
            assertEq(OsmAbstract(pip).bud(address(end)), 1, concat("TestError/checkIlkIntegration-spot-not-bud-on-pip-", _ilk));
            assertEq(MedianAbstract(OsmAbstract(pip).src()).bud(pip), 1, concat("TestError/checkIlkIntegration-pip-not-bud-on-osm-", _ilk));
            assertEq(OsmMomAbstract(osmMom).osms(_ilk), pip, concat("TestError/checkIlkIntegration-pip-not-bud-on-osmMom-", _ilk));
        }

        (,,,, uint256 dust) = vat.ilks(_ilk);
        dust /= RAY;
        uint256 amount = 2 * dust * 10 ** uint256(token.decimals()) / (_isOSM ? getOSMPrice(pip) : uint256(DSValueAbstract(pip).read()));
        uint256 amount18 = token.decimals() == 18 ? amount : amount * 10**(18 - uint256(token.decimals()));
        giveTokens(address(token), amount);

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
        (,uint256 rate,,uint256 line,) = vat.ilks(_ilk);

        assertEq(vat.dai(address(this)), 0);
        // Set max line to ensure we can create a new position
        setIlkLine(_ilk, uint256(-1));
        vat.frob(_ilk, address(this), address(this), address(this), int256(amount18), int256(divup(mul(RAY, dust), rate)));
        // Revert ilk line to proceed with testing
        setIlkLine(_ilk, line);
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

        // Set max line to ensure we can draw dai
        setIlkLine(_ilk, uint256(-1));
        vat.frob(_ilk, address(this), address(this), address(this), int256(amount18), int256(mul(amount18, spot) / rate));
        // Revert ilk line to proceed with testing
        setIlkLine(_ilk, line);

        hevm.warp(block.timestamp + 1);
        jug.drip(_ilk);
        assertEq(clip.kicks(), 0);
        if (_checkLiquidations) {
            if (getIlkDuty(_ilk) == rates.rates(0)) {
                // Rates wont accrue if 0, raise the mat to make the vault unsafe
                setIlkMat(_ilk, 100000 * RAY);
                hevm.warp(block.timestamp + 10 days);
                spotter.poke(_ilk);
            }
            dog.bark(_ilk, address(this), address(this));
            assertEq(clip.kicks(), 1);
        }

        // Dump all dai for next run
        vat.move(address(this), address(0x0), vat.dai(address(this)));
    }

    function checkIlkClipper(
        bytes32 ilk,
        GemJoinAbstract join,
        ClipAbstract clipper,
        address calc,
        OsmAbstract pip,
        uint256 ilkAmt
    ) internal {

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
        assertEq(vat.wards(address(clipper))    , 1);
        assertEq(dog.wards(address(clipper))    , 1);
        assertEq(clipper.wards(address(dog))    , 1);
        assertEq(clipper.wards(address(end))    , 1);
        assertEq(clipper.wards(address(clipMom)), 1);
        assertEq(clipper.wards(address(esm)), 1);

        try pip.bud(address(spotter)) returns (uint256 bud) {
            assertEq(bud, 1);
        } catch {}
        try pip.bud(address(clipper)) returns (uint256 bud) {
            assertEq(bud, 1);
        } catch {}
        try pip.bud(address(clipMom)) returns (uint256 bud) {
            assertEq(bud, 1);
        } catch {}
        try pip.bud(address(end)) returns (uint256 bud) {
            assertEq(bud, 1);
        } catch {}

        // Force max Hole
        hevm.store(
            address(dog),
            bytes32(uint256(4)),
            bytes32(uint256(-1))
        );

        // ----------------------- Check Clipper works and bids can be made -----------------------

        {
        GemAbstract token = GemAbstract(join.gem());
        uint256 tknAmt =  ilkAmt / 10 ** (18 - join.dec());
        giveTokens(address(token), tknAmt);
        assertEq(token.balanceOf(address(this)), tknAmt);

        // Join to adapter
        assertEq(vat.gem(ilk, address(this)), 0);
        assertEq(token.allowance(address(this), address(join)), 0);
        token.approve(address(join), tknAmt);
        join.join(address(this), tknAmt);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(vat.gem(ilk, address(this)), ilkAmt);
        }

        {
        // Generate new DAI to force a liquidation
        uint256 rate;
        int256 art;
        uint256 spot;
        uint256 line;
        (,rate, spot, line,) = vat.ilks(ilk);
        art = int256(mul(ilkAmt, spot) / rate);

        // dart max amount of DAI
        setIlkLine(ilk, uint256(-1));
        vat.frob(ilk, address(this), address(this), address(this), int256(ilkAmt), art);
        setIlkLine(ilk, line);
        setIlkMat(ilk, 100000 * RAY);
        hevm.warp(block.timestamp + 10 days);
        spotter.poke(ilk);
        assertEq(clipper.kicks(), 0);
        dog.bark(ilk, address(this), address(this));
        assertEq(clipper.kicks(), 1);

        (, rate,,,) = vat.ilks(ilk);
        uint256 debt = mul(mul(rate, uint256(art)), dog.chop(ilk)) / WAD;
        hevm.store(
            address(vat),
            keccak256(abi.encode(address(this), uint256(5))),
            bytes32(debt)
        );
        assertEq(vat.dai(address(this)), debt);
        assertEq(vat.gem(ilk, address(this)), 0);

        hevm.warp(block.timestamp + 20 minutes);
        (, uint256 tab, uint256 lot, address usr,, uint256 top) = clipper.sales(1);

        assertEq(usr, address(this));
        assertEq(tab, debt);
        assertEq(lot, ilkAmt);
        assertTrue(mul(lot, top) > tab); // There is enough collateral to cover the debt at current price

        vat.hope(address(clipper));
        clipper.take(1, lot, top, address(this), bytes(""));
        }

        {
        (, uint256 tab, uint256 lot, address usr,,) = clipper.sales(1);
        assertEq(usr, address(0));
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(vat.dai(address(this)), 0);
        assertEq(vat.gem(ilk, address(this)), ilkAmt); // What was purchased + returned back as it is the owner of the vault
        }
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
        GemAbstract token = GemAbstract(join.gem());

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
        giveTokens(address(token), amount);

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
        GemAbstract token = GemAbstract(join.gem());

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

        uint256 amount = 1000 * (10 ** uint256(token.decimals()));
        giveTokens(address(token), amount);

        // Approvals
        token.approve(address(join), amount);
        dai.approve(address(psm), uint256(-1));

        // Convert all TOKEN to DAI
        psm.sellGem(address(this), amount);
        amount -= amount * tin / WAD;
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(dai.balanceOf(address(this)), amount * (10 ** (18 - uint256(token.decimals()))));

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
        GemAbstract token = GemAbstract(join.gem());
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

    function checkCropCRVLPIntegration(
        bytes32 _ilk,
        CropJoinLike join,
        ClipAbstract clip,
        CurveLPOsmLike pip,
        address _medianizer1,
        address _medianizer2,
        bool _isMedian1,
        bool _isMedian2,
        bool _checkLiquidations
    ) public {
        pip.poke();
        hevm.warp(block.timestamp + 3601);
        pip.poke();
        spotter.poke(_ilk);

        // Check medianizer sources
        assertEq(pip.orbs(0), _medianizer1);
        assertEq(pip.orbs(1), _medianizer2);

        // Contracts set
        {
            (address _clip,,,) = dog.ilks(_ilk);
            assertEq(_clip, address(clip));
        }
        assertEq(clip.ilk(), _ilk);
        assertEq(clip.vat(), address(vat));
        assertEq(clip.vow(), address(vow));
        assertEq(clip.dog(), address(dog));
        assertEq(clip.spotter(), address(spotter));

        // Authorization
        assertEq(join.wards(pauseProxy), 1);
        assertEq(vat.wards(address(join)), 1);
        assertEq(vat.wards(address(clip)), 1);
        assertEq(dog.wards(address(clip)), 1);
        assertEq(clip.wards(address(dog)), 1);
        assertEq(clip.wards(address(end)), 1);
        assertEq(clip.wards(address(clipMom)), 1);
        assertEq(clip.wards(address(esm)), 1);
        assertEq(pip.wards(address(osmMom)), 1);
        assertEq(pip.bud(address(spotter)), 1);
        assertEq(pip.bud(address(end)), 1);
        assertEq(pip.bud(address(clip)), 1);
        assertEq(pip.bud(address(clipMom)), 1);
        if (_isMedian1) assertEq(MedianAbstract(_medianizer1).bud(address(pip)), 1);
        if (_isMedian2) assertEq(MedianAbstract(_medianizer2).bud(address(pip)), 1);

        (,,,, uint256 dust) = vat.ilks(_ilk);
        uint256 amount = 2 * dust / (getUNIV2LPPrice(address(pip)) * 1e9);
        giveTokens(address(join.gem()), amount);

        assertEq(GemAbstract(join.gem()).balanceOf(address(this)), amount);
        assertEq(vat.gem(_ilk, cropper.getOrCreateProxy(address(this))), 0);
        GemAbstract(join.gem()).approve(address(cropper), amount);
        cropper.join(address(join), address(this), amount);
        assertEq(GemAbstract(join.gem()).balanceOf(address(this)), 0);
        assertEq(vat.gem(_ilk, cropper.getOrCreateProxy(address(this))), amount);

        // Tick the fees forward so that art != dai in wad units
        hevm.warp(block.timestamp + 1);
        jug.drip(_ilk);

        // Check that we got rewards from the time increment above
        assertEq(GemAbstract(join.bonus()).balanceOf(address(this)), 0);
        cropper.join(address(join), address(this), 0);
        // NOTE: LDO rewards are shutting off on Friday so this will fail (bad timing), but they plan to extend
        //assertGt(GemAbstract(join.bonus()).balanceOf(address(this)), 0);

        // Deposit collateral, generate DAI
        (,uint256 rate,,,) = vat.ilks(_ilk);
        assertEq(vat.dai(address(this)), 0);
        cropper.frob(_ilk, address(this), address(this), address(this), int(amount), int(divup(dust, rate)));
        assertEq(vat.gem(_ilk, cropper.getOrCreateProxy(address(this))), 0);
        assertTrue(vat.dai(address(this)) >= dust && vat.dai(address(this)) <= dust + RAY);

        // Payback DAI, withdraw collateral
        vat.hope(address(cropper));      // Need to grant the cropper permission to remove dai
        cropper.frob(_ilk, address(this), address(this), address(this), -int(amount), -int(divup(dust, rate)));
        assertEq(vat.gem(_ilk, cropper.getOrCreateProxy(address(this))), amount);
        assertEq(vat.dai(address(this)), 0);

        // Withdraw from adapter
        cropper.exit(address(join), address(this), amount);
        assertEq(GemAbstract(join.gem()).balanceOf(address(this)), amount);
        assertEq(vat.gem(_ilk, cropper.getOrCreateProxy(address(this))), 0);

        if (_checkLiquidations) {
            // Generate new DAI to force a liquidation
            GemAbstract(join.gem()).approve(address(cropper), amount);
            cropper.join(address(join), address(this), amount);
            // dart max amount of DAI
            {   // Stack too deep
                (,,uint256 spot,,) = vat.ilks(_ilk);
                cropper.frob(_ilk, address(this), address(this), address(this), int(amount), int(mul(amount, spot) / rate));
            }
            hevm.warp(block.timestamp + 1);
            jug.drip(_ilk);
            assertEq(clip.kicks(), 0);

            // Kick off the liquidation
            dog.bark(_ilk, cropper.getOrCreateProxy(address(this)), address(this));
            assertEq(clip.kicks(), 1);

            // Complete the liquidation
            vat.hope(address(clip));
            (, uint256 tab,,,,) = clip.sales(1);
            hevm.store(
                address(vat),
                keccak256(abi.encode(address(this), uint256(5))),
                bytes32(tab)
            );
            assertEq(vat.dai(address(this)), tab);
            assertEq(vat.gem(_ilk, cropper.getOrCreateProxy(address(this))), 0);
            clip.take(1, type(uint256).max, type(uint256).max, address(this), "");
            assertEq(vat.gem(_ilk, cropper.getOrCreateProxy(address(this))), amount);
        }

        // Dump all dai for next run
        vat.move(address(this), address(0x0), vat.dai(address(this)));
    }

    function getSignatures(bytes32 signHash) internal returns (bytes memory signatures, address[] memory signers) {
        // seeds chosen s.t. corresponding addresses are in ascending order
        uint8[30] memory seeds = [8,10,6,2,9,15,14,20,7,29,24,13,12,25,16,26,21,22,0,18,17,27,3,28,23,19,4,5,1,11];
        uint256 numSigners = seeds.length;
        signers = new address[](numSigners);
        for(uint256 i; i < numSigners; i++) {
            uint256 sk = uint256(keccak256(abi.encode(seeds[i])));
            signers[i] = hevm.addr(sk);
            (uint8 v, bytes32 r, bytes32 s) = hevm.sign(sk, signHash);
            signatures = abi.encodePacked(signatures, r, s, v);
        }
        assertEq(signatures.length, numSigners * 65);
    }

    function oracleAuthRequestMint(
        bytes32 sourceDomain,
        bytes32 targetDomain,
        uint256 toMint,
        uint256 expectedFee
    ) internal {
        TeleportOracleAuthLike oracleAuth = TeleportOracleAuthLike(addr.addr("MCD_ORACLE_AUTH_TELEPORT_FW_A"));
        giveAuth(address(oracleAuth), address(this));
        (bytes memory signatures, address[] memory signers) = getSignatures(oracleAuth.getSignHash(TeleportGUID({
            sourceDomain: sourceDomain,
            targetDomain: targetDomain,
            receiver: bytes32(uint256(uint160(address(this)))),
            operator: bytes32(0),
            amount: uint128(toMint),
            nonce: 1,
            timestamp: uint48(block.timestamp)
        })));
        oracleAuth.addSigners(signers);
        oracleAuth.requestMint(TeleportGUID({
            sourceDomain: sourceDomain,
            targetDomain: targetDomain,
            receiver: bytes32(uint256(uint160(address(this)))),
            operator: bytes32(0),
            amount: uint128(toMint),
            nonce: 1,
            timestamp: uint48(block.timestamp)
        }), signatures, expectedFee, 0);
    }

    // NOTE: Only executable by forge
    function checkTeleportFWIntegration(
        bytes32 sourceDomain,
        bytes32 targetDomain,
        uint256 line,
        address gateway,
        address fee,
        address escrow,
        uint256 toMint,
        uint256 expectedFee,
        uint256 expectedTtl
    ) internal {
        TeleportJoinLike join = TeleportJoinLike(addr.addr("MCD_JOIN_TELEPORT_FW_A"));
        TeleportRouterLike router = TeleportRouterLike(addr.addr("MCD_ROUTER_TELEPORT_FW_A"));

        // Sanity checks
        assertEq(join.line(sourceDomain), line);
        assertEq(join.fees(sourceDomain), address(fee));
        assertEq(dai.allowance(escrow, gateway), type(uint256).max);
        assertEq(dai.allowance(gateway, address(router)), type(uint256).max);
        assertEq(TeleportFeeLike(fee).fee(), expectedFee);
        assertEq(TeleportFeeLike(fee).ttl(), expectedTtl);
        assertEq(router.gateways(sourceDomain), gateway);
        assertEq(router.domains(gateway), sourceDomain);
        assertEq(TeleportBridgeLike(gateway).l1Escrow(), escrow);
        assertEq(TeleportBridgeLike(gateway).l1TeleportRouter(), address(router));
        assertEq(TeleportBridgeLike(gateway).l1Token(), address(dai));

        {
            // NOTE: We are calling the router directly because the bridge code is minimal and unique to each domain
            // This tests the slow path via the router
            hevm.startPrank(gateway);
            router.requestMint(TeleportGUID({
                sourceDomain: sourceDomain,
                targetDomain: targetDomain,
                receiver: bytes32(uint256(uint160(address(this)))),
                operator: bytes32(0),
                amount: uint128(toMint),
                nonce: 0,
                timestamp: uint48(block.timestamp - TeleportFeeLike(fee).ttl())
            }), 0, 0);
            hevm.stopPrank();
            assertEq(dai.balanceOf(address(this)), toMint);
            assertEq(join.debt(sourceDomain), int256(toMint));
        }

        // Check oracle auth mint -- add custom signatures to test
        uint256 _fee = toMint * expectedFee / WAD;
        {
            uint256 prevDai = vat.dai(address(vow));
            oracleAuthRequestMint(sourceDomain, targetDomain, toMint, expectedFee);
            assertEq(dai.balanceOf(address(this)), toMint * 2 - _fee);
            assertEq(join.debt(sourceDomain), int256(toMint * 2));
            assertEq(vat.dai(address(vow)) - prevDai, _fee * RAY);
        }

        // Check settle
        dai.transfer(gateway, toMint * 2 - _fee);
        hevm.startPrank(gateway);
        router.settle(targetDomain, toMint * 2 - _fee);
        hevm.stopPrank();
        assertEq(dai.balanceOf(gateway), 0);
        assertEq(join.debt(sourceDomain), int256(_fee));
    }

    function checkCureLoadTeleport(
        bytes32 sourceDomain,
        bytes32 targetDomain,
        uint256 toMint,
        uint256 expectedFee,
        uint256 expectedTell,
        bool cage
    ) internal {
        TeleportJoinLike join = TeleportJoinLike(addr.addr("MCD_JOIN_TELEPORT_FW_A"));

        // Oracle auth mint -- add custom signatures to test
        oracleAuthRequestMint(sourceDomain, targetDomain, toMint, expectedFee);
        assertEq(join.debt(sourceDomain), int256(toMint));

        // Emulate Global Settlement
        if (cage) {
            assertEq(cure.live(), 1);
            hevm.store(
                address(cure),
                keccak256(abi.encode(address(this), uint256(0))),
                bytes32(uint256(1))
            );
            cure.cage();
            assertEq(cure.tell(), 0);
        }
        assertEq(cure.live(), 0);

        // Check cure tells the teleport source correctly
        cure.load(address(join));
        assertEq(cure.tell(), expectedTell);
    }

    function checkDaiVest(
        uint256 _index,
        address _wallet,
        uint256 _start,
        uint256 _cliff,
        uint256 _end,
        uint256 _days,
        address _manager,
        uint256 _restricted,
        uint256 _reward,
        uint256 _claimed
    ) public {
        assertEq(vestDai.usr(_index), _wallet,            "usr");
        assertEq(vestDai.bgn(_index), _start,             "bgn");
        assertEq(vestDai.clf(_index), _cliff,             "clf");
        assertEq(vestDai.fin(_index), _end,               "fin");
        assertEq(vestDai.fin(_index), _start + _days - 1, "fin");
        assertEq(vestDai.mgr(_index), _manager,           "mgr");
        assertEq(vestDai.res(_index), _restricted,        "res");
        assertEq(vestDai.tot(_index), _reward,            "tot");
        assertEq(vestDai.rxd(_index), _claimed,           "rxd");
    }

    function getIlkMat(bytes32 _ilk) internal view returns (uint256 mat) {
        (, mat) = spotter.ilks(_ilk);
    }

    function getIlkDuty(bytes32 _ilk) internal view returns (uint256 duty) {
        (duty,)  = jug.ilks(_ilk);
    }

    function setIlkMat(bytes32 ilk, uint256 amount) internal {
        hevm.store(
            address(spotter),
            bytes32(uint256(keccak256(abi.encode(ilk, uint256(1)))) + 1),
            bytes32(amount)
        );
        assertEq(getIlkMat(ilk), amount, concat("TestError/setIlkMat-", ilk));
    }

    function setIlkRate(bytes32 ilk, uint256 amount) internal {
        hevm.store(
            address(vat),
            bytes32(uint256(keccak256(abi.encode(ilk, uint256(2)))) + 1),
            bytes32(amount)
        );
        (,uint256 rate,,,) = vat.ilks(ilk);
        assertEq(rate, amount, concat("TestError/setIlkRate-", ilk));
    }

    function setIlkLine(bytes32 ilk, uint256 amount) internal {
        hevm.store(
            address(vat),
            bytes32(uint256(keccak256(abi.encode(ilk, uint256(2)))) + 3),
            bytes32(amount)
        );
        (,,,uint256 line,) = vat.ilks(ilk);
        assertEq(line, amount, concat("TestError/setIlkLine-", ilk));
    }

    function checkIlkLerpOffboarding(bytes32 _ilk, bytes32 _lerp, uint256 _startMat, uint256 _endMat) public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        LerpAbstract lerp = LerpAbstract(lerpFactory.lerps(_lerp));

        hevm.warp(block.timestamp + lerp.duration() / 2);
        assertEq(getIlkMat(_ilk), _startMat * RAY / 100);
        lerp.tick();
        assertEqApprox(getIlkMat(_ilk), ((_startMat + _endMat) / 2) * RAY / 100, RAY / 100);

        hevm.warp(block.timestamp + lerp.duration());
        lerp.tick();
        assertEq(getIlkMat(_ilk), _endMat * RAY / 100);
    }

    function checkIlkLerpIncreaseMatOffboarding(bytes32 _ilk, bytes32 _oldLerp, bytes32 _newLerp, uint256 _newEndMat) public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        LerpFactoryAbstract OLD_LERP_FAB = LerpFactoryAbstract(0x00B416da876fe42dd02813da435Cc030F0d72434);
        LerpAbstract oldLerp = LerpAbstract(OLD_LERP_FAB.lerps(_oldLerp));

        uint256 t = (block.timestamp - oldLerp.startTime()) * WAD / oldLerp.duration();
        uint256 tickMat = oldLerp.end() * t / WAD + oldLerp.start() - oldLerp.start() * t / WAD;
        assertEq(getIlkMat(_ilk), tickMat);
        assertEq(spotter.wards(address(oldLerp)), 0);

        LerpAbstract newLerp = LerpAbstract(lerpFactory.lerps(_newLerp));

        hevm.warp(block.timestamp + newLerp.duration() / 2);
        assertEq(getIlkMat(_ilk), tickMat);
        newLerp.tick();
        assertEqApprox(getIlkMat(_ilk), (tickMat + _newEndMat * RAY / 100) / 2, RAY / 100);

        hevm.warp(block.timestamp + newLerp.duration());
        newLerp.tick();
        assertEq(getIlkMat(_ilk), _newEndMat * RAY / 100);
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

    // Add an exception here if a registered deployer can be a valid auth on target
    function skipWards(address target, address deployer) internal view returns (bool) {
        // Add logic here in case any wards need to be skipped, otherwise return false.
        target; deployer;
        return false;
    }

    function checkWards(address _addr, string memory contractName) internal {
        for (uint256 i = 0; i < deployers.count(); i ++) {
            address deployer = deployers.addr(i);
            (bool ok, bytes memory data) = _addr.call(
                abi.encodeWithSignature("wards(address)", deployer)
            );
            if (!ok || data.length != 32) return;
            uint256 ward = abi.decode(data, (uint256));
            if (ward > 0) {
                if (skipWards(_addr, deployer)) continue;
                emit log("Error: Bad Auth");
                emit log_named_address("   Deployer Address", deployer);
                emit log_named_string("  Affected Contract", contractName);
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

    function checkChainlogKey(bytes32 key) internal {
        assertEq(chainLog.getAddress(key), addr.addr(key), concat("TestError/Chainlog-key-mismatch-", key));
    }

    function checkChainlogVersion(string memory key) internal {
        assertEq(chainLog.version(), key, concat("TestError/Chainlog-version-mismatch-", key));
    }
}
