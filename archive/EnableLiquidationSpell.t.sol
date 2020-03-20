pragma solidity 0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {EnableLiquidationSpell} from "./EnableLiquidationSpell.sol";

contract Hevm {
    function warp(uint256) public;
}

contract EnableLiquidationSpellTest is DSTest, DSMath {
    // populate with mainnet spell if needed
    address constant MAINNET_SPELL = 0xd36DF11cF6855b616a36eAdBcf9290f7953D90FD;

    Hevm hevm;

    // MAINNET ADDRESSES
    DSChiefAbstract chief   = DSChiefAbstract(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    CatAbstract     cat     = CatAbstract(0x78F2c2AF65126834c51822F56Be0d7469D7A523E);
    MKRAbstract     gov     = MKRAbstract(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    FlipAbstract  eflip     = FlipAbstract(0xd8a04F5412223F513DC55F839574430f5EC15531);
    FlipAbstract  bflip     = FlipAbstract(0xaA745404d55f88C108A28c86abE7b5A1E7817c07);
    FlipAbstract  uflip     = FlipAbstract(0xE6ed1d09a19Bd335f051d78D5d22dF3bfF2c28B1);

    EnableLiquidationSpell spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));
    
    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        gov.mint(address(this), uint256(-1) - gov.totalSupply());

        spell = MAINNET_SPELL != address(0) ? EnableLiquidationSpell(MAINNET_SPELL) : new EnableLiquidationSpell();
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

    function testSpellIsCast() public {
        vote();
        spell.cast();

        // spell done
        assertTrue(spell.done());

        assertEq(eflip.wards(address(cat)), 1);
        assertEq(bflip.wards(address(cat)), 1);
        assertEq(uflip.wards(address(cat)), 1);
    }

    function testFailCanOnlyCastOnce() public {
        vote();
        spell.cast();
        spell.cast();
    }

    function testFailCannotCastAfterExpiration() public {
        vote();
        hevm.warp(now + 30 days);
        spell.cast();
    }
}
