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

import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dss/CatAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipAbstract.sol";
import "lib/dss-interfaces/src/dss/FlapAbstract.sol";
import "lib/dss-interfaces/src/dss/FlopAbstract.sol";
import "lib/dss-interfaces/src/dss/SpotAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmMomAbstract.sol";
import "lib/dss-interfaces/src/dss/MedianAbstract.sol";
import "lib/dss-interfaces/src/dss/GemJoinAbstract.sol";
import "lib/dss-interfaces/src/dss/PotAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipperMomAbstract.sol";
import "lib/dss-interfaces/src/dss/VowAbstract.sol";
import "lib/dss-interfaces/src/dss/MkrAuthorityAbstract.sol";

contract SpellAction {

    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.0.9/contracts.json

    address constant public MCD_VAT             = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public MCD_VOW             = 0xA950524441892A31ebddF91d3cEEFa04Bf454466;
    address constant public MCD_CAT             = 0x78F2c2AF65126834c51822F56Be0d7469D7A523E;
    address constant public MCD_JUG             = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public MCD_POT             = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address constant public GOV_GUARD           = 0x6eEB68B2C7A918f36B78E2DB80dcF279236DDFb8;

    address constant public MCD_SPOT            = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant public MCD_END             = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;
    address constant public FLIPPER_MOM         = 0x9BdDB99625A711bf9bda237044924E34E8570f75;
    address constant public OSM_MOM             = 0x76416A4d5190d071bfed309861527431304aA14f;

    address constant public MCD_JOIN_MANA_A     = 0xA6EA3b9C04b8a38Ff5e224E7c3D6937ca44C0ef9;
    address constant public PIP_MANA            = 0x8067259EA630601f319FccE477977E55C6078C13;
    address constant public MCD_FLIP_MANA_A     = 0x4bf9D2EBC4c57B9B783C12D30076507660B58b3a;
    address constant public MANA                = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942;

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

    // Decimals & precision
    uint256 constant public THOUSAND = 10 ** 3;
    uint256 constant public MILLION  = 10 ** 6;
    uint256 constant public WAD      = 10 ** 18;
    uint256 constant public RAY      = 10 ** 27;
    uint256 constant public RAD      = 10 ** 45;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    uint256 constant public TWELVE_PCT_RATE = 1000000003593629043335673582;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/master/governance/votes/Executive%20vote%20-%20July%2027%2C%202020%20.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-07-27 MakerDAO Executive Spell | Executive for July Governance Cycle | 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

    function execute() external {

        PotAbstract(MCD_POT).drip();
        JugAbstract(MCD_JUG).drip("ETH-A");
        JugAbstract(MCD_JUG).drip("BAT-A");
        JugAbstract(MCD_JUG).drip("USDC-A");
        JugAbstract(MCD_JUG).drip("USDC-B");
        JugAbstract(MCD_JUG).drip("WBTC-A");
        JugAbstract(MCD_JUG).drip("ZRX-A");
        JugAbstract(MCD_JUG).drip("KNC-A");
        JugAbstract(MCD_JUG).drip("TUSD-A");

        // Raise the global debt ceiling by 41 million (40 million for ETH-A, 1 million for MANA-A)
        VatAbstract(MCD_VAT).file("Line", VatAbstract(MCD_VAT).Line() + 41 * MILLION * RAD);

        // Raise the ETH-A deby ceiling by 40 million to 260 million
        bytes32 ilk = "ETH-A";
        VatAbstract(MCD_VAT).file(ilk, "line", 260 * MILLION * RAD); // 260 MM debt ceiling

        // Set ilk bytes32 variable
        ilk = "MANA-A";

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_MANA_A).vat() == MCD_VAT,  "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_MANA_A).ilk() == ilk,      "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_MANA_A).gem() == MANA,     "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_MANA_A).dec() == 18,       "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_MANA_A).vat() == MCD_VAT,     "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_MANA_A).ilk() == ilk,         "flip-ilk-not-match");

        // Set price feed for MANA-A
        SpotAbstract(MCD_SPOT).file(ilk, "pip", PIP_MANA);

        // Set the MANA-A flipper in the cat
        CatAbstract(MCD_CAT).file(ilk, "flip", MCD_FLIP_MANA_A);

        // Init MANA-A in Vat & Jug
        VatAbstract(MCD_VAT).init(ilk);
        JugAbstract(MCD_JUG).init(ilk);

        // Allow MANA-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_MANA_A);

        // Allow cat to kick auctions in MANA-A Flipper
        FlipAbstract(MCD_FLIP_MANA_A).rely(MCD_CAT);

        // Allow End to yank auctions in MANA-A Flipper
        FlipAbstract(MCD_FLIP_MANA_A).rely(MCD_END);

        // Allow FlipperMom to access the MANA-A Flipper
        FlipAbstract(MCD_FLIP_MANA_A).rely(FLIPPER_MOM);

        // Update OSM
        MedianAbstract(OsmAbstract(PIP_MANA).src()).kiss(PIP_MANA);
        OsmAbstract(PIP_MANA).rely(OSM_MOM);
        OsmAbstract(PIP_MANA).kiss(MCD_SPOT);
        OsmAbstract(PIP_MANA).kiss(MCD_END);
        OsmMomAbstract(OSM_MOM).setOsm(ilk, PIP_MANA);

        VatAbstract(MCD_VAT).file(ilk, "line", 1 * MILLION * RAD);    // 1 MM debt ceiling
        VatAbstract(MCD_VAT).file(ilk, "dust", 20 * RAD);             // 20 Dai dust
        CatAbstract(MCD_CAT).file(ilk, "lump", 500 * THOUSAND * WAD); // 500,000 lot size
        CatAbstract(MCD_CAT).file(ilk, "chop", 113 * RAY / 100);      // 13% liq. penalty
        JugAbstract(MCD_JUG).file(ilk, "duty", TWELVE_PCT_RATE);      // 12% stability fee

        FlipAbstract(MCD_FLIP_MANA_A).file("beg",  103 * WAD / 100);  // 3% bid increase
        FlipAbstract(MCD_FLIP_MANA_A).file("ttl",  6 hours);          // 6 hours ttl
        FlipAbstract(MCD_FLIP_MANA_A).file("tau",  6 hours);          // 6 hours tau

        SpotAbstract(MCD_SPOT).file(ilk, "mat",  175 * RAY / 100);    // 175% coll. ratio
        SpotAbstract(MCD_SPOT).poke(ilk);

        /*** Add new Flip, Flap, Flop contracts ***/
        MkrAuthorityAbstract mkrAuthority = MkrAuthorityAbstract(GOV_GUARD);
        VatAbstract                   vat = VatAbstract(MCD_VAT);
        CatAbstract                   cat = CatAbstract(MCD_CAT);
        VowAbstract                   vow = VowAbstract(MCD_VOW);

        FlapAbstract newFlap = FlapAbstract(MCD_FLAP);
        FlopAbstract newFlop = FlopAbstract(MCD_FLOP);
        FlapAbstract oldFlap = FlapAbstract(MCD_FLAP_OLD);
        FlopAbstract oldFlop = FlopAbstract(MCD_FLOP_OLD);

        /*** Flap ***/
        vow.file("flapper", MCD_FLAP);
        newFlap.rely(MCD_VOW);
        newFlap.file("beg", oldFlap.beg());
        newFlap.file("ttl", oldFlap.ttl());
        newFlap.file("tau", oldFlap.tau());
        oldFlap.deny(MCD_VOW);
        require(newFlap.gem() == oldFlap.gem(), "non-matching-gem");
        require(newFlap.vat() == MCD_VAT, "non-matching-vat");

        /*** Flop ***/
        vow.file("flopper", MCD_FLOP);
        newFlop.rely(MCD_VOW);
        vat.rely(MCD_FLOP);
        mkrAuthority.rely(MCD_FLOP);
        newFlop.file("beg", oldFlop.beg());
        newFlop.file("pad", oldFlop.pad());
        newFlop.file("ttl", oldFlop.ttl());
        newFlop.file("tau", oldFlop.tau());
        oldFlop.deny(MCD_VOW);
        vat.deny(MCD_FLOP_OLD);
        mkrAuthority.deny(MCD_FLOP_OLD);
        require(newFlop.gem() == oldFlop.gem(), "non-matching-gem");
        require(newFlop.vat() == MCD_VAT, "non-matching-vat");

        FlipAbstract newFlip;
        FlipAbstract oldFlip;

        // /*** ETH-A Flip ***/
        ilk = "ETH-A";
        newFlip = FlipAbstract(MCD_FLIP_ETH_A);
        oldFlip = FlipAbstract(MCD_FLIP_ETH_A_OLD);

        cat.file(ilk, "flip", address(newFlip));
        newFlip.rely(MCD_CAT);
        newFlip.rely(MCD_END);
        newFlip.rely(FLIPPER_MOM);
        oldFlip.deny(MCD_CAT);
        oldFlip.deny(MCD_END);
        oldFlip.deny(FLIPPER_MOM);
        newFlip.file("beg", oldFlip.beg());
        newFlip.file("ttl", oldFlip.ttl());
        newFlip.file("tau", oldFlip.tau());
        require(newFlip.ilk() == ilk, "non-matching-ilk");
        require(newFlip.vat() == MCD_VAT, "non-matching-vat");


        /*** BAT-A Flip ***/
        ilk = "BAT-A";
        newFlip = FlipAbstract(MCD_FLIP_BAT_A);
        oldFlip = FlipAbstract(MCD_FLIP_BAT_A_OLD);

        cat.file(ilk, "flip", address(newFlip));
        newFlip.rely(MCD_CAT);
        newFlip.rely(MCD_END);
        newFlip.rely(FLIPPER_MOM);
        oldFlip.deny(MCD_CAT);
        oldFlip.deny(MCD_END);
        oldFlip.deny(FLIPPER_MOM);
        newFlip.file("beg", oldFlip.beg());
        newFlip.file("ttl", oldFlip.ttl());
        newFlip.file("tau", oldFlip.tau());
        require(newFlip.ilk() == ilk, "non-matching-ilk");
        require(newFlip.vat() == MCD_VAT, "non-matching-vat");


        /*** USDC-A Flip ***/
        ilk = "USDC-A";
        newFlip = FlipAbstract(MCD_FLIP_USDC_A);
        oldFlip = FlipAbstract(MCD_FLIP_USDC_A_OLD);

        cat.file(ilk, "flip", address(newFlip));
        newFlip.rely(MCD_CAT); // This will be denied after via FlipperMom, just doing this for explicitness
        newFlip.rely(MCD_END);
        newFlip.rely(FLIPPER_MOM);
        oldFlip.deny(MCD_CAT);
        oldFlip.deny(MCD_END);
        oldFlip.deny(FLIPPER_MOM);
        newFlip.file("beg", oldFlip.beg());
        newFlip.file("ttl", oldFlip.ttl());
        newFlip.file("tau", oldFlip.tau());
        require(newFlip.ilk() == ilk, "non-matching-ilk");
        require(newFlip.vat() == MCD_VAT, "non-matching-vat");
        FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_USDC_A);


        /*** USDC-B Flip ***/
        ilk = "USDC-B";
        newFlip = FlipAbstract(MCD_FLIP_USDC_B);
        oldFlip = FlipAbstract(MCD_FLIP_USDC_B_OLD);

        cat.file(ilk, "flip", address(newFlip));
        newFlip.rely(MCD_CAT); // This will be denied after via FlipperMom, just doing this for explicitness
        newFlip.rely(MCD_END);
        newFlip.rely(FLIPPER_MOM);
        oldFlip.deny(MCD_CAT);
        oldFlip.deny(MCD_END);
        oldFlip.deny(FLIPPER_MOM);
        newFlip.file("beg", oldFlip.beg());
        newFlip.file("ttl", oldFlip.ttl());
        newFlip.file("tau", oldFlip.tau());
        require(newFlip.ilk() == ilk, "non-matching-ilk");
        require(newFlip.vat() == MCD_VAT, "non-matching-vat");
        FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_USDC_B);


        /*** WBTC-A Flip ***/
        ilk = "WBTC-A";
        newFlip = FlipAbstract(MCD_FLIP_WBTC_A);
        oldFlip = FlipAbstract(MCD_FLIP_WBTC_A_OLD);

        cat.file(ilk, "flip", address(newFlip));
        newFlip.rely(MCD_CAT);
        newFlip.rely(MCD_END);
        newFlip.rely(FLIPPER_MOM);
        oldFlip.deny(MCD_CAT);
        oldFlip.deny(MCD_END);
        oldFlip.deny(FLIPPER_MOM);
        newFlip.file("beg", oldFlip.beg());
        newFlip.file("ttl", oldFlip.ttl());
        newFlip.file("tau", oldFlip.tau());
        require(newFlip.ilk() == ilk, "non-matching-ilk");
        require(newFlip.vat() == MCD_VAT, "non-matching-vat");


        /*** ZRX-A Flip ***/
        ilk = "ZRX-A";
        newFlip = FlipAbstract(MCD_FLIP_ZRX_A);
        oldFlip = FlipAbstract(MCD_FLIP_ZRX_A_OLD);

        cat.file(ilk, "flip", address(newFlip));
        newFlip.rely(MCD_CAT);
        newFlip.rely(MCD_END);
        newFlip.rely(FLIPPER_MOM);
        oldFlip.deny(MCD_CAT);
        oldFlip.deny(MCD_END);
        oldFlip.deny(FLIPPER_MOM);
        newFlip.file("beg", oldFlip.beg());
        newFlip.file("ttl", oldFlip.ttl());
        newFlip.file("tau", oldFlip.tau());
        require(newFlip.ilk() == ilk, "non-matching-ilk");
        require(newFlip.vat() == MCD_VAT, "non-matching-vat");


        /*** KNC-A Flip ***/
        ilk = "KNC-A";
        newFlip = FlipAbstract(MCD_FLIP_KNC_A);
        oldFlip = FlipAbstract(MCD_FLIP_KNC_A_OLD);

        cat.file(ilk, "flip", address(newFlip));
        newFlip.rely(MCD_CAT);
        newFlip.rely(MCD_END);
        newFlip.rely(FLIPPER_MOM);
        oldFlip.deny(MCD_CAT);
        oldFlip.deny(MCD_END);
        oldFlip.deny(FLIPPER_MOM);
        newFlip.file("beg", oldFlip.beg());
        newFlip.file("ttl", oldFlip.ttl());
        newFlip.file("tau", oldFlip.tau());
        require(newFlip.ilk() == ilk, "non-matching-ilk");
        require(newFlip.vat() == MCD_VAT, "non-matching-vat");


        /*** TUSD-A Flip ***/
        ilk = "TUSD-A";
        newFlip = FlipAbstract(MCD_FLIP_TUSD_A);
        oldFlip = FlipAbstract(MCD_FLIP_TUSD_A_OLD);

        cat.file(ilk, "flip", address(newFlip));
        newFlip.rely(MCD_CAT);
        newFlip.rely(MCD_END);
        newFlip.rely(FLIPPER_MOM);
        oldFlip.deny(MCD_CAT);
        oldFlip.deny(MCD_END);
        oldFlip.deny(FLIPPER_MOM);
        newFlip.file("beg", oldFlip.beg());
        newFlip.file("ttl", oldFlip.ttl());
        newFlip.file("tau", oldFlip.tau());
        require(newFlip.ilk() == ilk, "non-matching-ilk");
        require(newFlip.vat() == MCD_VAT, "non-matching-vat");
    }
}

contract DssSpell {
    DSPauseAbstract public pause = 
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    modifier officeHours {
        uint day = (now / 1 days + 3) % 7;
        require(day < 5, "Can only be cast on a weekday");
        uint hour = now / 1 hours % 24;
        require(hour >= 14 && hour < 21, "Outside office hours");
        _;
    }

    function description() public view returns (string memory) {
        return SpellAction(action).description();
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public officeHours {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
