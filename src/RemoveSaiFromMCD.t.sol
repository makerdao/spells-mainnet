pragma solidity 0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssSpell, SpellAction} from "./RemoveSaiFromMCD.sol";

contract Hevm { function warp(uint) public; }

contract DssSpellTest is DSTest, DSMath {

    // Replace with mainnet spell address to test against live
    address constant MAINNET_SPELL = address(0);

    bytes32 ilk = "SAI";


    Hevm hevm;

    DSPauseAbstract pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    DSChiefAbstract chief =
        DSChiefAbstract(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    VatAbstract     vat =
        VatAbstract(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    CatAbstract     cat =
        CatAbstract(0x78F2c2AF65126834c51822F56Be0d7469D7A523E);
    PotAbstract     pot =
        PotAbstract(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    JugAbstract     jug =
        JugAbstract(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    EndAbstract     end =
        EndAbstract(0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5);
    MKRAbstract     gov =
        MKRAbstract(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    SaiTubAbstract  tub =
        SaiTubAbstract(0x448a5065aeBB8E423F0896E6c5D525C040f59af3);
    FlipAbstract    saiflip =
        FlipAbstract(0x5432b2f3c0DFf95AA191C45E5cbd539E2820aE72);
    GemJoinAbstract saijoin =
        GemJoinAbstract(0xad37fd42185Ba63009177058208dd1be4b136e6b);
    SpotAbstract    spot =
        SpotAbstract(0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);
    FlipperMomAbstract fmom =
        FlipperMomAbstract(0x9BdDB99625A711bf9bda237044924E34E8570f75);

    DssSpell spell;

    // this spell is intended to run as the MkrAuthority
    function canCall(address, address, bytes4) public pure returns (bool) {
        return true;
    }

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
        // Using the MkrAuthority test address, mint enough MKR to overcome the
        // current hat.
        //gov.mint(address(this), 300000 ether);
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

    function waitAndCast() public {
        hevm.warp(add(now, pause.delay()));
        spell.cast();
    }

    function scheduleWaitAndCast() public {
        spell.schedule();
        hevm.warp(add(now, pause.delay()));
        spell.cast();
    }

    function testSaiRemoval() public {
        spell = MAINNET_SPELL != address(0) ?
            DssSpell(MAINNET_SPELL) : new DssSpell();

        (address spip, uint256 smat) = spot.ilks(ilk);
        assertEq(spip, 0x54003DBf6ae6CBa6DDaE571CcdC34d834b44Ab1e);

        (address cflip, uint256 cchop, uint256 clump) = cat.ilks(ilk);
        assertEq(cflip, 0x5432b2f3c0DFf95AA191C45E5cbd539E2820aE72);

        (uint256 vArt, uint256 vrate, uint256 vspot, uint256 vline, uint256 vdust)
          = vat.ilks(ilk);
        // These are already 0 due to previous actions,
        //   they probabaly don't need to be called.
        assertEq(vline, 0);
        assertEq(vdust, 0);

        assertEq(saijoin.live(), 1);

        assertEq(saiflip.wards(address(cat)), 1);
        assertEq(saiflip.wards(address(end)), 1);
        assertEq(saiflip.wards(address(fmom)), 0);

        vote();
        spell.schedule();
        waitAndCast();

        (spip, smat) = spot.ilks(ilk);
        assertEq(spip, address(0));

        (cflip, cchop, clump) = cat.ilks(ilk);
        assertEq(spip, address(0));

        (vArt, vrate, vspot, vline, vdust) = vat.ilks(ilk);
        assertEq(vline, 0);
        assertEq(vdust, 0);

        assertEq(saijoin.live(), 0);

        assertEq(saiflip.wards(address(cat)), 0);
        assertEq(saiflip.wards(address(end)), 0);
        assertEq(saiflip.wards(address(fmom)), 0);
    }

}
