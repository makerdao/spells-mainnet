pragma solidity 0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssSpell} from "./DssSpell.sol";

contract Hevm {
    function warp(uint256) public;
}

contract FlipMomLike {
    function setOwner(address) external;
    function setAuthority(address) external;
    function rely(address) external;
    function deny(address) external;
    function authority() public returns (address);
    function owner() public returns (address);
    function cat() public returns (address);
}

contract DssSpellTest is DSTest, DSMath {
    // populate with mainnet spell if needed
    address constant MAINNET_SPELL = 0x049E4D10C1B7280CFED5B0D990e39F9c54529A32;

    Hevm hevm;

    // MAINNET ADDRESSES
    DSPauseAbstract pause   = DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address pauseProxy      = 0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
    DSChiefAbstract chief   = DSChiefAbstract(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    VatAbstract     vat     = VatAbstract(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    CatAbstract     cat     = CatAbstract(0x78F2c2AF65126834c51822F56Be0d7469D7A523E);
    VowAbstract     vow     = VowAbstract(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
    PotAbstract     pot     = PotAbstract(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    JugAbstract     jug     = JugAbstract(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    SpotAbstract   spot     = SpotAbstract(0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);
    MKRAbstract     gov     = MKRAbstract(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    SaiTubAbstract  tub     = SaiTubAbstract(0x448a5065aeBB8E423F0896E6c5D525C040f59af3);
    GemJoinAbstract uJoin   = GemJoinAbstract(0xA191e578a6736167326d05c119CE0c90849E84B7);
    EndAbstract     end     = EndAbstract(0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5);
    address  flipperMom     = 0x9BdDB99625A711bf9bda237044924E34E8570f75;
    GemAbstract     usdc    = GemAbstract(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    DSValueAbstract uPip    = DSValueAbstract(0x77b68899b99b686F415d074278a9a16b336085A0);

    DssSpell spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));
    
    uint256 constant THOUSAND = 10**3;
    uint256 constant MILLION = 10**6;
    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;
    uint256 constant RAD = 10**45;

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
        gov.mint(address(this), 300000 ether);

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

        // spell done
        assertTrue(spell.done());

        // USDC-A fee
        (uint256 dutyUSDC,) = jug.ilks("USDC-A");
        assertEq(dutyUSDC, 1000000005781378656804591712);
        assertTrue(diffCalc(expectedRate(20 * 1000), yearlyYield(dutyUSDC)) <= TOLERANCE);

        // USDC-A line and dust
        (,,, uint256 lineUSDC, uint256 dustUSDC) = vat.ilks("USDC-A");
        assertEq(lineUSDC, 20 * MILLION * RAD);
        assertEq(dustUSDC, 20 * RAD);

        // USDC-A liquidation penalty and lot size
        (address aux, uint256 chop, uint256 lump) = cat.ilks("USDC-A");
        FlipAbstract uFlip = FlipAbstract(aux);
        assertEq(chop, 113 * RAY / 100);
        assertEq(lump, 50 * THOUSAND * WAD);

        // USDC-A percentage between bids
        assertEq(uFlip.beg(), 103 * WAD / 100);
        // USDC-A max time between bids
        assertEq(uint256(uFlip.ttl()), 6 hours);
        // USDC-A max auction duration
        assertEq(uint256(uFlip.tau()), 3 days);

        // USDC-A min collateralization ratio
        (, uint256 mat) = spot.ilks("USDC-A");
        assertEq(mat, 125 * RAY / 100);

        // Line
        assertEq(vat.Line(), 133 * MILLION * RAD);

        // USDC Pip => 1 USDC == 1 DAI
        assertEq(uint256(uPip.read()), 1 * WAD);
        // USDC Pip Owner
        assertEq(uPip.owner(), pauseProxy);
        // USDC Pip Authority
        assertEq(uPip.authority(), address(0));

        // Authorization
        assertEq(uJoin.wards(pauseProxy), 1);
        assertEq(vat.wards(address(uJoin)), 1);
        assertEq(uFlip.wards(address(cat)), 0); // FlipperMom denied it at the end of the spell (no liquidations on first phase)
        assertEq(uFlip.wards(address(end)), 1);
        assertEq(uFlip.wards(flipperMom), 1);

        // Start testing Vault

        // Join to adapter
        assertEq(usdc.balanceOf(address(this)), 40 * 10 ** 6);
        assertEq(vat.gem("USDC-A", address(this)), 0);
        usdc.approve(address(uJoin), 40 * 10 ** 6);
        uJoin.join(address(this), 40 * 10 ** 6);
        assertEq(usdc.balanceOf(address(this)), 0);
        assertEq(vat.gem("USDC-A", address(this)), 40 * WAD);

        // Deposit collateral, generate DAI
        assertEq(vat.dai(address(this)), 0);
        vat.frob("USDC-A", address(this), address(this), address(this), int(40 * WAD), int(25 * WAD));
        assertEq(vat.gem("USDC-A", address(this)), 0);
        assertEq(vat.dai(address(this)), 25 * RAD);

        // Payback DAI, withdraw collateral
        vat.frob("USDC-A", address(this), address(this), address(this), -int(40 * WAD), -int(25 * WAD));
        assertEq(vat.gem("USDC-A", address(this)), 40 * WAD);
        assertEq(vat.dai(address(this)), 0);

        // Withdraw from adapter
        uJoin.exit(address(this), 40 * 10 ** 6);
        assertEq(usdc.balanceOf(address(this)), 40 * 10 ** 6);
        assertEq(vat.gem("USDC-A", address(this)), 0);

        // // Generate new DAI to force a liquidation
        // usdc.approve(address(uJoin), 40 * 10 ** 6);
        // uJoin.join(address(this), 40 * 10 ** 6);
        // vat.frob("USDC-A", address(this), address(this), address(this), int(40 * WAD), int(32 * WAD)); // Max amount of DAI
        // hevm.warp(now + 1);
        // jug.drip("USDC-A");
        // assertEq(uFlip.kicks(), 0);
        // cat.bite("USDC-A", address(this));
        // assertEq(uFlip.kicks(), 1);
    }
}
