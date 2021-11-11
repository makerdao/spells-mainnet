// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.6.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "dss-interfaces/Interfaces.sol";
import "./test/rates.sol";
import "./test/addresses_mainnet.sol";

import {DssSpell} from "./DssSpell.sol";

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
    function load(address,bytes32) external view returns (bytes32);
}

interface SpellLike {
    function done() external view returns (bool);
    function cast() external;
}

interface LPTokenLike {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface RwaUrnLike {
    function can(address) external returns (uint);
    function rely(address) external;
    function deny(address) external;
    function hope(address) external;
    function nope(address) external;
    function file(bytes32, address) external;
    function lock(uint256) external;
    function free(uint256) external;
    function draw(uint256) external;
    function wipe(uint256) external;
}

interface RwaInputConduitLike {
    function push() external;
}

interface RwaOutputConduitLike {
    function wards(address) external returns (uint);
    function can(address) external returns (uint);
    function rely(address) external;
    function deny(address) external;
    function hope(address) external;
    function nope(address) external;
    function bud(address) external returns (uint);
    function kiss(address) external;
    function diss(address) external;
    function pick(address) external;
    function push() external;
}

interface RwaLiquidationLike {
    function wards(address) external returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function ilks(bytes32) external returns (string memory, address, uint48, uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
    function bump(bytes32, uint256) external;
    function tell(bytes32) external;
    function cure(bytes32) external;
    function cull(bytes32, address) external;
    function good(bytes32) external view returns (bool);
}

interface TinlakeManagerLike {
    function gem() external returns(address);
    function owner() external returns(address);
    function lock(uint256) external;
    function join(uint256) external;
    function draw(uint256) external;
    function wipe(uint256) external;
    function exit(uint256) external;
    function wards(address) external returns(uint);
    function file(bytes32 what, address data) external;
}

contract EndSpellAction {
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    function execute() public {
        EndAbstract(CHANGELOG.getAddress("MCD_END")).cage();
    }
}

contract TestSpell {
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    DSPauseAbstract public pause =
        DSPauseAbstract(CHANGELOG.getAddress("MCD_PAUSE"));

    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
    }

    function setTag() internal {
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
        require(eta == 0, "This spell has already been scheduled");
        eta = block.timestamp + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}

contract EndSpell is TestSpell {
    constructor() public {
        action = address(new EndSpellAction());
        setTag();
    }
}

contract CullSpellAction {
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    bytes32 constant ilk = "RWA002-A";

    function execute() public {
        RwaLiquidationLike(
            CHANGELOG.getAddress("MIP21_LIQUIDATION_ORACLE")
        ).cull(ilk, CHANGELOG.getAddress("RWA002_A_URN"));
    }
}

contract CullSpell is TestSpell {
    constructor() public {
        action = address(new CullSpellAction());
        setTag();
    }
}

contract CureSpellAction {
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    bytes32 constant ilk = "RWA002-A";

    function execute() public {
        RwaLiquidationLike(
            CHANGELOG.getAddress("MIP21_LIQUIDATION_ORACLE")
        ).cure(ilk);
    }
}

contract CureSpell is TestSpell {
    constructor() public {
        action = address(new CureSpellAction());
        setTag();
    }
}

contract TellSpellAction {
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    bytes32 constant ilk = "RWA002-A";

    function execute() public {
        VatAbstract(CHANGELOG.getAddress("MCD_VAT")).file(ilk, "line", 0);
        RwaLiquidationLike(
            CHANGELOG.getAddress("MIP21_LIQUIDATION_ORACLE")
        ).tell(ilk);
    }
}

contract TellSpell is TestSpell {
    constructor() public {
        action = address(new TellSpellAction());
        setTag();
    }
}

contract BumpSpellAction {
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    bytes32 constant ilk = "RWA002-A";
    uint256 constant WAD = 10 ** 18;

    function execute() public {
        RwaLiquidationLike(
            CHANGELOG.getAddress("MIP21_LIQUIDATION_ORACLE")
        ).bump(ilk, 5_634_805 * WAD);
    }
}

contract BumpSpell is TestSpell {
    constructor() public {
        action = address(new BumpSpellAction());
        setTag();
    }
}

contract DssSpellTest is DSTest, DSMath {

    struct SpellValues {
        address deployed_spell;
        uint256 deployed_spell_created;
        address previous_spell;
        uint256 previous_spell_execution_time;
        bool    office_hours_enabled;
        uint256 expiration_threshold;
    }

    struct CollateralValues {
        bool aL_enabled;
        uint256 aL_line;
        uint256 aL_gap;
        uint256 aL_ttl;
        uint256 line;
        uint256 dust;
        uint256 chop;
        uint256 dunk;
        uint256 pct;
        uint256 mat;
        uint256 beg;
        uint48  ttl;
        uint48  tau;
        uint256 liquidations;
        uint256 flipper_mom;
    }

    struct SystemValues {
        uint256 pot_dsr;
        uint256 pause_delay;
        uint256 vow_wait;
        uint256 vow_dump;
        uint256 vow_sump;
        uint256 vow_bump;
        uint256 vow_hump;
        uint256 flap_beg;
        uint256 flap_ttl;
        uint256 flap_tau;
        uint256 cat_box;
        address pause_authority;
        address osm_mom_authority;
        address flipper_mom_authority;
        uint256 ilk_count;
        mapping (bytes32 => CollateralValues) collaterals;
    }

    SystemValues afterSpell;
    SpellValues  spellValues;

    Hevm hevm;
    Rates     rates = new Rates();
    Addresses addr  = new Addresses();

    // MAINNET ADDRESSES
    DSPauseAbstract        pause = DSPauseAbstract(    addr.addr("MCD_PAUSE"));
    address           pauseProxy =                     addr.addr("MCD_PAUSE_PROXY");
    DSChiefAbstract        chief = DSChiefAbstract(    addr.addr("MCD_ADM"));
    VatAbstract              vat = VatAbstract(        addr.addr("MCD_VAT"));
    VowAbstract              vow = VowAbstract(        addr.addr("MCD_VOW"));
    CatAbstract              cat = CatAbstract(        addr.addr("MCD_CAT"));
    PotAbstract              pot = PotAbstract(        addr.addr("MCD_POT"));
    JugAbstract              jug = JugAbstract(        addr.addr("MCD_JUG"));
    SpotAbstract            spot = SpotAbstract(       addr.addr("MCD_SPOT"));
    DaiAbstract              dai = DaiAbstract(        addr.addr("MCD_DAI"));
    DaiJoinAbstract      daiJoin = DaiJoinAbstract(    addr.addr("MCD_JOIN_DAI"));
    DSTokenAbstract          gov = DSTokenAbstract(    addr.addr("MCD_GOV"));
    EndAbstract              end = EndAbstract(        addr.addr("MCD_END"));
    IlkRegistryAbstract      reg = IlkRegistryAbstract(addr.addr("ILK_REGISTRY"));
    FlapAbstract            flap = FlapAbstract(       addr.addr("MCD_FLAP"));

    OsmMomAbstract        osmMom = OsmMomAbstract(     addr.addr("OSM_MOM"));
    FlipperMomAbstract   flipMom = FlipperMomAbstract( addr.addr("FLIPPER_MOM"));
    DssAutoLineAbstract autoLine = DssAutoLineAbstract(addr.addr("MCD_IAM_AUTO_LINE"));

    // Specific for this spell
    //
    bytes32 constant ilk               = "RWA002-A";
    DSTokenAbstract             rwagem = DSTokenAbstract(     addr.addr("RWA002"));
    GemJoinAbstract            rwajoin = GemJoinAbstract(     addr.addr("MCD_JOIN_RWA002_A"));
    RwaLiquidationLike          oracle = RwaLiquidationLike(  addr.addr("MIP21_LIQUIDATION_ORACLE"));
    RwaUrnLike                  rwaurn = RwaUrnLike(          addr.addr("RWA002_A_URN"));
    RwaInputConduitLike   rwaconduitin = RwaInputConduitLike( addr.addr("RWA002_A_INPUT_CONDUIT"));
    RwaOutputConduitLike rwaconduitout = RwaOutputConduitLike(addr.addr("RWA002_A_OUTPUT_CONDUIT"));

    address    makerDeployer06 = 0xda0fab060e6cc7b1C0AA105d29Bd50D71f036711;

    // Tinlake (same as INPUT/OUTPUT conduit)
    TinlakeManagerLike mgr = TinlakeManagerLike(
        addr.addr("RWA002_A_OUTPUT_CONDUIT")
    );
    address mgr_ = address(mgr);

    BumpSpell bumpSpell;
    TellSpell tellSpell;
    CureSpell cureSpell;
    CullSpell cullSpell;
    EndSpell   endSpell;
    DssSpell   spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    uint256 constant HUNDRED    = 10 ** 2;
    uint256 constant THOUSAND   = 10 ** 3;
    uint256 constant MILLION    = 10 ** 6;
    uint256 constant BILLION    = 10 ** 9;
    // uint256 constant WAD        = 10 ** 18; // provided by ds-math
    // uint256 constant RAY        = 10 ** 27; // provided by ds-math
    uint256 constant RAD        = 10 ** 45;

    uint256 constant monthly_expiration = 4 days;
    uint256 constant weekly_expiration = 30 days;

    event Debug(uint256 index, uint256 val);
    event Debug(uint256 index, address addr);
    event Debug(uint256 index, bytes32 what);
    event Log(string message, address deployer, string contractName);

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
        SpellLike prevSpell = SpellLike(spellValues.previous_spell);
        // warp and cast previous spell so values are up-to-date to test against
        if (prevSpell != SpellLike(0) && !prevSpell.done()) {
            hevm.warp(spellValues.previous_spell_execution_time);
            prevSpell.cast();
        }
    }

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));

        //
        // Test for spell-specific parameters
        //
        spellValues = SpellValues({
            deployed_spell:                 address(0x637F98654cC147C263ae740455d350D0339b19F5),        // populate with deployed spell if deployed
            deployed_spell_created:         1618246761,        // use get-created-timestamp.sh if deployed
            previous_spell:                 address(0),        // supply if there is a need to test prior to its cast() function being called on-chain.
            previous_spell_execution_time:  1617926460 + 2 days,        // Time to warp to in order to allow the previous spell to be cast ignored if PREV_SPELL is SpellLike(address(0)).
            office_hours_enabled:           true,              // true if officehours is expected to be enabled in the spell
            expiration_threshold:           weekly_expiration  // (weekly_expiration,monthly_expiration) if weekly or monthly spell
        });
        spell = spellValues.deployed_spell != address(0) ?
            DssSpell(spellValues.deployed_spell) : new DssSpell();

        //
        // Test for all system configuration changes
        //
        afterSpell = SystemValues({
            pot_dsr:               1,                       // In basis points
            pause_delay:           48 hours,                // In seconds
            vow_wait:              156 hours,               // In seconds
            vow_dump:              250,                     // In whole Dai units
            vow_sump:              50 * THOUSAND,           // In whole Dai units
            vow_bump:              30 * THOUSAND,           // In whole Dai units
            vow_hump:              30 * MILLION,            // In whole Dai units
            flap_beg:              400,                     // in basis points
            flap_ttl:              1 hours,                 // in seconds
            flap_tau:              72 hours,                // in seconds
            cat_box:               20 * MILLION,            // In whole Dai units
            pause_authority:       address(chief),          // Pause authority
            osm_mom_authority:     address(chief),          // OsmMom authority
            flipper_mom_authority: address(chief),          // FlipperMom authority
            ilk_count:             35                       // Num expected in system
        });

        //
        // Test for all collateral based changes here
        //
        afterSpell.collaterals["ETH-A"] = CollateralValues({
            aL_enabled:   true,            // DssAutoLine is enabled?
            aL_line:      15 * BILLION,  // In whole Dai units
            aL_gap:       80 * MILLION,    // In whole Dai units
            aL_ttl:       12 hours,        // In seconds
            line:         0 * MILLION,     // In whole Dai units  // Not checked here as there is auto line
            dust:         5 * THOUSAND,    // In whole Dai units
            pct:          550,             // In basis points
            chop:         1300,            // In basis points
            dunk:         50 * THOUSAND,   // In whole Dai units
            mat:          15000,           // In basis points
            beg:          300,             // In basis points
            ttl:          4 hours,         // In seconds
            tau:          4 hours,         // In seconds
            liquidations: 1,               // 1 if enabled
            flipper_mom:  1                // 1 if circuit breaker enabled
        });
        afterSpell.collaterals["ETH-B"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      50 * MILLION,
            aL_gap:       5 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,     // Not checked as there is auto line
            dust:         15 * THOUSAND,
            pct:          900,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          13000,
            beg:          500,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["ETH-C"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      2000 * MILLION,
            aL_gap:       100 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,     // Not checked as there is auto line
            dust:         5 * THOUSAND,
            pct:          350,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          17500,
            beg:          300,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["BAT-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      3 * MILLION,
            aL_gap:       1 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          600,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          15000,
            beg:          300,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["USDC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          0,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          10100,
            beg:          300,
            ttl:          6 hours,
            tau:          3 days,
            liquidations: 0,
            flipper_mom:  0
        });
        afterSpell.collaterals["USDC-B"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         30 * MILLION,
            dust:         5 * THOUSAND,
            pct:          5000,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          12000,
            beg:          300,
            ttl:          6 hours,
            tau:          3 days,
            liquidations: 0,
            flipper_mom:  0
        });
        afterSpell.collaterals["WBTC-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      750 * MILLION,
            aL_gap:       15 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          450,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          15000,
            beg:          300,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["TUSD-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          0,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          10100,
            beg:          300,
            ttl:          6 hours,
            tau:          3 days,
            liquidations: 0,
            flipper_mom:  0
        });
        afterSpell.collaterals["KNC-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      5 * MILLION,
            aL_gap:       1 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          200,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          17500,
            beg:          300,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["ZRX-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      10 * MILLION,
            aL_gap:       1 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          200,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          17500,
            beg:          300,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["MANA-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      2 * MILLION,
            aL_gap:       500_000,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          400,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          17500,
            beg:          300,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["USDT-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         25 * MILLION / 10,
            dust:         5 * THOUSAND,
            pct:          800,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          15000,
            beg:          300,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["PAXUSD-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         100 * MILLION,
            dust:         5 * THOUSAND,
            pct:          0,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          10100,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 0,
            flipper_mom:  0
        });
        afterSpell.collaterals["COMP-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      30 * MILLION,
            aL_gap:       2 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          300,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          17500,
            beg:          300,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["LRC-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      10 * MILLION,
            aL_gap:       2 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          300,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          17500,
            beg:          300,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["LINK-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      140 * MILLION,
            aL_gap:       7 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          350,
            chop:         1300,
            dunk:         50 * THOUSAND,
            mat:          17500,
            beg:          300,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["BAL-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      5 * MILLION,
            aL_gap:       1 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          350,
            chop:         1300,
            dunk:         50000,
            mat:          17500,
            beg:          300,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["YFI-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      75 * MILLION,
            aL_gap:       5 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          550,
            chop:         1300,
            dunk:         50000,
            mat:          17500,
            beg:          300,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["GUSD-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         5 * MILLION,
            dust:         5 * THOUSAND,
            pct:          0,
            chop:         1300,
            dunk:         50000,
            mat:          10100,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 0,
            flipper_mom:  0
        });
        afterSpell.collaterals["UNI-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      50 * MILLION,
            aL_gap:       3 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          300,
            chop:         1300,
            dunk:         50000,
            mat:          17500,
            beg:          300,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["RENBTC-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      2 * MILLION,
            aL_gap:       500_000,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          500,
            chop:         1300,
            dunk:         50000,
            mat:          17500,
            beg:          300,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["AAVE-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      25 * MILLION,
            aL_gap:       2 * MILLION,
            aL_ttl:       12 hours,
            line:         0 * MILLION,
            dust:         5 * THOUSAND,
            pct:          400,
            chop:         1300,
            dunk:         50000,
            mat:          17500,
            beg:          300,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["UNIV2DAIETH-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      30 * MILLION,
            aL_gap:       5 * MILLION,
            aL_ttl:       12 hours,
            line:         0,
            dust:         5 * THOUSAND,
            pct:          300,
            chop:         1300,
            dunk:         50000,
            mat:          12500,
            beg:          500,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["PSM-USDC-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         2 * BILLION,
            dust:         0,
            pct:          0,
            chop:         1300,
            dunk:         50000,
            mat:          10000,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 0,
            flipper_mom:  0
        });
        afterSpell.collaterals["UNIV2WBTCETH-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         3 * MILLION,
            dust:         5 * THOUSAND,
            pct:          450,
            chop:         1300,
            dunk:         50000,
            mat:          15000,
            beg:          500,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["UNIV2USDCETH-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      50 * MILLION,
            aL_gap:       5 * MILLION,
            aL_ttl:       12 hours,
            line:         0,
            dust:         5 * THOUSAND,
            pct:          350,
            chop:         1300,
            dunk:         50000,
            mat:          12500,
            beg:          500,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["UNIV2DAIUSDC-A"] = CollateralValues({
            aL_enabled:   true,
            aL_line:      50 * MILLION,
            aL_gap:       10 * MILLION,
            aL_ttl:       12 hours,
            line:         0,
            dust:         5 * THOUSAND,
            pct:          300,
            chop:         1300,
            dunk:         50000,
            mat:          11000,
            beg:          300,
            ttl:          6 hours,
            tau:          6 hours,
            liquidations: 0,
            flipper_mom:  0
        });
        afterSpell.collaterals["UNIV2ETHUSDT-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         3 * MILLION,
            dust:         5 * THOUSAND,
            pct:          500,
            chop:         1300,
            dunk:         50000,
            mat:          14000,
            beg:          500,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["UNIV2LINKETH-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         3 * MILLION,
            dust:         5 * THOUSAND,
            pct:          500,
            chop:         1300,
            dunk:         50000,
            mat:          16500,
            beg:          500,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["UNIV2UNIETH-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         3 * MILLION,
            dust:         5 * THOUSAND,
            pct:          500,
            chop:         1300,
            dunk:         50000,
            mat:          16500,
            beg:          500,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["UNIV2WBTCDAI-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         3 * MILLION,
            dust:         5 * THOUSAND,
            pct:          200,
            chop:         1300,
            dunk:         50000,
            mat:          12500,
            beg:          500,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["UNIV2AAVEETH-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         3 * MILLION,
            dust:         5 * THOUSAND,
            pct:          500,
            chop:         1300,
            dunk:         50000,
            mat:          16500,
            beg:          500,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["UNIV2DAIUSDT-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         3 * MILLION,
            dust:         5 * THOUSAND,
            pct:          400,
            chop:         1300,
            dunk:         50000,
            mat:          12500,
            beg:          500,
            ttl:          4 hours,
            tau:          4 hours,
            liquidations: 1,
            flipper_mom:  1
        });
        afterSpell.collaterals["RWA001-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         1 * THOUSAND,
            dust:         0,
            pct:          300,
            chop:         0,
            dunk:         0,
            mat:          10000,
            beg:          0,
            ttl:          0,
            tau:          0,
            liquidations: 0,
            flipper_mom:  0
        });
        afterSpell.collaterals["RWA002-A"] = CollateralValues({
            aL_enabled:   false,
            aL_line:      0 * MILLION,
            aL_gap:       0 * MILLION,
            aL_ttl:       0,
            line:         5 * MILLION,
            dust:         0,
            pct:          350,
            chop:         0,
            dunk:         0,
            mat:          10500,
            beg:          0,
            ttl:          0,
            tau:          0,
            liquidations: 0,
            flipper_mom:  0
        });
    }

    function scheduleWaitAndCastFailDay() public {
        spell.schedule();

        uint256 castTime = now + pause.delay();
        uint256 day = (castTime / 1 days + 3) % 7;
        if (day < 5) {
            castTime += 5 days - day * 86400;
        }

        hevm.warp(castTime);
        spell.cast();
    }

    function scheduleWaitAndCastFailEarly() public {
        spell.schedule();

        uint256 castTime = now + pause.delay() + 24 hours;
        uint256 hour = castTime / 1 hours % 24;
        if (hour >= 14) {
            castTime -= hour * 3600 - 13 hours;
        }

        hevm.warp(castTime);
        spell.cast();
    }

    function scheduleWaitAndCastFailLate() public {
        spell.schedule();

        uint256 castTime = now + pause.delay();
        uint256 hour = castTime / 1 hours % 24;
        if (hour < 21) {
            castTime += 21 hours - hour * 3600;
        }

        hevm.warp(castTime);
        spell.cast();
    }

    function vote(address spell_) internal {
        if (chief.hat() != spell_) {
            hevm.store(
                address(gov),
                keccak256(abi.encode(address(this), uint256(1))),
                bytes32(uint256(999999999999 ether))
            );
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
        assertTrue(
            pot.dsr() >= RAY && pot.dsr() < 1000000021979553151239153027
        );
        assertTrue(diffCalc(expectedRate(values.pot_dsr), yearlyYield(expectedDSRRate)) <= TOLERANCE);

        {
        // Line values in RAD
        assertTrue(
            (vat.Line() >= RAD && vat.Line() < 100 * BILLION * RAD) ||
            vat.Line() == 0
        );
        }

        // Pause delay
        assertEq(pause.delay(), values.pause_delay);

        // wait
        assertEq(vow.wait(), values.vow_wait);

        {
        // dump values in WAD
        uint256 normalizedDump = values.vow_dump * WAD;
        assertEq(vow.dump(), normalizedDump);
        assertTrue(
            (vow.dump() >= WAD && vow.dump() < 2 * THOUSAND * WAD) ||
            vow.dump() == 0
        );
        }
        {
        // sump values in RAD
        uint256 normalizedSump = values.vow_sump * RAD;
        assertEq(vow.sump(), normalizedSump);
        assertTrue(
            (vow.sump() >= RAD && vow.sump() < 500 * THOUSAND * RAD) ||
            vow.sump() == 0
        );
        }
        {
        // bump values in RAD
        uint256 normalizedBump = values.vow_bump * RAD;
        assertEq(vow.bump(), normalizedBump);
        assertTrue(
            (vow.bump() >= RAD && vow.bump() < HUNDRED * THOUSAND * RAD) ||
            vow.bump() == 0
        );
        }
        {
        // hump values in RAD
        uint256 normalizedHump = values.vow_hump * RAD;
        assertEq(vow.hump(), normalizedHump);
        assertTrue(
            (vow.hump() >= RAD && vow.hump() < HUNDRED * MILLION * RAD) ||
            vow.hump() == 0
        );
        }

        // box values in RAD
        {
            uint256 normalizedBox = values.cat_box * RAD;
            assertEq(cat.box(), normalizedBox);
            assertTrue(
                cat.box() >= MILLION * RAD && cat.box() < 50 * MILLION * RAD
            );
        }

        // check Pause authority
        assertEq(pause.authority(), values.pause_authority);

        // check OsmMom authority
        assertEq(osmMom.authority(), values.osm_mom_authority);

        // check FlipperMom authority
        assertEq(flipMom.authority(), values.flipper_mom_authority);

        // check number of ilks
        assertEq(reg.count() + 2, values.ilk_count); // Extra collaterals RWA

        // flap
        // check beg value
        uint256 normalizedTestBeg = (values.flap_beg + 10000)  * 10**14;
        assertEq(flap.beg(), normalizedTestBeg);
        assertTrue(flap.beg() >= WAD && flap.beg() <= 110 * WAD / 100); // gte 0% and lte 10%
        // Check flap ttl and sanity checks
        assertEq(flap.ttl(), values.flap_ttl);
        assertTrue(flap.ttl() > 0 && flap.ttl() < 86400); // gt 0 && lt 1 day
        // Check flap tau and sanity checks
        assertEq(flap.tau(), values.flap_tau);
        assertTrue(flap.tau() > 0 && flap.tau() < 2678400); // gt 0 && lt 1 month
        assertTrue(flap.tau() >= flap.ttl());
    }

    function checkCollateralValues(SystemValues storage values) internal {
        uint256 sumlines;
        bytes32[] memory _ilks = reg.list();
        bytes32[] memory ilks = new bytes32[](_ilks.length + 2);
        for (uint256 i; i < _ilks.length; i++) {
            ilks[i] = _ilks[i];
        }
        ilks[ilks.length -2] = "RWA001-A";
        ilks[ilks.length -1] = "RWA002-A";
        for(uint256 i = 0; i < ilks.length; i++) {
            bytes32 ilk = ilks[i];
            (uint256 duty,)  = jug.ilks(ilk);

            assertEq(duty, rates.rates(values.collaterals[ilk].pct));
            // make sure duty is less than 1000% APR
            // bc -l <<< 'scale=27; e( l(10.00)/(60 * 60 * 24 * 365) )'
            // 1000000073014496989316680335
            assertTrue(duty >= RAY && duty < 1000000073014496989316680335);  // gt 0 and lt 1000%
            assertTrue(diffCalc(expectedRate(values.collaterals[ilk].pct), yearlyYield(rates.rates(values.collaterals[ilk].pct))) <= TOLERANCE);
            assertTrue(values.collaterals[ilk].pct < THOUSAND * THOUSAND);   // check value lt 1000%
            {
            (,,, uint256 line, uint256 dust) = vat.ilks(ilk);
            // Convert whole Dai units to expected RAD
            uint256 normalizedTestLine = values.collaterals[ilk].line * RAD;
            sumlines += line;
            (uint256 aL_line, uint256 aL_gap, uint256 aL_ttl,,) = autoLine.ilks(ilk);
            if (!values.collaterals[ilk].aL_enabled) {
                assertTrue(aL_line == 0);
                assertEq(line, normalizedTestLine);
                assertTrue((line >= RAD && line < 10 * BILLION * RAD) || line == 0);  // eq 0 or gt eq 1 RAD and lt 10B
            } else {
                assertTrue(aL_line > 0);
                assertEq(aL_line, values.collaterals[ilk].aL_line * RAD);
                assertEq(aL_gap, values.collaterals[ilk].aL_gap * RAD);
                assertEq(aL_ttl, values.collaterals[ilk].aL_ttl);
                assertTrue((aL_line >= RAD && aL_line < 20 * BILLION * RAD) || aL_line == 0); // eq 0 or gt eq 1 RAD and lt 20B
            }
            uint256 normalizedTestDust = values.collaterals[ilk].dust * RAD;
            assertEq(dust, normalizedTestDust);
            assertTrue((dust >= RAD && dust < 20 * THOUSAND * RAD) || dust == 0); // eq 0 or gt eq 1 and lt 20k
            }

            {
            (,uint256 mat) = spot.ilks(ilk);
            // Convert BP to system expected value
            uint256 normalizedTestMat = (values.collaterals[ilk].mat * 10**23);
            assertEq(mat, normalizedTestMat);
            assertTrue(mat >= RAY && mat < 10 * RAY);    // cr eq 100% and lt 1000%
            }

            if (ilk != "RWA001-A" && ilk != "RWA002-A") {
                {
                (, uint256 chop, uint256 dunk) = cat.ilks(ilk);
                // Convert BP to system expected value
                uint256 normalizedTestChop = (values.collaterals[ilk].chop * 10**14) + WAD;
                assertEq(chop, normalizedTestChop);
                // make sure chop is less than 100%
                assertTrue(chop >= WAD && chop < 2 * WAD);   // penalty gt eq 0% and lt 100%

                // Convert whole Dai units to expected RAD
                uint256 normalizedTestDunk = values.collaterals[ilk].dunk * RAD;
                assertEq(dunk, normalizedTestDunk);
                // put back in after LIQ-1.2
                assertTrue(dunk >= RAD && dunk < MILLION * RAD);

                (address flipper,,) = cat.ilks(ilk);
                FlipAbstract flip = FlipAbstract(flipper);
                // Convert BP to system expected value
                uint256 normalizedTestBeg = (values.collaterals[ilk].beg + 10000)  * 10**14;
                assertEq(uint256(flip.beg()), normalizedTestBeg);
                assertTrue(flip.beg() >= WAD && flip.beg() <= 110 * WAD / 100); // gte 0% and lte 10%
                assertEq(uint256(flip.ttl()), values.collaterals[ilk].ttl);
                assertTrue(flip.ttl() >= 600 && flip.ttl() < 10 hours);         // gt eq 10 minutes and lt 10 hours
                assertEq(uint256(flip.tau()), values.collaterals[ilk].tau);
                assertTrue(flip.tau() >= 600 && flip.tau() <= 3 days);          // gt eq 10 minutes and lt eq 3 days

                assertEq(flip.wards(address(flipMom)), values.collaterals[ilk].flipper_mom);

                assertEq(flip.wards(address(cat)), values.collaterals[ilk].liquidations);  // liquidations == 1 => on
                checkWards(address(flip), bytes32ToStr(ilk));
                assertEq(flip.wards(address(pauseProxy)), 1); // Check pause_proxy ward
                }
                {
                GemJoinAbstract join = GemJoinAbstract(reg.join(ilk));
                checkWards(address(join), bytes32ToStr(ilk));
                assertEq(join.wards(address(pauseProxy)), 1); // Check pause_proxy ward
                }
            }
        }
        assertEq(sumlines, vat.Line());
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
        //       once the PIP uint size is increased
        assertTrue(price <= (10 ** 14) * WAD);

        return price;
    }

    function getUNIV2LPPrice(address pip) internal returns (uint256) {
        // hevm.load is to pull the price from the LP Oracle storage bypassing the whitelist
        uint256 price = uint256(hevm.load(
            pip,
            bytes32(uint256(6))
        )) & uint128(-1);   // Price is in the second half of the 32-byte storage slot

        // Price is bounded in the spot by around 10^23
        // Give a 10^9 buffer for price appreciation over time
        // Note: This currently can't be hit due to the uint112, but we want to backstop
        //       once the PIP uint size is increased
        assertTrue(price <= (10 ** 14) * WAD);

        return price;
    }

    function giveTokens(DSTokenAbstract token, uint256 amount) internal {
        // Edge case - balance is already set for some reason
        if (token.balanceOf(address(this)) == amount) return;

        for (int i = 0; i < 100; i++) {
            // Scan the storage for the balance storage slot
            bytes32 prevValue = hevm.load(
                address(token),
                keccak256(abi.encode(address(this), uint256(i)))
            );
            hevm.store(
                address(token),
                keccak256(abi.encode(address(this), uint256(i))),
                bytes32(amount)
            );
            if (token.balanceOf(address(this)) == amount) {
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

        // We have failed if we reach here
        assertTrue(false);
    }

	function checkIlkIntegration(
        bytes32 _ilk,
        GemJoinAbstract join,
        FlipAbstract flip,
        address pip,
        bool _isOSM,
        bool _checkLiquidations
    ) public {
        DSTokenAbstract token = DSTokenAbstract(join.gem());

        if (_isOSM) OsmAbstract(pip).poke();
        hevm.warp(now + 3601);
        if (_isOSM) OsmAbstract(pip).poke();
        spot.poke(_ilk);

        // Authorization
        assertEq(join.wards(pauseProxy), 1);
        assertEq(vat.wards(address(join)), 1);
        assertEq(flip.wards(address(end)), 1);
        assertEq(flip.wards(address(flipMom)), 1);
        if (_isOSM) {
            assertEq(OsmAbstract(pip).wards(address(osmMom)), 1);
            assertEq(OsmAbstract(pip).bud(address(spot)), 1);
            assertEq(OsmAbstract(pip).bud(address(end)), 1);
            assertEq(MedianAbstract(OsmAbstract(pip).src()).bud(pip), 1);
        }

        (,,,, uint256 dust) = vat.ilks(_ilk);
        dust /= RAY;
        uint256 amount = 2 * dust * WAD / (_isOSM ? getOSMPrice(pip) : uint256(DSValueAbstract(pip).read()));
        giveTokens(token, amount);

        assertEq(token.balanceOf(address(this)), amount);
        assertEq(vat.gem(_ilk, address(this)), 0);
        token.approve(address(join), amount);
        join.join(address(this), amount);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(vat.gem(_ilk, address(this)), amount);

        // Tick the fees forward so that art != dai in wad units
        hevm.warp(now + 1);
        jug.drip(_ilk);

        // Deposit collateral, generate DAI
        (,uint256 rate,,,) = vat.ilks(_ilk);
        assertEq(vat.dai(address(this)), 0);
        vat.frob(_ilk, address(this), address(this), address(this), int(amount), int(divup(mul(RAY, dust), rate)));
        assertEq(vat.gem(_ilk, address(this)), 0);
        assertTrue(vat.dai(address(this)) >= dust * RAY);
        assertTrue(vat.dai(address(this)) <= (dust + 1) * RAY);

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
        (,,uint256 spotV,,) = vat.ilks(_ilk);
        vat.frob(_ilk, address(this), address(this), address(this), int(amount), int(mul(amount, spotV) / rate));
        hevm.warp(now + 1);
        jug.drip(_ilk);
        assertEq(flip.kicks(), 0);
        if (_checkLiquidations) {
            cat.bite(_ilk, address(this));
            assertEq(flip.kicks(), 1);
        }

        // Dump all dai for next run
        vat.move(address(this), address(0x0), vat.dai(address(this)));
    }

	function checkUNIV2LPIntegration(
        bytes32 _ilk,
        GemJoinAbstract join,
        FlipAbstract flip,
        LPOsmAbstract pip,
        address _medianizer1,
        address _medianizer2,
        bool _isMedian1,
        bool _isMedian2,
        bool _checkLiquidations
    ) public {
        DSTokenAbstract token = DSTokenAbstract(join.gem());

        pip.poke();
        hevm.warp(now + 3601);
        pip.poke();
        spot.poke(_ilk);

        // Check medianizer sources
        assertEq(pip.src(), address(token));
        assertEq(pip.orb0(), _medianizer1);
        assertEq(pip.orb1(), _medianizer2);

        // Authorization
        assertEq(join.wards(pauseProxy), 1);
        assertEq(vat.wards(address(join)), 1);
        assertEq(flip.wards(address(end)), 1);
        assertEq(flip.wards(address(flipMom)), 1);
        assertEq(pip.wards(address(osmMom)), 1);
        assertEq(pip.bud(address(spot)), 1);
        assertEq(pip.bud(address(end)), 1);
        if (_isMedian1) assertEq(MedianAbstract(_medianizer1).bud(address(pip)), 1);
        if (_isMedian2) assertEq(MedianAbstract(_medianizer2).bud(address(pip)), 1);

        (,,,, uint256 dust) = vat.ilks(_ilk);
        dust /= RAY;
        uint256 amount = 2 * dust * WAD / getUNIV2LPPrice(address(pip));
        giveTokens(token, amount);

        assertEq(token.balanceOf(address(this)), amount);
        assertEq(vat.gem(_ilk, address(this)), 0);
        token.approve(address(join), amount);
        join.join(address(this), amount);
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(vat.gem(_ilk, address(this)), amount);

        // Tick the fees forward so that art != dai in wad units
        hevm.warp(now + 1);
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
        (,,uint256 spotV,,) = vat.ilks(_ilk);
        vat.frob(_ilk, address(this), address(this), address(this), int(amount), int(mul(amount, spotV) / rate));
        hevm.warp(now + 1);
        jug.drip(_ilk);
        assertEq(flip.kicks(), 0);
        if (_checkLiquidations) {
            cat.bite(_ilk, address(this));
            assertEq(flip.kicks(), 1);
        }

        // Dump all dai for next run
        vat.move(address(this), address(0x0), vat.dai(address(this)));
    }

    function getExtcodesize(address target) public view returns (uint256 exsize) {
        assembly {
            exsize := extcodesize(target)
        }
    }

    function testSpellIsCast_GENERAL() public {
        string memory description = new DssSpell().description();
        assertTrue(bytes(description).length > 0);
        // DS-Test can't handle strings directly, so cast to a bytes32.
        assertEq(stringToBytes32(spell.description()),
                stringToBytes32(description));

        if(address(spell) != address(spellValues.deployed_spell)) {
            assertEq(spell.expiration(), (now + spellValues.expiration_threshold));
        } else {
            assertEq(spell.expiration(), (spellValues.deployed_spell_created + spellValues.expiration_threshold));

            // If the spell is deployed compare the on-chain bytecode size with the generated bytecode size.
            //   extcodehash doesn't match, potentially because it's address-specific, avenue for further research.
            address depl_spell = spellValues.deployed_spell;
            address code_spell = address(new DssSpell());
            assertEq(getExtcodesize(depl_spell), getExtcodesize(code_spell));
        }

        castPreviousSpell();
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        checkSystemValues(afterSpell);

        checkCollateralValues(afterSpell);
    }

    function testChainlogValues() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        ChainlogAbstract chainLog = ChainlogAbstract(addr.addr("CHANGELOG"));

        assertEq(
            chainLog.getAddress("RWA002"),
            addr.addr("RWA002")
        );
        assertEq(
            chainLog.getAddress("MCD_JOIN_RWA002_A"),
            addr.addr("MCD_JOIN_RWA002_A")
        );
        assertEq(
            chainLog.getAddress("RWA002_A_URN"),
            addr.addr("RWA002_A_URN")
        );
        assertEq(
            chainLog.getAddress("RWA002_A_INPUT_CONDUIT"),
            addr.addr("RWA002_A_INPUT_CONDUIT")
        );
        assertEq(
            chainLog.getAddress("RWA002_A_OUTPUT_CONDUIT"),
            addr.addr("RWA002_A_OUTPUT_CONDUIT")
        );
        assertEq(
            chainLog.getAddress("MIP21_LIQUIDATION_ORACLE"),
            addr.addr("MIP21_LIQUIDATION_ORACLE")
        );

        (,address pip,,) = RwaLiquidationLike(
            addr.addr("MIP21_LIQUIDATION_ORACLE")
        ).ilks(ilk);
        assertTrue(chainLog.getAddress("PIP_RWA002") == pip);

        assertEq(chainLog.version(), "1.2.11");
    }

    function testCollateralIntegrations() public {
        vote(address(spell));
        spell.schedule();
        castPreviousSpell();
        hevm.warp(spell.nextCastTime());
        spell.cast();
        assertTrue(spell.done());

        // Insert new collateral tests here
    }

    function testOfficeHoursMatches() public {
        assertTrue(spell.officeHours() == spellValues.office_hours_enabled);
    }

    function testFailWrongDay() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote(address(spell));
            scheduleWaitAndCastFailDay();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testFailTooEarly() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote(address(spell));
            scheduleWaitAndCastFailEarly();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testFailTooLate() public {
        require(spell.officeHours() == spellValues.office_hours_enabled);
        if (spell.officeHours()) {
            vote(address(spell));
            scheduleWaitAndCastFailLate();
        } else {
            revert("Office Hours Disabled");
        }
    }

    function testOnTime() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
    }

    function testCastCost() public {
        vote(address(spell));
        spell.schedule();

        castPreviousSpell();

        hevm.warp(spell.nextCastTime());
        uint256 startGas = gasleft();
        spell.cast();
        uint256 endGas = gasleft();
        uint256 totalGas = startGas - endGas;

        assertTrue(spell.done());
        // Fail if cast is too expensive
        assertTrue(totalGas <= 8 * MILLION);
    }

    function test_nextCastTime() public {
        hevm.warp(1606161600); // Nov 23, 20 UTC (could be cast Nov 26)

        vote(address(spell));
        spell.schedule();

        uint256 monday_1400_UTC = 1606744800; // Nov 30, 2020
        uint256 monday_2100_UTC = 1606770000; // Nov 30, 2020

        // Day tests
        hevm.warp(monday_1400_UTC);                                    // Monday,   14:00 UTC
        assertEq(spell.nextCastTime(), monday_1400_UTC);               // Monday,   14:00 UTC

        if (spell.officeHours()) {
            hevm.warp(monday_1400_UTC - 1 days);                       // Sunday,   14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_1400_UTC - 2 days);                       // Saturday, 14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_1400_UTC - 3 days);                       // Friday,   14:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC - 3 days);  // Able to cast

            hevm.warp(monday_2100_UTC);                                // Monday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC + 1 days);  // Tuesday,  14:00 UTC

            hevm.warp(monday_2100_UTC - 1 days);                       // Sunday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_2100_UTC - 2 days);                       // Saturday, 21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            hevm.warp(monday_2100_UTC - 3 days);                       // Friday,   21:00 UTC
            assertEq(spell.nextCastTime(), monday_1400_UTC);           // Monday,   14:00 UTC

            // Time tests
            uint256 castTime;

            for(uint256 i = 0; i < 5; i++) {
                castTime = monday_1400_UTC + i * 1 days; // Next day at 14:00 UTC
                hevm.warp(castTime - 1 seconds); // 13:59:59 UTC
                assertEq(spell.nextCastTime(), castTime);

                hevm.warp(castTime + 7 hours + 1 seconds); // 21:00:01 UTC
                if (i < 4) {
                    assertEq(spell.nextCastTime(), monday_1400_UTC + (i + 1) * 1 days); // Next day at 14:00 UTC
                } else {
                    assertEq(spell.nextCastTime(), monday_1400_UTC + 7 days); // Next monday at 14:00 UTC (friday case)
                }
            }
        }
    }

    function testFail_notScheduled() public view {
        spell.nextCastTime();
    }

    function test_use_eta() public {
        hevm.warp(1606161600); // Nov 23, 20 UTC (could be cast Nov 26)

        vote(address(spell));
        spell.schedule();

        uint256 castTime = spell.nextCastTime();
        assertEq(castTime, spell.eta());
    }

    function test_OSMs() public {
        vote(address(spell));
        spell.schedule();
        castPreviousSpell();
        hevm.warp(spell.nextCastTime());
        spell.cast();
        assertTrue(spell.done());

        // Track OSM authorizations here

        address YEARN_PROXY = 0x208EfCD7aad0b5DD49438E0b6A0f38E951A50E5f;
        assertEq(OsmAbstract(addr.addr("PIP_YFI")).bud(YEARN_PROXY), 1);

        // Gnosis
        address GNOSIS = 0xD5885fbCb9a8a8244746010a3BC6F1C6e0269777;
        assertEq(OsmAbstract(addr.addr("PIP_WBTC")).bud(GNOSIS), 1);
        assertEq(OsmAbstract(addr.addr("PIP_LINK")).bud(GNOSIS), 1);
        assertEq(OsmAbstract(addr.addr("PIP_COMP")).bud(GNOSIS), 1);
        assertEq(OsmAbstract(addr.addr("PIP_YFI")).bud(GNOSIS), 1);
        assertEq(OsmAbstract(addr.addr("PIP_ZRX")).bud(GNOSIS), 1);

        // Instadapp
        address INSTADAPP = 0xDF3CDd10e646e4155723a3bC5b1191741DD90333;
        assertEq(OsmAbstract(addr.addr("PIP_ETH")).bud(INSTADAPP), 1);
    }

    function test_Medianizers() public {
        vote(address(spell));
        spell.schedule();
        castPreviousSpell();
        hevm.warp(spell.nextCastTime());
        spell.cast();
        assertTrue(spell.done());

        // Track Median authorizations here

        address SET_AAVE    = 0x8b1C079f8192706532cC0Bf0C02dcC4fF40d045D;
        address AAVEUSD_MED = OsmAbstract(addr.addr("PIP_AAVE")).src();
        assertEq(MedianAbstract(AAVEUSD_MED).bud(SET_AAVE), 1);

        address SET_LRC     = 0x1D5d9a2DDa0843eD9D8a9Bddc33F1fca9f9C64a0;
        address LRCUSD_MED  = OsmAbstract(addr.addr("PIP_LRC")).src();
        assertEq(MedianAbstract(LRCUSD_MED).bud(SET_LRC), 1);

        address SET_YFI     = 0x1686d01Bd776a1C2A3cCF1579647cA6D39dd2465;
        address YFIUSD_MED  = OsmAbstract(addr.addr("PIP_YFI")).src();
        assertEq(MedianAbstract(YFIUSD_MED).bud(SET_YFI), 1);

        address SET_ZRX     = 0xFF60D1650696238F81BE53D23b3F91bfAAad938f;
        address ZRXUSD_MED  = OsmAbstract(addr.addr("PIP_ZRX")).src();
        assertEq(MedianAbstract(ZRXUSD_MED).bud(SET_ZRX), 1);

        address SET_UNI     = 0x3c3Afa479d8C95CF0E1dF70449Bb5A14A3b7Af67;
        address UNIUSD_MED  = OsmAbstract(addr.addr("PIP_UNI")).src();
        assertEq(MedianAbstract(UNIUSD_MED).bud(SET_UNI), 1);
    }

    address[] deployerAddresses = [
        0xdDb108893104dE4E1C6d0E47c42237dB4E617ACc,
        0xDa0FaB05039809e63C5D068c897c3e602fA97457,
        0xda0fab060e6cc7b1C0AA105d29Bd50D71f036711,
        0xDA0FaB0700A4389F6E6679aBAb1692B4601ce9bf,
        0x0048d6225D1F3eA4385627eFDC5B4709Cab4A21c,
        0xd200790f62c8da69973e61d4936cfE4f356ccD07,
        0xdA0C0de01d90A5933692Edf03c7cE946C7c50445
    ];

    function checkWards(address _addr, string memory contractName) internal {
        for (uint256 i = 0; i < deployerAddresses.length; i ++) {
            (bool ok, bytes memory data) = _addr.call(
                abi.encodeWithSignature("wards(address)", deployerAddresses[i])
            );
            if (!ok || data.length != 32) return;
            uint256 ward = abi.decode(data, (uint256));
            if (ward > 0) {
                emit Log("Bad auth", deployerAddresses[i], contractName);
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
        spell.schedule();
        castPreviousSpell();
        hevm.warp(spell.nextCastTime());
        spell.cast();
        assertTrue(spell.done());
        ChainlogAbstract chainLog = ChainlogAbstract(addr.addr("CHANGELOG"));
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

    function test_auth() public {
        checkAuth(false);
    }

    function test_auth_in_sources() public {
        checkAuth(true);
    }

    function testSpellIsCast_RWA002_INTEGRATION_BUMP() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        bumpSpell = new BumpSpell();
        vote(address(bumpSpell));

        bumpSpell.schedule();

        uint256 castTime = block.timestamp + pause.delay();
        hevm.warp(castTime);
        (, address pip, ,) = oracle.ilks(ilk);

        assertEq(DSValueAbstract(pip).read(), bytes32(5_634_804 * WAD));
        bumpSpell.cast();
        assertEq(DSValueAbstract(pip).read(), bytes32(5_634_805 * WAD));
    }

    function testSpellIsCast_RWA002_INTEGRATION_TELL() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        tellSpell = new TellSpell();
        vote(address(tellSpell));

        tellSpell.schedule();

        uint256 castTime = block.timestamp + pause.delay();
        hevm.warp(castTime);
        (, , uint48 tau, uint48 tocPre) = oracle.ilks(ilk);
        assertEq(uint256(tocPre), 0);
        assertTrue(oracle.good(ilk));
        tellSpell.cast();
        (, , , uint48 tocPost) = oracle.ilks(ilk);
        assertEq(uint256(tocPost), block.timestamp);
        if (tau == 0) {
            assertTrue(!oracle.good(ilk));
        } else {
            assertTrue(oracle.good(ilk));
        }
        hevm.warp(block.timestamp + 600);
        assertTrue(!oracle.good(ilk));
    }

    function testSpellIsCast_RWA002_INTEGRATION_TELL_CURE_GOOD() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        tellSpell = new TellSpell();
        vote(address(tellSpell));

        tellSpell.schedule();

        uint256 castTime = block.timestamp + pause.delay();
        hevm.warp(castTime);
        tellSpell.cast();
        (, , uint48 tau,) = oracle.ilks(ilk);
        if (tau == 0) {
            assertTrue(!oracle.good(ilk));
        } else {
            assertTrue(oracle.good(ilk));
        }
        hevm.warp(block.timestamp + 600);
        assertTrue(!oracle.good(ilk));

        cureSpell = new CureSpell();
        vote(address(cureSpell));

        cureSpell.schedule();
        castTime = block.timestamp + pause.delay();
        hevm.warp(castTime);
        cureSpell.cast();
        assertTrue(oracle.good(ilk));
        (,,, uint48 toc) = oracle.ilks(ilk);
        assertEq(uint256(toc), 0);
    }

    function testFailSpellIsCast_RWA002_INTEGRATION_CURE() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        cureSpell = new CureSpell();
        vote(address(cureSpell));

        cureSpell.schedule();
        uint256 castTime = block.timestamp + pause.delay();
        hevm.warp(castTime);
        cureSpell.cast();
    }

    function testSpellIsCast_RWA002_INTEGRATION_TELL_CULL() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());
        (, , uint48 tau,) = oracle.ilks(ilk);
        assertTrue(oracle.good(ilk));

        tellSpell = new TellSpell();
        vote(address(tellSpell));

        tellSpell.schedule();

        uint256 castTime = block.timestamp + pause.delay();
        hevm.warp(castTime);
        tellSpell.cast();
        if (tau == 0) {
            assertTrue(!oracle.good(ilk));
        } else {
            assertTrue(oracle.good(ilk));
        }
        hevm.warp(block.timestamp + 600);
        assertTrue(!oracle.good(ilk));

        cullSpell = new CullSpell();
        vote(address(cullSpell));

        cullSpell.schedule();
        castTime = block.timestamp + pause.delay();
        hevm.warp(castTime);
        cullSpell.cast();
        assertTrue(!oracle.good(ilk));
        (, address pip,,) = oracle.ilks(ilk);
        assertEq(DSValueAbstract(pip).read(), bytes32(0));
    }

    function testSpellIsCast_RWA002_END() public {
        vote(address(spell));
        scheduleWaitAndCast(address(spell));
        assertTrue(spell.done());

        endSpell = new EndSpell();
        vote(address(endSpell));

        endSpell.schedule();

        uint256 castTime = block.timestamp + pause.delay();
        hevm.warp(castTime);
        endSpell.cast();

        assertEq(end.live(), 0);
    }
}
