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
import "lib/dss-interfaces/src/dss/CatAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipAbstract.sol";
import "lib/dss-interfaces/src/dss/IlkRegistryAbstract.sol";
import "lib/dss-interfaces/src/dss/GemJoinAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/MedianAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmMomAbstract.sol";
import "lib/dss-interfaces/src/dss/SpotAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";

contract SpellAction {
    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.1.1/contracts.json

    address constant MCD_VAT         = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant MCD_CAT         = 0xa5679C04fc3d9d8b0AaB1F0ab83555b301cA70Ea;
    address constant MCD_JUG         = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant MCD_SPOT        = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant MCD_POT         = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address constant MCD_END         = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;
    address constant FLIPPER_MOM     = 0xc4bE7F74Ee3743bDEd8E0fA218ee5cf06397f472;
    address constant OSM_MOM         = 0x76416A4d5190d071bfed309861527431304aA14f;
    address constant ILK_REGISTRY    = 0x8b4ce5DCbb01e0e1f0521cd8dCfb31B308E52c24;

    // COMP-A specific addresses
    address constant COMP            = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    address constant MCD_JOIN_COMP_A = 0xBEa7cDfB4b49EC154Ae1c0D731E4DC773A3265aA;
    address constant MCD_FLIP_COMP_A = ;
    address constant PIP_COMP        = ;

    // LRC-A specific addresses
    address constant LRC             = 0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD;
    address constant MCD_JOIN_LRC_A  = 0x6C186404A7A238D3d6027C0299D1822c1cf5d8f1;
    address constant MCD_FLIP_LRC_A  = ;
    address constant PIP_LRC         = ;

    // LINK specific addresses
    address constant LINK            = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address constant MCD_JOIN_LINK_A = 0xdFccAf8fDbD2F4805C174f856a317765B49E4a50;
    address constant MCD_FLIP_LINK_A = ;
    address constant PIP_LINK        = ;

    // Decimals & precision
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.01)/(60 * 60 * 24 * 365) )'
    //
    uint256 constant   ZERO_PERCENT_RATE = 1000000000000000000000000000;
    uint256 constant    ONE_PERCENT_RATE = 1000000000315522921573372069;
    uint256 constant    TWO_PERCENT_RATE = 1000000000627937192491029810;
    uint256 constant  THREE_PERCENT_RATE = 1000000000937303470807876289;
    uint256 constant   FOUR_PERCENT_RATE = 1000000001243680656318820312;
    uint256 constant  EIGHT_PERCENT_RATE = 1000000002440418608258400030;
    uint256 constant TWELVE_PERCENT_RATE = 1000000003593629043335673582;
    uint256 constant  FIFTY_PERCENT_RATE = 1000000012857214317438491659;

    function execute() external {
        /*** Risk Parameter Adjustments ***/
        
        /*** ETH-A ***/
        // Set Stability Fee to 0%
        JugAbstract(MCD_JUG).drip("ETH-A");
        JugAbstract(MCD_JUG).file("ETH-A", "duty", ZERO_PERCENT_RATE);

        /*** BAT-A ***/
        // Set Stability Fee to 4%
        JugAbstract(MCD_JUG).drip("BAT-A");
        JugAbstract(MCD_JUG).file("BAT-A", "duty", FOUR_PERCENT_RATE);

        /*** USDC-A ***/
        // Set Stability Fee to 0%
        JugAbstract(MCD_JUG).drip("USDC-A");
        JugAbstract(MCD_JUG).file("USDC-A", "duty", FOUR_PERCENT_RATE);
        // Set Debt Ceiling to $400 million
        VatAbstract(MCD_VAT).file("USDC-A", "line", 400 * MILLION * RAD);
        // Set Liquidation Ratio to 101%
        SpotAbstract(MCD_SPOT).file("USDC-A", "mat", 101 * RAY / 100);

        /*** USDC-B ***/
        // Set Stability Fee to 50%
        JugAbstract(MCD_JUG).drip("USDC-B");
        JugAbstract(MCD_JUG).file("USDC-B", "duty", FIFTY_PERCENT_RATE);

        /*** WBTC-A ***/
        // Set Stability Fee to 4%
        JugAbstract(MCD_JUG).drip("WBTC-A");
        JugAbstract(MCD_JUG).file("WBTC-A", "duty", FOUR_PERCENT_RATE);

        /*** TUSD-A ***/
        // Set Stability Fee to 0%
        JugAbstract(MCD_JUG).drip("TUSD-A");
        JugAbstract(MCD_JUG).file("TUSD-A", "duty", FOUR_PERCENT_RATE);
        // Set Debt Ceiling to $400 million
        VatAbstract(MCD_VAT).file("TUSD-A", "line", 50 * MILLION * RAD);
        // Set Liquidation Ratio to 101%
        SpotAbstract(MCD_SPOT).file("TUSD-A", "mat", 101 * RAY / 100);

        /*** KNC-A ***/
        // Set Stability Fee to 4%
        JugAbstract(MCD_JUG).drip("KNC-A");
        JugAbstract(MCD_JUG).file("KNC-A", "duty", FOUR_PERCENT_RATE);

        /*** ZRX-A ***/
        // Set Stability Fee to 4%
        JugAbstract(MCD_JUG).drip("ZRX-A");
        JugAbstract(MCD_JUG).file("ZRX-A", "duty", FOUR_PERCENT_RATE);

        /*** MANA-A ***/
        // Set Stability Fee to 12%
        JugAbstract(MCD_JUG).drip("MANA-A");
        JugAbstract(MCD_JUG).file("MANA-A", "duty", TWELVE_PERCENT_RATE);

        /*** USDT-A ***/
        // Set Stability Fee to 8%
        JugAbstract(MCD_JUG).drip("USDT-A");
        JugAbstract(MCD_JUG).file("USDT-A", "duty", EIGHT_PERCENT_RATE);

        /*** PAXUSD-A ***/
        // Set Stability Fee to 0%
        JugAbstract(MCD_JUG).drip("PAXUSD-A");
        JugAbstract(MCD_JUG).file("PAXUSD-A", "duty", FOUR_PERCENT_RATE);
        // Set Debt Ceiling to $400 million
        VatAbstract(MCD_VAT).file("PAXUSD-A", "line", 30 * MILLION * RAD);
        // Set Liquidation Ratio to 101%
        SpotAbstract(MCD_SPOT).file("PAXUSD-A", "mat", 101 * RAY / 100);

        // Set the global debt ceiling
        VatAbstract(MCD_VAT).file("Line", 1196 * MILLION * RAD);

        /************************************/
        /*** COMP-A COLLATERAL ONBOARDING ***/
        /************************************/
        // Set ilk bytes32 variable
        bytes32 ilk = "COMP-A";

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_COMP_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_COMP_A).ilk() == ilk,     "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_COMP_A).gem() == COMP,    "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_COMP_A).dec() == 18,      "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_COMP_A).vat() == MCD_VAT,    "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_COMP_A).cat() == MCD_CAT,    "flip-cat-not-match");
        require(FlipAbstract(MCD_FLIP_COMP_A).ilk() == ilk,        "flip-ilk-not-match");

        // Set the COMP PIP in the Spotter
        SpotAbstract(MCD_SPOT).file(ilk, "pip", PIP_COMP);

        // Set the COMP-A Flipper in the Cat
        CatAbstract(MCD_CAT).file(ilk, "flip", MCD_FLIP_COMP_A);

        // Init COMP-A ilk in Vat & Jug
        VatAbstract(MCD_VAT).init(ilk);
        JugAbstract(MCD_JUG).init(ilk);

        // Allow COMP-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_COMP_A);
        // Allow the COMP-A Flipper to reduce the Cat litterbox on deal()
        CatAbstract(MCD_CAT).rely(MCD_FLIP_COMP_A);
        // Allow Cat to kick auctions in COMP-A Flipper
        FlipAbstract(MCD_FLIP_COMP_A).rely(MCD_CAT);
        // Allow End to yank auctions in COMP-A Flipper
        FlipAbstract(MCD_FLIP_COMP_A).rely(MCD_END);
        // Allow FlipperMom to access to the COMP-A Flipper
        FlipAbstract(MCD_FLIP_COMP_A).rely(FLIPPER_MOM);

        // Allow OsmMom to access to the COMP Osm
        OsmAbstract(PIP_COMP).rely(OSM_MOM);
        // Whitelist Osm to read the Median data (only necessary if it is the first time the token is being added to an ilk)
        MedianAbstract(OsmAbstract(PIP_COMP).src()).kiss(PIP_COMP);
        // Whitelist Spotter to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        OsmAbstract(PIP_COMP).kiss(MCD_SPOT);
        // Whitelist End to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        OsmAbstract(PIP_COMP).kiss(MCD_END);
        // Set COMP Osm in the OsmMom for new ilk
        OsmMomAbstract(OSM_MOM).setOsm(ilk, PIP_COMP);

        // Set the COMP-A debt ceiling
        VatAbstract(MCD_VAT).file(ilk, "line", 7 * MILLION * RAD);
        // Set the COMP-A dust
        VatAbstract(MCD_VAT).file(ilk, "dust", 100 * RAD);
        // Set the COMP-A dunk
        CatAbstract(MCD_CAT).file(ilk, "dunk", 500 * RAD);
        // Set the COMP-A liquidation penalty 
        CatAbstract(MCD_CAT).file(ilk, "chop", 113 * WAD / 100);
        // Set the COMP-A stability fee 
        JugAbstract(MCD_JUG).file(ilk, "duty", ONE_PERCENT_RATE);
        // Set the COMP-A percentage between bids 
        FlipAbstract(MCD_FLIP_COMP_A).file("beg", 103 * WAD / 100);
        // Set the COMP-A time max time between bids
        FlipAbstract(MCD_FLIP_COMP_A).file("ttl", 1 hours);
        // Set the COMP-A max auction duration to
        FlipAbstract(MCD_FLIP_COMP_A).file("tau", 1 hours);
        // Set the COMP-A min collateralization ratio 
        SpotAbstract(MCD_SPOT).file(ilk, "mat", 175 * RAY / 100);

        // Update COMP-A spot value in Vat
        SpotAbstract(MCD_SPOT).poke(ilk);

        // Add new ilk to the IlkRegistry
        IlkRegistryAbstract(ILK_REGISTRY).add(MCD_JOIN_COMP_A);

        // Set Faucet amount
        FaucetAbstract(FAUCET).setAmt(COMP, 2 * WAD);


        /***********************************/
        /*** LRC-A COLLATERAL ONBOARDING ***/
        /***********************************/
        // Set ilk bytes32 variable
        ilk = "LRC-A";

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_LRC_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_LRC_A).ilk() == ilk,     "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_LRC_A).gem() == LRC,     "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_LRC_A).dec() == 18,      "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_LRC_A).vat() == MCD_VAT,    "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_LRC_A).cat() == MCD_CAT,    "flip-cat-not-match");
        require(FlipAbstract(MCD_FLIP_LRC_A).ilk() == ilk,        "flip-ilk-not-match");

        // Set the LRC PIP in the Spotter
        SpotAbstract(MCD_SPOT).file(ilk, "pip", PIP_LRC);

        // Set the LRC-A Flipper in the Cat
        CatAbstract(MCD_CAT).file(ilk, "flip", MCD_FLIP_LRC_A);

        // Init LRC-A ilk in Vat & Jug
        VatAbstract(MCD_VAT).init(ilk);
        JugAbstract(MCD_JUG).init(ilk);

        // Allow LRC-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_LRC_A);
        // Allow the LRC-A Flipper to reduce the Cat litterbox on deal()
        CatAbstract(MCD_CAT).rely(MCD_FLIP_LRC_A);
        // Allow Cat to kick auctions in LRC-A Flipper
        FlipAbstract(MCD_FLIP_LRC_A).rely(MCD_CAT);
        // Allow End to yank auctions in LRC-A Flipper
        FlipAbstract(MCD_FLIP_LRC_A).rely(MCD_END);
        // Allow FlipperMom to access to the LRC-A Flipper
        FlipAbstract(MCD_FLIP_LRC_A).rely(FLIPPER_MOM);

        // Allow OsmMom to access to the LRC Osm
        OsmAbstract(PIP_LRC).rely(OSM_MOM);
        // Whitelist Osm to read the Median data (only necessary if it is the first time the token is being added to an ilk)
        MedianAbstract(OsmAbstract(PIP_LRC).src()).kiss(PIP_LRC);
        // Whitelist Spotter to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        OsmAbstract(PIP_LRC).kiss(MCD_SPOT);
        // Whitelist End to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        OsmAbstract(PIP_LRC).kiss(MCD_END);
        // Set LRC Osm in the OsmMom for new ilk
        OsmMomAbstract(OSM_MOM).setOsm(ilk, PIP_LRC);

        // Set the LRC-A debt ceiling
        VatAbstract(MCD_VAT).file(ilk, "line", 3 * MILLION * RAD);
        // Set the LRC-A dust
        VatAbstract(MCD_VAT).file(ilk, "dust", 100 * RAD);
        // Set the LRC-A dunk
        CatAbstract(MCD_CAT).file(ilk, "dunk", 500 * RAD);
        // Set the LRC-A liquidation penalty 
        CatAbstract(MCD_CAT).file(ilk, "chop", 113 * WAD / 100);
        // Set the LRC-A stability fee 
        JugAbstract(MCD_JUG).file(ilk, "duty", THREE_PERCENT_RATE);
        // Set the LRC-A percentage between bids 
        FlipAbstract(MCD_FLIP_LRC_A).file("beg", 103 * WAD / 100);
        // Set the LRC-A time max time between bids
        FlipAbstract(MCD_FLIP_LRC_A).file("ttl", 1 hours);
        // Set the LRC-A max auction duration to
        FlipAbstract(MCD_FLIP_LRC_A).file("tau", 1 hours);
        // Set the LRC-A min collateralization ratio 
        SpotAbstract(MCD_SPOT).file(ilk, "mat", 175 * RAY / 100);

        // Update LRC-A spot value in Vat
        SpotAbstract(MCD_SPOT).poke(ilk);

        // Add new ilk to the IlkRegistry
        IlkRegistryAbstract(ILK_REGISTRY).add(MCD_JOIN_LRC_A);

        // Set Faucet amount
        FaucetAbstract(FAUCET).setAmt(LRC, 2000 * WAD);


        /************************************/
        /*** LINK-A COLLATERAL ONBOARDING ***/
        /************************************/
        // Set ilk bytes32 variable
        ilk = "LINK-A";

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_LINK_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_LINK_A).ilk() == ilk,     "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_LINK_A).gem() == LINK,    "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_LINK_A).dec() == 18,      "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_LINK_A).vat() == MCD_VAT,    "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_LINK_A).cat() == MCD_CAT,    "flip-cat-not-match");
        require(FlipAbstract(MCD_FLIP_LINK_A).ilk() == ilk,        "flip-ilk-not-match");

        // Set the LINK PIP in the Spotter
        SpotAbstract(MCD_SPOT).file(ilk, "pip", PIP_LINK);

        // Set the LINK-A Flipper in the Cat
        CatAbstract(MCD_CAT).file(ilk, "flip", MCD_FLIP_LINK_A);

        // Init LINK-A ilk in Vat & Jug
        VatAbstract(MCD_VAT).init(ilk);
        JugAbstract(MCD_JUG).init(ilk);

        // Allow LINK-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_LINK_A);
        // Allow the LINK-A Flipper to reduce the Cat litterbox on deal()
        CatAbstract(MCD_CAT).rely(MCD_FLIP_LINK_A);
        // Allow Cat to kick auctions in LINK-A Flipper
        FlipAbstract(MCD_FLIP_LINK_A).rely(MCD_CAT);
        // Allow End to yank auctions in LINK-A Flipper
        FlipAbstract(MCD_FLIP_LINK_A).rely(MCD_END);
        // Allow FlipperMom to access to the LINK-A Flipper
        FlipAbstract(MCD_FLIP_LINK_A).rely(FLIPPER_MOM);

        // Allow OsmMom to access to the LINK Osm
        OsmAbstract(PIP_LINK).rely(OSM_MOM);
        // Whitelist Osm to read the Median data (only necessary if it is the first time the token is being added to an ilk)
        MedianAbstract(OsmAbstract(PIP_LINK).src()).kiss(PIP_LINK);
        // Whitelist Spotter to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        OsmAbstract(PIP_LINK).kiss(MCD_SPOT);
        // Whitelist End to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        OsmAbstract(PIP_LINK).kiss(MCD_END);
        // Set LINK Osm in the OsmMom for new ilk
        OsmMomAbstract(OSM_MOM).setOsm(ilk, PIP_LINK);

        // Set the LINK-A debt ceiling
        VatAbstract(MCD_VAT).file(ilk, "line", 5 * MILLION * RAD);
        // Set the LINK-A dust
        VatAbstract(MCD_VAT).file(ilk, "dust", 100 * RAD);
        // Set the LINK-A dunk
        CatAbstract(MCD_CAT).file(ilk, "dunk", 500 * RAD);
        // Set the LINK-A liquidation penalty 
        CatAbstract(MCD_CAT).file(ilk, "chop", 113 * WAD / 100);
        // Set the LINK-A stability fee 
        JugAbstract(MCD_JUG).file(ilk, "duty", TWO_PERCENT_RATE);
        // Set the LINK-A percentage between bids 
        FlipAbstract(MCD_FLIP_LINK_A).file("beg", 103 * WAD / 100);
        // Set the LINK-A time max time between bids
        FlipAbstract(MCD_FLIP_LINK_A).file("ttl", 1 hours);
        // Set the LINK-A max auction duration to
        FlipAbstract(MCD_FLIP_LINK_A).file("tau", 1 hours);
        // Set the LINK-A min collateralization ratio 
        SpotAbstract(MCD_SPOT).file(ilk, "mat", 175 * RAY / 100);

        // Update LINK-A spot value in Vat
        SpotAbstract(MCD_SPOT).poke(ilk);

        // Add new ilk to the IlkRegistry
        IlkRegistryAbstract(ILK_REGISTRY).add(MCD_JOIN_LINK_A);

        // Set Faucet amount
        FaucetAbstract(FAUCET).setAmt(LINK, 30 * WAD);
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
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/9fe29a1704a7885305774bbb31ab04fedd363259/governance/votes/Executive%20vote%20-%20September%2018%2C%202020.md -q -O - 2>/dev/null)"

	// get link here: https://github.com/makerdao/community/tree/master/governance/votes
    string constant public description =
        "2020-09-28 MakerDAO Executive Spell | Hash: ";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    // modifier officeHours {
    //     uint day = (now / 1 days + 3) % 7;
    //     require(day < 5, "Can only be cast on a weekday");
    //     uint hour = now / 1 hours % 24;
    //     require(hour >= 14 && hour < 21, "Outside office hours");
    //     _;
    // }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
