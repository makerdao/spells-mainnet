// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity 0.6.11;

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
import "lib/dss-interfaces/src/dss/LPOsmAbstract.sol";
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

    // AAVE-A
    address constant AAVE               = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address constant MCD_JOIN_AAVE_A    = 0x24e459F61cEAa7b1cE70Dbaea938940A7c5aD46e;
    address constant MCD_FLIP_AAVE_A    = 0x16e1b844094c885a37509a8f76c533B5fbFED13a;
    address constant PIP_AAVE           = 0x8Df8f06DC2dE0434db40dcBb32a82A104218754c;
    bytes32 constant ILK_AAVE_A         = "AAVE-A";

    // UNIV2DAIETH-A
    address constant UNIV2DAIETH            = 0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11;
    address constant MCD_JOIN_UNIV2DAIETH_A = 0x2502F65D77cA13f183850b5f9272270454094A08;
    address constant MCD_FLIP_UNIV2DAIETH_A = 0x57dfd99f45747DD55C1c432Db4aEa07FBd5d2B5c;
    address constant PIP_UNIV2DAIETH        = 0x87ecBd742cEB40928E6cDE77B2f0b5CFa3342A09;
    bytes32 constant ILK_UNIV2DAIETH_A      = "UNIV2DAIETH-A";

    // Gnosis
    address constant GNOSIS = 0xD5885fbCb9a8a8244746010a3BC6F1C6e0269777;

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
    uint256 constant ZERO_PERCENT_RATE            = 1000000000000000000000000000;
    uint256 constant ONE_PERCENT_RATE             = 1000000000315522921573372069;
    uint256 constant TWO_PERCENT_RATE             = 1000000000627937192491029810;
    uint256 constant TWO_POINT_FIVE_PERCENT_RATE  = 1000000000782997609082909351;
    uint256 constant THREE_PERCENT_RATE           = 1000000000937303470807876289;
    uint256 constant FOUR_POINT_FIVE_PERCENT_RATE = 1000000001395766281313196627;
    uint256 constant FIVE_PERCENT_RATE            = 1000000001547125957863212448;
    uint256 constant SIX_PERCENT_RATE             = 1000000001847694957439350562;
    uint256 constant EIGHT_PERCENT_RATE           = 1000000002440418608258400030;
    uint256 constant NINE_PERCENT_RATE            = 1000000002732676825177582095;
    uint256 constant TEN_PERCENT_RATE             = 1000000003022265980097387650;

    modifier limited {
        if (officeHours) {
            uint day = (block.timestamp / 1 days + 3) % 7;
            require(day < 5, "Can only be cast on a weekday");
            uint hour = block.timestamp / 1 hours % 24;
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
        address PIP_ETH      = CHANGELOG.getAddress("PIP_ETH");

        // Set the global debt ceiling
        // + 10 M for AAVE-A
        // +  3 M for UNIV2DAIETH-A
        VatAbstract(MCD_VAT).file("Line", VatAbstract(MCD_VAT).Line() + 10 * MILLION * RAD + 3 * MILLION * RAD);

        //
        // Add AAVE
        //
        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_AAVE_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_AAVE_A).ilk() == ILK_AAVE_A, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_AAVE_A).gem() == AAVE, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_AAVE_A).dec() == DSTokenAbstract(AAVE).decimals(), "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_AAVE_A).vat() == MCD_VAT, "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_AAVE_A).cat() == MCD_CAT, "flip-cat-not-match");
        require(FlipAbstract(MCD_FLIP_AAVE_A).ilk() == ILK_AAVE_A, "flip-ilk-not-match");

        // Set the AAVE PIP in the Spotter
        SpotAbstract(MCD_SPOT).file(ILK_AAVE_A, "pip", PIP_AAVE);

        // Set the AAVE-A Flipper in the Cat
        CatAbstract(MCD_CAT).file(ILK_AAVE_A, "flip", MCD_FLIP_AAVE_A);

        // Init AAVE-A ilk in Vat & Jug
        VatAbstract(MCD_VAT).init(ILK_AAVE_A);
        JugAbstract(MCD_JUG).init(ILK_AAVE_A);

        // Allow AAVE-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_AAVE_A);
        // Allow the AAVE-A Flipper to reduce the Cat litterbox on deal()
        CatAbstract(MCD_CAT).rely(MCD_FLIP_AAVE_A);
        // Allow Cat to kick auctions in AAVE-A Flipper
        FlipAbstract(MCD_FLIP_AAVE_A).rely(MCD_CAT);
        // Allow End to yank auctions in AAVE-A Flipper
        FlipAbstract(MCD_FLIP_AAVE_A).rely(MCD_END);
        // Allow FlipperMom to access to the AAVE-A Flipper
        FlipAbstract(MCD_FLIP_AAVE_A).rely(FLIPPER_MOM);
        // Disallow Cat to kick auctions in AAVE-A Flipper
        // !!!!!!!! Only for certain collaterals that do not trigger liquidations like USDC-A)
        //FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_AAVE_A);

        // Allow OsmMom to access to the AAVE Osm
        // !!!!!!!! Only if PIP_AAVE = Osm and hasn't been already relied due a previous deployed ilk
        OsmAbstract(PIP_AAVE).rely(OSM_MOM);
        // Whitelist Osm to read the Median data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_AAVE = Osm, its src is a Median and hasn't been already whitelisted due a previous deployed ilk
        MedianAbstract(OsmAbstract(PIP_AAVE).src()).kiss(PIP_AAVE);
        // Whitelist Spotter to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_AAVE = Osm or PIP_AAVE = Median and hasn't been already whitelisted due a previous deployed ilk
        OsmAbstract(PIP_AAVE).kiss(MCD_SPOT);
        // Whitelist End to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_AAVE = Osm or PIP_AAVE = Median and hasn't been already whitelisted due a previous deployed ilk
        OsmAbstract(PIP_AAVE).kiss(MCD_END);
        // Set AAVE Osm in the OsmMom for new ilk
        // !!!!!!!! Only if PIP_AAVE = Osm
        OsmMomAbstract(OSM_MOM).setOsm(ILK_AAVE_A, PIP_AAVE);

        // Set the AAVE-A debt ceiling
        VatAbstract(MCD_VAT).file(ILK_AAVE_A, "line", 10 * MILLION * RAD);
        // Set the AAVE-A dust
        VatAbstract(MCD_VAT).file(ILK_AAVE_A, "dust", 500 * RAD);
        // Set the Lot size
        CatAbstract(MCD_CAT).file(ILK_AAVE_A, "dunk", 50 * THOUSAND * RAD);
        // Set the AAVE-A liquidation penalty (e.g. 13% => X = 113)
        CatAbstract(MCD_CAT).file(ILK_AAVE_A, "chop", 113 * WAD / 100);
        // Set the AAVE-A stability fee (e.g. 1% = 1000000000315522921573372069)
        JugAbstract(MCD_JUG).file(ILK_AAVE_A, "duty", SIX_PERCENT_RATE);
        // Set the AAVE-A percentage between bids (e.g. 3% => X = 103)
        FlipAbstract(MCD_FLIP_AAVE_A).file("beg", 103 * WAD / 100);
        // Set the AAVE-A time max time between bids
        FlipAbstract(MCD_FLIP_AAVE_A).file("ttl", 6 hours);
        // Set the AAVE-A max auction duration to
        FlipAbstract(MCD_FLIP_AAVE_A).file("tau", 6 hours);
        // Set the AAVE-A min collateralization ratio (e.g. 150% => X = 150)
        SpotAbstract(MCD_SPOT).file(ILK_AAVE_A, "mat", 175 * RAY / 100);

        // Update AAVE-A spot value in Vat
        SpotAbstract(MCD_SPOT).poke(ILK_AAVE_A);

        // Add new ilk to the IlkRegistry
        IlkRegistryAbstract(ILK_REGISTRY).add(MCD_JOIN_AAVE_A);

        // Update the changelog
        CHANGELOG.setAddress("AAVE", AAVE);
        CHANGELOG.setAddress("MCD_JOIN_AAVE_A", MCD_JOIN_AAVE_A);
        CHANGELOG.setAddress("MCD_FLIP_AAVE_A", MCD_FLIP_AAVE_A);
        CHANGELOG.setAddress("PIP_AAVE", PIP_AAVE);


        //
        // Add UniswapV2 ETH/DAI
        //

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_UNIV2DAIETH_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_UNIV2DAIETH_A).ilk() == ILK_UNIV2DAIETH_A, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_UNIV2DAIETH_A).gem() == UNIV2DAIETH, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_UNIV2DAIETH_A).dec() == DSTokenAbstract(UNIV2DAIETH).decimals(), "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_UNIV2DAIETH_A).vat() == MCD_VAT, "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_UNIV2DAIETH_A).cat() == MCD_CAT, "flip-cat-not-match");
        require(FlipAbstract(MCD_FLIP_UNIV2DAIETH_A).ilk() == ILK_UNIV2DAIETH_A, "flip-ilk-not-match");

        // Set the UNIV2DAIETH PIP in the Spotter
        SpotAbstract(MCD_SPOT).file(ILK_UNIV2DAIETH_A, "pip", PIP_UNIV2DAIETH);

        // Set the UNIV2DAIETH-A Flipper in the Cat
        CatAbstract(MCD_CAT).file(ILK_UNIV2DAIETH_A, "flip", MCD_FLIP_UNIV2DAIETH_A);

        // Init UNIV2DAIETH-A ilk in Vat & Jug
        VatAbstract(MCD_VAT).init(ILK_UNIV2DAIETH_A);
        JugAbstract(MCD_JUG).init(ILK_UNIV2DAIETH_A);

        // Allow UNIV2DAIETH-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_UNIV2DAIETH_A);
        // Allow the UNIV2DAIETH-A Flipper to reduce the Cat litterbox on deal()
        CatAbstract(MCD_CAT).rely(MCD_FLIP_UNIV2DAIETH_A);
        // Allow Cat to kick auctions in UNIV2DAIETH-A Flipper
        FlipAbstract(MCD_FLIP_UNIV2DAIETH_A).rely(MCD_CAT);
        // Allow End to yank auctions in UNIV2DAIETH-A Flipper
        FlipAbstract(MCD_FLIP_UNIV2DAIETH_A).rely(MCD_END);
        // Allow FlipperMom to access to the UNIV2DAIETH-A Flipper
        FlipAbstract(MCD_FLIP_UNIV2DAIETH_A).rely(FLIPPER_MOM);
        // Disallow Cat to kick auctions in UNIV2DAIETH-A Flipper
        // !!!!!!!! Only for certain collaterals that do not trigger liquidations like USDC-A)
        //FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_UNIV2DAIETH_A);

        // Allow OsmMom to access to the UNIV2DAIETH Osm
        // !!!!!!!! Only if PIP_UNIV2DAIETH = Osm and hasn't been already relied due a previous deployed ilk
        LPOsmAbstract(PIP_UNIV2DAIETH).rely(OSM_MOM);
        // Whitelist Osm to read the Median data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_UNIV2DAIETH = Osm, its src is a Median and hasn't been already whitelisted due a previous deployed ilk
        MedianAbstract(LPOsmAbstract(PIP_UNIV2DAIETH).orb1()).kiss(PIP_UNIV2DAIETH);
        // Whitelist Spotter to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_UNIV2DAIETH = Osm or PIP_UNIV2DAIETH = Median and hasn't been already whitelisted due a previous deployed ilk
        LPOsmAbstract(PIP_UNIV2DAIETH).kiss(MCD_SPOT);
        // Whitelist End to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_UNIV2DAIETH = Osm or PIP_UNIV2DAIETH = Median and hasn't been already whitelisted due a previous deployed ilk
        LPOsmAbstract(PIP_UNIV2DAIETH).kiss(MCD_END);
        // Set UNIV2DAIETH Osm in the OsmMom for new ilk
        // !!!!!!!! Only if PIP_UNIV2DAIETH = Osm
        OsmMomAbstract(OSM_MOM).setOsm(ILK_UNIV2DAIETH_A, PIP_UNIV2DAIETH);

        // Set the UNIV2DAIETH-A debt ceiling
        VatAbstract(MCD_VAT).file(ILK_UNIV2DAIETH_A, "line", 3 * MILLION * RAD);
        // Set the UNIV2DAIETH-A dust
        VatAbstract(MCD_VAT).file(ILK_UNIV2DAIETH_A, "dust", 500 * RAD);
        // Set the Lot size
        CatAbstract(MCD_CAT).file(ILK_UNIV2DAIETH_A, "dunk", 50 * THOUSAND * RAD);
        // Set the UNIV2DAIETH-A liquidation penalty (e.g. 13% => X = 113)
        CatAbstract(MCD_CAT).file(ILK_UNIV2DAIETH_A, "chop", 113 * WAD / 100);
        // Set the UNIV2DAIETH-A stability fee (e.g. 1% = 1000000000315522921573372069)
        JugAbstract(MCD_JUG).file(ILK_UNIV2DAIETH_A, "duty", ONE_PERCENT_RATE);
        // Set the UNIV2DAIETH-A percentage between bids (e.g. 3% => X = 103)
        FlipAbstract(MCD_FLIP_UNIV2DAIETH_A).file("beg", 103 * WAD / 100);
        // Set the UNIV2DAIETH-A time max time between bids
        FlipAbstract(MCD_FLIP_UNIV2DAIETH_A).file("ttl", 6 hours);
        // Set the UNIV2DAIETH-A max auction duration to
        FlipAbstract(MCD_FLIP_UNIV2DAIETH_A).file("tau", 6 hours);
        // Set the UNIV2DAIETH-A min collateralization ratio (e.g. 150% => X = 150)
        SpotAbstract(MCD_SPOT).file(ILK_UNIV2DAIETH_A, "mat", 125 * RAY / 100);

        // Update UNIV2DAIETH-A spot value in Vat
        SpotAbstract(MCD_SPOT).poke(ILK_UNIV2DAIETH_A);

        // Add new ilk to the IlkRegistry
        IlkRegistryAbstract(ILK_REGISTRY).add(MCD_JOIN_UNIV2DAIETH_A);

        // Update the changelog
        CHANGELOG.setAddress("UNIV2DAIETH", UNIV2DAIETH);
        CHANGELOG.setAddress("MCD_JOIN_UNIV2DAIETH_A", MCD_JOIN_UNIV2DAIETH_A);
        CHANGELOG.setAddress("MCD_FLIP_UNIV2DAIETH_A", MCD_FLIP_UNIV2DAIETH_A);
        CHANGELOG.setAddress("PIP_UNIV2DAIETH", PIP_UNIV2DAIETH);
        // Bump version
        CHANGELOG.setVersion("1.2.2");

        //
        // Various polling changes
        //

        // Whitelist Gnosis on ETHUSD Oracle (MIP10c9-SP15) - December 14, 2020
        // https://vote.makerdao.com/polling/QmUqW1pf#poll-detail
        OsmAbstract(PIP_ETH).kiss(GNOSIS);

        // Rates Proposal - December 14, 2020
        // https://vote.makerdao.com/polling/QmTTjqGb?network=mainnet#poll-detail
        // Increase the ETH-A stability fee from 2% to 2.5%.
        JugAbstract(MCD_JUG).drip("ETH-A");
        JugAbstract(MCD_JUG).file("ETH-A", "duty", TWO_POINT_FIVE_PERCENT_RATE);
        // Increase the ETH-B stability fee from 4% to 5%.
        JugAbstract(MCD_JUG).drip("ETH-B");
        JugAbstract(MCD_JUG).file("ETH-B", "duty", FIVE_PERCENT_RATE);
        // Increase the WBTC-A stability fee from 4% to 4.5%.
        JugAbstract(MCD_JUG).drip("WBTC-A");
        JugAbstract(MCD_JUG).file("WBTC-A", "duty", FOUR_POINT_FIVE_PERCENT_RATE);
        // Increase the BAT-A stability fee from 4% to 8%.
        JugAbstract(MCD_JUG).drip("BAT-A");
        JugAbstract(MCD_JUG).file("BAT-A", "duty", EIGHT_PERCENT_RATE);
        // Decrease the KNC-A stability fee from 4% to 2%.
        JugAbstract(MCD_JUG).drip("KNC-A");
        JugAbstract(MCD_JUG).file("KNC-A", "duty", TWO_PERCENT_RATE);
        // Decrease the ZRX-A stability fee from 4% to 2%.
        JugAbstract(MCD_JUG).drip("ZRX-A");
        JugAbstract(MCD_JUG).file("ZRX-A", "duty", TWO_PERCENT_RATE);
        // Decrease the MANA-A stability fee from 12% to 10%.
        JugAbstract(MCD_JUG).drip("MANA-A");
        JugAbstract(MCD_JUG).file("MANA-A", "duty", TEN_PERCENT_RATE);
        // Decrease the COMP-A stability fee from 3% to 2%.
        JugAbstract(MCD_JUG).drip("COMP-A");
        JugAbstract(MCD_JUG).file("COMP-A", "duty", TWO_PERCENT_RATE);
        // Decrease the BAL-A stability fee from 5% to 2%.
        JugAbstract(MCD_JUG).drip("BAL-A");
        JugAbstract(MCD_JUG).file("BAL-A", "duty", TWO_PERCENT_RATE);
        // Decrease the YFI-A stability fee from 10% to 9%.
        JugAbstract(MCD_JUG).drip("YFI-A");
        JugAbstract(MCD_JUG).file("YFI-A", "duty", NINE_PERCENT_RATE);

    }
}

contract DssSpell {
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    DSPauseAbstract immutable public pause;
    address         immutable public action;
    bytes32         immutable public tag;
    uint256         immutable public expiration;
    uint256         public eta;
    bytes           public sig;
    bool            public done;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/be0d35d9e457d1f87a4ea06863d3e8db90bff7b9/governance/votes/Executive%20vote%20-%20December%2018%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-12-18 MakerDAO Executive Spell | Hash: 0x88410d74be25d71344e5c2e2b1855b666e865ac29271778a9e5ff1b8bc931318";

    function officeHours() external view returns (bool) {
        return SpellAction(action).officeHours();
    }

    constructor() public {
        pause = DSPauseAbstract(CHANGELOG.getAddress("MCD_PAUSE"));
        sig = abi.encodeWithSignature("execute()");
        bytes32 _tag;
        address _action = action = address(new SpellAction());
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = block.timestamp + 30 days;
    }

    function nextCastTime() external view returns (uint256 castTime) {
        require(eta != 0, "DSSSpell/spell-not-scheduled");
        castTime = block.timestamp > eta ? block.timestamp : eta; // Any day at XX:YY

        if (SpellAction(action).officeHours()) {
            uint256 day    = (castTime / 1 days + 3) % 7;
            uint256 hour   = castTime / 1 hours % 24;
            uint256 minute = castTime / 1 minutes % 60;
            uint256 second = castTime % 60;

            if (day >= 5) {
                castTime += (6 - day) * 1 days;                 // Go to Sunday XX:YY
                castTime += (24 - hour + 14) * 1 hours;         // Go to 14:YY UTC Monday
                castTime -= minute * 1 minutes + second;        // Go to 14:00 UTC
            } else {
                if (hour >= 21) {
                    if (day == 4) castTime += 2 days;           // If Friday, fast forward to Sunday XX:YY
                    castTime += (24 - hour + 14) * 1 hours;     // Go to 14:YY UTC next day
                    castTime -= minute * 1 minutes + second;    // Go to 14:00 UTC
                } else if (hour < 14) {
                    castTime += (14 - hour) * 1 hours;          // Go to 14:YY UTC same day
                    castTime -= minute * 1 minutes + second;    // Go to 14:00 UTC
                }
            }
        }
    }

    function schedule() external {
        require(block.timestamp <= expiration, "DSSSpell/spell-has-expired");
        require(eta == 0, "DSSSpell/spell-already-scheduled");
        eta = block.timestamp + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() external {
        require(!done, "DSSSpell/spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
