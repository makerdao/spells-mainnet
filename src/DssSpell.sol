// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
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
import "lib/dss-interfaces/src/dss/DaiJoinAbstract.sol";
import "lib/dss-interfaces/src/dss/IlkRegistryAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dss/CatAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/SpotAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipAbstract.sol";
import "lib/dss-interfaces/src/dss/GemJoinAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmMomAbstract.sol";
import "lib/dss-interfaces/src/dss/MedianAbstract.sol";
import "lib/dss-interfaces/src/dss/LPOsmAbstract.sol";

interface LerpFabLike {
    function newIlkLerp(address target_, bytes32 ilk_, bytes32 what_, uint256 start_, uint256 end_, uint256 duration_) external returns (address);
}

interface LerpLike {
    function init() external;
}

contract SpellAction {
    // Office hours enabled if true
    bool constant public officeHours = false;

    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/active/contracts.json
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    // Ilks
    bytes32 constant ILK_LINK_A         = "LINK-A";
    bytes32 constant ILK_MANA_A         = "MANA-A";
    bytes32 constant ILK_BAT_A          = "BAT-A";
    bytes32 constant ILK_TUSD_A         = "TUSD-A";
    bytes32 constant ILK_PSM_USDC_A     = "PSM-USDC-A";

    // UNIV2WBTCETH-A
    address constant UNIV2WBTCETH            = 0xBb2b8038a1640196FbE3e38816F3e67Cba72D940;
    address constant MCD_JOIN_UNIV2WBTCETH_A = 0xDc26C9b7a8fe4F5dF648E314eC3E6Dc3694e6Dd2;
    address constant MCD_FLIP_UNIV2WBTCETH_A = 0xbc95e8904d879F371Ac6B749727a0EAfDCd2ACB6;
    address constant PIP_UNIV2WBTCETH        = 0x771338D5B31754b25D2eb03Cea676877562Dec26; 
    bytes32 constant ILK_UNIV2WBTCETH_A      = "UNIV2WBTCETH-A";

    // UNIV2USDCETH-A
    address constant UNIV2USDCETH            = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;
    address constant MCD_JOIN_UNIV2USDCETH_A = 0x03Ae53B33FeeAc1222C3f372f32D37Ba95f0F099;
    address constant MCD_FLIP_UNIV2USDCETH_A = 0x48d2C08b93E57701C8ae8974Fc4ADd725222B0BB;
    address constant PIP_UNIV2USDCETH        = 0xECB03Fec701B93DC06d19B4639AA8b5a838472BE;
    bytes32 constant ILK_UNIV2USDCETH_A      = "UNIV2USDCETH-A";

    // Lerp Module - https://github.com/BellwoodStudios/dss-lerp
    address constant LERP_FAB = 0x9B98aF142993877BEF8FC5cA514fD8A18E8f8Ed6;

    // Oracle whitelist
    address constant ETHUSD_OSM    = 0x81FE72B5A8d1A857d176C3E7d5Bd2679A9B85763;
    address constant INSTA_DAPP    = 0xDF3CDd10e646e4155723a3bC5b1191741DD90333;

    // rates
    uint256 constant ONE_PERCENT_RATE = 1000000000315522921573372069;
	uint256 constant TWO_PERCENT_RATE = 1000000000627937192491029810;

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
        address MCD_SPOT     = CHANGELOG.getAddress("MCD_SPOT");
        address MCD_JUG      = CHANGELOG.getAddress("MCD_JUG");
        address MCD_END      = CHANGELOG.getAddress("MCD_END");
        address MCD_VOW      = CHANGELOG.getAddress("MCD_VOW");
        address FLIPPER_MOM  = CHANGELOG.getAddress("FLIPPER_MOM");
        address OSM_MOM      = CHANGELOG.getAddress("OSM_MOM");
        address MCD_JOIN_DAI = CHANGELOG.getAddress("MCD_JOIN_DAI");
        address ILK_REGISTRY = CHANGELOG.getAddress("ILK_REGISTRY");

        // Adjust Debt Ceiling Parameters - January 18, 2021
        // https://vote.makerdao.com/polling/QmQtn7UY#poll-detail - LINK-A
        // https://vote.makerdao.com/polling/QmSCLfXN#poll-detail - MANA-A
        // https://vote.makerdao.com/polling/QmW4ei2M#poll-detail - BAT-A
        // https://vote.makerdao.com/polling/QmXTGwq4#poll-detail - TUSD-A
        // https://vote.makerdao.com/polling/QmfTU85J#poll-detail - PSM-USDC-A [ December 14, 2020 ]

        // Set the global debt ceiling
        // + 10 M for LINK-A
        // + 750 K for WBTC-A [ Note: Units ]
        // - 8 M for WBTC-A
        // - 135 M for TUSD-A
        // + 470 M for PSM-USDC-A [ Lerp End Amount ]
        // TODO: WBTC-ETH UNI LP
        // TODO: USDC-ETH UNI LP
        // VatAbstract(MCD_VAT).file("Line",
        //     VatAbstract(MCD_VAT).Line()
        //     + 10 * MILLION * RAD
        //     + 750 * THOUSAND * RAD
        //     - 8 * MILLION * RAD
        //     - 135 * MILLION * RAD
        //     + 470 * MILLION * RAD
        // );
        // TODO: fix this, this includes 6M for the two uni lp tokens
        VatAbstract(MCD_VAT).file("Line",
            VatAbstract(MCD_VAT).Line()
            + 937750 * THOUSAND * RAD
            + 6 * MILLION * RAD
        );

        // Update the Debt Ceilings
        VatAbstract(MCD_VAT).file(ILK_LINK_A, "line", 20 * MILLION * RAD);
        VatAbstract(MCD_VAT).file(ILK_MANA_A, "line", 1 * MILLION * RAD);
        VatAbstract(MCD_VAT).file(ILK_BAT_A, "line", 2 * MILLION * RAD);
        VatAbstract(MCD_VAT).file(ILK_TUSD_A, "line", 0 * MILLION * RAD);
        // Note: PSM-USDC-A is set to 80 M in the Lerp.init()

        // Setup the Lerp module
        address lerp = LerpFabLike(LERP_FAB).newIlkLerp(MCD_VAT, ILK_PSM_USDC_A, "line", 80 * MILLION * RAD, 500 * MILLION * RAD, 12 weeks);
        VatAbstract(MCD_VAT).rely(lerp);
        LerpLike(lerp).init();

        // Set dust to 2000 DAI - January 18, 2021
        // https://vote.makerdao.com/polling/QmWPAu5z#poll-detail
        bytes32[] memory ilks = IlkRegistryAbstract(ILK_REGISTRY).list();
        for (uint256 i = 0; i < ilks.length; i++) {
            (,,,, uint256 dust) = VatAbstract(MCD_VAT).ilks(ilks[i]);
            if (dust != 0) {
                VatAbstract(MCD_VAT).file(ilks[i], "dust", 2000 * RAD);
            }
        }

        // Vault Compensation Working Group Payment - January 18, 2021
        // https://vote.makerdao.com/polling/QmQcXFeC#poll-detail
        VatAbstract(MCD_VAT).suck(MCD_VOW, address(this), 12700 * RAD);
        VatAbstract(MCD_VAT).hope(MCD_JOIN_DAI);
        
        // @makerman: 6,300 Dai for 126 hours to [0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0]
        DaiJoinAbstract(MCD_JOIN_DAI).exit(0x9AC6A6B24bCd789Fa59A175c0514f33255e1e6D0, 6300 * WAD);
        // @monet-supply: 3,800 Dai for 76 hours to [0x8d07D225a769b7Af3A923481E1FdF49180e6A265]
        DaiJoinAbstract(MCD_JOIN_DAI).exit(0x8d07D225a769b7Af3A923481E1FdF49180e6A265, 3800 * WAD);
        // @Joshua_Pritikin: 2,000 Dai for 40 hours to [0x2235A5D7bCC37855CB91dFf66334F4DFD9C39b58]
        DaiJoinAbstract(MCD_JOIN_DAI).exit(0x2235A5D7bCC37855CB91dFf66334F4DFD9C39b58, 2000 * WAD);
        // @befitsandpiper: 400 Dai for 8 hours to [0x851fB899dA7F80c211d9B8e5f231FB3BC9eca41a]
        DaiJoinAbstract(MCD_JOIN_DAI).exit(0x851fB899dA7F80c211d9B8e5f231FB3BC9eca41a, 400 * WAD);
        // @Vault2288: 200 Dai for 4 hours to [0x92e5a14b08E5232682Eb38269A1cE661F04Ec93D]
        DaiJoinAbstract(MCD_JOIN_DAI).exit(0x92e5a14b08E5232682Eb38269A1cE661F04Ec93D, 200 * WAD);

        VatAbstract(MCD_VAT).nope(MCD_JOIN_DAI);

        // Whitelist Instadapp on ETHUSD Oracle - January 18, 2021
        // https://vote.makerdao.com/polling/QmNSb2cu#poll-detail
        OsmAbstract(ETHUSD_OSM).kiss(INSTA_DAPP);

        //
        // TODO: Onboard WBTC-ETH UNI LP
        //

		// Sanity checks
        require(GemJoinAbstract(MCD_JOIN_UNIV2WBTCETH_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_UNIV2WBTCETH_A).ilk() == ILK_UNIV2WBTCETH_A, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_UNIV2WBTCETH_A).gem() == UNIV2WBTCETH, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_UNIV2WBTCETH_A).dec() == DSTokenAbstract(UNIV2WBTCETH).decimals(), "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_UNIV2WBTCETH_A).vat() == MCD_VAT, "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_UNIV2WBTCETH_A).cat() == MCD_CAT, "flip-cat-not-match");
        require(FlipAbstract(MCD_FLIP_UNIV2WBTCETH_A).ilk() == ILK_UNIV2WBTCETH_A, "flip-ilk-not-match");

        // Set the UNIV2WBTCETH PIP in the Spotter
        SpotAbstract(MCD_SPOT).file(ILK_UNIV2WBTCETH_A, "pip", PIP_UNIV2WBTCETH);

        // Set the UNIV2WBTCETH-A Flipper in the Cat
        CatAbstract(MCD_CAT).file(ILK_UNIV2WBTCETH_A, "flip", MCD_FLIP_UNIV2WBTCETH_A);

        // Init UNIV2WBTCETH-A ilk in Vat & Jug
        VatAbstract(MCD_VAT).init(ILK_UNIV2WBTCETH_A);
        JugAbstract(MCD_JUG).init(ILK_UNIV2WBTCETH_A);

        // Allow UNIV2WBTCETH-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_UNIV2WBTCETH_A);
        // Allow the UNIV2WBTCETH-A Flipper to reduce the Cat litterbox on deal()
        CatAbstract(MCD_CAT).rely(MCD_FLIP_UNIV2WBTCETH_A);
        // Allow Cat to kick auctions in UNIV2WBTCETH-A Flipper
        FlipAbstract(MCD_FLIP_UNIV2WBTCETH_A).rely(MCD_CAT);
        // Allow End to yank auctions in UNIV2WBTCETH-A Flipper
        FlipAbstract(MCD_FLIP_UNIV2WBTCETH_A).rely(MCD_END);
        // Allow FlipperMom to access to the UNIV2WBTCETH-A Flipper
        FlipAbstract(MCD_FLIP_UNIV2WBTCETH_A).rely(FLIPPER_MOM);
        // Disallow Cat to kick auctions in UNIV2WBTCETH-A Flipper
        // !!!!!!!! Only for certain collaterals that do not trigger liquidations like USDC-A)
        //FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_UNIV2WBTCETH_A);

        // Allow OsmMom to access to the UNIV2WBTCETH Osm
        // !!!!!!!! Only if PIP_UNIV2WBTCETH = Osm and hasn't been already relied due a previous deployed ilk
        LPOsmAbstract(PIP_UNIV2WBTCETH).rely(OSM_MOM);

        // Whitelist Osm to read the Median data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_UNIV2WBTCETH = Osm, its src is a Median and hasn't been already whitelisted due a previous deployed ilk
        MedianAbstract(LPOsmAbstract(PIP_UNIV2WBTCETH).orb0()).kiss(PIP_UNIV2WBTCETH);
        MedianAbstract(LPOsmAbstract(PIP_UNIV2WBTCETH).orb1()).kiss(PIP_UNIV2WBTCETH);

        // Whitelist Spotter to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_UNIV2WBTCETH = Osm or PIP_UNIV2WBTCETH = Median and hasn't been already whitelisted due a previous deployed ilk
        LPOsmAbstract(PIP_UNIV2WBTCETH).kiss(MCD_SPOT);

        // Whitelist End to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_UNIV2WBTCETH = Osm or PIP_UNIV2WBTCETH = Median and hasn't been already whitelisted due a previous deployed ilk
        LPOsmAbstract(PIP_UNIV2WBTCETH).kiss(MCD_END);
        // Set UNIV2WBTCETH Osm in the OsmMom for new ilk
        // !!!!!!!! Only if PIP_UNIV2WBTCETH = Osm
        OsmMomAbstract(OSM_MOM).setOsm(ILK_UNIV2WBTCETH_A, PIP_UNIV2WBTCETH);

        // Set the UNIV2WBTCETH-A debt ceiling
        VatAbstract(MCD_VAT).file(ILK_UNIV2WBTCETH_A, "line", 3 * MILLION * RAD);
        // Set the UNIV2WBTCETH-A dust
        VatAbstract(MCD_VAT).file(ILK_UNIV2WBTCETH_A, "dust", 2000 * RAD);
        // Set the Lot size
        CatAbstract(MCD_CAT).file(ILK_UNIV2WBTCETH_A, "dunk", 50 * THOUSAND * RAD);
        // Set the UNIV2WBTCETH-A liquidation penalty (e.g. 13% => X = 113)
        CatAbstract(MCD_CAT).file(ILK_UNIV2WBTCETH_A, "chop", 113 * WAD / 100);
        // Set the UNIV2WBTCETH-A stability fee (e.g. 1% = 1000000000315522921573372069)
        JugAbstract(MCD_JUG).file(ILK_UNIV2WBTCETH_A, "duty", TWO_PERCENT_RATE);
        // Set the UNIV2WBTCETH-A percentage between bids (e.g. 3% => X = 103)
        FlipAbstract(MCD_FLIP_UNIV2WBTCETH_A).file("beg", 103 * WAD / 100);
        // Set the UNIV2WBTCETH-A time max time between bids
        FlipAbstract(MCD_FLIP_UNIV2WBTCETH_A).file("ttl", 6 hours);
        // Set the UNIV2WBTCETH-A max auction duration to
        FlipAbstract(MCD_FLIP_UNIV2WBTCETH_A).file("tau", 6 hours);
        // Set the UNIV2WBTCETH-A min collateralization ratio (e.g. 150% => X = 150)
        SpotAbstract(MCD_SPOT).file(ILK_UNIV2WBTCETH_A, "mat", 150 * RAY / 100);

        // Update UNIV2WBTCETH-A spot value in Vat
        SpotAbstract(MCD_SPOT).poke(ILK_UNIV2WBTCETH_A);

        // Add new ilk to the IlkRegistry
        IlkRegistryAbstract(ILK_REGISTRY).add(MCD_JOIN_UNIV2WBTCETH_A);

        // Update the changelog
        CHANGELOG.setAddress("UNIV2WBTCETH", UNIV2WBTCETH);
        CHANGELOG.setAddress("MCD_JOIN_UNIV2WBTCETH_A", MCD_JOIN_UNIV2WBTCETH_A);
        CHANGELOG.setAddress("MCD_FLIP_UNIV2WBTCETH_A", MCD_FLIP_UNIV2WBTCETH_A);
        CHANGELOG.setAddress("PIP_UNIV2WBTCETH", PIP_UNIV2WBTCETH);

        //
        // TODO: Onboard USDC-ETH UNI LP
        //

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_UNIV2USDCETH_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_UNIV2USDCETH_A).ilk() == ILK_UNIV2USDCETH_A, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_UNIV2USDCETH_A).gem() == UNIV2USDCETH, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_UNIV2USDCETH_A).dec() == DSTokenAbstract(UNIV2USDCETH).decimals(), "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_UNIV2USDCETH_A).vat() == MCD_VAT, "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_UNIV2USDCETH_A).cat() == MCD_CAT, "flip-cat-not-match");
        require(FlipAbstract(MCD_FLIP_UNIV2USDCETH_A).ilk() == ILK_UNIV2USDCETH_A, "flip-ilk-not-match");

        // Set the UNIV2USDCETH PIP in the Spotter
        SpotAbstract(MCD_SPOT).file(ILK_UNIV2USDCETH_A, "pip", PIP_UNIV2USDCETH);

        // Set the UNIV2USDCETH-A Flipper in the Cat
        CatAbstract(MCD_CAT).file(ILK_UNIV2USDCETH_A, "flip", MCD_FLIP_UNIV2USDCETH_A);

        // Init UNIV2USDCETH-A ilk in Vat & Jug
        VatAbstract(MCD_VAT).init(ILK_UNIV2USDCETH_A);
        JugAbstract(MCD_JUG).init(ILK_UNIV2USDCETH_A);

        // Allow UNIV2USDCETH-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_UNIV2USDCETH_A);
        // Allow the UNIV2USDCETH-A Flipper to reduce the Cat litterbox on deal()
        CatAbstract(MCD_CAT).rely(MCD_FLIP_UNIV2USDCETH_A);
        // Allow Cat to kick auctions in UNIV2USDCETH-A Flipper
        FlipAbstract(MCD_FLIP_UNIV2USDCETH_A).rely(MCD_CAT);
        // Allow End to yank auctions in UNIV2USDCETH-A Flipper
        FlipAbstract(MCD_FLIP_UNIV2USDCETH_A).rely(MCD_END);
        // Allow FlipperMom to access to the UNIV2USDCETH-A Flipper
        FlipAbstract(MCD_FLIP_UNIV2USDCETH_A).rely(FLIPPER_MOM);
        // Disallow Cat to kick auctions in UNIV2USDCETH-A Flipper
        // !!!!!!!! Only for certain collaterals that do not trigger liquidations like USDC-A)
        //FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_UNIV2USDCETH_A);

        // Allow OsmMom to access to the UNIV2USDCETH Osm
        // !!!!!!!! Only if PIP_UNIV2USDCETH = Osm and hasn't been already relied due a previous deployed ilk
        LPOsmAbstract(PIP_UNIV2USDCETH).rely(OSM_MOM);
        // Whitelist Osm to read the Median data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_UNIV2USDCETH = Osm, its src is a Median and hasn't been already whitelisted due a previous deployed ilk
        MedianAbstract(LPOsmAbstract(PIP_UNIV2USDCETH).orb1()).kiss(PIP_UNIV2USDCETH);
        // Whitelist Spotter to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_UNIV2USDCETH = Osm or PIP_UNIV2USDCETH = Median and hasn't been already whitelisted due a previous deployed ilk
        LPOsmAbstract(PIP_UNIV2USDCETH).kiss(MCD_SPOT);
        // Whitelist End to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_UNIV2USDCETH = Osm or PIP_UNIV2USDCETH = Median and hasn't been already whitelisted due a previous deployed ilk
        LPOsmAbstract(PIP_UNIV2USDCETH).kiss(MCD_END);
        // Set UNIV2USDCETH Osm in the OsmMom for new ilk
        // !!!!!!!! Only if PIP_UNIV2USDCETH = Osm
        OsmMomAbstract(OSM_MOM).setOsm(ILK_UNIV2USDCETH_A, PIP_UNIV2USDCETH);

        // Set the UNIV2USDCETH-A debt ceiling
        VatAbstract(MCD_VAT).file(ILK_UNIV2USDCETH_A, "line", 3 * MILLION * RAD);
        // Set the UNIV2USDCETH-A dust
        VatAbstract(MCD_VAT).file(ILK_UNIV2USDCETH_A, "dust", 2000 * RAD);
        // Set the Lot size
        CatAbstract(MCD_CAT).file(ILK_UNIV2USDCETH_A, "dunk", 50 * THOUSAND * RAD);
        // Set the UNIV2USDCETH-A liquidation penalty (e.g. 13% => X = 113)
        CatAbstract(MCD_CAT).file(ILK_UNIV2USDCETH_A, "chop", 113 * WAD / 100);
        // Set the UNIV2USDCETH-A stability fee (e.g. 1% = 1000000000315522921573372069)
        JugAbstract(MCD_JUG).file(ILK_UNIV2USDCETH_A, "duty", ONE_PERCENT_RATE);
        // Set the UNIV2USDCETH-A percentage between bids (e.g. 3% => X = 103)
        FlipAbstract(MCD_FLIP_UNIV2USDCETH_A).file("beg", 103 * WAD / 100);
        // Set the UNIV2USDCETH-A time max time between bids
        FlipAbstract(MCD_FLIP_UNIV2USDCETH_A).file("ttl", 6 hours);
        // Set the UNIV2USDCETH-A max auction duration to
        FlipAbstract(MCD_FLIP_UNIV2USDCETH_A).file("tau", 6 hours);
        // Set the UNIV2USDCETH-A min collateralization ratio (e.g. 150% => X = 150)
        SpotAbstract(MCD_SPOT).file(ILK_UNIV2USDCETH_A, "mat", 125 * RAY / 100);

        // Update UNIV2USDCETH-A spot value in Vat
        SpotAbstract(MCD_SPOT).poke(ILK_UNIV2USDCETH_A);

        // Add new ilk to the IlkRegistry
        IlkRegistryAbstract(ILK_REGISTRY).add(MCD_JOIN_UNIV2USDCETH_A);

        // Update the changelog
        CHANGELOG.setAddress("UNIV2USDCETH", UNIV2USDCETH);
        CHANGELOG.setAddress("MCD_JOIN_UNIV2USDCETH_A", MCD_JOIN_UNIV2USDCETH_A);
        CHANGELOG.setAddress("MCD_FLIP_UNIV2USDCETH_A", MCD_FLIP_UNIV2USDCETH_A);
        CHANGELOG.setAddress("PIP_UNIV2USDCETH", PIP_UNIV2USDCETH);

        // Update the changelog
        CHANGELOG.setAddress("LERP_FAB", LERP_FAB);
        // Bump version
        CHANGELOG.setVersion("1.2.4");
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
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/e59032178a702181d82f7a2be12bd95714ff53e0/governance/votes/Community%20Executive%20vote%20-%20January%2022%2C%202021.md -q -O - 2>/dev/null)"
    string constant public description =
        "2021-01-22 MakerDAO Executive Spell | Hash: 0x2d13137cf10cdd9dcf9e5047d1894608d1d3893a5c07a1c8955f0d11726b12b2";

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
