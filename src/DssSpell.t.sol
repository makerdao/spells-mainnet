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
    address constant MAINNET_SPELL = address(0);

    Hevm hevm;

    // MAINNET ADDRESSES
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
    GemJoinAbstract uJoin   = GemJoinAbstract(0x4c514656E7dB7B859E994322D2b511d99105C1Eb);
    EndAbstract     end     = EndAbstract(0x24728AcF2E2C403F5d2db4Df6834B8998e56aA5F);
    //address  flipperMom     = 0x9BdDB99625A711bf9bda237044924E34E8570f75;
    GemAbstract     usdc    = GemAbstract(0x4c514656E7dB7B859E994322D2b511d99105C1Eb);

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
        //gov.mint(address(this), 300000 ether);

        // If the spell which changes the delay to 4 hours haven't run yet, warp the time and do it
        //if (!DSSpellAbstract(0xd77ad957fcF536d13A17f5D1FfFA3987F83376cf).done()) {
        //    hevm.warp(1584386127);
        //    DSSpellAbstract(0xd77ad957fcF536d13A17f5D1FfFA3987F83376cf).cast();
        //}
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
        hevm.warp(add(now, pause.delay()));
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
        assertEq(lineUSDC, 25 * MILLION * RAD);
        assertEq(dustUSDC, 20 * RAD);

        // USDC-A liquidation penalty and lot size
        (address aux, uint256 chop, uint256 lump) = cat.ilks("USDC-A");
        FlipAbstract uFlip = FlipAbstract(aux);
        assertEq(chop, 113 * RAY / 100);
        assertEq(lump, 50 * THOUSAND * WAD);

        // USDC-A percentage between bids
        assertEq(uFlip.beg(), 102 * WAD / 100);
        // USDC-A max time between bids
        assertEq(uint256(uFlip.ttl()), 6 hours);
        // USDC-A max auction duration
        assertEq(uint256(uFlip.tau()), 6 hours);

        // USDC-A min collateralization ratio
        (, uint256 mat) = spot.ilks("USDC-A");
        assertEq(mat, 125 * RAY / 100);

        // Line
        assertEq(vat.Line(), 138 * MILLION * RAD);

        // Authorization
        assertEq(vat.wards(address(uJoin)), 1);
        assertEq(uFlip.wards(address(cat)), 1);
        assertEq(uFlip.wards(address(end)), 1);
        //assertEq(uFlip.wards(flipperMom), 1);

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
    }
}
