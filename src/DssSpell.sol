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

contract SpellAction {

    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.1.0/contracts.json

    address constant MCD_VAT                = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant MCD_CAT                = 0xa5679C04fc3d9d8b0AaB1F0ab83555b301cA70Ea;
    address constant MCD_JUG                = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant MCD_SPOT               = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant MCD_END                = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;
    address constant FLIPPER_MOM            = 0xc4bE7F74Ee3743bDEd8E0fA218ee5cf06397f472;
    address constant OSM_MOM                = 0x76416A4d5190d071bfed309861527431304aA14f;
    address constant ILK_REGISTRY           = 0x8b4ce5DCbb01e0e1f0521cd8dCfb31B308E52c24;

    address constant USDT                   = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant MCD_JOIN_USDT_A        = ;
    address constant MCD_FLIP_USDT_A        = ;
    address constant PIP_USDT               = ;

    address constant PAXUSD                 = 0x8E870D67F660D95d5be530380D0eC0bd388289E1;
    address constant MCD_JOIN_PAXUSD_A      = ;
    address constant MCD_FLIP_PAXUSD_A      = ;
    address constant PIP_PAXUSD             = ;

    // Decimals & precision
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    uint256 constant TWO_PCT_RATE           = 1000000000627937192491029810;
    uint256 constant TEN_PCT_RATE           = 1000000003022265980097387650;
    uint256 constant FOURTY_EIGHT_PCT_RATE  = 1000000012431573129530493155;

    function execute() external {
        /*** Risk Parameter Adjustments ***/

        // set the global debt ceiling to 708,000,000
        // 588 (current DC) + 120 (ETH-A increase)
        VatAbstract(MCD_VAT).file("Line", 748 * MILLION * RAD);

        // Set the WBTC-A debt ceiling
        //
        // Existing debt: 80 million
        // New debt ceiling: 120 million
        uint256 WBTC_A_LINE = 120 * MILLION * RAD;
        VatAbstract(MCD_VAT).file("WBTC-A", "line", WBTC_A_LINE);

        // Set the BAT-A stability fee
        // Previous: 0%
        // New: 2%
        JugAbstract(MCD_JUG).drip("BAT-A"); // drip right before
        JugAbstract(MCD_JUG).file("BAT-A", "duty", TWO_PCT_RATE);

        // Set the USDC-A stability fee
        // Previous: 0%
        // New: 2%
        JugAbstract(MCD_JUG).drip("USDC-A"); // drip right before
        JugAbstract(MCD_JUG).file("USDC-A", "duty", TWO_PCT_RATE);

        // Set the USDC-B stability fee
        // Previous: 46%
        // New: 48%
        JugAbstract(MCD_JUG).drip("USDC-B"); // drip right before
        JugAbstract(MCD_JUG).file("USDC-B", "duty", FOURTY_EIGHT_PCT_RATE);

        // Set the WBTC-A stability fee
        // Previous: 0%
        // New: 2%
        JugAbstract(MCD_JUG).drip("WBTC-A"); // drip right before
        JugAbstract(MCD_JUG).file("WBTC-A", "duty", TWO_PCT_RATE);

        // Set the KNC-A stability fee
        // Previous: 0%
        // New: 2%
        JugAbstract(MCD_JUG).drip("KNC-A"); // drip right before
        JugAbstract(MCD_JUG).file("KNC-A", "duty", TWO_PCT_RATE);

        // Set the ZRX-A stability fee
        // Previous: 0%
        // New: 2%
        JugAbstract(MCD_JUG).drip("ZRX-A"); // drip right before
        JugAbstract(MCD_JUG).file("ZRX-A", "duty", TWO_PCT_RATE);

        // Set the MANA-A stability fee
        // Previous: 8%
        // New: 10%
        JugAbstract(MCD_JUG).drip("MANA-A"); // drip right before
        JugAbstract(MCD_JUG).file("MANA-A", "duty", TEN_PCT_RATE);

        ////////////////////////////////////////////////////////////////////////////////
        // USDT-A collateral deploy

        // Set ilk bytes32 variable
        bytes32 ilkUSDTA = "USDT-A";

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_USDT_A).vat() == MCD_VAT,  "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_USDT_A).ilk() == ilkUSDTA, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_USDT_A).gem() == USDT,     "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_USDT_A).dec() == 6,        "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_USDT_A).vat()    == MCD_VAT,  "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_USDT_A).ilk()    == ilkUSDTA, "flip-ilk-not-match");

        // Set price feed for USDT-A
        SpotAbstract(MCD_SPOT).file(ilkUSDTA, "pip", PIP_USDT);

        // Set the USDT-A flipper in the cat
        CatAbstract(MCD_CAT).file(ilkUSDTA, "flip", MCD_FLIP_USDT_A);

        // Init USDT-A in Vat
        VatAbstract(MCD_VAT).init(ilkUSDTA);
        // Init USDT-A in Jug
        JugAbstract(MCD_JUG).init(ilkUSDTA);

        // Allow USDT-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_USDT_A);

        // Allow cat to kick auctions in USDT-A Flipper
        FlipAbstract(MCD_FLIP_USDT_A).rely(MCD_CAT);

        // Allow End to yank auctions in USDT-A Flipper
        FlipAbstract(MCD_FLIP_USDT_A).rely(MCD_END);

        // Allow FlipperMom to access the USDT-A Flipper
        FlipAbstract(MCD_FLIP_USDT_A).rely(FLIPPER_MOM);

        // Update OSM
        OsmAbstract(PIP_USDT).rely(OSM_MOM);
        MedianAbstract(OsmAbstract(PIP_USDT).src()).kiss(PIP_USDT);
        OsmAbstract(PIP_USDT).kiss(MCD_SPOT);
        OsmAbstract(PIP_USDT).kiss(MCD_END);
        OsmMomAbstract(OSM_MOM).setOsm(ilkUSDTA, PIP_USDT);

        // since we're adding 2 collateral types in this spell, global line is at beginning
        VatAbstract(MCD_VAT).file( ilkUSDTA, "line", 10 * MILLION * RAD   ); // 10m debt ceiling
        VatAbstract(MCD_VAT).file( ilkUSDTA, "dust", 100 * RAD            ); // 100 Dai dust
        CatAbstract(MCD_CAT).file( ilkUSDTA, "dunk", 500 * RAD            ); // 50,000 dunk
        CatAbstract(MCD_CAT).file( ilkUSDTA, "chop", 113 * WAD / 100      ); // 13% liq. penalty
        JugAbstract(MCD_JUG).file( ilkUSDTA, "duty", EIGHT_PCT_RATE       ); // 8% stability fee

        FlipAbstract(MCD_FLIP_USDT_A).file(  "beg" , 103 * WAD / 100      ); // 3% bid increase
        FlipAbstract(MCD_FLIP_USDT_A).file(  "ttl" , 6 hours              ); // 6 hours ttl
        FlipAbstract(MCD_FLIP_USDT_A).file(  "tau" , 6 hours              ); // 6 hours tau

        SpotAbstract(MCD_SPOT).file(ilkUSDTA, "mat",  150 * RAY / 100     ); // 150% coll. ratio
        SpotAbstract(MCD_SPOT).poke(ilkUSDTA);

        IlkRegistryAbstract(ILK_REGISTRY).add(MCD_JOIN_USDT_A);

        ////////////////////////////////////////////////////////////////////////////////
        // PAXUSD-A collateral deploy
        // Set ilk bytes32 variable
        bytes32 ilkPAXUSDA = "PAXUSD-A";

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_PAXUSD_A).vat() == MCD_VAT,    "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_PAXUSD_A).ilk() == ilkPAXUSDA, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_PAXUSD_A).gem() == PAXUSD,     "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_PAXUSD_A).dec() == 18,         "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_PAXUSD_A).vat()    == MCD_VAT,    "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_PAXUSD_A).ilk()    == ilkPAXUSDA, "flip-ilk-not-match");

        // Set price feed for PAXUSD-A
        SpotAbstract(MCD_SPOT).file(ilkPAXUSDA, "pip", PIP_PAXUSD);

        // Set the PAXUSD-A flipper in the cat
        CatAbstract(MCD_CAT).file(ilkPAXUSDA, "flip", MCD_FLIP_PAXUSD_A);

        // Init PAXUSD-A in Vat
        VatAbstract(MCD_VAT).init(ilkPAXUSDA);
        // Init PAXUSD-A in Jug
        JugAbstract(MCD_JUG).init(ilkPAXUSDA);

        // Allow PAXUSD-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_PAXUSD_A);

        // Allow cat to kick auctions in PAXUSD-A Flipper
        // NOTE: this will be reverse later in spell, and is done only for explicitness.
        FlipAbstract(MCD_FLIP_PAXUSD_A).rely(MCD_CAT);

        // Allow End to yank auctions in PAXUSD-A Flipper
        FlipAbstract(MCD_FLIP_PAXUSD_A).rely(MCD_END);

        // Allow FlipperMom to access the PAXUSD-A Flipper
        FlipAbstract(MCD_FLIP_PAXUSD_A).rely(FLIPPER_MOM);

        // TODO: update these, we still don't have variables yet
        VatAbstract(MCD_VAT).file(ilkPAXUSDA,   "line"  , 5 * MILLION * RAD    ); // 5 MM debt ceiling
        VatAbstract(MCD_VAT).file(ilkPAXUSDA,   "dust"  , 100 * RAD            ); // 100 Dai dust
        CatAbstract(MCD_CAT).file(ilkPAXUSDA,   "dunk"  , 500 * RAD            ); // 50,000 dunk
        CatAbstract(MCD_CAT).file(ilkPAXUSDA,   "chop"  , 113 * WAD / 100      ); // 13% liq. penalty
        JugAbstract(MCD_JUG).file(ilkPAXUSDA,   "duty"  , FOUR_PCT_RATE        ); // 4% stability fee
        FlipAbstract(MCD_FLIP_PAXUSD_A).file(   "beg"   , 103 * WAD / 100      ); // 3% bid increase
        FlipAbstract(MCD_FLIP_PAXUSD_A).file(   "ttl"   , 6 hours              ); // 6 hours ttl
        FlipAbstract(MCD_FLIP_PAXUSD_A).file(   "tau"   , 6 hours              ); // 6 hours tau
        SpotAbstract(MCD_SPOT).file(ilkPAXUSDA, "mat"   , 120 * RAY / 100      ); // 120% coll. ratio
        SpotAbstract(MCD_SPOT).poke(ilkPAXUSDA);

        IlkRegistryAbstract(ILK_REGISTRY).add(MCD_JOIN_PAXUSD_A);

        // Consequently, deny PAXUSD-A Flipper
        FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_PAXUSD_A);
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

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/b9569... -q -O - 2>/dev/null)"
    string constant public description =
        "2020-09-04 MakerDAO Executive Spell | Hash: 0x0";

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

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public /*officeHours*/ {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
