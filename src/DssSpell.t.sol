pragma solidity 0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssSpell, SpellAction} from "./DssSpell.sol";

interface Hevm {
    function warp(uint) external;
    function store(address,bytes32,bytes32) external;
}

interface USDTAbstract {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external;               // nonstandard
    function transfer(address, uint256) external;              // nonstandard
    function transferFrom(address, address, uint256) external; // nonstandard
}

contract DssSpellTest is DSTest, DSMath {
    // populate with mainnet spell if needed
    address constant MAINNET_SPELL = address(0);
    // this needs to be updated
    uint256 constant SPELL_CREATED = 1599139568;

    struct CollateralValues {
        uint256 line;
        uint256 dust;
        uint256 duty;
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
        uint256 pot_dsrPct;
        uint256 vat_Line;
        uint256 pause_delay;
        uint256 vow_wait;
        uint256 vow_dump;
        uint256 vow_sump;
        uint256 vow_bump;
        uint256 vow_hump;
        uint256 cat_box;
        mapping (bytes32 => CollateralValues) collaterals;
    }

    SystemValues afterSpell;

    Hevm hevm;

    // MAINNET ADDRESSES
    DSPauseAbstract      pause = DSPauseAbstract(    0xbE286431454714F511008713973d3B053A2d38f3);
    address         pauseProxy =                     0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
    DSChiefAbstract      chief = DSChiefAbstract(    0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    VatAbstract            vat = VatAbstract(        0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    CatAbstract            cat = CatAbstract(        0xa5679C04fc3d9d8b0AaB1F0ab83555b301cA70Ea);
    VowAbstract            vow = VowAbstract(        0xA950524441892A31ebddF91d3cEEFa04Bf454466);
    PotAbstract            pot = PotAbstract(        0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    JugAbstract            jug = JugAbstract(        0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    SpotAbstract          spot = SpotAbstract(       0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);
    FlipperMomAbstract  newMom = FlipperMomAbstract( 0xc4bE7F74Ee3743bDEd8E0fA218ee5cf06397f472);

    DSTokenAbstract        gov = DSTokenAbstract(    0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    EndAbstract            end = EndAbstract(        0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5);
    DSTokenAbstract       weth = DSTokenAbstract(    0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    GemJoinAbstract   wethJoin = GemJoinAbstract(    0x2F0b23f53734252Bda2277357e97e1517d6B042A);
    IlkRegistryAbstract    reg = IlkRegistryAbstract(0x8b4ce5DCbb01e0e1f0521cd8dCfb31B308E52c24);

    OsmMomAbstract      osmMom = OsmMomAbstract(     0x76416A4d5190d071bfed309861527431304aA14f);
    FlipperMomAbstract flipMom = FlipperMomAbstract( 0xc4bE7F74Ee3743bDEd8E0fA218ee5cf06397f472);

    // USDT-A specific
    USDTAbstract usdt            = USDTAbstract(     0xdAC17F958D2ee523a2206206994597C13D831ec7);
    GemJoinAbstract joinUSDTA    = GemJoinAbstract(  0x0Ac6A1D74E84C2dF9063bDDc31699FF2a2BB22A2);
    OsmAbstract pipUSDT          = OsmAbstract(      0x7a5918670B0C390aD25f7beE908c1ACc2d314A3C);
    FlipAbstract flipUSDTA       = FlipAbstract(     0x667F41d0fDcE1945eE0f56A79dd6c142E37fCC26);
    MedianAbstract medUSDTA      = MedianAbstract(   0x56D4bBF358D7790579b55eA6Af3f605BcA2c0C3A);

    // PAXUSD-A specific
    GemAbstract      paxusd      = GemAbstract(      0x8E870D67F660D95d5be530380D0eC0bd388289E1);
    GemJoinAbstract  joinPAXUSDA = GemJoinAbstract(  0x7e62B7E279DFC78DEB656E34D6a435cC08a44666);
    DSValueAbstract    pipPAXUSD = DSValueAbstract(  0x043B963E1B2214eC90046167Ea29C2c8bDD7c0eC);
    FlipAbstract     flipPAXUSDA = FlipAbstract(     0x52D5D1C05CC79Fc24A629Cb24cB06C5BE5d766E7);


    // lightfeed addresses
    address constant ARGENT     = 0x130431b4560Cd1d74A990AE86C337a33171FF3c6;
    address constant MYCRYPTO   = 0x3CB645a8f10Fb7B0721eaBaE958F77a878441Cb9;

	MedianAbstract BATUSD = MedianAbstract(0x18B4633D6E39870f398597f3c1bA8c4A41294966);
    MedianAbstract BTCUSD = MedianAbstract(0xe0F30cb149fAADC7247E953746Be9BbBB6B5751f);
    MedianAbstract ETHBTC = MedianAbstract(0x81A679f98b63B3dDf2F17CB5619f4d6775b3c5ED);
    MedianAbstract ETHUSD = MedianAbstract(0x64DE91F5A373Cd4c28de3600cB34C7C6cE410C85);
    MedianAbstract KNCUSD = MedianAbstract(0x83076a2F42dc1925537165045c9FDe9A4B71AD97);
    MedianAbstract ZRXUSD = MedianAbstract(0x956ecD6a9A9A0d84e8eB4e6BaaC09329E202E55e);
    MedianAbstract MANAUSD = MedianAbstract(0x681c4F8f69cF68852BAd092086ffEaB31F5B812c);

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

        //
        // Test for all system configuration changes
        //
        afterSpell = SystemValues({
            pot_dsr: 1000000000000000000000000000,
            pot_dsrPct: 0 * 1000,
            vat_Line: 763 * MILLION * RAD,
            pause_delay: 12 * 60 * 60,
            vow_wait: 561600,
            vow_dump: 250 * WAD,
            vow_sump: 50000 * RAD,
            vow_bump: 10000 * RAD,
            vow_hump: 2 * MILLION * RAD,
            cat_box: 10 * MILLION * RAD
        });

        //
        // Test for all collateral based changes here
        //
        afterSpell.collaterals["ETH-A"] = CollateralValues({
            line:         540 * MILLION * RAD,
            dust:         100 * RAD,
            duty:         1000000000000000000000000000,
            pct:          0 * 1000,
            chop:         113 * WAD / 100,
            dunk:         50 * THOUSAND * RAD,
            mat:          150 * RAY / 100,
            beg:          103 * WAD / 100,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["BAT-A"] = CollateralValues({
            line:         5 * MILLION * RAD,
            dust:         100 * RAD,
            duty:         1000000000627937192491029810,
            pct:          2 * 1000,
            chop:         113 * WAD / 100,
            dunk:         50 * THOUSAND * RAD,
            mat:          150 * RAY / 100,
            beg:          103 * WAD / 100,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["USDC-A"] = CollateralValues({
            line:         40 * MILLION * RAD,
            dust:         100 * RAD,
            duty:         1000000000627937192491029810,
            pct:          2 * 1000,
            chop:         113 * WAD / 100,
            dunk:         50 * THOUSAND * RAD,
            mat:          110 * RAY / 100,
            beg:          103 * WAD / 100,
            ttl:          6 hours,
            tau:          3 days,
            liquidations: 0
        });
        afterSpell.collaterals["USDC-B"] = CollateralValues({
            line:         30 * MILLION * RAD,
            dust:         100 * RAD,
            duty:         1000000012431573129530493155,
            pct:          48 * 1000,
            chop:         113 * WAD / 100,
            dunk:         50 * THOUSAND * RAD,
            mat:          120 * RAY / 100,
            beg:          103 * WAD / 100,
            ttl:          6 hours,
            tau:          3 days,
            liquidations: 0
        });
        afterSpell.collaterals["WBTC-A"] = CollateralValues({
            line:         120 * MILLION * RAD,
            dust:         100 * RAD,
            duty:         1000000000627937192491029810,
            pct:          2 * 1000,
            chop:         113 * WAD / 100,
            dunk:         50 * THOUSAND * RAD,
            mat:          150 * RAY / 100,
            beg:          103 * WAD / 100,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["TUSD-A"] = CollateralValues({
            line:         2 * MILLION * RAD,
            dust:         100 * RAD,
            duty:         1000000000000000000000000000,
            pct:          0 * 1000,
            chop:         113 * WAD / 100,
            dunk:         50 * THOUSAND * RAD,
            mat:          120 * RAY / 100,
            beg:          103 * WAD / 100,
            ttl:          6 hours,
            tau:          3 days,
            liquidations: 0
        });
        afterSpell.collaterals["KNC-A"] = CollateralValues({
            line:         5 * MILLION * RAD,
            dust:         100 * RAD,
            duty:         1000000000627937192491029810,
            pct:          2 * 1000,
            chop:         113 * WAD / 100,
            dunk:         50 * THOUSAND * RAD,
            mat:          175 * RAY / 100,
            beg:          103 * WAD / 100,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["ZRX-A"] = CollateralValues({
            line:         5 * MILLION * RAD,
            dust:         100 * RAD,
            duty:         1000000000627937192491029810,
            pct:          2 * 1000,
            chop:         113 * WAD / 100,
            dunk:         50 * THOUSAND * RAD,
            mat:          175 * RAY / 100,
            beg:          103 * WAD / 100,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["MANA-A"] = CollateralValues({
            line:         1 * MILLION * RAD,
            dust:         100 * RAD,
            duty:         1000000003022265980097387650,
            pct:          10 * 1000,
            chop:         113 * WAD / 100,
            dunk:         50 * THOUSAND * RAD,
            mat:          175 * RAY / 100,
            beg:          103 * WAD / 100,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["USDT-A"] = CollateralValues({
            line:         10 * MILLION * RAD,
            dust:         100 * RAD,
            duty:         1000000001847694957439350562, // 6% SF w/ base
            pct:          6 * 1000,
            chop:         113 * WAD / 100,
            dunk:         50 * THOUSAND * RAD,
            mat:          150 * RAY / 100,
            beg:          103 * WAD / 100,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 1
        });
        afterSpell.collaterals["PAXUSD-A"] = CollateralValues({
            line:         5 * MILLION * RAD,
            dust:         100 * RAD,
            duty:         1000000000627937192491029810, // 2% SF w/ base
            pct:          2 * 1000,
            chop:         113 * WAD / 100,
            dunk:         50 * THOUSAND * RAD,
            mat:          120 * RAY / 100,
            beg:          103 * WAD / 100,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 0
        });
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

    function scheduleWaitAndCastFailDay() public {
        spell.schedule();

        uint castTime = now + pause.delay();
        uint day = (castTime / 1 days + 3) % 7;
        if (day < 5) {
            castTime += 5 days - day * 86400;
        }

        hevm.warp(castTime);
        spell.cast();
    }

    function scheduleWaitAndCastFailEarly() public {
        spell.schedule();

        uint castTime = now + pause.delay() + 24 hours;
        uint hour = castTime / 1 hours % 24;
        if (hour >= 14) {
            castTime -= hour * 3600 - 13 hours;
        }

        hevm.warp(castTime);
        spell.cast();
    }

    function scheduleWaitAndCastFailLate() public {
        spell.schedule();

        uint castTime = now + pause.delay();
        uint hour = castTime / 1 hours % 24;
        if (hour < 21) {
            castTime += 21 hours - hour * 3600;
        }

        hevm.warp(castTime);
        spell.cast();
    }

    function scheduleWaitAndCast() public {
        spell.schedule();
        hevm.warp(1599573601);
        spell.cast();
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function checkSystemValues(SystemValues storage values) internal {
        // dsr
        assertEq(pot.dsr(), values.pot_dsr);
        // make sure dsr is less than 100% APR
        // bc -l <<< 'scale=27; e( l(2.00)/(60 * 60 * 24 * 365) )'
        // 1000000021979553151239153027
        assertTrue(
            pot.dsr() >= RAY && pot.dsr() < 1000000021979553151239153027
        );
        assertTrue(diffCalc(expectedRate(values.pot_dsrPct), yearlyYield(values.pot_dsr)) <= TOLERANCE);

        // Line
        assertEq(vat.Line(), values.vat_Line);
        assertTrue(
            (vat.Line() >= RAD && vat.Line() < BILLION * RAD) ||
            vat.Line() == 0
        );

        // Pause delay
        assertEq(pause.delay(), values.pause_delay);

        // wait
        assertEq(vow.wait(), values.vow_wait);

        // dump
        assertEq(vow.dump(), values.vow_dump);
        assertTrue(
            (vow.dump() >= WAD && vow.dump() < 2 * THOUSAND * WAD) ||
            vow.dump() == 0
        );

        // sump
        assertEq(vow.sump(), values.vow_sump);
        assertTrue(
            (vow.sump() >= RAD && vow.sump() < 500 * THOUSAND * RAD) ||
            vow.sump() == 0
        );

        // bump
        assertEq(vow.bump(), values.vow_bump);
        assertTrue(
            (vow.bump() >= RAD && vow.bump() < HUNDRED * THOUSAND * RAD) ||
            vow.bump() == 0
        );

        // hump
        assertEq(vow.hump(), values.vow_hump);
        assertTrue(
            (vow.hump() >= RAD && vow.hump() < HUNDRED * MILLION * RAD) ||
            vow.hump() == 0
        );
    }

    function checkCollateralValues(bytes32 ilk, SystemValues storage values) internal {
        (uint duty,)  = jug.ilks(ilk);
        assertEq(duty,   values.collaterals[ilk].duty);
        // make sure duty is less than 1000% APR
        // bc -l <<< 'scale=27; e( l(10.00)/(60 * 60 * 24 * 365) )'
        // 1000000073014496989316680335
        assertTrue(duty >= RAY && duty < 1000000073014496989316680335);  // gt 0 and lt 1000%
        assertTrue(diffCalc(expectedRate(values.collaterals[ilk].pct), yearlyYield(values.collaterals[ilk].duty)) <= TOLERANCE);
        assertTrue(values.collaterals[ilk].pct < THOUSAND * THOUSAND);   // check value lt 1000%

        (,,, uint line, uint dust) = vat.ilks(ilk);
        assertEq(line, values.collaterals[ilk].line);
        assertTrue((line >= RAD && line < BILLION * RAD) || line == 0);  // eq 0 or gt eq 1 RAD and lt 1B
        assertEq(dust, values.collaterals[ilk].dust);
        assertTrue((dust >= RAD && dust < 10 * THOUSAND * RAD) || dust == 0); // eq 0 or gt eq 1 and lt 10k

        (, uint chop, uint dunk) = cat.ilks(ilk);
        assertEq(chop, values.collaterals[ilk].chop);
        // make sure chop is less than 100%
        assertTrue(chop >= WAD && chop < 2 * WAD);   // penalty gt eq 0% and lt 100%
        assertEq(dunk, values.collaterals[ilk].dunk);
        // put back in after LIQ-1.2
        assertTrue(dunk >= RAD && dunk < MILLION * RAD);

        (,uint mat) = spot.ilks(ilk);
        assertEq(mat, values.collaterals[ilk].mat);
        assertTrue(mat >= RAY && mat < 10 * RAY);    // cr eq 100% and lt 1000%

        (address flipper,,) = cat.ilks(ilk);
        FlipAbstract flip = FlipAbstract(flipper);
        assertEq(uint(flip.beg()), values.collaterals[ilk].beg);
        assertTrue(flip.beg() >= WAD && flip.beg() < 105 * WAD / 100);  // gt eq 0% and lt 5%
        assertEq(uint(flip.ttl()), values.collaterals[ilk].ttl);
        assertTrue(flip.ttl() >= 600 && flip.ttl() < 10 hours);         // gt eq 10 minutes and lt 10 hours
        assertEq(uint(flip.tau()), values.collaterals[ilk].tau);
        assertTrue(flip.tau() >= 600 && flip.tau() <= 3 days);          // gt eq 10 minutes and lt eq 3 days

        assertEq(flip.wards(address(cat)), values.collaterals[ilk].liquidations);  // liquidations == 1 => on
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

        bytes32[] memory ilks = reg.list();
        for(uint i = 0; i < ilks.length; i++) {
            checkCollateralValues(ilks[i],  afterSpell);
        }

        // argent oracle assertions
        assertEq(BATUSD.orcl(ARGENT), 1);
        assertEq(BTCUSD.orcl(ARGENT), 1);
        assertEq(ETHBTC.orcl(ARGENT), 1);
        assertEq(ETHUSD.orcl(ARGENT), 1);
        assertEq(KNCUSD.orcl(ARGENT), 1);
        assertEq(ZRXUSD.orcl(ARGENT), 1);
        assertEq(medUSDTA.orcl(ARGENT), 1);
        assertEq(MANAUSD.orcl(ARGENT), 1);

        // mycrypto oracle assertions
        assertEq(BATUSD.orcl(MYCRYPTO), 1);
        assertEq(BTCUSD.orcl(MYCRYPTO), 1);
        assertEq(ETHBTC.orcl(MYCRYPTO), 1);
        assertEq(ETHUSD.orcl(MYCRYPTO), 1);
        assertEq(KNCUSD.orcl(MYCRYPTO), 1);
        assertEq(ZRXUSD.orcl(MYCRYPTO), 1);
        assertEq(medUSDTA.orcl(MYCRYPTO), 1);
        assertEq(MANAUSD.orcl(MYCRYPTO), 1);
    }

    function testSpellIsCast_USDTA_INTEGRATION() public {
        vote();
        scheduleWaitAndCast();
        // spell done
        assertTrue(spell.done());

        pipUSDT.poke();
        hevm.warp(now + 3601);
        pipUSDT.poke();
        spot.poke("USDT-A");

        hevm.store(
            address(usdt),
            keccak256(abi.encode(address(this), uint256(2))),
            bytes32(uint256(600 * 10 ** 6))
        );

        // check median matches pip.src()
        assertEq(pipUSDT.src(), address(medUSDTA));

        // Authorization
        assertEq(joinUSDTA.wards(pauseProxy), 1);
        assertEq(vat.wards(address(joinUSDTA)), 1);
        assertEq(flipUSDTA.wards(address(end)), 1);
        assertEq(flipUSDTA.wards(address(flipMom)), 1);
        assertEq(pipUSDT.wards(address(osmMom)), 1);
        assertEq(pipUSDT.bud(address(spot)), 1);
        assertEq(pipUSDT.bud(address(end)), 1);
        assertEq(MedianAbstract(pipUSDT.src()).bud(address(pipUSDT)), 1);

        // Join to adapter
        assertEq(usdt.balanceOf(address(this)), 600 * 10 ** 6);
        assertEq(vat.gem("USDT-A", address(this)), 0);
        usdt.approve(address(joinUSDTA), 600 * 10 ** 6);
        joinUSDTA.join(address(this), 600 * 10 ** 6);
        assertEq(usdt.balanceOf(address(this)), 0);
        assertEq(vat.gem("USDT-A", address(this)), 600 * WAD);

        // Deposit collateral, generate DAI
        assertEq(vat.dai(address(this)), 0);
        vat.frob("USDT-A", address(this), address(this), address(this), int(600 * WAD), int(100 * WAD));
        assertEq(vat.gem("USDT-A", address(this)), 0);
        assertEq(vat.dai(address(this)), 100 * RAD);

        // Payback DAI, withdraw collateral
        vat.frob("USDT-A", address(this), address(this), address(this), -int(600 * WAD), -int(100 * WAD));
        assertEq(vat.gem("USDT-A", address(this)), 600 * WAD);
        assertEq(vat.dai(address(this)), 0);

        // Withdraw from adapter
        joinUSDTA.exit(address(this), 600 * 10 ** 6);
        assertEq(usdt.balanceOf(address(this)), 600 * 10 ** 6);
        assertEq(vat.gem("USDT-A", address(this)), 0);

        // Generate new DAI to force a liquidation
        usdt.approve(address(joinUSDTA), 600 * 10 ** 6);
        joinUSDTA.join(address(this), 600 * 10 ** 6);
        (,,uint256 spotV,,) = vat.ilks("USDT-A");
        // dart max amount of DAI
        vat.frob("USDT-A", address(this), address(this), address(this), int(600 * WAD), int(mul(600 * WAD, spotV) / RAY));
        hevm.warp(now + 1);
        jug.drip("USDT-A");
        assertEq(flipUSDTA.kicks(), 0);
        cat.bite("USDT-A", address(this));
        assertEq(flipUSDTA.kicks(), 1);
    }

    function testSpellIsCast_PAXUSDA_INTEGRATION() public {
        vote();
        scheduleWaitAndCast();
        // spell done
        assertTrue(spell.done());

        // Authorization

        assertEq(joinPAXUSDA.wards(pauseProxy), 1);
        assertEq(vat.wards(address(joinPAXUSDA)), 1);
        assertEq(flipPAXUSDA.wards(address(end)), 1);
        assertEq(flipPAXUSDA.wards(address(flipMom)), 1);

        // Join to adapter
        hevm.store(
            address(paxusd),
            keccak256(abi.encode(address(this), uint256(1))),
            bytes32(uint256(600 * WAD))
        );
        assertEq(paxusd.balanceOf(address(this)), 600 * WAD);
        assertEq(vat.gem("PAXUSD-A", address(this)), 0);
        paxusd.approve(address(joinPAXUSDA), 600 * WAD);
        joinPAXUSDA.join(address(this), 600 * WAD);
        assertEq(paxusd.balanceOf(address(this)), 0);
        assertEq(vat.gem("PAXUSD-A", address(this)), 600 * WAD);

        // Deposit collateral, generate DAI
        assertEq(vat.dai(address(this)), 0);
        vat.frob("PAXUSD-A", address(this), address(this), address(this), int(600 * WAD), int(100 * WAD));
        assertEq(vat.gem("PAXUSD-A", address(this)), 0);
        assertEq(vat.dai(address(this)), 100 * RAD);

        // Payback DAI, withdraw collateral
        vat.frob("PAXUSD-A", address(this), address(this), address(this), -int(600 * WAD), -int(100 * WAD));
        assertEq(vat.gem("PAXUSD-A", address(this)), 600 * WAD);
        assertEq(vat.dai(address(this)), 0);

        // Withdraw from adapter
        joinPAXUSDA.exit(address(this), 600 * 10 ** 18);
        assertEq(paxusd.balanceOf(address(this)), 600 * 10 ** 18);
        assertEq(vat.gem("PAXUSD-A", address(this)), 0);
    }
}
