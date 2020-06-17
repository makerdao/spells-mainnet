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

import {DssSpell, SpellAction} from "./KNC-Kovan-Spell.sol";

contract MedianAbstract {
    function bud(address) public view returns (uint256);
}

contract Hevm { function warp(uint) public; }

contract DssSpellTest is DSTest, DSMath {

    // Replace with mainnet spell address to test against live
    address constant MAINNET_SPELL = address(0);

    uint256 constant THOUSAND = 10**3;
    uint256 constant MILLION = 10**6;

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

    DSPauseAbstract pause   = DSPauseAbstract(0x8754E6ecb4fe68DaA5132c2886aB39297a5c7189);
    address pauseProxy      = 0x0e4725db88Bb038bBa4C4723e91Ba183BE11eDf3;
    DSChiefAbstract chief   = DSChiefAbstract(0xbBFFC76e94B34F72D96D054b31f6424249c1337d);
    VatAbstract     vat     = VatAbstract(0xbA987bDB501d131f766fEe8180Da5d81b34b69d9);
    CatAbstract     cat     = CatAbstract(0x0511674A67192FE51e86fE55Ed660eB4f995BDd6);
    VowAbstract     vow     = VowAbstract(0x0F4Cbe6CBA918b7488C26E29d9ECd7368F38EA3b);
    PotAbstract     pot     = PotAbstract(0xEA190DBDC7adF265260ec4dA6e9675Fd4f5A78bb);
    JugAbstract     jug     = JugAbstract(0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD);
    SpotAbstract   spot     = SpotAbstract(0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D);
    MKRAbstract     gov     = MKRAbstract(0xAaF64BFCC32d0F15873a02163e7E500671a4ffcD);
    SaiTubAbstract  tub     = SaiTubAbstract(0xa71937147b55Deb8a530C7229C442Fd3F31b7db2);
    GemJoinAbstract kJoin   = GemJoinAbstract(0xF97Ef6cb76c5E27c79703683daA4A4166116c95f);
    EndAbstract     end     = EndAbstract(0x24728AcF2E2C403F5d2db4Df6834B8998e56aA5F);
    GemAbstract     knc     = GemAbstract(0xad67cB4d63C9da94AcA37fDF2761AaDF780ff4a2);
    address    flipperMom   = 0xf3828caDb05E5F22844f6f9314D99516D68a0C84;
    OsmAbstract    kPip     = OsmAbstract(0x4C511ae3FFD63c0DE35D4A138Ff2b584FF450466);
    address      osmMom     = 0x5dA9D1C3d4f1197E5c52Ff963916Fe84D2F5d8f3;

    

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

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        spell = MAINNET_SPELL != address(0) ? DssSpell(MAINNET_SPELL) : new DssSpell();
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

    function testSpellIsCast() public {
        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());

        (address aux, uint256 chop, uint256 lump) = cat.ilks("KNC-A");
        FlipAbstract kFlip = FlipAbstract(aux);

        // Authorization
        assertEq(kJoin.wards(pauseProxy), 1);
        assertEq(vat.wards(address(kJoin)), 1);
        assertEq(kFlip.wards(address(cat)), 1);
        assertEq(kFlip.wards(address(end)), 1);
        assertEq(kFlip.wards(flipperMom), 1);
        assertEq(kPip.wards(osmMom), 1);
        assertEq(kPip.bud(address(spot)), 1);
        assertEq(MedianAbstract(kPip.src()).bud(address(kPip)), 1);

        // Start testing Vault

        // Join to adapter
        assertEq(knc.balanceOf(address(this)), 0.25 * 10 ** 8);
        assertEq(vat.gem("KNC-A", address(this)), 0);
        knc.approve(address(kJoin), 0.25 * 10 ** 8);
        kJoin.join(address(this), 0.25 * 10 ** 8);
        assertEq(knc.balanceOf(address(this)), 0);
        assertEq(vat.gem("KNC-A", address(this)), 0.25 * 10 ** 18);

        hevm.warp(now + 5000);

        kPip.poke();
        spot.poke("KNC-A");

        // Deposit collateral, generate DAI
        assertEq(vat.dai(address(this)), 0);
        vat.frob("KNC-A", address(this), address(this), address(this), int(0.25 * 10 ** 18), int(25 * 10 ** 18));
        assertEq(vat.gem("KNC-A", address(this)), 0);
        assertEq(vat.dai(address(this)), 25 * RAD);

        // Payback DAI, withdraw collateral
        vat.frob("KNC-A", address(this), address(this), address(this), -int(0.25 * 10 ** 18), -int(25 * 10 ** 18));
        assertEq(vat.gem("KNC-A", address(this)), 0.25 * 10 ** 18);
        assertEq(vat.dai(address(this)), 0);

        // Withdraw from adapter
        kJoin.exit(address(this), 0.25 * 10 ** 8);
        assertEq(knc.balanceOf(address(this)), 0.25 * 10 ** 8);
        assertEq(vat.gem("KNC-A", address(this)), 0);

        // Generate new DAI to force a liquidation
        knc.approve(address(kJoin), 0.25 * 10 ** 8);
        kJoin.join(address(this), 0.25 * 10 ** 8);
        (, uint256 rateV, uint256 spotV,,) = vat.ilks("KNC-A");
        vat.frob("KNC-A", address(this), address(this), address(this), int(0.25 * 10 ** 18), int(0.25 * 10 ** 18 * spotV / rateV)); // Max amount of DAI
        hevm.warp(now + 100);
        jug.drip("KNC-A");
        assertEq(kFlip.kicks(), 0);
        cat.bite("KNC-A", address(this));
        assertEq(kFlip.kicks(), 1);
    }
}
