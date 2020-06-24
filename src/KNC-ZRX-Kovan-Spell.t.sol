// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
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

pragma solidity 0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssSpell, SpellAction} from "./KNC-ZRX-Kovan-Spell.sol";

contract MedianAbstract {
    function bud(address) public view returns (uint256);
}

contract Hevm { function warp(uint) public; }

contract DssSpellTest is DSTest, DSMath {

    // Replace with mainnet spell address to test against live
    address constant MAINNET_SPELL = address(0);

    uint256 constant THOUSAND = 10**3;
    uint256 constant MILLION = 10**6;
    uint256 constant WAD = 10**18;

    uint256 constant public ZERO_PCT_RATE = 1000000000000000000000000000;
    uint256 constant public ONE_PCT_RATE =  1000000000315522921573372069;

    struct CollateralValues {
        uint256 line;
        uint256 dust;
        uint256 duty;
        uint256 chop;
        uint256 lump;
        uint256 pct;
        uint256 mat;
        uint256 beg;
        uint48  ttl;
        uint48  tau;
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

    DSPauseAbstract        pause = DSPauseAbstract(0x8754E6ecb4fe68DaA5132c2886aB39297a5c7189);
    address           pauseProxy = 0x0e4725db88Bb038bBa4C4723e91Ba183BE11eDf3;
    DSChiefAbstract        chief = DSChiefAbstract(0xbBFFC76e94B34F72D96D054b31f6424249c1337d);
    VatAbstract              vat = VatAbstract(0xbA987bDB501d131f766fEe8180Da5d81b34b69d9);
    CatAbstract              cat = CatAbstract(0x0511674A67192FE51e86fE55Ed660eB4f995BDd6);
    VowAbstract              vow = VowAbstract(0x0F4Cbe6CBA918b7488C26E29d9ECd7368F38EA3b);
    PotAbstract              pot = PotAbstract(0xEA190DBDC7adF265260ec4dA6e9675Fd4f5A78bb);
    JugAbstract              jug = JugAbstract(0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD);
    SpotAbstract            spot = SpotAbstract(0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D);
    MKRAbstract              gov = MKRAbstract(0xAaF64BFCC32d0F15873a02163e7E500671a4ffcD);
    SaiTubAbstract           tub = SaiTubAbstract(0xa71937147b55Deb8a530C7229C442Fd3F31b7db2);
    EndAbstract              end = EndAbstract(0x24728AcF2E2C403F5d2db4Df6834B8998e56aA5F);
    address           flipperMom = 0xf3828caDb05E5F22844f6f9314D99516D68a0C84;
    address               osmMom = 0x5dA9D1C3d4f1197E5c52Ff963916Fe84D2F5d8f3;

    GemAbstract              knc = GemAbstract(0x9800a0a3c7e9682e1AEb7CAA3200854eFD4E9327);
    GemJoinAbstract        kJoin = GemJoinAbstract(0xE42427325A0e4c8e194692FfbcACD92C2C381598);
    FlipAbstract           kFlip = FlipAbstract(0xf14Ec3538C86A31bBf576979783a8F6dbF16d571);
    OsmAbstract             kPip = OsmAbstract(0x10799280EF9d7e2d037614F5165eFF2cB8522651);

    GemAbstract              zrx = GemAbstract(0xC2C08A566aD44129E69f8FC98684EAA28B01a6e7);
    GemJoinAbstract        zJoin = GemJoinAbstract(0x85D38fF6a6FCf98bD034FB5F9D72cF15e38543f2);
    FlipAbstract           zFlip = FlipAbstract(0x1341E0947D03Fd2C24e16aaEDC347bf9D9af002F);
    OsmAbstract             zPip = OsmAbstract(0x218037a42947E634191A231fcBAEAE8b16a39b3f);

    OsmAbstract             wPip = OsmAbstract(0x2f38a1bD385A9B395D01f2Cbf767b4527663edDB);

    DssSpell spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    // not provided in DSMath
    uint constant RAD = 10 ** 45;
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

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        spell = MAINNET_SPELL != address(0) ? DssSpell(MAINNET_SPELL) : new DssSpell();

        afterSpell = SystemValues({
            dsr:        1000000000000000000000000000,
            dsrPct:     0 * 1000,
            Line:       122 * MILLION * RAD,
            pauseDelay: 60
        });
        afterSpell.collaterals["KNC-A"] = CollateralValues({
            line: 10 * MILLION * RAD,
            dust: 20 * RAD,
            duty: ONE_PCT_RATE,
            pct:  1 * 1000,
            chop: 113 * RAY / 100,
            lump: 1 * WAD,
            mat:  150 * RAY / 100,
            beg:  103 * WAD / 100,
            ttl:  6 hours,
            tau:  6 hours
        });
        afterSpell.collaterals["ZRX-A"] = CollateralValues({
            line: 10 * MILLION * RAD,
            dust: 20 * RAD,
            duty: ONE_PCT_RATE,
            pct:  1 * 1000,
            chop: 113 * RAY / 100,
            lump: 1 * WAD,
            mat:  150 * RAY / 100,
            beg:  103 * WAD / 100,
            ttl:  6 hours,
            tau:  6 hours
        });

    }

    function vote() private {
        if (chief.hat() != address(spell)) {
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

    function yearlyYield(uint256 duty) public pure returns (uint256) {
        return rpow(duty, (365 * 24 * 60 * 60), RAY);
    }

    function expectedRate(uint256 percentValue) public pure returns (uint256) {
        return (100000 + percentValue) * (10 ** 22);
    }

    function diffCalc(uint256 expectedRate_, uint256 yearlyYield_) public pure returns (uint256) {
        return (expectedRate_ > yearlyYield_) ? expectedRate_ - yearlyYield_ : yearlyYield_ - expectedRate_;
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

    function checkCollateralValues(bytes32 ilk, SystemValues storage values, FlipAbstract flip) internal {
        (uint duty,) = jug.ilks(ilk);
        assertEq(duty, values.collaterals[ilk].duty);
        assertTrue(diffCalc(expectedRate(values.collaterals[ilk].pct), yearlyYield(values.collaterals[ilk].duty)) <= TOLERANCE);

        (,,, uint256 line, uint256 dust) = vat.ilks(ilk);
        assertEq(line, values.collaterals[ilk].line);
        assertEq(dust, values.collaterals[ilk].dust);

        (, uint256 chop, uint256 lump) = cat.ilks(ilk);
        assertEq(chop, values.collaterals[ilk].chop);
        assertEq(lump, values.collaterals[ilk].lump);

        (,uint256 mat) = spot.ilks(ilk);
        assertEq(mat, values.collaterals[ilk].mat);

        // Commented out because FlipFab is used on Kovan
        assertEq(uint256(flip.beg()), values.collaterals[ilk].beg);
        assertEq(uint256(flip.ttl()), values.collaterals[ilk].ttl);
        assertEq(uint256(flip.tau()), values.collaterals[ilk].tau);
    }

    function testSpellIsCast() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        // Test description
        string memory description = new SpellAction().description();
        assertTrue(bytes(description).length > 0);
        // DS-Test can't handle strings directly, so cast to a bytes32.
        assertEq(stringToBytes32(spell.description()), stringToBytes32(description));

        // General System values
        checkSystemValues(afterSpell);

        // Collateral values
        checkCollateralValues("KNC-A", afterSpell, kFlip);
        checkCollateralValues("ZRX-A", afterSpell, zFlip);

        // Check previously missing WBTC permission is now set
        assertEq(wPip.bud(address(end)), 1);
    }

    function testNewCollateralKNC() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        // Authorization
        assertEq(kJoin.wards(pauseProxy), 1);
        assertEq(vat.wards(address(kJoin)), 1);
        assertEq(kFlip.wards(address(cat)), 1);
        assertEq(kFlip.wards(address(end)), 1);
        assertEq(kFlip.wards(flipperMom), 1);
        assertEq(kPip.wards(osmMom), 1);
        assertEq(kPip.bud(address(spot)), 1);
        assertEq(kPip.bud(address(end)), 1);
        assertEq(MedianAbstract(kPip.src()).bud(address(kPip)), 1);

        // Start testing Vault

        // Join to adapter
        assertEq(address(this), 0xdB33dFD3D61308C33C63209845DaD3e6bfb2c674);
        assertEq(knc.balanceOf(address(this)), 10000 * WAD);
        assertEq(vat.gem("KNC-A", address(this)), 0);
        knc.approve(address(kJoin), 10000 * WAD);
        kJoin.join(address(this), 10000 * WAD);
        assertEq(knc.balanceOf(address(this)), 0);
        assertEq(vat.gem("KNC-A", address(this)), 10000 * WAD); 

        hevm.warp(now + 5000);
        spot.poke("KNC-A");

        // Deposit collateral, generate DAI
        assertEq(vat.dai(address(this)), 0);
        vat.frob("KNC-A", address(this), address(this), address(this), int(10000 * WAD), int(500 * WAD));
        assertEq(vat.gem("KNC-A", address(this)), 0);
        assertEq(vat.dai(address(this)), 500 * RAD);

        // Payback DAI, withdraw collateral
        vat.frob("KNC-A", address(this), address(this), address(this), -int(10000 * WAD), -int(500 * WAD));
        assertEq(vat.gem("KNC-A", address(this)), 10000 * WAD);
        assertEq(vat.dai(address(this)), 0);

        // Withdraw from adapter
        kJoin.exit(address(this), 10000 * WAD);
        assertEq(knc.balanceOf(address(this)), 10000 * WAD);
        assertEq(vat.gem("KNC-A", address(this)), 0);

        // Generate new DAI to force a liquidation
        knc.approve(address(kJoin), 10000 * WAD);
        kJoin.join(address(this), 10000 * WAD);
        (, uint256 rateV, uint256 spotV,,) = vat.ilks("KNC-A");
        vat.frob("KNC-A", address(this), address(this), address(this), int(10000 * WAD), int(10000 * WAD * spotV / rateV)); // Max amount of DAI
        hevm.warp(now + 100);
        jug.drip("KNC-A");
        assertEq(kFlip.kicks(), 0);
        cat.bite("KNC-A", address(this));
        assertEq(kFlip.kicks(), 1);
    }

    function testNewCollateralZRX() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        // Authorization
        assertEq(zJoin.wards(pauseProxy), 1);
        assertEq(vat.wards(address(zJoin)), 1);
        assertEq(zFlip.wards(address(cat)), 1);
        assertEq(zFlip.wards(address(end)), 1);
        assertEq(zFlip.wards(flipperMom), 1);
        assertEq(zPip.wards(osmMom), 1);
        assertEq(zPip.bud(address(spot)), 1);
        assertEq(zPip.bud(address(end)), 1);
        assertEq(MedianAbstract(zPip.src()).bud(address(zPip)), 1);

        // Start testing Vault

        // Join to adapter
        assertEq(address(this), 0xdB33dFD3D61308C33C63209845DaD3e6bfb2c674);
        assertEq(zrx.balanceOf(address(this)), 10000 * WAD);
        assertEq(vat.gem("ZRX-A", address(this)), 0);
        zrx.approve(address(zJoin), 10000 * WAD);
        zJoin.join(address(this), 10000 * WAD);
        assertEq(zrx.balanceOf(address(this)), 0);
        assertEq(vat.gem("ZRX-A", address(this)), 10000 * WAD);

        hevm.warp(now + 5000);
        spot.poke("ZRX-A");

        // Deposit collateral, generate DAI
        assertEq(vat.dai(address(this)), 0);
        vat.frob("ZRX-A", address(this), address(this), address(this), int(10000 * WAD), int(500 * WAD));
        assertEq(vat.gem("ZRX-A", address(this)), 0);
        assertEq(vat.dai(address(this)), 500 * RAD);

        // Payback DAI, withdraw collateral
        vat.frob("ZRX-A", address(this), address(this), address(this), -int(10000 * WAD), -int(500 * WAD));
        assertEq(vat.gem("ZRX-A", address(this)), 10000 * WAD);
        assertEq(vat.dai(address(this)), 0);

        // Withdraw from adapter
        zJoin.exit(address(this), 10000 * WAD);
        assertEq(zrx.balanceOf(address(this)), 10000 * WAD);
        assertEq(vat.gem("ZRX-A", address(this)), 0);

        // Generate new DAI to force a liquidation
        zrx.approve(address(zJoin), 10000 * WAD);
        zJoin.join(address(this), 10000 * WAD);
        (, uint256 rateV, uint256 spotV,,) = vat.ilks("ZRX-A");
        vat.frob("ZRX-A", address(this), address(this), address(this), int(10000 * WAD), int(10000 * WAD * spotV / rateV)); // Max amount of DAI
        hevm.warp(now + 100);
        jug.drip("ZRX-A");
        assertEq(zFlip.kicks(), 0);
        cat.bite("ZRX-A", address(this));
        assertEq(zFlip.kicks(), 1);
    }
}
