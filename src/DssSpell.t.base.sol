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

pragma solidity 0.8.16;

import "dss-interfaces/Interfaces.sol";
import {DssTest, GodMode} from "dss-test/DssTest.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";

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

interface DirectDepositLike is GemJoinAbstract {
    function file(bytes32, uint256) external;
    function exec() external;
    function tau() external view returns (uint256);
    function tic() external view returns (uint256);
    function bar() external view returns (uint256);
    function king() external view returns (address);
}

interface AaveDirectDepositLike is DirectDepositLike {
    function adai() external view returns (address);
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
}

interface OptimismTeleportBridgeLike is TeleportBridgeLike {
    function l2TeleportGateway() external view returns (address);
    function messenger() external view returns (address);
}

interface ArbitrumTeleportBridgeLike is TeleportBridgeLike {
    function l2TeleportGateway() external view returns (address);
    function inbox() external view returns (address);
}

interface StarknetTeleportBridgeLike {
    function l2TeleportGateway() external view returns (uint256);
    function starkNet() external view returns (address);
}

interface RwaLiquidationLike {
    function ilks(bytes32) external view returns (string memory, address, uint48, uint48);
}

interface AuthorityLike {
    function authority() external view returns (address);
}

interface SplitterMomLike {
    function authority() external view returns (address);
    function stop() external;
}

// TODO: add full interfaces to dss-interfaces and remove from here
interface FlapUniV2Like {
    function gem() external view returns (address);
    function pair() external view returns (address);
    function pip() external view returns (address);
    function want() external view returns (uint256);
}

// TODO: add full interfaces to dss-interfaces and remove from here
interface SplitLike {
    function burn() external view returns (uint256);
    function farm() external view returns (address);
    function flapper() external view returns (address);
    function hop() external view returns (uint256);
}

interface FlapOracleLike {
    function read() external view returns (bytes32);
}

// TODO: add full interfaces to dss-interfaces and remove from here
interface UsdsJoinLike is DaiJoinAbstract {}

interface SUsdsLike {
    function allowance(address, address) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function asset() external view returns (address);
    function balanceOf(address) external view returns (uint256);
    function chi() external view returns (uint192);
    function convertToAssets(uint256 shares) external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function drip() external returns (uint256 nChi);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    function rho() external view returns (uint64);
    function ssr() external view returns (uint256);
}

interface DaiUsdsLike {
    function daiToUsds(address usr, uint256 wad) external;
    function usdsToDai(address usr, uint256 wad) external;
}

interface MkrSkyLike {
    function mkrToSky(address usr, uint256 mkrAmt) external;
    function skyToMkr(address usr, uint256 skyAmt) external;
}

interface LitePsmLike {
    function bud(address) external view returns (uint256);
    function buf() external view returns (uint256);
    function buyGem(address usr, uint256 gemAmt) external returns (uint256 daiInWad);
    function buyGemNoFee(address usr, uint256 gemAmt) external returns (uint256 daiInWad);
    function chug() external returns (uint256 wad);
    function cut() external view returns (uint256 wad);
    function daiJoin() external view returns (address);
    function file(bytes32 what, uint256 data) external;
    function fill() external returns (uint256 wad);
    function gem() external view returns (address);
    function gemJoin() external view returns (address);
    function gush() external view returns (uint256 wad);
    function ilk() external view returns (bytes32);
    function kiss(address usr) external;
    function pocket() external view returns (address);
    function rush() external view returns (uint256 wad);
    function sellGem(address usr, uint256 gemAmt) external returns (uint256 daiOutWad);
    function sellGemNoFee(address usr, uint256 gemAmt) external returns (uint256 daiOutWad);
    function tin() external view returns (uint256);
    function to18ConversionFactor() external view returns (uint256);
    function tout() external view returns (uint256);
    function trim() external returns (uint256 wad);
    function vow() external view returns (address);
    function wards(address) external view returns (uint256);
}

interface LitePsmMomLike is AuthorityLike {
    function halt(address, uint8) external;
}

contract DssSpellTestBase is Config, DssTest {
    using stdStorage for StdStorage;

    Rates         rates = new Rates();
    Addresses      addr = new Addresses();
    Deployers deployers = new Deployers();
    Wallets     wallets = new Wallets();

    // ADDRESSES
    ChainlogAbstract            chainLog = ChainlogAbstract(   addr.addr("CHANGELOG"));
    DSPauseAbstract                pause = DSPauseAbstract(    addr.addr("MCD_PAUSE"));
    address                   pauseProxy =                     addr.addr("MCD_PAUSE_PROXY");
    DSChiefAbstract                chief = DSChiefAbstract(    addr.addr("MCD_ADM"));
    VatAbstract                      vat = VatAbstract(        addr.addr("MCD_VAT"));
    VowAbstract                      vow = VowAbstract(        addr.addr("MCD_VOW"));
    DogAbstract                      dog = DogAbstract(        addr.addr("MCD_DOG"));
    PotAbstract                      pot = PotAbstract(        addr.addr("MCD_POT"));
    JugAbstract                      jug = JugAbstract(        addr.addr("MCD_JUG"));
    SpotAbstract                 spotter = SpotAbstract(       addr.addr("MCD_SPOT"));
    DaiAbstract                      dai = DaiAbstract(        addr.addr("MCD_DAI"));
    DaiJoinAbstract              daiJoin = DaiJoinAbstract(    addr.addr("MCD_JOIN_DAI"));
    GemAbstract                     usds = GemAbstract(        addr.addr("USDS"));
    SUsdsLike                      susds = SUsdsLike(          addr.addr("SUSDS"));
    UsdsJoinLike                usdsJoin = UsdsJoinLike(       addr.addr("USDS_JOIN"));
    DSTokenAbstract                  gov = DSTokenAbstract(    addr.addr("MCD_GOV"));
    GemAbstract                      sky = GemAbstract(        addr.addr("SKY"));
    EndAbstract                      end = EndAbstract(        addr.addr("MCD_END"));
    ESMAbstract                      esm = ESMAbstract(        addr.addr("MCD_ESM"));
    CureAbstract                    cure = CureAbstract(       addr.addr("MCD_CURE"));
    IlkRegistryAbstract              reg = IlkRegistryAbstract(addr.addr("ILK_REGISTRY"));
    SplitLike                      split = SplitLike(          addr.addr("MCD_SPLIT"));
    FlapUniV2Like                   flap = FlapUniV2Like(      addr.addr("MCD_FLAP"));
    CropperLike                  cropper = CropperLike(        addr.addr("MCD_CROPPER"));

    OsmMomAbstract                osmMom = OsmMomAbstract(     addr.addr("OSM_MOM"));
    ClipperMomAbstract           clipMom = ClipperMomAbstract( addr.addr("CLIPPER_MOM"));
    AuthorityLike                 d3mMom = AuthorityLike(      addr.addr("DIRECT_MOM"));
    AuthorityLike                lineMom = AuthorityLike(      addr.addr("LINE_MOM"));
    AuthorityLike             litePsmMom = AuthorityLike(      addr.addr("LITE_PSM_MOM"));
    SplitterMomLike          splitterMom = SplitterMomLike(    addr.addr("SPLITTER_MOM"));
    DssAutoLineAbstract         autoLine = DssAutoLineAbstract(addr.addr("MCD_IAM_AUTO_LINE"));
    LerpFactoryAbstract      lerpFactory = LerpFactoryAbstract(addr.addr("LERP_FAB"));
    VestAbstract                 vestDai = VestAbstract(       addr.addr("MCD_VEST_DAI"));
    VestAbstract                 vestMkr = VestAbstract(       addr.addr("MCD_VEST_MKR_TREASURY"));
    VestAbstract                 vestSky = VestAbstract(       addr.addr("MCD_VEST_SKY"));
    RwaLiquidationLike liquidationOracle = RwaLiquidationLike( addr.addr("MIP21_LIQUIDATION_ORACLE"));

    DssSpell spell;

    event Debug(uint256 index, uint256 val);
    event Debug(uint256 index, address addr);
    event Debug(uint256 index, bytes32 what);

    function _rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * y + RAY / 2) / RAY;
    }

    // not provided in DSMath
    function _rpow(uint256 x, uint256 n, uint256 b) internal pure returns (uint256 z) {
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

    function _divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x != 0 ? ((x - 1) / y) + 1 : 0;
        }
    }

    // not provided in DSTest
    function _assertEqApprox(uint256 _a, uint256 _b, uint256 _tolerance) internal {
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

    function _cmpStr(string memory a, string memory b) internal pure returns (bool) {
         return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function _concat(string memory a, string memory b) internal pure returns (string memory) {
        return string.concat(a, b);
    }

    function _concat(string memory a, bytes32 b) internal pure returns (string memory) {
        return string.concat(a, _bytes32ToString(b));
    }

    function _bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint256 charCount = 0;
        while(charCount < 32 && _bytes32[charCount] != 0) {
            charCount++;
        }
        bytes memory bytesArray = new bytes(charCount);
        for (uint256 i = 0; i < charCount; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function _stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    /**
     * @dev Add this modifier to a test to skip it.
     *      It will still show in the test report, but with a `[SKIP]` label added to it.
     *      This is meant to be used for tests that need to be enabled/disabled on-demand.
     */
    modifier skipped() {
        vm.skip(true);
        _;
    }

    modifier skippedWhenDeployed() {
        if (spellValues.deployed_spell != address(0)) {
            vm.skip(true);
        }
        _;
    }

    modifier skippedWhenNotDeployed() {
        if (spellValues.deployed_spell == address(0)) {
            vm.skip(true);
        }
        _;
    }

    // 10^-5 (tenth of a basis point) as a RAY
    uint256 TOLERANCE = 10 ** 22;

    function _yearlyYield(uint256 duty) internal pure returns (uint256) {
        return _rpow(duty, (365 * 24 * 60 * 60), RAY);
    }

    function _expectedRate(uint256 percentValue) internal pure returns (uint256) {
        return (10000 + percentValue) * (10 ** 23);
    }

    function _diffCalc(
        uint256 expectedRate_,
        uint256 yearlyYield_
    ) internal pure returns (uint256) {
        return (expectedRate_ > yearlyYield_) ?
            expectedRate_ - yearlyYield_ : yearlyYield_ - expectedRate_;
    }

    function _castPreviousSpell() internal {
        address[] memory prevSpells = spellValues.previous_spells;

        // warp and cast previous spells so values are up-to-date to test against
        for (uint256 i; i < prevSpells.length; i++) {
            DssSpell prevSpell = DssSpell(prevSpells[i]);
            if (prevSpell != DssSpell(address(0)) && !prevSpell.done()) {
                if (prevSpell.eta() == 0) {
                    _vote(address(prevSpell));
                    _scheduleWaitAndCast(address(prevSpell));
                }
                else {
                    // jump to nextCastTime to be a little more forgiving on the spell execution time
                    vm.warp(prevSpell.nextCastTime());
                    prevSpell.cast();
                }
            }
        }
    }

    function setUp() public {
        setValues(address(chief));
        _castPreviousSpell();

        spellValues.deployed_spell_created = spellValues.deployed_spell != address(0)
            ? spellValues.deployed_spell_created
            : block.timestamp;
        spell = spellValues.deployed_spell != address(0)
            ?  DssSpell(spellValues.deployed_spell)
            : new DssSpell();

        if (spellValues.deployed_spell_block != 0 && spell.eta() != 0) {
            // if we have a deployed spell in the config
            // we want to roll our fork to the block where it was deployed
            // this means the test suite will continue to accurately pass/fail
            // even if mainnet has already scheduled/cast the spell
            vm.makePersistent(address(rates));
            vm.makePersistent(address(addr));
            vm.makePersistent(address(deployers));
            vm.makePersistent(address(wallets));
            vm.rollFork(spellValues.deployed_spell_block);

            // Reset `eta` to `0`, otherwise the tests will fail with "This spell has already been scheduled".
            // This is a workaround for the issue described here:
            // @see { https://github.com/foundry-rs/foundry/issues/5739 }
            vm.store(
                address(spell),
                bytes32(0),
                bytes32(0)
            );
        }
    }

    function _vote(address spell_) internal {
        if (chief.hat() != spell_) {
            _giveTokens(address(gov), 999999999999 ether);
            gov.approve(address(chief), type(uint256).max);
            chief.lock(999999999999 ether);

            address[] memory slate = new address[](1);

            assertFalse(DssSpell(spell_).done(), "TestError/spell-done-before-vote");

            slate[0] = spell_;

            chief.vote(slate);
            chief.lift(spell_);
        }
        assertEq(chief.hat(), spell_);
    }

    function _scheduleWaitAndCast(address spell_) internal {
        DssSpell(spell_).schedule();

        vm.warp(DssSpell(spell_).nextCastTime());

        DssSpell(spell_).cast();
    }

    function _checkSystemValues(SystemValues storage values) internal {
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
            _diffCalc(_expectedRate(values.pot_dsr), _yearlyYield(expectedDSRRate)) <= TOLERANCE,
            "TestError/pot-dsr-rates-table"
        );

        // ssr
        uint256 expectedSSRRate = rates.rates(values.susds_ssr);
        // make sure dsr is less than 100% APR
        // bc -l <<< 'scale=27; e( l(2.00)/(60 * 60 * 24 * 365) )'
        // 1000000021979553151239153027
        assertEq(susds.ssr(), expectedSSRRate, "TestError/susds-ssr-expected-value");
        assertTrue(
            susds.ssr() >= RAY && susds.ssr() < 1000000021979553151239153027,
            "TestError/susds-ssr-range"
        );
        assertTrue(
            _diffCalc(_expectedRate(values.susds_ssr), _yearlyYield(expectedSSRRate)) <= TOLERANCE,
            "TestError/susds-ssr-rates-table"
        );
        // SSR should always be higher than or equal to DSR
        assertGe(expectedSSRRate, expectedDSRRate, "TestError/ssr-lower-than-dsr");

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
            (vow.bump() >= RAD && vow.bump() < 100 * THOUSAND * RAD) ||
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
            (vow.hump() >= RAD && vow.hump() < 1 * BILLION * RAD) ||
            vow.hump() == 0,
            "TestError/vow-hump-range"
        );
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
            assertTrue(esm.min() > WAD && esm.min() < 400 * THOUSAND * WAD, "TestError/esm-min-range");
        }

        // check Pause authority
        assertEq(pause.authority(), values.pause_authority, "TestError/pause-authority");

        // check OsmMom authority
        assertEq(osmMom.authority(), values.osm_mom_authority, "TestError/osmMom-authority");

        // check ClipperMom authority
        assertEq(clipMom.authority(), values.clipper_mom_authority, "TestError/clipperMom-authority");

        // check D3MMom authority
        assertEq(d3mMom.authority(), values.d3m_mom_authority, "TestError/d3mMom-authority");

        // check LineMom authority
        assertEq(lineMom.authority(), values.line_mom_authority, "TestError/lineMom-authority");

        // check LitePsmMom authority
        assertEq(litePsmMom.authority(), values.lite_psm_mom_authority, "TestError/linePsmMom-authority");

        // check SplitterMom authority
        assertEq(splitterMom.authority(), values.splitter_mom_authority, "TestError/splitterMom-authority");

        // check number of ilks
        assertEq(reg.count(), values.ilk_count, "TestError/ilks-count");

        // split
        {
            // check split hop and sanity checks
            assertEq(split.hop(), values.split_hop, "TestError/split-hop");
            assertTrue(split.hop() > 0 && split.hop() < 86400, "TestError/split-hop-range"); // gt 0 && lt 1 day
            // check burn value
            uint256 normalizedTestBurn = values.split_burn * 10**14;
            assertEq(split.burn(), normalizedTestBurn, "TestError/split-burn");
            assertTrue(split.burn() >= 50 * WAD / 100 && split.burn() <= 1 * WAD, "TestError/split-burn-range"); // gte 50% and lte 100%
        }

        // flap
        {
            // check want value
            uint256 normalizedTestWant = values.flap_want * 10**14;
            assertEq(flap.want(), normalizedTestWant, "TestError/flap-want");
            assertTrue(flap.want() >= 90 * WAD / 100 && flap.want() <= 110 * WAD / 100, "TestError/flap-want-range"); // gte 90% and lte 110%
        }

        // vest
        {
            assertEq(vestDai.cap(), values.vest_dai_cap, "TestError/vest-dai-cap");
            assertEq(vestMkr.cap(), values.vest_mkr_cap, "TestError/vest-mkr-cap");
            assertEq(vestSky.cap(), values.vest_sky_cap, "TestError/vest-sky-cap");
        }

        assertEq(vat.wards(pauseProxy), uint256(1), "TestError/pause-proxy-deauthed-on-vat");

        // transferrable vest
        // check mkr allowance
        _checkTransferrableVestMkrAllowance();
    }

    function _checkCollateralValues(SystemValues storage values) internal {
        // Using an array to work around stack depth limitations.
        // sums[0] : sum of all lines
        // sums[1] : sum over ilks of (line - Art * rate)--i.e. debt that could be drawn at any time
        uint256[] memory sums = new uint256[](2);
        bytes32[] memory ilks = reg.list();
        for(uint256 i = 0; i < ilks.length; i++) {
            bytes32 ilk = ilks[i];
            (uint256 duty,)  = jug.ilks(ilk);

            assertEq(duty, rates.rates(values.collaterals[ilk].pct), _concat("TestError/jug-duty-", ilk));
            // make sure duty is less than 1000% APR
            // bc -l <<< 'scale=27; e( l(10.00)/(60 * 60 * 24 * 365) )'
            // 1000000073014496989316680335
            assertTrue(duty >= RAY && duty < 1000000073014496989316680335, _concat("TestError/jug-duty-range-", ilk));  // gt 0 and lt 1000%
            assertTrue(
                _diffCalc(_expectedRate(values.collaterals[ilk].pct), _yearlyYield(rates.rates(values.collaterals[ilk].pct))) <= TOLERANCE,
                _concat("TestError/rates-", ilk)
            );
            assertTrue(values.collaterals[ilk].pct < THOUSAND * THOUSAND, _concat("TestError/pct-max-", ilk));   // check value lt 1000%
            {
            uint256 line;
            uint256 dust;
            {
            uint256 Art;
            uint256 rate;
            (Art, rate,, line, dust) = vat.ilks(ilk);
            if (Art * rate < line) {
                sums[1] += line - Art * rate;
            }
            }
            // Convert whole Dai units to expected RAD
            uint256 normalizedTestLine = values.collaterals[ilk].line * RAD;
            sums[0] += line;
            (uint256 aL_line, uint256 aL_gap, uint256 aL_ttl,,) = autoLine.ilks(ilk);
            if (!values.collaterals[ilk].aL_enabled) {
                assertTrue(aL_line == 0, _concat("TestError/al-Line-not-zero-", ilk));
                assertEq(line, normalizedTestLine, _concat("TestError/vat-line-", ilk));
                assertTrue((line >= RAD && line < 10 * BILLION * RAD) || line == 0, _concat("TestError/vat-line-range-", ilk));  // eq 0 or gt eq 1 RAD and lt 10B
            } else {
                assertTrue(aL_line > 0, _concat("TestError/al-Line-is-zero-", ilk));
                assertEq(aL_line, values.collaterals[ilk].aL_line * RAD, _concat("TestError/al-line-", ilk));
                assertEq(aL_gap, values.collaterals[ilk].aL_gap * RAD, _concat("TestError/al-gap-", ilk));
                assertEq(aL_ttl, values.collaterals[ilk].aL_ttl, _concat("TestError/al-ttl-", ilk));
                assertTrue((aL_line >= RAD && aL_line < 20 * BILLION * RAD) || aL_line == 0, _concat("TestError/al-line-range-", ilk)); // eq 0 or gt eq 1 RAD and lt 10B
            }
            uint256 normalizedTestDust = values.collaterals[ilk].dust * RAD;
            assertEq(dust, normalizedTestDust, _concat("TestError/vat-dust-", ilk));
            assertTrue((dust >= RAD && dust <= 100 * THOUSAND * RAD) || dust == 0, _concat("TestError/vat-dust-range-", ilk)); // eq 0 or gt eq 1 and lte 100k
            }

            {
            (address pip, uint256 mat) = spotter.ilks(ilk);
            if (pip != address(0)) {
                // Convert BP to system expected value
                uint256 normalizedTestMat = (values.collaterals[ilk].mat * 10**23);
                if (values.collaterals[ilk].offboarding) {
                    assertTrue(mat <= normalizedTestMat, _concat("TestError/vat-lerping-mat-", ilk));
                    assertTrue(mat >= RAY && mat <= 300 * RAY, _concat("TestError/vat-mat-range-", ilk));  // cr gt 100% and lt 30000%
                } else {
                    assertEq(mat, normalizedTestMat, _concat("TestError/vat-mat-", ilk));
                    assertTrue(mat >= RAY && mat < 10 * RAY, _concat("TestError/vat-mat-range-", ilk));    // cr gt 100% and lt 1000%
                }
            }
            }

            if (values.collaterals[ilk].liqType == "flip") {
                // NOTE: MCD_CAT has been scuttled in the spell on 2023-09-13
                revert("TestError/flip-deprecated");
            }
            if (values.collaterals[ilk].liqType == "clip") {
                {
                assertEq(reg.class(ilk), 1, _concat("TestError/reg-class-", ilk));
                (bool ok, bytes memory val) = reg.xlip(ilk).call(abi.encodeWithSignature("dog()"));
                assertTrue(ok, _concat("TestError/reg-xlip-dog-", ilk));
                assertEq(abi.decode(val, (address)), address(dog), _concat("TestError/reg-xlip-dog-", ilk));
                }
                {
                (, uint256 chop, uint256 hole,) = dog.ilks(ilk);
                // Convert BP to system expected value
                uint256 normalizedTestChop = (values.collaterals[ilk].chop * 10**14) + WAD;
                assertEq(chop, normalizedTestChop, _concat("TestError/dog-chop-", ilk));
                // make sure chop is less than 100%
                assertTrue(chop >= WAD && chop < 2 * WAD, _concat("TestError/dog-chop-range-", ilk));   // penalty gt eq 0% and lt 100%

                // Convert whole Dai units to expected RAD
                uint256 normalizedTesthole = values.collaterals[ilk].dog_hole * RAD;
                assertEq(hole, normalizedTesthole, _concat("TestError/dog-hole-", ilk));
                assertTrue(hole == 0 || hole >= RAD && hole <= 100 * MILLION * RAD, _concat("TestError/dog-hole-range-", ilk));
                }
                (address clipper,,,) = dog.ilks(ilk);
                assertTrue(clipper != address(0), _concat("TestError/invalid-clip-address-", ilk));
                ClipAbstract clip = ClipAbstract(clipper);
                {
                // Convert BP to system expected value
                uint256 normalizedTestBuf = values.collaterals[ilk].clip_buf * 10**23;
                assertEq(uint256(clip.buf()), normalizedTestBuf, _concat("TestError/clip-buf-", ilk));
                assertTrue(clip.buf() >= RAY && clip.buf() <= 2 * RAY, _concat("TestError/clip-buf-range-", ilk)); // gte 0% and lte 100%
                assertEq(uint256(clip.tail()), values.collaterals[ilk].clip_tail, _concat("TestError/clip-tail-", ilk));
                if (ilk == "TUSD-A") { // long tail liquidation
                    assertTrue(clip.tail() >= 1200 && clip.tail() <= 30 days, _concat("TestError/TUSD-clip-tail-range-", ilk)); // gt eq 20 minutes and lt eq 30 days
                } else {
                    assertTrue(clip.tail() >= 1200 && clip.tail() <= 12 hours, _concat("TestError/clip-tail-range-", ilk)); // gt eq 20 minutes and lt eq 12 hours
                }
                uint256 normalizedTestCusp = (values.collaterals[ilk].clip_cusp)  * 10**23;
                assertEq(uint256(clip.cusp()), normalizedTestCusp, _concat("TestError/clip-cusp-", ilk));
                assertTrue(clip.cusp() >= RAY / 10 && clip.cusp() < RAY, _concat("TestError/clip-cusp-range-", ilk)); // gte 10% and lt 100%
                assertTrue(_rmul(clip.buf(), clip.cusp()) <= RAY, _concat("TestError/clip-buf-cusp-limit-", ilk));
                uint256 normalizedTestChip = (values.collaterals[ilk].clip_chip)  * 10**14;
                assertEq(uint256(clip.chip()), normalizedTestChip, _concat("TestError/clip-chip-", ilk));
                assertTrue(clip.chip() < 1 * WAD / 100, _concat("TestError/clip-chip-range-", ilk)); // lt 1%
                uint256 normalizedTestTip = values.collaterals[ilk].clip_tip * RAD;
                assertEq(uint256(clip.tip()), normalizedTestTip, _concat("TestError/clip-tip-", ilk));
                assertTrue(clip.tip() == 0 || clip.tip() >= RAD && clip.tip() <= 500 * RAD, _concat("TestError/clip-tip-range-", ilk));

                assertEq(clip.wards(address(clipMom)), values.collaterals[ilk].clipper_mom, _concat("TestError/clip-clipperMom-auth-", ilk));

                assertEq(clipMom.tolerance(address(clip)), values.collaterals[ilk].cm_tolerance * RAY / 10000, _concat("TestError/clipperMom-tolerance-", ilk));

                if (values.collaterals[ilk].liqOn) {
                    assertEq(clip.stopped(), 0, _concat("TestError/clip-liqOn-", ilk));
                } else {
                    assertTrue(clip.stopped() > 0, _concat("TestError/clip-liqOn-", ilk));
                }

                assertEq(clip.wards(address(end)), 1, _concat("TestError/clip-end-auth-", ilk));
                assertEq(clip.wards(address(pauseProxy)), 1, _concat("TestError/clip-pause-proxy-auth-", ilk)); // Check pause_proxy ward
                }
                {
                    (bool exists, bytes memory value) = clip.calc().call(abi.encodeWithSignature("tau()"));
                    assertEq(exists ? abi.decode(value, (uint256)) : 0, values.collaterals[ilk].calc_tau, _concat("TestError/calc-tau-", ilk));
                    (exists, value) = clip.calc().call(abi.encodeWithSignature("step()"));
                    assertEq(exists ? abi.decode(value, (uint256)) : 0, values.collaterals[ilk].calc_step, _concat("TestError/calc-step-", ilk));
                    if (exists) {
                        assertTrue(abi.decode(value, (uint256)) > 0, _concat("TestError/calc-step-is-zero-", ilk));
                    }
                    (exists, value) = clip.calc().call(abi.encodeWithSignature("cut()"));
                    uint256 normalizedTestCut = values.collaterals[ilk].calc_cut * 10**23;
                    assertEq(exists ? abi.decode(value, (uint256)) : 0, normalizedTestCut, _concat("TestError/calc-cut-", ilk));
                    if (exists) {
                        assertTrue(abi.decode(value, (uint256)) > 0 && abi.decode(value, (uint256)) < RAY, _concat("TestError/calc-cut-range-", ilk));
                    }
                }
                {
                    uint256 normalizedTestChop = (values.collaterals[ilk].chop * 10**14) + WAD;
                    uint256 _chost = (values.collaterals[ilk].dust * RAD) * normalizedTestChop / WAD;
                    assertEq(clip.chost(), _chost, _concat("TestError/calc-chost-incorrect-", ilk)); // Ensure clip.upchost() is called when dust changes
                }
            }
            if (reg.class(ilk) < 3) {
                {
                GemJoinAbstract join = GemJoinAbstract(reg.join(ilk));
                assertEq(join.wards(address(pauseProxy)), 1, _concat("TestError/join-pause-proxy-auth-", ilk)); // Check pause_proxy ward
                }
            }
        }
        // Require that debt + (debt that could be drawn) does not exceed Line.
        // TODO: consider a buffer for fee accrual
        assertTrue(vat.debt() + sums[1] <= vat.Line(), "TestError/vat-Line-1");

        // Enforce the global Line also falls between (sum of lines) + offset and (sum of lines) + 2*offset.
        assertTrue(sums[0] +     values.line_offset * RAD <= vat.Line(), "TestError/vat-Line-2");
        assertTrue(sums[0] + 2 * values.line_offset * RAD >= vat.Line(), "TestError/vat-Line-3");

        // TODO: have a discussion about how we want to manage the global Line going forward.
    }

    function _getOSMPrice(address pip) internal returns (uint256) {
        // vm.load is to pull the price from the LP Oracle storage bypassing the whitelist
        uint256 price = uint256(vm.load(
            pip,
            bytes32(uint256(3))
        )) & type(uint128).max;   // Price is in the second half of the 32-byte storage slot

        // Price is bounded in the spot by around 10^23
        // Give a 10^9 buffer for price appreciation over time
        // Note: This currently can't be hit due to the uint112, but we want to backstop
        //       once the PIP uint256 size is increased
        assertTrue(price <= (10 ** 14) * WAD);

        return price;
    }

    function _getUNIV2LPPrice(address pip) internal returns (uint256) {
        // vm.load is to pull the price from the LP Oracle storage bypassing the whitelist
        uint256 price = uint256(vm.load(
            pip,
            bytes32(uint256(3))
        )) & type(uint128).max;   // Price is in the second half of the 32-byte storage slot

        // Price is bounded in the spot by around 10^23
        // Give a 10^9 buffer for price appreciation over time
        // Note: This currently can't be hit due to the uint112, but we want to backstop
        //       once the PIP uint256 size is increased
        assertTrue(price <= (10 ** 14) * WAD);

        return price;
    }

    function _giveTokens(address token, uint256 amount) internal {
        if (token == addr.addr("GUSD")) {
            _giveTokensGUSD(token, amount);
            return;
        }

        GodMode.setBalance(token, address(this), amount);
    }

    function _giveTokensGUSD(address _token, uint256 amount) internal {
        DSTokenAbstract token = DSTokenAbstract(_token);

        if (token.balanceOf(address(this)) == amount) return;

        // Special exception GUSD has its storage in a separate contract
        address STORE = 0xc42B14e49744538e3C239f8ae48A1Eaaf35e68a0;

        // Edge case - balance is already set for some reason
        if (token.balanceOf(address(this)) == amount) return;

        for (uint256 i = 0; i < 200; i++) {
            // Scan the storage for the balance storage slot
            bytes32 prevValue = vm.load(
                STORE,
                keccak256(abi.encode(address(this), uint256(i)))
            );
            vm.store(
                STORE,
                keccak256(abi.encode(address(this), uint256(i))),
                bytes32(amount)
            );
            if (token.balanceOf(address(this)) == amount) {
                // Found it
                return;
            } else {
                // Keep going after restoring the original value
                vm.store(
                    STORE,
                    keccak256(abi.encode(address(this), uint256(i))),
                    prevValue
                );
            }
        }

        // We have failed if we reach here
        assertTrue(false, "TestError/GiveTokens-slot-not-found");
    }

    function _checkIlkIntegration(
        bytes32 _ilk,
        GemJoinAbstract join,
        ClipAbstract clip,
        address pip,
        bool _isOSM,
        bool _checkLiquidations,
        bool _transferFee
    ) internal {
        GemAbstract token = GemAbstract(join.gem());

        if (_isOSM) OsmAbstract(pip).poke();
        vm.warp(block.timestamp + 3601);
        if (_isOSM) OsmAbstract(pip).poke();
        spotter.poke(_ilk);

        // Authorization
        assertEq(join.wards(pauseProxy), 1, _concat("TestError/checkIlkIntegration-pauseProxy-not-auth-on-join-", _ilk));
        assertEq(vat.wards(address(join)), 1, _concat("TestError/checkIlkIntegration-join-not-auth-on-vat-", _ilk));
        assertEq(vat.wards(address(clip)), 1, _concat("TestError/checkIlkIntegration-clip-not-auth-on-vat-", _ilk));
        assertEq(dog.wards(address(clip)), 1, _concat("TestError/checkIlkIntegration-clip-not-auth-on-dog-", _ilk));
        assertEq(clip.wards(address(dog)), 1, _concat("TestError/checkIlkIntegration-dog-not-auth-on-clip-", _ilk));
        assertEq(clip.wards(address(end)), 1, _concat("TestError/checkIlkIntegration-end-not-auth-on-clip-", _ilk));
        assertEq(clip.wards(address(clipMom)), 1, _concat("TestError/checkIlkIntegration-clipMom-not-auth-on-clip-", _ilk));
        assertEq(clip.wards(address(esm)), 1, _concat("TestError/checkIlkIntegration-esm-not-auth-on-clip-", _ilk));
        if (_isOSM) {
            assertEq(OsmAbstract(pip).wards(address(osmMom)), 1, _concat("TestError/checkIlkIntegration-osmMom-not-auth-on-pip-", _ilk));
            assertEq(OsmAbstract(pip).bud(address(spotter)), 1, _concat("TestError/checkIlkIntegration-spot-not-bud-on-pip-", _ilk));
            assertEq(OsmAbstract(pip).bud(address(clip)), 1, _concat("TestError/checkIlkIntegration-spot-not-bud-on-pip-", _ilk));
            assertEq(OsmAbstract(pip).bud(address(clipMom)), 1, _concat("TestError/checkIlkIntegration-spot-not-bud-on-pip-", _ilk));
            assertEq(OsmAbstract(pip).bud(address(end)), 1, _concat("TestError/checkIlkIntegration-spot-not-bud-on-pip-", _ilk));
            assertEq(MedianAbstract(OsmAbstract(pip).src()).bud(pip), 1, _concat("TestError/checkIlkIntegration-pip-not-bud-on-osm-", _ilk));
            assertEq(OsmMomAbstract(osmMom).osms(_ilk), pip, _concat("TestError/checkIlkIntegration-pip-not-bud-on-osmMom-", _ilk));
        }

        (,,,, uint256 dust) = vat.ilks(_ilk);
        dust /= RAY;
        uint256 amount = 4 * dust * 10 ** uint256(token.decimals()) / (_isOSM ? _getOSMPrice(pip) : uint256(DSValueAbstract(pip).read()));
        uint256 amount18 = token.decimals() == 18 ? amount : amount * 10**(18 - uint256(token.decimals()));
        _giveTokens(address(token), amount);

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
        vm.warp(block.timestamp + 1);
        jug.drip(_ilk);

        // Deposit collateral, generate DAI
        (,uint256 rate,,uint256 line,) = vat.ilks(_ilk);

        assertEq(vat.dai(address(this)), 0);
        // Set max line to ensure we can create a new position
        _setIlkLine(_ilk, type(uint256).max);
        vat.frob(_ilk, address(this), address(this), address(this), int256(amount18), int256(_divup(RAY * dust, rate)));
        // Revert ilk line to proceed with testing
        _setIlkLine(_ilk, line);
        assertEq(vat.gem(_ilk, address(this)), 0);
        assertTrue(vat.dai(address(this)) >= dust * RAY);
        assertTrue(vat.dai(address(this)) <= (dust + 1) * RAY);

        // Payback DAI, withdraw collateral
        vat.frob(_ilk, address(this), address(this), address(this), -int256(amount18), -int256(_divup(RAY * dust, rate)));
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
        _setIlkLine(_ilk, type(uint256).max);
        vat.frob(_ilk, address(this), address(this), address(this), int256(amount18), int256(amount18 * spot / rate));
        // Revert ilk line to proceed with testing
        _setIlkLine(_ilk, line);

        vm.warp(block.timestamp + 1);
        jug.drip(_ilk);
        assertEq(clip.kicks(), 0);
        if (_checkLiquidations) {
            if (_getIlkDuty(_ilk) == rates.rates(0)) {
                // Rates wont accrue if 0, raise the mat to make the vault unsafe
                _setIlkMat(_ilk, 100000 * RAY);
                vm.warp(block.timestamp + 10 days);
                spotter.poke(_ilk);
            }
            dog.bark(_ilk, address(this), address(this));
            assertEq(clip.kicks(), 1);
        }

        // Dump all dai for next run
        vat.move(address(this), address(0x0), vat.dai(address(this)));
    }

    function _checkIlkClipper(
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
        vm.store(
            address(dog),
            bytes32(uint256(4)),
            bytes32(type(uint256).max)
        );

        // Initially this test assume that's we are using freshly deployed Cliiper contract without any past auctions
        if (clipper.kicks() > 0) {
            // Cleanup clipper auction counter
            vm.store(
                address(clipper),
                bytes32(uint256(10)),
                bytes32(uint256(0))
            );

            assertEq(clipper.kicks(), 0);
        }

        // ----------------------- Check Clipper works and bids can be made -----------------------

        {
        GemAbstract token = GemAbstract(join.gem());
        uint256 tknAmt =  ilkAmt / 10 ** (18 - join.dec());
        _giveTokens(address(token), tknAmt);
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
        art = int256(ilkAmt * spot / rate);

        // dart max amount of DAI
        _setIlkLine(ilk, type(uint256).max);
        vat.frob(ilk, address(this), address(this), address(this), int256(ilkAmt), art);
        _setIlkLine(ilk, line);
        _setIlkMat(ilk, 100000 * RAY);
        vm.warp(block.timestamp + 10 days);
        spotter.poke(ilk);
        assertEq(clipper.kicks(), 0);
        dog.bark(ilk, address(this), address(this));
        assertEq(clipper.kicks(), 1);

        (, rate,,,) = vat.ilks(ilk);
        uint256 debt = rate * uint256(art) * dog.chop(ilk) / WAD;
        vm.store(
            address(vat),
            keccak256(abi.encode(address(this), uint256(5))),
            bytes32(debt)
        );
        assertEq(vat.dai(address(this)), debt);
        assertEq(vat.gem(ilk, address(this)), 0);

        vm.warp(block.timestamp + 20 minutes);
        (, uint256 tab, uint256 lot, address usr,, uint256 top) = clipper.sales(1);

        assertEq(usr, address(this));
        assertEq(tab, debt);
        assertEq(lot, ilkAmt);
        assertTrue(lot * top > tab); // There is enough collateral to cover the debt at current price

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

    function _checkUNILPIntegration(
        bytes32 _ilk,
        GemJoinAbstract join,
        ClipAbstract clip,
        LPOsmAbstract pip,
        address _medianizer1,
        address _medianizer2,
        bool _isMedian1,
        bool _isMedian2,
        bool _checkLiquidations
    ) internal {
        GemAbstract token = GemAbstract(join.gem());

        pip.poke();
        vm.warp(block.timestamp + 3601);
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
        uint256 amount = 2 * dust * WAD / _getUNIV2LPPrice(address(pip));
        _giveTokens(address(token), amount);

        assertEq(token.balanceOf(address(this)), amount);
        assertEq(vat.gem(_ilk, address(this)), 0);
        token.approve(address(join), amount);
        join.join(address(this), amount);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(vat.gem(_ilk, address(this)), amount);

        // Tick the fees forward so that art != dai in wad units
        vm.warp(block.timestamp + 1);
        jug.drip(_ilk);

        // Deposit collateral, generate DAI
        (,uint256 rate,,,) = vat.ilks(_ilk);
        assertEq(vat.dai(address(this)), 0);
        vat.frob(_ilk, address(this), address(this), address(this), int256(amount), int256(_divup(RAY * dust, rate)));
        assertEq(vat.gem(_ilk, address(this)), 0);
        assertTrue(vat.dai(address(this)) >= dust * RAY && vat.dai(address(this)) <= (dust + 1) * RAY);

        // Payback DAI, withdraw collateral
        vat.frob(_ilk, address(this), address(this), address(this), -int256(amount), -int256(_divup(RAY * dust, rate)));
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
        vat.frob(_ilk, address(this), address(this), address(this), int256(amount), int256(amount * spot / rate));
        vm.warp(block.timestamp + 1);
        jug.drip(_ilk);
        assertEq(clip.kicks(), 0);
        if (_checkLiquidations) {
            dog.bark(_ilk, address(this), address(this));
            assertEq(clip.kicks(), 1);
        }

        // Dump all dai for next run
        vat.move(address(this), address(0x0), vat.dai(address(this)));
    }

    function _checkPsmIlkIntegration(
        bytes32 _ilk,
        GemJoinAbstract join,
        ClipAbstract clip,
        address pip,
        PsmAbstract psm,
        uint256 tinBps,
        uint256 toutBps
    ) internal {
        uint256 tin  = tinBps  * WAD / 100_00;
        uint256 tout = toutBps * WAD / 100_00;
        GemAbstract token = GemAbstract(join.gem());

        // Check PIP is set (ilk exists)
        assertTrue(pip != address(0));

        // Update price (poke spotter)
        spotter.poke(_ilk);

        // Authorization (check wards)
        assertEq(join.wards(pauseProxy),    1);
        assertEq(join.wards(address(psm)),  1);
        assertEq(psm.wards(pauseProxy),     1);
        assertEq(vat.wards(address(join)),  1);
        assertEq(clip.wards(address(end)),  1);

        // Check tin / tout values of PSM
        assertEq(psm.tin(),  tin,  _concat("Incorrect-tin-",  _ilk));
        assertEq(psm.tout(), tout, _concat("Incorrect-tout-", _ilk));

        // Arbitrary amount of TOKEN to test PSM sellGem and buyGem with (in whole units)
        // `amount` is the amount of _TOKEN_ we are selling/buying (NOT measured in Dai)
        uint256 amount = 100_000;
        // Amount should be more than 10,000 as `tin` and `tout` are basis point measurements
        require(amount >= 10_000, "checkPsmIlkIntegration/amount-too-low-for-precision-checks");

        // Increase line where necessary to allow for coverage for both `buyGem` and `sellGem`
        {
            // Get the Art (current debt) and line (debt ceiling) for this PSM
            (uint256 Art ,,, uint256 line,) = vat.ilks(_ilk);
            // Normalize values to whole units so we can compare them
            Art  = Art  / WAD; // `rate` is 1 * RAY for all PSMs
            line = line / RAD;

            // If not enough room below line (e.g. Maxed out PSM)
            if(Art + amount > line){
                _setIlkLine(_ilk, (Art + amount + 1) * RAD); // Increase `line` to `Art`+`amount`
            }
        }

        // Scale up `amount` to the correct Gem decimals value (buyGem and sellGem both use Gem decimals for precision)
        amount = amount * WAD / _to18ConversionFactor(psm);
        _giveTokens(address(token), amount);

        // Approvals
        token.approve(address(join), amount);
        dai.approve(address(psm), type(uint256).max);

        // Sell TOKEN _to_ the PSM for DAI (increases debt)
        psm.sellGem(address(this), amount);

        amount  =   amount * (10 ** (18 - uint256(token.decimals())));  // Scale to Dai decimals (18) for Dai balance check
        amount -=   amount * tin / WAD;                                 // Subtract `tin` fee (was deducted by PSM)

        assertEq(token.balanceOf(address(this)),    0,  _concat("PSM.sellGem-token-balance-",   _ilk));
        assertEq(dai.balanceOf(address(this)),  amount, _concat("PSM.sellGem-dai-balance-",     _ilk));

        // For `sellGem` we had `amount` TOKENS, so there is no issue calling it
        // For `buyGem` we have `amount` Dai, but `buyGem` takes `gemAmt` as TOKENS
        // So we need to calculate the `gemAmt` of TOKEN we want to buy (i.e. subtract `tout` in advance)
        amount -=   _divup(amount * tout, WAD);                         // Subtract `tout` fee (i.e. convert to `gemAmt`)
        amount  =   amount / (10 ** (18 - uint256(token.decimals())));  // Scale to Gem decimals for `buyGem()`

        // Buy TOKEN _from_ the PSM for DAI (decreases debt)
        psm.buyGem(address(this), amount);

        // There may be some Dai dust left over depending on tout and decimals
        // This should always be less than some dust limit
        assertTrue(dai.balanceOf(address(this)) < 1 * WAD); // TODO lower this
        assertEq(token.balanceOf(address(this)), amount, _concat("PSM.buyGem-token-balance-", _ilk));

        // Dump all dai for next run
        dai.transfer(address(0x0), dai.balanceOf(address(this)));
    }

    struct LitePsmIlkIntegrationParams {
        bytes32 ilk;
        address pip;
        address litePsm;
        address pocket;
        uint256 bufUnits; // `buf` as whole units
        uint256 tinBps;   // tin as bps
        uint256 toutBps;  // tout as bps
    }

    function _checkLitePsmIlkIntegration(LitePsmIlkIntegrationParams memory p) internal {
        uint256 tin         = p.tinBps  * WAD / 100_00;
        uint256 tout        = p.toutBps * WAD / 100_00;
        LitePsmLike litePsm = LitePsmLike(p.litePsm);
        GemAbstract token   = GemAbstract(litePsm.gem());

        // Authorization (check wards)
        assertEq(litePsm.wards(address(pauseProxy)), 1, _concat("checkLitePsmIlkIntegration/pauseProxy-not-ward-", p.ilk));
        // pauseProxy can execute swaps with no fees
        assertEq(litePsm.bud(address(pauseProxy)),   1, _concat("checkLitePsmIlkIntegration/pauseProxy-not-bud-",  p.ilk));

        // litePsm params are properly set
        assertEq(litePsm.vow(),     address(vow),     _concat("checkLitePsmIlkIntegration/incorrect-vow-",     p.ilk));
        assertEq(litePsm.daiJoin(), address(daiJoin), _concat("checkLitePsmIlkIntegration/incorrect-daiJoin-", p.ilk));
        assertEq(litePsm.pocket(),  p.pocket,         _concat("checkLitePsmIlkIntegration/incorrect-pocket-",  p.ilk));
        assertEq(litePsm.buf(),     p.bufUnits * WAD, _concat("checkLitePsmIlkIntegration/incorrect-buf-",     p.ilk));
        assertEq(litePsm.tin(),     tin,              _concat("checkLitePsmIlkIntegration/incorrect-tin-",     p.ilk));
        assertEq(litePsm.tout(),    tout,             _concat("checkLitePsmIlkIntegration/incorrect-tout-",    p.ilk));

        // Vat is properly initialized
        {
            // litePsm is given "unlimited" ink
            (uint256 ink, ) = vat.urns(p.ilk, address(litePsm));
            assertEq(ink, type(uint256).max / RAY, _concat("checkLitePsmIlkIntegration/incorrect-vat-ink-", p.ilk));
        }

        // Spotter is properly initialized
        {
            (address pip,) = spotter.ilks(p.ilk);
            assertEq(pip, p.pip, _concat("checkLitePsmIlkIntegration/incorrect-spot-pip-", p.ilk));
        }

        // Update price (poke spotter)
        spotter.poke(p.ilk);

        // New PSM info is added to IlkRegistry
        {
            (
                string memory name,
                string memory symbol,
                uint256 _class,
                uint256 decimals,
                address gem,
                address pip,
                address gemJoin,
                address clip
            ) = reg.info(p.ilk);

            assertEq(name,     token.name(),     "checkLitePsmIlkIntegration/incorrect-reg-name");
            assertEq(symbol,   token.symbol(),   "checkLitePsmIlkIntegration/incorrect-reg-symbol");
            assertEq(_class,   6,                "checkLitePsmIlkIntegration/incorrect-reg-class"); // REG_CLASS_JOINLESS
            assertEq(decimals, token.decimals(), "checkLitePsmIlkIntegration/incorrect-reg-dec");
            assertEq(gem,      address(token),   "checkLitePsmIlkIntegration/incorrect-reg-gem");
            assertEq(pip,      p.pip,            "checkLitePsmIlkIntegration/incorrect-reg-pip");
            assertEq(gemJoin,  address(0),       "checkLitePsmIlkIntegration/incorrect-reg-gemJoin");
            assertEq(clip,     address(0),       "checkLitePsmIlkIntegration/incorrect-reg-xlip");
        }

        // ------ Test swap flows ------

        // Arbitrary amount of TOKEN to test PSM sellGem and buyGem with (in whole units)
        // `amount` is the amount of _TOKEN_ we are selling/buying (NOT measured in Dai)
        uint256 amount = 100_000;
        // Amount should be more than 10,000 as `tin` and `tout` are basis point measurements
        require(amount >= 10_000, "checkLitePsmIlkIntegration/amount-too-low-for-precision-checks");

        // Increase line where necessary to allow for coverage for both `buyGem` and `sellGem`
        {
            // Get the Art (current debt) and line (debt ceiling) for this PSM
            (uint256 Art ,,, uint256 line,) = vat.ilks(p.ilk);
            // Normalize values to whole units so we can compare them
            Art  = Art  / WAD; // `rate` is 1 * RAY for all PSMs
            line = line / RAD;

            // If not enough room below line (e.g. Maxed out PSM)
            if (Art + amount > line) {
                _setIlkLine(p.ilk, (Art + amount + 1) * RAD); // Increase `line` to `Art`+`amount`
            }

            // If required, add pre-minted Dai to litePsm
            if (litePsm.rush() > 0) {
                litePsm.fill();
            }
        }

        // Allow the test contract to sell or buy gems with no fees
        GodMode.setWard(address(litePsm), address(this), 1);
        litePsm.kiss(address(this));

        // Approvals
        token.approve(address(litePsm), type(uint256).max);
        dai.approve(address(litePsm), type(uint256).max);

        // Scale up `amount` to the correct Gem decimals value (buyGem and sellGem both use Gem decimals for precision)
        uint256 snapshot = vm.snapshot();

        // Sell TOKEN _to_ the PSM for DAI (increases debt)
        {
            uint256 sellWadOut  = amount * WAD;           // Scale to Dai decimals (18) for Dai balance check
            sellWadOut         -= sellWadOut * tin / WAD; // Subtract `tin` fee (was deducted by PSM)

            uint256 sellAmt = amount * WAD / _to18ConversionFactor(litePsm);
            _giveTokens(address(token), sellAmt);
            litePsm.sellGem(address(this), sellAmt);

            assertEq(token.balanceOf(address(this)), 0,          _concat("checkLitePsmIlkIntegration/sellGem-token-balance-", p.ilk));
            assertEq(dai.balanceOf(address(this)),   sellWadOut, _concat("checkLitePsmIlkIntegration/sellGem-dai-balance-",   p.ilk));

            vm.revertTo(snapshot);
        }

        // Sell TOKEN _to_ the PSM for DAI with no fees (increases debt)
        {
            litePsm.file("tin", 0.01 ether); // Force fee
            uint256 sellWadOut = amount * WAD; // Scale to Dai decimals (18) for Dai balance check

            uint256 sellAmt = amount * WAD / _to18ConversionFactor(litePsm);
            _giveTokens(address(token), sellAmt);
            litePsm.sellGemNoFee(address(this), sellAmt);

            assertEq(token.balanceOf(address(this)), 0,          _concat("checkLitePsmIlkIntegration/sellGemNoFee-token-balance-", p.ilk));
            assertEq(dai.balanceOf(address(this)),   sellWadOut, _concat("checkLitePsmIlkIntegration/sellGemNoFee-dai-balance-",   p.ilk));

            vm.revertTo(snapshot);
        }

        // For `sellGem` we had `amount` TOKENS, so there is no issue calling it
        // For `buyGem` we have `amount` Dai, but `buyGem` takes `gemAmt` as TOKENS
        // So we need to calculate the `gemAmt` of TOKEN we want to buy (i.e. subtract `tout` in advance)

        // Buy TOKEN _from_ the PSM for DAI (decreases debt)
        {
            uint256 buyWadIn  = amount * WAD;                 // Scale to Dai decimals (18) for Dai balance check
            buyWadIn         += _divup(buyWadIn * tout, WAD); // Add `tout` fee
            _giveTokens(address(dai), buyWadIn);              // Mints Dai into the test contract

            uint256 buyAmt = amount * WAD / _to18ConversionFactor(litePsm); // Scale to Gem decimals for `buyGem()`
            litePsm.buyGem(address(this), buyAmt);

            // There may be some Dai dust left over depending on tout and decimals
            // This should always be less than some dust limit
            assertLe(dai.balanceOf(address(this)),   tout,   _concat("checkLitePsmIlkIntegration/buyGem-dai-balance-",   p.ilk));
            assertEq(token.balanceOf(address(this)), buyAmt, _concat("checkLitePsmIlkIntegration/buyGem-token-balance-", p.ilk));

            vm.revertTo(snapshot);
        }

        // Buy TOKEN _from_ the PSM for DAI with no fees (decreases debt)
        {
            litePsm.file("tout", 0.01 ether); // Force fee

            uint256 buyWadIn = amount * WAD; // Scale to Dai decimals (18) for Dai balance check
            _giveTokens(address(dai), buyWadIn); // Mints Dai into the test contract

            uint256 buyAmt = amount * WAD / _to18ConversionFactor(litePsm); // Scale to Gem decimals for `buyGem()`
            litePsm.buyGemNoFee(address(this), buyAmt);

            // There may be some Dai dust left over depending on tout and decimals
            // This should always be less than some dust limit
            assertLe(dai.balanceOf(address(this)),   tout,   _concat("checkLitePsmIlkIntegration/buyGemNoFee-dai-balance-",   p.ilk));
            assertEq(token.balanceOf(address(this)), buyAmt, _concat("checkLitePsmIlkIntegration/buyGemNoFee-token-balance-", p.ilk));

            vm.revertTo(snapshot);
        }

        // ----- LitePsmMom can halt swaps -----

        // LitePsmMom can halt litePSM
        assertEq(litePsm.wards(address(litePsmMom)), 1, _concat("checkLitePsmIlkIntegration/litePsmMom-not-ward-", p.ilk));

        // Gives the hat to the test contract, so it can invoke LitePsmMom
        vm.store(address(chief), bytes32(uint256(0x0c)) /* `hat` slot */, bytes32(uint256(uint160(address(this)))));
        LitePsmMomLike(address(litePsmMom)).halt(address(litePsm), 2 /* = BOTH */);

        assertEq(litePsm.tin(),  type(uint256).max, _concat("checkLitePsmIlkIntegration/mom-halt-invalid-tin-",  p.ilk));
        assertEq(litePsm.tout(), type(uint256).max, _concat("checkLitePsmIlkIntegration/mom-halt-invalid-tout-", p.ilk));
    }

    function _to18ConversionFactor(LitePsmLike litePsm) internal view returns (uint256) {
        return litePsm.to18ConversionFactor();
    }

    function _to18ConversionFactor(PsmAbstract psm) internal view returns (uint256) {
        return 10 ** (18 - GemJoinAbstract(psm.gemJoin()).dec());
    }

    function _checkDirectIlkIntegration(
        bytes32 _ilk,
        DirectDepositLike join,
        ClipAbstract clip,
        address pip,
        uint256 bar,
        uint256 tau
    ) internal {
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
        GodMode.setWard(address(join), address(this), 1);
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
        GodMode.setWard(address(join), address(this), 1);
        join.file("bar", 0);
        join.deny(address(this));
        join.exec();

        // Module should clear out
        (ink, art) = vat.urns(_ilk, address(join));
        assertLe(ink, 1);
        assertLe(art, 1);
        assertEq(token.balanceOf(address(join)), 0);

        assertEq(join.tic(), 0);
    }

    function _getSignatures(bytes32 signHash) internal returns (bytes memory signatures, address[] memory signers) {
        // seeds chosen s.t. corresponding addresses are in ascending order
        uint8[30] memory seeds = [8,10,6,2,9,15,14,20,7,29,24,13,12,25,16,26,21,22,0,18,17,27,3,28,23,19,4,5,1,11];
        uint256 numSigners = seeds.length;
        signers = new address[](numSigners);
        for(uint256 i; i < numSigners; i++) {
            uint256 sk = uint256(keccak256(abi.encode(seeds[i])));
            signers[i] = vm.addr(sk);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(sk, signHash);
            signatures = abi.encodePacked(signatures, r, s, v);
        }
        assertEq(signatures.length, numSigners * 65);
    }

    function _oracleAuthRequestMint(
        bytes32 sourceDomain,
        bytes32 targetDomain,
        uint256 toMint,
        uint256 expectedFee
    ) internal {
        TeleportOracleAuthLike oracleAuth = TeleportOracleAuthLike(addr.addr("MCD_ORACLE_AUTH_TELEPORT_FW_A"));
        GodMode.setWard(address(oracleAuth), address(this), 1);
        (bytes memory signatures, address[] memory signers) = _getSignatures(oracleAuth.getSignHash(TeleportGUID({
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

    function _checkTeleportFWIntegration(
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
            vm.startPrank(gateway);
            router.requestMint(TeleportGUID({
                sourceDomain: sourceDomain,
                targetDomain: targetDomain,
                receiver: bytes32(uint256(uint160(address(this)))),
                operator: bytes32(0),
                amount: uint128(toMint),
                nonce: 0,
                timestamp: uint48(block.timestamp - TeleportFeeLike(fee).ttl())
            }), 0, 0);
            vm.stopPrank();
            assertEq(dai.balanceOf(address(this)), toMint);
            assertEq(join.debt(sourceDomain), int256(toMint));
        }

        // Check oracle auth mint -- add custom signatures to test
        uint256 _fee = toMint * expectedFee / WAD;
        {
            uint256 prevDai = vat.dai(address(vow));
            _oracleAuthRequestMint(sourceDomain, targetDomain, toMint, expectedFee);
            assertEq(dai.balanceOf(address(this)), toMint * 2 - _fee);
            assertEq(join.debt(sourceDomain), int256(toMint * 2));
            assertEq(vat.dai(address(vow)) - prevDai, _fee * RAY);
        }

        // Check settle
        dai.transfer(gateway, toMint * 2 - _fee);
        vm.startPrank(gateway);
        router.settle(targetDomain, toMint * 2 - _fee);
        vm.stopPrank();
        assertEq(dai.balanceOf(gateway), 0);
        assertEq(join.debt(sourceDomain), int256(_fee));
    }

    function _checkCureLoadTeleport(
        bytes32 sourceDomain,
        bytes32 targetDomain,
        uint256 toMint,
        uint256 expectedFee,
        uint256 expectedTell,
        bool cage
    ) internal {
        TeleportJoinLike join = TeleportJoinLike(addr.addr("MCD_JOIN_TELEPORT_FW_A"));

        // Oracle auth mint -- add custom signatures to test
        _oracleAuthRequestMint(sourceDomain, targetDomain, toMint, expectedFee);
        assertEq(join.debt(sourceDomain), int256(toMint));

        // Emulate Global Settlement
        if (cage) {
            assertEq(cure.live(), 1);
            vm.store(
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

    struct VestStream {
        uint256 id;
        address usr;
        uint256 bgn;
        uint256 clf;
        uint256 fin;
        uint256 tau;
        address mgr;
        uint256 res;
        uint256 tot;
        uint256 rxd;
    }

    function _checkVestDai(VestStream[] memory _ss) internal {
        uint256 prevStreamCount = vestDai.ids();

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        // Check that all streams added in this spell are tested
        assertEq(vestDai.ids(), prevStreamCount + _ss.length, "testVestDai/not-all-streams-tested");

        for (uint256 i = 0; i < _ss.length; i++) {
            _checkVestStream("testVestDai", vestDai, address(dai), _ss[i]);
        }
    }

    function _checkVestMkr(VestStream[] memory _ss) internal {
        uint256 prevStreamCount = vestMkr.ids();
        uint256 prevAllowance = gov.allowance(pauseProxy, address(vestMkr));

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        // Check allowance was increased according to the streams
        uint256 sumTot = 0;
        uint256 sumRxd = 0;
        for (uint256 i = 0; i < _ss.length; i++) {
            sumTot = sumTot + _ss[i].tot;
            sumRxd = sumRxd + _ss[i].rxd;
        }
        assertEq(gov.allowance(pauseProxy, address(vestMkr)), prevAllowance + sumTot - sumRxd, "testVestMkr/invalid-allowance");

        // Check that all streams added in this spell are tested
        assertEq(vestMkr.ids(), prevStreamCount + _ss.length, "testVestMrk/not-all-streams-tested");

        for (uint256 i = 0; i < _ss.length; i++) {
            _checkVestStream("testVestMkr", vestMkr, address(gov), _ss[i]);
        }
    }

    function _checkTransferrableVestMkrAllowance() internal {
        uint256 vestableAmt;

        for(uint256 i = 1; i <= vestMkr.ids(); i++) {
            if (vestMkr.valid(i)) {
                (,,,,,,uint128 tot, uint128 rxd) = vestMkr.awards(i);
                vestableAmt = vestableAmt + (tot - rxd);
            }
        }

        uint256 allowance = gov.allowance(pauseProxy, address(vestMkr));
        assertGe(allowance, vestableAmt, "TestError/insufficient-gov-transferrable-vest-mkr-allowance");
    }


    function _checkVestSky(VestStream[] memory _ss) internal {
        uint256 prevStreamCount = vestSky.ids();

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        // Check that all streams added in this spell are tested
        assertEq(vestSky.ids(), prevStreamCount + _ss.length, "testVestSky/not-all-streams-tested");

        for (uint256 i = 0; i < _ss.length; i++) {
            _checkVestStream("testVestSky", vestSky, address(sky), _ss[i]);
        }
    }

    function _checkVestStream(
        string memory _errPrefix,
        VestAbstract _vest,
        address _token,
        VestStream memory _s
    ) internal {
        assertEq(_vest.usr(_s.id), _s.usr,          _concat(_errPrefix, string("/usr")));
        assertEq(_vest.bgn(_s.id), _s.bgn,          _concat(_errPrefix, string("/bgn")));
        assertEq(_vest.clf(_s.id), _s.clf,          _concat(_errPrefix, string("/clf")));
        assertEq(_vest.fin(_s.id), _s.fin,          _concat(_errPrefix, string("/fin")));
        assertEq(_vest.fin(_s.id), _s.bgn + _s.tau, _concat(_errPrefix, string("/fin (bgn + tau)")));
        assertEq(_vest.mgr(_s.id), _s.mgr,          _concat(_errPrefix, string("/mgr")));
        assertEq(_vest.res(_s.id), _s.res,          _concat(_errPrefix, string("/res")));
        assertEq(_vest.tot(_s.id), _s.tot,          _concat(_errPrefix, string("/tot")));
        assertEq(_vest.rxd(_s.id), _s.rxd,          _concat(_errPrefix, string("/rxd")));

        GemAbstract token = GemAbstract(_token);

        {
            uint256 before = vm.snapshot();

            // Check each new stream is payable in the future
            uint256 pbalance = token.balanceOf(_s.usr);
            GodMode.setWard(address(_vest), address(this), 1);
            _vest.unrestrict(_s.id);

            vm.warp(_s.fin);
            _vest.vest(_s.id);
            assertEq(
                token.balanceOf(_s.usr),
                pbalance + _s.tot - _s.rxd,
                _concat(_errPrefix, string("/invalid-received-amount"))
            );

            vm.revertTo(before);
        }
    }

    function _getIlkMat(bytes32 _ilk) internal view returns (uint256 mat) {
        (, mat) = spotter.ilks(_ilk);
    }

    function _getIlkDuty(bytes32 _ilk) internal view returns (uint256 duty) {
        (duty,)  = jug.ilks(_ilk);
    }

    function _setIlkMat(bytes32 ilk, uint256 amount) internal {
        vm.store(
            address(spotter),
            bytes32(uint256(keccak256(abi.encode(ilk, uint256(1)))) + 1),
            bytes32(amount)
        );
        assertEq(_getIlkMat(ilk), amount, _concat("TestError/setIlkMat-", ilk));
    }

    function _setIlkRate(bytes32 ilk, uint256 amount) internal {
        vm.store(
            address(vat),
            bytes32(uint256(keccak256(abi.encode(ilk, uint256(2)))) + 1),
            bytes32(amount)
        );
        (,uint256 rate,,,) = vat.ilks(ilk);
        assertEq(rate, amount, _concat("TestError/setIlkRate-", ilk));
    }

    function _setIlkLine(bytes32 ilk, uint256 amount) internal {
        vm.store(
            address(vat),
            bytes32(uint256(keccak256(abi.encode(ilk, uint256(2)))) + 3),
            bytes32(amount)
        );
        (,,,uint256 line,) = vat.ilks(ilk);
        assertEq(line, amount, _concat("TestError/setIlkLine-", ilk));
    }

    function _checkIlkLerpOffboarding(bytes32 _ilk, bytes32 _lerp, uint256 _startMat, uint256 _endMat) internal {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        LerpAbstract lerp = LerpAbstract(lerpFactory.lerps(_lerp));

        vm.warp(block.timestamp + lerp.duration() / 2);
        assertEq(_getIlkMat(_ilk), _startMat * RAY / 100);
        lerp.tick();
        _assertEqApprox(_getIlkMat(_ilk), ((_startMat + _endMat) / 2) * RAY / 100, RAY / 100);

        vm.warp(block.timestamp + lerp.duration());
        lerp.tick();
        assertEq(_getIlkMat(_ilk), _endMat * RAY / 100);
    }

    function _checkIlkLerpIncreaseMatOffboarding(bytes32 _ilk, bytes32 _oldLerp, bytes32 _newLerp, uint256 _newEndMat) internal {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        LerpFactoryAbstract OLD_LERP_FAB = LerpFactoryAbstract(0x00B416da876fe42dd02813da435Cc030F0d72434);
        LerpAbstract oldLerp = LerpAbstract(OLD_LERP_FAB.lerps(_oldLerp));

        uint256 t = (block.timestamp - oldLerp.startTime()) * WAD / oldLerp.duration();
        uint256 tickMat = oldLerp.end() * t / WAD + oldLerp.start() - oldLerp.start() * t / WAD;
        assertEq(_getIlkMat(_ilk), tickMat);
        assertEq(spotter.wards(address(oldLerp)), 0);

        LerpAbstract newLerp = LerpAbstract(lerpFactory.lerps(_newLerp));

        vm.warp(block.timestamp + newLerp.duration() / 2);
        assertEq(_getIlkMat(_ilk), tickMat);
        newLerp.tick();
        _assertEqApprox(_getIlkMat(_ilk), (tickMat + _newEndMat * RAY / 100) / 2, RAY / 100);

        vm.warp(block.timestamp + newLerp.duration());
        newLerp.tick();
        assertEq(_getIlkMat(_ilk), _newEndMat * RAY / 100);
    }

    function _getExtcodesize(address target) internal view returns (uint256 exsize) {
        assembly {
            exsize := extcodesize(target)
        }
    }

    function _getBytecodeMetadataLength(address a) internal view returns (uint256 length) {
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

    /**
     * @dev Checks if the deployer of a contract has not kept `wards` access to the contract.
     * Notice that it depends on `deployers` being kept up-to-date.
     */
    function _checkWards(address _addr, string memory contractName) internal {
        for (uint256 i = 0; i < deployers.count(); i ++) {
            address deployer = deployers.addr(i);
            (bool ok, bytes memory data) = _addr.call(abi.encodeWithSignature("wards(address)", deployer));
            if (!ok || data.length != 32) return;

            uint256 ward = abi.decode(data, (uint256));
            if (ward > 0) {
                emit log_named_address("   Deployer Address", deployer);
                emit log_named_string("  Affected Contract", contractName);
                fail("Error: Bad Auth");
            }
        }
    }

    /**
     * @dev Same as `_checkWards`, but for OSMs' underlying Median contracts.
     */
    function _checkOsmSrcWards(address _addr, string memory contractName) internal {
        (bool ok, bytes memory data) = _addr.call(abi.encodeWithSignature("src()"));
        if (!ok || data.length != 32) return;

        address source = abi.decode(data, (address));
        string memory sourceName = _concat("src of ", contractName);
        _checkWards(source, sourceName);
    }

    /**
     * @notice Checks if the the deployer of a contract the chainlog has not kept `wards` access to it.
     * @dev Reverts if `key` is not in the chainlog.
     */
    function _checkAuth(bytes32 key) internal {
        address _addr = chainLog.getAddress(key);
        string memory contractName = _bytes32ToString(key);

        _checkWards(_addr, contractName);
        _checkOsmSrcWards(_addr, contractName);
    }

    function _checkRWADocUpdate(bytes32 ilk, string memory currentDoc, string memory newDoc) internal {
        (string memory doc, address pip, uint48 tau, uint48 toc) = liquidationOracle.ilks(ilk);

        assertEq(doc, currentDoc, _concat("TestError/bad-old-document-for-", ilk));

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        (string memory docNew, address pipNew, uint48 tauNew, uint48 tocNew) = liquidationOracle.ilks(ilk);

        assertEq(docNew, newDoc,  _concat("TestError/bad-new-document-for-", ilk));
        assertEq(pip, pipNew,     _concat("TestError/pip-is-not-the-same-for-", ilk));
        assertTrue(tau == tauNew, _concat("TestError/tau-is-not-the-same-for-", ilk));
        assertTrue(toc == tocNew, _concat("TestError/toc-is-not-the-same-for", ilk));
    }

    function _testGeneral() internal {
        string memory description = new DssSpell().description();
        assertTrue(bytes(description).length > 0, "TestError/spell-description-length");
        // DS-Test can't handle strings directly, so cast to a bytes32.
        assertEq(_stringToBytes32(spell.description()),
                _stringToBytes32(description), "TestError/spell-description");

        if(address(spell) != address(spellValues.deployed_spell)) {
            assertEq(spell.expiration(), block.timestamp + spellValues.expiration_threshold, "TestError/spell-expiration");
        } else {
            assertEq(spell.expiration(), spellValues.deployed_spell_created + spellValues.expiration_threshold, "TestError/spell-expiration");
        }

        assertTrue(spell.officeHours() == spellValues.office_hours_enabled, "TestError/spell-office-hours");

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        _checkSystemValues(afterSpell);

        _checkCollateralValues(afterSpell);
    }

    function _testOfficeHours() internal {
        assertEq(spell.officeHours(), spellValues.office_hours_enabled, "TestError/office-hours-mismatch");

        // Only relevant if office hours are enabled
        if (spell.officeHours()) {

            _vote(address(spell));
            spell.schedule();

            uint256 afterSchedule = vm.snapshot();

            // Cast in the wrong day
            {
                uint256 castTime = block.timestamp + pause.delay();
                uint256 day = (castTime / 1 days + 3) % 7;
                if (day < 5) {
                    castTime += 5 days - day * 86400;
                }

                // Original revert reason is swallowed and "ds-pause-delegatecall-error" reason is given,
                // so it's not worth bothering to check the revert reason.
                vm.expectRevert();
                vm.warp(castTime);
                spell.cast();
            }

            vm.revertTo(afterSchedule);

            // Cast too early in the day

            {
                uint256 castTime = block.timestamp + pause.delay() + 24 hours;
                uint256 hour = castTime / 1 hours % 24;
                if (hour >= 14) {
                    castTime -= hour * 3600 - 13 hours;
                }

                vm.expectRevert();
                vm.warp(castTime);
                spell.cast();
            }

            vm.revertTo(afterSchedule);

            // Cast too late in the day

            {
                uint256 castTime = block.timestamp + pause.delay();
                uint256 hour = castTime / 1 hours % 24;
                if (hour < 21) {
                    castTime += 21 hours - hour * 3600;
                }

                vm.expectRevert();
                vm.warp(castTime);
                spell.cast();
            }

        }
    }

    function _testCastOnTime() internal {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");
    }

    function _testCastCost() internal {
        _vote(address(spell));
        spell.schedule();

        _castPreviousSpell();
        vm.warp(spell.nextCastTime());
        uint256 startGas = gasleft();
        spell.cast();
        uint256 endGas = gasleft();
        uint256 totalGas = startGas - endGas;

        assertTrue(spell.done(), "TestError/spell-not-done");
        // Fail if cast is too expensive
        assertLe(totalGas, 15 * MILLION, "TestError/spell-cast-cost-too-high");
    }

    function _testDeployCost() internal {
        uint256 startGas = gasleft();
        new DssSpell();
        uint256 endGas = gasleft();
        uint256 totalGas = startGas - endGas;

        // Warn if deploy exceeds block target size
        if (totalGas > 15 * MILLION) {
            emit log("Warn: deploy gas exceeds average block target");
            emit log_named_uint("    deploy gas", totalGas);
            emit log_named_uint("  block target", 15 * MILLION);
        }

        // Fail if deploy is too expensive
        assertLe(totalGas, 30 * MILLION, "TestError/spell-deploy-cost-too-high");
    }

    // Fail when contract code size exceeds 24576 bytes (a limit introduced in Spurious Dragon).
    // This contract may not be deployable.
    // Consider enabling the optimizer (with a low "runs" value!),
    //   turning off revert strings, or using libraries.
    function _testContractSize() internal {
        uint256 _sizeSpell;
        address _spellAddr  = address(spell);
        assembly {
            _sizeSpell := extcodesize(_spellAddr)
        }
        assertLe(_sizeSpell, 24576, "testContractSize/DssSpell-exceeds-max-contract-size");

        uint256 _sizeAction;
        address _actionAddr = spell.action();
        assembly {
            _sizeAction := extcodesize(_actionAddr)
        }
        assertLe(_sizeAction, 24576, "testContractSize/DssSpellAction-exceeds-max-contract-size");

    }

    // The specific date doesn't matter that much since function is checking for difference between warps
    function _testNextCastTime() internal {
        vm.warp(1606161600); // Nov 23, 20 UTC (could be cast Nov 26)

        _vote(address(spell));
        spell.schedule();

        uint256 monday_1400_UTC = 1606744800; // Nov 30, 2020
        uint256 monday_2100_UTC = 1606770000; // Nov 30, 2020

        // Day tests
        vm.warp(monday_1400_UTC);                                      // Monday,   14:00 UTC
        assertEq(spell.nextCastTime(), monday_1400_UTC);               // Monday,   14:00 UTC

        if (spell.officeHours()) {
            vm.warp(monday_1400_UTC - 1 days);                         // Sunday,   14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            vm.warp(monday_1400_UTC - 2 days);                         // Saturday, 14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            vm.warp(monday_1400_UTC - 3 days);                         // Friday,   14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC - 3 days);  // Able to cast

            vm.warp(monday_2100_UTC);                                  // Monday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC + 1 days);  // Tuesday,  14:00 UTC

            vm.warp(monday_2100_UTC - 1 days);                         // Sunday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            vm.warp(monday_2100_UTC - 2 days);                         // Saturday, 21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            vm.warp(monday_2100_UTC - 3 days);                         // Friday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            // Time tests
            uint256 castTime;

            for(uint256 i = 0; i < 5; i++) {
                castTime = monday_1400_UTC + i * 1 days; // Next day at 14:00 UTC
                vm.warp(castTime - 1 seconds); // 13:59:59 UTC
                assertEq(spell.nextCastTime(), castTime);

                vm.warp(castTime + 7 hours + 1 seconds); // 21:00:01 UTC
                if (i < 4) {
                    assertEq(spell.nextCastTime(), monday_1400_UTC + (i + 1) * 1 days); // Next day at 14:00 UTC
                } else {
                    assertEq(spell.nextCastTime(), monday_1400_UTC + 7 days); // Next monday at 14:00 UTC (friday case)
                }
            }
        }
    }

    function _testRevertIfNotScheduled() internal {
        vm.expectRevert();
        spell.nextCastTime();
    }

    function _testUseEta() internal {
        vm.warp(1606161600); // Nov 23, 20 UTC (could be cast Nov 26)

        _vote(address(spell));
        spell.schedule();

        uint256 castTime = spell.nextCastTime();
        assertGe(castTime, spell.eta());
    }

    // Verifies that the bytecode of the action of the spell used for testing
    // matches what we'd expect.
    //
    // Not a complete replacement for Etherscan verification, unfortunately.
    // This is because the DssSpell bytecode is non-deterministic because it
    // deploys the action in its constructor and incorporates the action
    // address as an immutable variable--but the action address depends on the
    // address of the DssSpell which depends on the address+nonce of the
    // deploying address. If we had a way to simulate a contract creation by
    // an arbitrary address+nonce, we could verify the bytecode of the DssSpell
    // instead.
    //
    // Vacuous until the deployed_spell value is non-zero.
    function _testBytecodeMatches() internal {
        // The DssSpell bytecode is non-deterministic, compare only code size
        DssSpell expectedSpell = new DssSpell();
        assertEq(_getExtcodesize(address(spell)), _getExtcodesize(address(expectedSpell)), "TestError/spell-codesize");

        // The SpellAction bytecode can be compared after chopping off the metada
        address expectedAction = expectedSpell.action();
        address actualAction   = spell.action();
        uint256 expectedBytecodeSize;
        uint256 actualBytecodeSize;
        assembly {
            expectedBytecodeSize := extcodesize(expectedAction)
            actualBytecodeSize   := extcodesize(actualAction)
        }

        uint256 metadataLength = _getBytecodeMetadataLength(expectedAction);
        assertTrue(metadataLength <= expectedBytecodeSize, "TestError/metadata-length-gt-expected-bytecode-size");
        expectedBytecodeSize -= metadataLength;

        metadataLength = _getBytecodeMetadataLength(actualAction);
        assertTrue(metadataLength <= actualBytecodeSize, "TestError/metadata-length-gt-actual-bytecode-size");
        actualBytecodeSize -= metadataLength;

        assertEq(actualBytecodeSize, expectedBytecodeSize, "TestError/bytecode-size-mismatch");
        uint256 size = actualBytecodeSize;
        uint256 expectedHash;
        uint256 actualHash;
        assembly {
            let ptr := mload(0x40)

            extcodecopy(expectedAction, ptr, 0, size)
            expectedHash := keccak256(ptr, size)

            extcodecopy(actualAction, ptr, 0, size)
            actualHash := keccak256(ptr, size)
        }
        assertEq(actualHash, expectedHash, "TestError/bytecode-hash-mismatch");
    }

    struct ChainlogCache {
        bytes32 versionHash;
        bytes32 contentHash;
        uint256 count;
        bytes32[] keys;
        address[] values;
    }

    /**
     * @dev Checks the integrity of the chainlog.
     *      This test case is able to catch the following spell issues:

     *      1. Modifications without version bumping:
     *        a. Removing a key.
     *        b. Updating a key.
     *        c. Adding a key.
     *        d. Removing a key and adding it back (this can change the order of the list).
     *      2. Version bumping without modifications.
     *      3. Dangling wards on new or updated keys.
     *
     *      When adding or updating a key, the test will automatically check for dangling wards if applicable.
     *      Notice that when a key is removed, if it is not the last one, there is a side-effect of moving
     *      the last key to the position of the removed one (well-known Solidity iterability pattern).
     *      This will generate a false-positive that will cause the test to re-check wards for the moved key.
     */
    function _testChainlogIntegrity() internal {
        ChainlogCache memory cacheBefore = ChainlogCache({
            count: chainLog.count(),
            keys: chainLog.list(),
            versionHash: keccak256(abi.encodePacked("")),
            contentHash: keccak256(abi.encode(new bytes32[](0), new address[](0))),
            values: new address[](0)
        });

        cacheBefore.values = new address[](cacheBefore.count);
        for(uint256 i = 0; i < cacheBefore.count; i++) {
            cacheBefore.values[i] = chainLog.getAddress(cacheBefore.keys[i]);
        }

        cacheBefore.versionHash = keccak256(abi.encodePacked(chainLog.version()));
        // Using `abi.encode` to prevent ambiguous encoding
        cacheBefore.contentHash = keccak256(abi.encode(cacheBefore.keys, cacheBefore.values));

        //////////////////////////////////////////

        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        //////////////////////////////////////////

        ChainlogCache memory cacheAfter = ChainlogCache({
            count: chainLog.count(),
            keys: chainLog.list(),
            versionHash: keccak256(abi.encodePacked("")),
            contentHash: keccak256(abi.encode(new bytes32[](0), new address[](0))),
            values: new address[](0)
        });

        cacheAfter.values = new address[](cacheAfter.count);
        for(uint256 i = 0; i < cacheAfter.count; i++) {
            cacheAfter.values[i] = chainLog.getAddress(cacheAfter.keys[i]);
        }

        cacheAfter.versionHash = keccak256(abi.encodePacked(chainLog.version()));
        // Using `abi.encode` to prevent ambiguous encoding
        cacheAfter.contentHash = keccak256(abi.encode(cacheAfter.keys, cacheAfter.values));

        //////////////////////////////////////////

        // If neither the version or the content have changed, there is nothing to test
        if (cacheAfter.versionHash == cacheBefore.versionHash && cacheAfter.contentHash == cacheBefore.contentHash) {
            vm.skip(true);
        }

        // If the version is the same, the content should not have changed
        if (cacheAfter.versionHash == cacheBefore.versionHash) {
            assertEq(cacheBefore.count, cacheAfter.count, "TestError/chainlog-version-not-updated-length-change");

            // Add explicit check otherwise this would fail with an array-out-of-bounds error,
            // since Foundry does not halt the execution when an assertion fails.
            if (cacheBefore.count == cacheAfter.count) {
                // Fail if the chainlog is the same size, but EITHER:
                //   1. The value for a specific key changed
                //   2. The order of keys changed
                for (uint256 i = 0; i < cacheAfter.count; i++) {
                    assertEq(
                        cacheBefore.values[i],
                        cacheAfter.values[i],
                        _concat(
                            "TestError/chainlog-version-not-updated-value-change: ",
                            _concat(
                                _concat("+ ", cacheAfter.keys[i]),
                                _concat(" | - ", cacheBefore.keys[i])
                            )
                        )
                    );
                }
            }
        } else {
            // If the version changed, the content should have changed
            assertTrue(cacheAfter.contentHash != cacheBefore.contentHash, "TestError/chainlog-version-updated-no-content-change");
        }

        // If the content has changed, we look into the diff
        if (cacheAfter.contentHash != cacheBefore.contentHash) {
            // If the content changed, the version should have changed
            assertTrue(cacheAfter.versionHash != cacheBefore.versionHash, "TestError/chainlog-content-updated-no-version-change");

            uint256 diffCount;
            // Iteration must stop at the shorter array length
            uint256 maxIters = cacheAfter.count > cacheBefore.count ? cacheBefore.count : cacheAfter.count;

            // Look for changes in existing keys
            for (uint256 i = 0; i < maxIters; i++) {
                if (cacheAfter.keys[i] != cacheBefore.keys[i]) {
                    // Change in order
                    diffCount += 1;
                } else if (cacheAfter.values[i] != cacheBefore.values[i]) {
                    // Change in value
                    diffCount += 1;
                }
            }

            // Account for new keys
            // Notice: we don't care about removed keys
            if (cacheAfter.count > cacheBefore.count) {
                diffCount += (cacheAfter.count - cacheBefore.count);
            }

            ////////////////////////////////////////

            bytes32[] memory diffKeys = new bytes32[](diffCount);
            uint256 j = 0;

            for (uint256 i = 0; i < maxIters; i++) {
                if (cacheAfter.keys[i] != cacheBefore.keys[i]) {
                    // Mark keys whose order has changed
                    diffKeys[j++] = cacheAfter.keys[i];
                } else if (cacheAfter.values[i] != cacheBefore.values[i]) {
                    // Mark changed values
                    diffKeys[j++] = cacheAfter.keys[i];
                }
            }

            // Mark new keys
            if (cacheAfter.count > cacheBefore.count) {
                for (uint256 i = cacheBefore.count; i < cacheAfter.count; i++) {
                    diffKeys[j++] = cacheAfter.keys[i];
                }
            }

            for (uint256 i = 0; i < diffKeys.length; i++) {
                _checkAuth(diffKeys[i]);
            }
        }
    }

    // Validate addresses in test harness match chainlog
    function _testChainlogValues() internal {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done(), "TestError/spell-not-done");

        bytes32[] memory keys = chainLog.list();
        for (uint256 i = 0; i < keys.length; i++) {
            assertEq(
                chainLog.getAddress(keys[i]),
                addr.addr(keys[i]),
                _concat("TestError/chainlog-vs-harness-key-mismatch: ", keys[i])
            );
        }

        assertEq(chainLog.version(), afterSpell.chainlog_version, "TestError/chainlog-version-mismatch");
    }

    function _checkCropCRVLPIntegration(
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
        vm.warp(block.timestamp + 3601);
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
        uint256 amount = 2 * dust / (_getUNIV2LPPrice(address(pip)) * 1e9);
        _giveTokens(address(join.gem()), amount);

        assertEq(GemAbstract(join.gem()).balanceOf(address(this)), amount);
        assertEq(vat.gem(_ilk, cropper.getOrCreateProxy(address(this))), 0);
        GemAbstract(join.gem()).approve(address(cropper), amount);
        cropper.join(address(join), address(this), amount);
        assertEq(GemAbstract(join.gem()).balanceOf(address(this)), 0);
        assertEq(vat.gem(_ilk, cropper.getOrCreateProxy(address(this))), amount);

        // Tick the fees forward so that art != dai in wad units
        vm.warp(block.timestamp + 1);
        jug.drip(_ilk);

        // Check that we got rewards from the time increment above
        assertEq(GemAbstract(join.bonus()).balanceOf(address(this)), 0);
        cropper.join(address(join), address(this), 0);
        // NOTE: LDO rewards are shutting off on Friday so this will fail (bad timing), but they plan to extend
        //assertGt(GemAbstract(join.bonus()).balanceOf(address(this)), 0);

        // Deposit collateral, generate DAI
        (,uint256 rate,,,) = vat.ilks(_ilk);
        assertEq(vat.dai(address(this)), 0);
        cropper.frob(_ilk, address(this), address(this), address(this), int256(amount), int256(_divup(dust, rate)));
        assertEq(vat.gem(_ilk, cropper.getOrCreateProxy(address(this))), 0);
        assertTrue(vat.dai(address(this)) >= dust && vat.dai(address(this)) <= dust + RAY);

        // Payback DAI, withdraw collateral
        vat.hope(address(cropper));      // Need to grant the cropper permission to remove dai
        cropper.frob(_ilk, address(this), address(this), address(this), -int256(amount), -int256(_divup(dust, rate)));
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
                cropper.frob(_ilk, address(this), address(this), address(this), int256(amount), int256(amount * spot / rate));
            }
            vm.warp(block.timestamp + 1);
            jug.drip(_ilk);
            assertEq(clip.kicks(), 0);

            // Kick off the liquidation
            dog.bark(_ilk, cropper.getOrCreateProxy(address(this)), address(this));
            assertEq(clip.kicks(), 1);

            // Complete the liquidation
            vat.hope(address(clip));
            (, uint256 tab,,,,) = clip.sales(1);
            vm.store(
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

    function _testSplitter() internal {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        assertEq(vow.flapper(), address(split), "TestError/invalid-vow-flapper");
        assertEq(split.flapper(), address(flap), "TestError/invalid-split-flapper");
        assertEq(flap.gem(), address(sky), "TestError/invalid-flapper-gem");
        assertEq(flap.pip(), addr.addr("FLAP_SKY_ORACLE"), "TestError/invalid-flapper-pip");
        assertEq(flap.pair(), addr.addr("UNIV2USDSSKY"), "TestError/invalid-flapper-pair");

        // Check splitter and flapper
        {
            // Leave surplus buffer ready to be flapped
            vow.heal(vat.sin(address(vow)) - (vow.Sin() + vow.Ash()));
            // Ensure flapping is possible
            stdstore
                .target(address(vat))
                .sig("dai(address)")
                .with_key(address(vow))
                .checked_write(vat.sin(address(vow)) + vow.bump() + vow.hump());

            GemAbstract pair = GemAbstract(addr.addr("UNIV2USDSSKY"));
            FlapOracleLike pip = FlapOracleLike(flap.pip());

            vm.prank(address(flap));
            uint256 price = uint256(pip.read());

            // Ensure there is enough liquidity
            uint256 usdsWad = 150_000_000 * WAD;
            GodMode.setBalance(address(usds), address(pair), usdsWad);
            // Ensure price is within the tolerane (flap.want() + delta (1 p.p.))
            uint256 skyWad = usdsWad * (flap.want() + 10**16) / price;
            GodMode.setBalance(address(sky), address(pair), skyWad);

            uint256 lotRad = vow.bump() * split.burn() / WAD;
            uint256 payWad = (vow.bump() - lotRad) / RAY;

            uint256 pbalancePauseProxy = pair.balanceOf(pauseProxy);
            uint256 pdaiVow = vat.dai(address(vow));
            uint256 preserveUsds = usds.balanceOf(address(pair));
            uint256 preserveSky = sky.balanceOf(address(pair));

            uint256 pbalanceUsdsFarm;
            // Checking the farm balance is only relevant if split.burn() < 100%
            if (split.burn() < 1 * WAD) {
                pbalanceUsdsFarm = usds.balanceOf(split.farm());
                assertFalse(split.farm() == address(0), "TestError/Splitter/missing-farm");
            }

            vow.flap();

            // TODO: fix the tests
            // assertGt(pair.balanceOf(pauseProxy),      pbalancePauseProxy,          "TestError/Flapper/pair-pauseProxy-balance-no-increase");
            // assertEq(sky.balanceOf(address(pair)),    preserveSky,                 "TestError/Flapper/unexpected-sky-pair-balance-change");

            assertEq(usds.balanceOf(address(pair)),   preserveUsds + lotRad / RAY, "TestError/Flapper/invalid-usds-pair-balance-increase");
            assertEq(pdaiVow - vat.dai(address(vow)), vow.bump(),                  "TestError/Flapper/invalid-vat-dai-vow-change");
            assertEq(usds.balanceOf(address(flap)),   0,                           "TestError/Flapper/invalid-usds-balance");
            assertEq(sky.balanceOf(address(flap)),    0,                           "TestError/Flapper/invalid-sky-balance");

            if (split.burn() < 1 * WAD) {
                assertEq(usds.balanceOf(split.farm()), pbalanceUsdsFarm + payWad, "TestError/Splitter/invalid-farm-balance");
            }
        }

        // Check Mom can increase hop
        {
            // The check for the configured value is already done in `_checkSystemValues()`
            assertLt(split.hop(), type(uint256).max, "TestError/SplitterMom/already-stopped");
            vm.prank(chief.hat());
            splitterMom.stop();
            assertEq(split.hop(), type(uint256).max, "TestError/SplitterMom/not-stopped");
        }
    }

    function _testSystemTokens() internal {
        _vote(address(spell));
        _scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        // USDS
        {
            // USDS is upgradeable, so we need to ensure the implementation contract address is correct.
            assertEq(_imp(address(usds)), addr.addr("USDS_IMP"), "TestError/USDS/invalid-usds-implementation");
        }

        // Converter: Dai <-> USDS
        {
            DaiUsdsLike daiUsds = DaiUsdsLike(addr.addr("DAI_USDS"));
            address daiHolder = address(0x42);
            deal(address(dai), daiHolder, 1_000 * WAD);
            address usdsHolder = address(0x65);
            deal(address(usds), usdsHolder, 1_000 * WAD);


            // Dai -> USDS conversion
            {
                uint256 before = vm.snapshot();

                uint256 pdaiBalance  = dai.balanceOf(daiHolder);
                uint256 pusdsBalance = usds.balanceOf(usdsHolder);

                vm.startPrank(daiHolder);
                dai.approve(address(daiUsds),  type(uint256).max);
                daiUsds.daiToUsds(usdsHolder,  pdaiBalance);
                vm.stopPrank();

                uint256 expectedUsdsBalance = pusdsBalance + pdaiBalance;

                assertEq(dai.balanceOf(daiHolder),   0,                   "TestError/Dai/bad-dai-to-usds-conversion");
                assertEq(usds.balanceOf(usdsHolder), expectedUsdsBalance, "TestError/Usds/bad-dai-to-usds-conversion");

                vm.revertTo(before);
            }

            // USDS -> Dai conversion
            {
                uint256 before = vm.snapshot();

                uint256 pusdsBalance = usds.balanceOf(usdsHolder);
                uint256 pdaiBalance  = dai.balanceOf(daiHolder);

                vm.startPrank(usdsHolder);
                usds.approve(address(daiUsds), type(uint256).max);
                daiUsds.usdsToDai(daiHolder,   pusdsBalance);
                vm.stopPrank();

                uint256 expectedDaiBalance = pdaiBalance + pusdsBalance;

                assertEq(usds.balanceOf(usdsHolder), 0,                  "TestError/USDS/bad-usds-to-dai-conversion");
                assertEq(dai.balanceOf(daiHolder),   expectedDaiBalance, "TestError/Dai/bad-usds-to-dai-conversion");

                vm.revertTo(before);
            }
        }

        // Converter: MKR <-> SKY
        {
            MkrSkyLike mkrSky = MkrSkyLike(addr.addr("MKR_SKY"));
            address mkrHolder = address(0x42);
            deal(address(gov), mkrHolder, 1_000 * WAD);
            address skyHolder = address(0x65);
            deal(address(sky), skyHolder, 1_000 * WAD * afterSpell.sky_mkr_rate);


            // MKR -> SKY conversion
            {
                uint256 before = vm.snapshot();

                uint256 pmkrBalance = gov.balanceOf(mkrHolder);
                uint256 pskyBalance = sky.balanceOf(skyHolder);

                vm.startPrank(mkrHolder);
                gov.approve(address(mkrSky), type(uint256).max);
                mkrSky.mkrToSky(skyHolder,   pmkrBalance);
                vm.stopPrank();

                uint256 expectedSkyBalance = pskyBalance + (pmkrBalance * afterSpell.sky_mkr_rate);

                assertEq(gov.balanceOf(mkrHolder), 0,                  "TestError/MKR/bad-mkr-to-sky-conversion");
                assertEq(sky.balanceOf(skyHolder), expectedSkyBalance, "TestError/Sky/bad-mkr-to-sky-conversion");

                vm.revertTo(before);
            }

            // SKY -> MKR conversion
            {
                uint256 before = vm.snapshot();

                uint256 pskyBalance = sky.balanceOf(skyHolder);
                uint256 pmkrBalance = gov.balanceOf(mkrHolder);

                vm.startPrank(skyHolder);
                sky.approve(address(mkrSky), type(uint256).max);
                mkrSky.skyToMkr(mkrHolder,   pskyBalance);
                vm.stopPrank();

                uint256 expectedMkrBalance = pmkrBalance + (pskyBalance / afterSpell.sky_mkr_rate);

                assertEq(sky.balanceOf(skyHolder), 0,                  "TestError/SKY/bad-sky-to-mkr-conversion");
                assertEq(gov.balanceOf(mkrHolder), expectedMkrBalance, "TestError/Mkr/bad-sky-to-mkr-conversion");

                vm.revertTo(before);
            }
        }

        // sUSDS
        {
            // sUSDS is upgradeable, so we need to ensure the implementation contract address is correct.
            assertEq(_imp(address(susds)), addr.addr("SUSDS_IMP"), "TestError/sUSDS/invalid-susds-implementation");
            assertEq(susds.asset(),        address(usds),          "TestError/sUSDS/invalid-susds-asset");

            // Ensure rate accumulator is up-to-date
            susds.drip();
            // Ensure the test contract has some tokens
            _giveTokens(address(usds),    1_000 * WAD);
            usds.approve(address(susds),  type(uint256).max);

            uint256 pchi    = susds.chi();
            uint256 passets = usds.balanceOf(address(this));

            uint256 shares  = susds.deposit(passets, address(this));
            assertLe(shares, passets, "TestError/sUSDS/invalid-shares");

            uint256 interval = 365 days;
            skip(interval);
            susds.drip();

            uint256 chi         = susds.chi();
            uint256 expectedChi = _rpow(rates.rates(afterSpell.susds_ssr), interval, RAY) * pchi / RAY;
            uint256 assets      = susds.redeem(shares, address(this), address(this));

            // Allow a 0.01% rounding error
            assertApproxEqRel(chi, expectedChi, 10**14,     "TestError/sUSDS/invalid-chi");
            assertGt(assets, passets,                       "TestError/sUSDS/invalid-redeem-assets");
            assertEq(assets, usds.balanceOf(address(this)), "TestError/sUSDS/invalid-balance-after-redeem");
        }
    }

    // Obtained as `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`
    bytes32 constant EIP1967_IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev Returns the implementation of upgradeable contracts following EIP1697
    function _imp(address _tgt) internal view returns (address) {
        return address(uint160(uint256(vm.load(_tgt, EIP1967_IMPLEMENTATION_SLOT))));
    }
}
