pragma solidity 0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssSpell, SpellAction} from "./2020-07-27-DssSpell.sol";

contract Hevm {
    function warp(uint256) public;
    function store(address,bytes32,bytes32) public;
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
    uint256 constant SPELL_CREATED = 0;

    struct CollateralValues {
        uint256 line;
        uint256 dust;
        uint256 duty;
        uint256 chop;
        uint256 lump;
        uint256 pct;
        uint256 mat;
        uint256 beg;
        uint48 ttl;
        uint48 tau;
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

    // MAINNET ADDRESSES
    DSPauseAbstract      pause        = DSPauseAbstract(     0xbE286431454714F511008713973d3B053A2d38f3);
    address              pauseProxy   =                      0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
    DSChiefAbstract      chief        = DSChiefAbstract(     0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    VatAbstract          vat          = VatAbstract(         0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    CatAbstract          cat          = CatAbstract(         0x78F2c2AF65126834c51822F56Be0d7469D7A523E);
    PotAbstract          pot          = PotAbstract(         0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    JugAbstract          jug          = JugAbstract(         0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    SpotAbstract         spot         = SpotAbstract(        0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);
    DSTokenAbstract      gov          = DSTokenAbstract(     0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    VowAbstract          vow          = VowAbstract(         0xA950524441892A31ebddF91d3cEEFa04Bf454466);
    MkrAuthorityAbstract mkrAuthority = MkrAuthorityAbstract(0x6eEB68B2C7A918f36B78E2DB80dcF279236DDFb8);

    FlipAbstract         manaFlip     = FlipAbstract(        0x4bf9D2EBC4c57B9B783C12D30076507660B58b3a); 

    GemJoinAbstract      manajoin     = GemJoinAbstract(     0xA6EA3b9C04b8a38Ff5e224E7c3D6937ca44C0ef9);
    EndAbstract          end          = EndAbstract(         0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5);
    address              flipperMom   =                      0x9BdDB99625A711bf9bda237044924E34E8570f75;
    GemAbstract          mana         = GemAbstract(         0x0F5D2fB29fb7d3CFeE444a200298f468908cC942);

    OsmAbstract          pip          = OsmAbstract(         0x8067259EA630601f319FccE477977E55C6078C13);
    OsmMomAbstract       osmMom       = OsmMomAbstract(      0x76416A4d5190d071bfed309861527431304aA14f);

    address constant public MCD_FLAP            = 0xC4269cC7acDEdC3794b221aA4D9205F564e27f0d;
    address constant public MCD_FLOP            = 0xA41B6EF151E06da0e34B009B86E828308986736D;
    address constant public MCD_FLAP_OLD        = 0xdfE0fb1bE2a52CDBf8FB962D5701d7fd0902db9f;
    address constant public MCD_FLOP_OLD        = 0x4D95A049d5B0b7d32058cd3F2163015747522e99;

    address constant public MCD_FLIP_ETH_A      = 0x0F398a2DaAa134621e4b687FCcfeE4CE47599Cc1;
    address constant public MCD_FLIP_ETH_A_OLD  = 0xd8a04F5412223F513DC55F839574430f5EC15531;

    address constant public MCD_FLIP_BAT_A      = 0x5EdF770FC81E7b8C2c89f71F30f211226a4d7495;
    address constant public MCD_FLIP_BAT_A_OLD  = 0xaA745404d55f88C108A28c86abE7b5A1E7817c07;

    address constant public MCD_FLIP_USDC_A     = 0x545521e0105C5698f75D6b3C3050CfCC62FB0C12;
    address constant public MCD_FLIP_USDC_A_OLD = 0xE6ed1d09a19Bd335f051d78D5d22dF3bfF2c28B1;

    address constant public MCD_FLIP_USDC_B     = 0x6002d3B769D64A9909b0B26fC00361091786fe48;
    address constant public MCD_FLIP_USDC_B_OLD = 0xec25Ca3fFa512afbb1784E17f1D414E16D01794F;

    address constant public MCD_FLIP_WBTC_A     = 0xF70590Fa4AaBe12d3613f5069D02B8702e058569;
    address constant public MCD_FLIP_WBTC_A_OLD = 0x3E115d85D4d7253b05fEc9C0bB5b08383C2b0603;

    address constant public MCD_FLIP_ZRX_A      = 0x92645a34d07696395b6e5b8330b000D0436A9aAD;
    address constant public MCD_FLIP_ZRX_A_OLD  = 0x08c89251FC058cC97d5bA5F06F95026C0A5CF9B0;

    address constant public MCD_FLIP_KNC_A      = 0xAD4a0B5F3c6Deb13ADE106Ba6E80Ca6566538eE6;
    address constant public MCD_FLIP_KNC_A_OLD  = 0xAbBCB9Ae89cDD3C27E02D279480C7fF33083249b;

    address constant public MCD_FLIP_TUSD_A     = 0x04C42fAC3e29Fd27118609a5c36fD0b3Cb8090b3;
    address constant public MCD_FLIP_TUSD_A_OLD = 0xba3f6a74BD12Cf1e48d4416c7b50963cA98AfD61;
    
    DssSpell spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));
    
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    uint256 constant public TWELVE_PCT_RATE = 1000000003593629043335673582;

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

        beforeSpell = SystemValues({
            dsr: 1000000000000000000000000000,
            dsrPct: 0 * 1000,
            Line: 345000 * THOUSAND * RAD,
            pauseDelay: 43200 // 12 hours
        });

        afterSpell = SystemValues({
            dsr: 1000000000000000000000000000,
            dsrPct: 0 * 1000,
            Line: 346000 * THOUSAND * RAD,
            pauseDelay: 43200 // 12 hours
        });

        afterSpell.collaterals["MANA-A"] = CollateralValues({
            line: 1 * MILLION * RAD,
            dust: 20 * RAD,
            duty: TWELVE_PCT_RATE,
            pct: 12 * 1000,
            chop: 113 * RAY / 100,
            lump: 500 * THOUSAND * WAD,
            mat: 175 * RAY / 100,
            beg: 103 * WAD / 100,
            ttl: 6 hours,
            tau: 6 hours
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

    function checkSystemValues(SystemValues storage values) internal {
        // dsr
        assertEq(pot.dsr(), values.dsr);
        assertTrue(diffCalc(expectedRate(values.dsrPct), yearlyYield(values.dsr)) <= TOLERANCE);

        // Line
        assertEq(vat.Line(), values.Line);

        // Pause delay
        assertEq(pause.delay(), values.pauseDelay);                
    }

    function checkCollateralValues(bytes32 ilk, SystemValues storage values) internal {
        (uint duty,)  = jug.ilks(ilk);
        assertEq(duty,   values.collaterals[ilk].duty);
        assertTrue(diffCalc(expectedRate(values.collaterals[ilk].pct), yearlyYield(values.collaterals[ilk].duty)) <= TOLERANCE);

        (,,, uint256 line, uint256 dust) = vat.ilks(ilk);
        assertEq(line, values.collaterals[ilk].line);
        assertEq(dust, values.collaterals[ilk].dust);

        (, uint256 chop, uint256 lump) = cat.ilks(ilk);
        assertEq(chop, values.collaterals[ilk].chop);
        assertEq(lump, values.collaterals[ilk].lump);

        (,uint256 mat) = spot.ilks(ilk);
        assertEq(mat, values.collaterals[ilk].mat);

        (address flipper,,) = cat.ilks(ilk);
        FlipAbstract flip = FlipAbstract(flipper);
        assertEq(uint256(flip.beg()), values.collaterals[ilk].beg);
        assertEq(uint256(flip.ttl()), values.collaterals[ilk].ttl);
        assertEq(uint256(flip.tau()), values.collaterals[ilk].tau);
    }

    function checkFlipValues(bytes32 ilk, address _newFlip, address _oldFlip) internal {
        FlipAbstract newFlip = FlipAbstract(_newFlip);
        FlipAbstract oldFlip = FlipAbstract(_oldFlip);

        assertEq(newFlip.ilk(), ilk);
        assertEq(newFlip.vat(), address(vat));

        (address flip,,) = cat.ilks(ilk);

        assertEq(flip, address(newFlip));

        assertEq(newFlip.wards(address(cat)), (ilk == "USDC-A" || ilk == "USDC-B") ? 0 : 1);
        assertEq(newFlip.wards(address(end)), 1);
        assertEq(newFlip.wards(address(flipperMom)), 1);

        assertEq(oldFlip.wards(address(cat)), 0);
        assertEq(oldFlip.wards(address(end)), 0);
        assertEq(oldFlip.wards(address(flipperMom)), 0);

        assertEq(uint256(newFlip.beg()), uint256(oldFlip.beg()));
        assertEq(uint256(newFlip.ttl()), uint256(oldFlip.ttl()));
        assertEq(uint256(newFlip.tau()), uint256(oldFlip.tau()));
    }

    function testSpellIsCast() public {
        if(address(spell) != address(MAINNET_SPELL)) {
            assertEq(spell.expiration(), (now + 30 days));
        } else {
            assertEq(spell.expiration(), (SPELL_CREATED + 30 days));
        }

        checkSystemValues(beforeSpell);

        vote();
        scheduleWaitAndCast();

        // spell done
        assertTrue(spell.done());

        pip.poke();
        hevm.warp(now + 3601);
        pip.poke();
        spot.poke("MANA-A");

        assertEq(mana.balanceOf(address(this)), 0);
        hevm.store(
            address(mana),
            keccak256(abi.encode(address(this), uint256(1))),
            bytes32(uint256(1000000 ether))
        );
        assertEq(mana.balanceOf(address(this)), 1000000 ether);

        // check afterSpell parameters
        checkSystemValues(afterSpell);
        checkCollateralValues("MANA-A", afterSpell);

        // Authorization
        assertEq(manajoin.wards(pauseProxy), 1);
        assertEq(vat.wards(address(manajoin)), 1);
        assertEq(manaFlip.wards(address(cat)), 1);
        assertEq(manaFlip.wards(address(end)), 1);
        assertEq(manaFlip.wards(flipperMom), 1);
        assertEq(pip.wards(address(osmMom)), 1);
        assertEq(pip.bud(address(spot)), 1);
        assertEq(pip.bud(address(end)), 1);
        assertEq(MedianAbstract(pip.src()).bud(address(pip)), 1);

        // Start testing Vault
        uint256 initialDAIBalance = vat.dai(address(this));

        // Join to adapter
        uint256 initialManaBalance = mana.balanceOf(address(this));
        assertEq(vat.gem("MANA-A", address(this)), 0);
        mana.approve(address(manajoin), 15000 ether);
        manajoin.join(address(this), 15000 ether);
        assertEq(mana.balanceOf(address(this)), initialManaBalance - 15000 ether);
        assertEq(vat.gem("MANA-A", address(this)), 15000 ether);

        // Deposit collateral, generate DAI
        assertEq(vat.dai(address(this)), initialDAIBalance);
        vat.frob("MANA-A", address(this), address(this), address(this), int(15000 ether), int(25 ether));
        assertEq(vat.gem("MANA-A", address(this)), 0);
        assertEq(vat.dai(address(this)), add(initialDAIBalance, 25 * RAD));

        // Payback DAI, withdraw collateral
        vat.frob("MANA-A", address(this), address(this), address(this), -int(15000 ether), -int(25 ether));
        assertEq(vat.gem("MANA-A", address(this)), 15000 ether);
        assertEq(vat.dai(address(this)), initialDAIBalance);

        // Withdraw from adapter
        manajoin.exit(address(this), 15000 ether);
        assertEq(mana.balanceOf(address(this)), initialManaBalance);
        assertEq(vat.gem("MANA-A", address(this)), 0);

        // Generate new DAI to force a liquidation
        mana.approve(address(manajoin), 1000 ether);
        manajoin.join(address(this), 1000 ether);
        (,,uint256 spotV,,) = vat.ilks("MANA-A");
        vat.frob("MANA-A", address(this), address(this), address(this), int(1000 ether), int(mul(1000 ether, spotV) / RAY)); // Max amount of DAI
        hevm.warp(now + 1);
        jug.drip("MANA-A");
        assertEq(manaFlip.kicks(), 0);
        cat.bite("MANA-A", address(this));
        assertEq(manaFlip.kicks(), 1);

        bytes32[] memory ilks = new bytes32[](8);
        ilks[0] = "ETH-A";
        ilks[1] = "BAT-A";
        ilks[2] = "USDC-A";
        ilks[3] = "USDC-B";
        ilks[4] = "WBTC-A";
        ilks[5] = "ZRX-A";
        ilks[6] = "KNC-A";
        ilks[7] = "TUSD-A";

        address[] memory newFlips = new address[](8);
        newFlips[0] = MCD_FLIP_ETH_A;
        newFlips[1] = MCD_FLIP_BAT_A;
        newFlips[2] = MCD_FLIP_USDC_A;
        newFlips[3] = MCD_FLIP_USDC_B;
        newFlips[4] = MCD_FLIP_WBTC_A;
        newFlips[5] = MCD_FLIP_ZRX_A;
        newFlips[6] = MCD_FLIP_KNC_A;
        newFlips[7] = MCD_FLIP_TUSD_A;

        address[] memory oldFlips = new address[](8);
        oldFlips[0] = MCD_FLIP_ETH_A_OLD;
        oldFlips[1] = MCD_FLIP_BAT_A_OLD;
        oldFlips[2] = MCD_FLIP_USDC_A_OLD;
        oldFlips[3] = MCD_FLIP_USDC_B_OLD;
        oldFlips[4] = MCD_FLIP_WBTC_A_OLD;
        oldFlips[5] = MCD_FLIP_ZRX_A_OLD;
        oldFlips[6] = MCD_FLIP_KNC_A_OLD;
        oldFlips[7] = MCD_FLIP_TUSD_A_OLD;

        require(
            ilks.length == newFlips.length && ilks.length == oldFlips.length,
            "array-lengths-not-equal"
        );
        // check flip parameters
        for(uint i = 0; i < ilks.length; i++) {
            checkFlipValues(ilks[i], newFlips[i], oldFlips[i]);
        }

        FlapAbstract newFlap = FlapAbstract(MCD_FLAP);
        FlapAbstract oldFlap = FlapAbstract(MCD_FLAP_OLD);

        assertEq(vow.flapper(), address(newFlap));
        assertEq(vat.can(address(vow), address(newFlap)), 1);
        assertEq(vat.can(address(vow), address(oldFlap)), 0);

        assertEq(newFlap.wards(address(vow)), 1);
        assertEq(oldFlap.wards(address(vow)), 0);

        assertEq(uint256(newFlap.beg()), uint256(oldFlap.beg()));
        assertEq(uint256(newFlap.ttl()), uint256(oldFlap.ttl()));
        assertEq(uint256(newFlap.tau()), uint256(oldFlap.tau()));

        FlopAbstract newFlop = FlopAbstract(MCD_FLOP);
        FlopAbstract oldFlop = FlopAbstract(MCD_FLOP_OLD);

        assertEq(vow.flopper(), address(newFlop));

        assertEq(newFlop.wards(address(vow)), 1);
        assertEq(vat.wards(address(newFlop)), 1);
        assertEq(mkrAuthority.wards(address(newFlop)), 1);
        
        assertEq(oldFlop.wards(address(vow)), 0);
        assertEq(vat.wards(address(oldFlop)), 0);
        assertEq(mkrAuthority.wards(address(oldFlop)), 0);

        assertEq(uint256(newFlop.beg()), uint256(oldFlop.beg()));
        assertEq(uint256(newFlop.pad()), uint256(oldFlop.pad()));
        assertEq(uint256(newFlop.ttl()), uint256(oldFlop.ttl()));
        assertEq(uint256(newFlop.tau()), uint256(oldFlop.tau()));
    }
}
