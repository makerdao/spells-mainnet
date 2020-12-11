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
import "lib/dss-interfaces/src/dapp/DSTokenAbstract.sol";
import "lib/dss-interfaces/src/dss/ChainlogAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dss/SpotAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/CatAbstract.sol";
import "lib/dss-interfaces/src/dss/IlkRegistryAbstract.sol";
import "lib/dss-interfaces/src/dss/FaucetAbstract.sol";
import "lib/dss-interfaces/src/dss/GemJoinAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmMomAbstract.sol";
import "lib/dss-interfaces/src/dss/MedianAbstract.sol";
import "lib/dss-interfaces/src/dss/DssAutoLineAbstract.sol";


contract SpellAction {
    // Office hours enabled if true
    bool constant public officeHours = true;

    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/active/contracts.json
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    // UNI-A
    address constant UNI               = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address constant MCD_JOIN_UNI_A    = 0x3BC3A58b4FC1CbE7e98bB4aB7c99535e8bA9b8F1;
    address constant MCD_FLIP_UNI_A    = 0xF5b8cD9dB5a0EC031304A7B815010aa7761BD426;
    address constant PIP_UNI           = 0xf363c7e351C96b910b92b45d34190650df4aE8e7;
    bytes32 constant ILK_UNI_A         = "UNI-A";

    // RENBTC-A
    address constant RENBTC            = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
    address constant MCD_JOIN_RENBTC_A = 0xFD5608515A47C37afbA68960c1916b79af9491D0;
    address constant MCD_FLIP_RENBTC_A = 0x30BC6eBC27372e50606880a36B279240c0bA0758;
    address constant PIP_RENBTC        = 0xf185d0682d50819263941e5f4EacC763CC5C6C42;
    bytes32 constant ILK_RENBTC_A      = "RENBTC-A";

    // DC IAM
    address constant MCD_IAM_AUTO_LINE = 0xC7Bdd1F2B16447dcf3dE045C4a039A60EC2f0ba3;

    // DC IAM
    address constant YEARN_PROXY       = 0x208EfCD7aad0b5DD49438E0b6A0f38E951A50E5f;

    // decimals & precision
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
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant ZERO_PERCENT_RATE  = 1000000000000000000000000000;
    uint256 constant THREE_PERCENT_RATE = 1000000000937303470807876289;
    uint256 constant SIX_PERCENT_RATE   = 1000000001847694957439350562;
    uint256 constant TEN_PERCENT_RATE   = 1000000003022265980097387650;

    modifier limited {
        if (officeHours) {
            uint day = (now / 1 days + 3) % 7;
            require(day < 5, "Can only be cast on a weekday");
            uint hour = now / 1 hours % 24;
            require(hour >= 14 && hour < 21, "Outside office hours");
        }
        _;
    }

    function execute() external limited {
        address MCD_VAT      = CHANGELOG.getAddress("MCD_VAT");
        address MCD_CAT      = CHANGELOG.getAddress("MCD_CAT");
        address MCD_JUG      = CHANGELOG.getAddress("MCD_JUG");
        address MCD_SPOT     = CHANGELOG.getAddress("MCD_SPOT");
        address MCD_END      = CHANGELOG.getAddress("MCD_END");
        address FLIPPER_MOM  = CHANGELOG.getAddress("FLIPPER_MOM");
        address OSM_MOM      = CHANGELOG.getAddress("OSM_MOM"); // Only if PIP_TOKEN = Osm
        address ILK_REGISTRY = CHANGELOG.getAddress("ILK_REGISTRY");
        address PIP_YFI      = CHANGELOG.getAddress("PIP_YFI");

        //
        // Add UNI
        //

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_UNI_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_UNI_A).ilk() == ILK_UNI_A, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_UNI_A).gem() == UNI, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_UNI_A).dec() == DSTokenAbstract(UNI).decimals(), "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_UNI_A).vat() == MCD_VAT, "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_UNI_A).cat() == MCD_CAT, "flip-cat-not-match");
        require(FlipAbstract(MCD_FLIP_UNI_A).ilk() == ILK_UNI_A, "flip-ilk-not-match");

        // Set the UNI PIP in the Spotter
        SpotAbstract(MCD_SPOT).file(ILK_UNI_A, "pip", PIP_UNI);

        // Set the UNI-A Flipper in the Cat
        CatAbstract(MCD_CAT).file(ILK_UNI_A, "flip", MCD_FLIP_UNI_A);

        // Init UNI-A ilk in Vat & Jug
        VatAbstract(MCD_VAT).init(ILK_UNI_A);
        JugAbstract(MCD_JUG).init(ILK_UNI_A);

        // Allow UNI-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_UNI_A);
        // Allow the UNI-A Flipper to reduce the Cat litterbox on deal()
        CatAbstract(MCD_CAT).rely(MCD_FLIP_UNI_A);
        // Allow Cat to kick auctions in UNI-A Flipper
        FlipAbstract(MCD_FLIP_UNI_A).rely(MCD_CAT);
        // Allow End to yank auctions in UNI-A Flipper
        FlipAbstract(MCD_FLIP_UNI_A).rely(MCD_END);
        // Allow FlipperMom to access to the UNI-A Flipper
        FlipAbstract(MCD_FLIP_UNI_A).rely(FLIPPER_MOM);
        // Disallow Cat to kick auctions in UNI-A Flipper
        // !!!!!!!! Only for certain collaterals that do not trigger liquidations like USDC-A)
        //FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_UNI_A);

        // Allow OsmMom to access to the UNI Osm
        // !!!!!!!! Only if PIP_UNI = Osm and hasn't been already relied due a previous deployed ilk
        OsmAbstract(PIP_UNI).rely(OSM_MOM);
        // Whitelist Osm to read the Median data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_UNI = Osm, its src is a Median and hasn't been already whitelisted due a previous deployed ilk
        MedianAbstract(OsmAbstract(PIP_UNI).src()).kiss(PIP_UNI);
        // Whitelist Spotter to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_UNI = Osm or PIP_UNI = Median and hasn't been already whitelisted due a previous deployed ilk
        OsmAbstract(PIP_UNI).kiss(MCD_SPOT);
        // Whitelist End to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_UNI = Osm or PIP_UNI = Median and hasn't been already whitelisted due a previous deployed ilk
        OsmAbstract(PIP_UNI).kiss(MCD_END);
        // Set UNI Osm in the OsmMom for new ilk
        // !!!!!!!! Only if PIP_UNI = Osm
        OsmMomAbstract(OSM_MOM).setOsm(ILK_UNI_A, PIP_UNI);

        // Set the UNI-A debt ceiling
        VatAbstract(MCD_VAT).file(ILK_UNI_A, "line", 15 * MILLION * RAD);
        // Set the UNI-A dust
        VatAbstract(MCD_VAT).file(ILK_UNI_A, "dust", 500 * RAD);
        // Set the Lot size
        CatAbstract(MCD_CAT).file(ILK_UNI_A, "dunk", 50 * THOUSAND * RAD);
        // Set the UNI-A liquidation penalty (e.g. 13% => X = 113)
        CatAbstract(MCD_CAT).file(ILK_UNI_A, "chop", 113 * WAD / 100);
        // Set the UNI-A stability fee (e.g. 1% = 1000000000315522921573372069)
        JugAbstract(MCD_JUG).file(ILK_UNI_A, "duty", THREE_PERCENT_RATE);
        // Set the UNI-A percentage between bids (e.g. 3% => X = 103)
        FlipAbstract(MCD_FLIP_UNI_A).file("beg", 103 * WAD / 100);
        // Set the UNI-A time max time between bids
        FlipAbstract(MCD_FLIP_UNI_A).file("ttl", 6 hours);
        // Set the UNI-A max auction duration to
        FlipAbstract(MCD_FLIP_UNI_A).file("tau", 6 hours);
        // Set the UNI-A min collateralization ratio (e.g. 150% => X = 150)
        SpotAbstract(MCD_SPOT).file(ILK_UNI_A, "mat", 175 * RAY / 100);

        // Update UNI-A spot value in Vat
        SpotAbstract(MCD_SPOT).poke(ILK_UNI_A);

        // Add new ilk to the IlkRegistry
        IlkRegistryAbstract(ILK_REGISTRY).add(MCD_JOIN_UNI_A);

        // Update the changelog
        CHANGELOG.setAddress("UNI", UNI);
        CHANGELOG.setAddress("MCD_JOIN_UNI_A", MCD_JOIN_UNI_A);
        CHANGELOG.setAddress("MCD_FLIP_UNI_A", MCD_FLIP_UNI_A);
        CHANGELOG.setAddress("PIP_UNI", PIP_UNI);

        //
        // Add renBTC
        //

        // Add RENBTC-A ilk
        require(GemJoinAbstract(MCD_JOIN_RENBTC_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RENBTC_A).ilk() == ILK_RENBTC_A, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RENBTC_A).gem() == RENBTC, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_RENBTC_A).dec() == DSTokenAbstract(RENBTC).decimals(), "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_RENBTC_A).vat() == MCD_VAT, "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_RENBTC_A).cat() == MCD_CAT, "flip-cat-not-match");
        require(FlipAbstract(MCD_FLIP_RENBTC_A).ilk() == ILK_RENBTC_A, "flip-ilk-not-match");

        SpotAbstract(MCD_SPOT).file(ILK_RENBTC_A, "pip", PIP_RENBTC);

        // Set the RENBTC-A Flipper in the Cat
        CatAbstract(MCD_CAT).file(ILK_RENBTC_A, "flip", MCD_FLIP_RENBTC_A);

        // Init RENBTC-A ilk in Vat & Jug
        VatAbstract(MCD_VAT).init(ILK_RENBTC_A);
        JugAbstract(MCD_JUG).init(ILK_RENBTC_A);

        // Allow RENBTC-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_RENBTC_A);
        // Allow the RENBTC-A Flipper to reduce the Cat litterbox on deal()
        CatAbstract(MCD_CAT).rely(MCD_FLIP_RENBTC_A);
        // Allow Cat to kick auctions in RENBTC-A Flipper
        FlipAbstract(MCD_FLIP_RENBTC_A).rely(MCD_CAT);
        // Allow End to yank auctions in RENBTC-A Flipper
        FlipAbstract(MCD_FLIP_RENBTC_A).rely(MCD_END);
        // Allow FlipperMom to access to the RENBTC-A Flipper
        FlipAbstract(MCD_FLIP_RENBTC_A).rely(FLIPPER_MOM);
        // Disallow Cat to kick auctions in RENBTC-A Flipper
        // !!!!!!!! Only for certain collaterals that do not trigger liquidations like USDC-A)
        // FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_RENBTC_A);

        // Allow OsmMom to access to the RENBTC Osm
        // !!!!!!!! Only if PIP_RENBTC = Osm and hasn't been already relied due a previous deployed ilk
        // OsmAbstract(PIP_RENBTC).rely(OSM_MOM);
        // Whitelist Osm to read the Median data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_RENBTC = Osm, its src is a Median and hasn't been already whitelisted due a previous deployed ilk
        // MedianAbstract(OsmAbstract(PIP_RENBTC).src()).kiss(PIP_RENBTC);
        // Whitelist Spotter to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_RENBTC = Osm or PIP_RENBTC = Median and hasn't been already whitelisted due a previous deployed ilk
        // OsmAbstract(PIP_RENBTC).kiss(MCD_SPOT);
        // Whitelist End to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_RENBTC = Osm or PIP_RENBTC = Median and hasn't been already whitelisted due a previous deployed ilk
        // OsmAbstract(PIP_RENBTC).kiss(MCD_END);
        // Set RENBTC Osm in the OsmMom for new ilk
        // !!!!!!!! Only if PIP_RENBTC = Osm
        OsmMomAbstract(OSM_MOM).setOsm(ILK_RENBTC_A, PIP_RENBTC);

        // Set the RENBTC-A debt ceiling
        VatAbstract(MCD_VAT).file(ILK_RENBTC_A, "line", 2 * MILLION * RAD);
        // Set the RENBTC-A dust
        VatAbstract(MCD_VAT).file(ILK_RENBTC_A, "dust", 500 * RAD);
        // Set the Lot size
        CatAbstract(MCD_CAT).file(ILK_RENBTC_A, "dunk", 50 * THOUSAND * RAD);
        // Set the RENBTC-A liquidation penalty (e.g. 13% => X = 113)
        CatAbstract(MCD_CAT).file(ILK_RENBTC_A, "chop", 113 * WAD / 100);
        // Set the RENBTC-A stability fee (e.g. 1% = 1000000000315522921573372069)
        JugAbstract(MCD_JUG).file(ILK_RENBTC_A, "duty", SIX_PERCENT_RATE);
        // Set the RENBTC-A percentage between bids (e.g. 3% => X = 103)
        FlipAbstract(MCD_FLIP_RENBTC_A).file("beg", 103 * WAD / 100);
        // Set the RENBTC-A time max time between bids
        FlipAbstract(MCD_FLIP_RENBTC_A).file("ttl", 6 hours);
        // Set the RENBTC-A max auction duration to
        FlipAbstract(MCD_FLIP_RENBTC_A).file("tau", 6 hours);
        // Set theRENBTC-A min collateralization ratio (e.g. 150% => X = 150)
        SpotAbstract(MCD_SPOT).file(ILK_RENBTC_A, "mat", 175 * RAY / 100);

        // Update RENBTC-A spot value in Vat
        SpotAbstract(MCD_SPOT).poke(ILK_RENBTC_A);

        // Add new ilk to the IlkRegistry
        IlkRegistryAbstract(ILK_REGISTRY).add(MCD_JOIN_RENBTC_A);

        // Update the changelog
        CHANGELOG.setAddress("RENBTC", RENBTC);
        CHANGELOG.setAddress("MCD_JOIN_RENBTC_A", MCD_JOIN_RENBTC_A);
        CHANGELOG.setAddress("MCD_FLIP_RENBTC_A", MCD_FLIP_RENBTC_A);
        CHANGELOG.setAddress("PIP_RENBTC", PIP_RENBTC);

        //
        // MIP27: Debt Ceiling Instant Access Module
        //

        // Give permissions to the MCD_IAM_AUTO_LINE to file() the vat
        VatAbstract(MCD_VAT).rely(MCD_IAM_AUTO_LINE);

        // Set ilks in MCD_IAM_AUTO_LINE
        DssAutoLineAbstract(MCD_IAM_AUTO_LINE).setIlk(
            "ETH-B", 50_000_000 * RAD, 5_000_000 * RAD, 12 hours
        );

        // Add MCD_IAM_AUTO_LINE
        CHANGELOG.setAddress("MCD_IAM_AUTO_LINE", MCD_IAM_AUTO_LINE);

        // Bump version
        CHANGELOG.setVersion("1.2.1");

        //
        // Various polling changes
        //

        // Allow yearn finance to access the YFI/USD OSM
        OsmAbstract(PIP_YFI).kiss(YEARN_PROXY);

        // Set the YFI-A debt ceiling
        //
        // Existing debt ceiling: 20 million
        // New debt ceiling: 30 million
        VatAbstract(MCD_VAT).file("YFI-A", "line", 30 * MILLION * RAD);

        // Set the YFI-A stability fee
        //
        // Previous: 4%
        // New: 10%
        JugAbstract(MCD_JUG).drip("YFI-A");
        JugAbstract(MCD_JUG).file("YFI-A", "duty", TEN_PERCENT_RATE);

        // Set the USDC-A stability fee
        //
        // Previous: 4%
        // New: 0%
        JugAbstract(MCD_JUG).drip("USDC-A");
        JugAbstract(MCD_JUG).file("USDC-A", "duty", ZERO_PERCENT_RATE);

        // Set the TUSD-A stability fee
        //
        // Previous: 4%
        // New: 0%
        JugAbstract(MCD_JUG).drip("TUSD-A");
        JugAbstract(MCD_JUG).file("TUSD-A", "duty", ZERO_PERCENT_RATE);

        // Set the PAXUSD-A stability fee
        //
        // Previous: 4%
        // New: 0%
        JugAbstract(MCD_JUG).drip("PAXUSD-A");
        JugAbstract(MCD_JUG).file("PAXUSD-A", "duty", ZERO_PERCENT_RATE);

        // Set the GUSD-A stability fee
        //
        // Previous: 4%
        // New: 0%
        JugAbstract(MCD_JUG).drip("GUSD-A");
        JugAbstract(MCD_JUG).file("GUSD-A", "duty", ZERO_PERCENT_RATE);

        // Set the global debt ceiling
        VatAbstract(MCD_VAT).file("Line", 1_598_750_000 * RAD);
    }
}

contract DssSpell {
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    address MCD_PAUSE = CHANGELOG.getAddress("MCD_PAUSE");

    DSPauseAbstract public pause = DSPauseAbstract(MCD_PAUSE);
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/9014856179684688ae29a8204f557fee53f552d5/governance/votes/Executive%20vote%20-%20December%202%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-12-02 MakerDAO Executive Spell | Hash: 0x2055ba0fea45996d1639e5a272ffaee7c7769422d771111c4cdede15c4c6af5d";

    function officeHours() external view returns (bool) {
        return SpellAction(action).officeHours();
    }

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    function schedule() external {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() external {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
