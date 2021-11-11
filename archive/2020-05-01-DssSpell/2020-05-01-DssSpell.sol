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
import "lib/dss-interfaces/src/dss/PotAbstract.sol";
import "lib/dss-interfaces/src/dss/GemJoinAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipAbstract.sol";
import "lib/dss-interfaces/src/dss/SpotAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmMomAbstract.sol";

contract MedianAbstract {
    function kiss(address) public;
}

contract SpellAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    string constant public description = "2020-05-01 MakerDAO Executive Spell";

    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.0.5/contracts.json
    //
    // Contract addresses pertaining to the SCD ecosystem can be found at:
    //     https://github.com/makerdao/sai#dai-v1-current-deployments
    address constant public MCD_VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public MCD_CAT = 0x78F2c2AF65126834c51822F56Be0d7469D7A523E;
    address constant public MCD_JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public MCD_SPOT = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant public MCD_POT = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address constant public MCD_END = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;
    address constant public FLIPPER_MOM = 0x9BdDB99625A711bf9bda237044924E34E8570f75;
    address constant public OSM_MOM = 0x76416A4d5190d071bfed309861527431304aA14f;

    address constant public WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant public MCD_JOIN_WBTC_A = 0xBF72Da2Bd84c5170618Fbe5914B0ECA9638d5eb5;
    address constant public MCD_FLIP_WBTC_A = 0x3E115d85D4d7253b05fEc9C0bB5b08383C2b0603;
    address constant public PIP_WBTC = 0xf185d0682d50819263941e5f4EacC763CC5C6C42;

    uint256 constant public THOUSAND = 10**3;
    uint256 constant public MILLION = 10**6;
    uint256 constant public WAD = 10**18;
    uint256 constant public RAY = 10**27;
    uint256 constant public RAD = 10**45;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    uint256 constant public ZERO_PCT_RATE = 1000000000000000000000000000;
    uint256 constant public ONE_PCT_RATE =  1000000000315522921573372069;

    function execute() external {
        // perform drips
        PotAbstract(MCD_POT).drip();
        JugAbstract(MCD_JUG).drip("ETH-A");
        JugAbstract(MCD_JUG).drip("BAT-A");
        JugAbstract(MCD_JUG).drip("USDC-A");

        bytes32 ilk = "WBTC-A";

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_WBTC_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_WBTC_A).ilk() == ilk, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_WBTC_A).gem() == WBTC, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_WBTC_A).dec() == 8, "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_WBTC_A).vat() == MCD_VAT, "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_WBTC_A).ilk() == ilk, "flip-ilk-not-match");

        // Set the WBTC PIP in the Spotter
        SpotAbstract(MCD_SPOT).file(ilk, "pip", PIP_WBTC);

        // Set the WBTC-A Flipper in the Cat
        CatAbstract(MCD_CAT).file(ilk, "flip", MCD_FLIP_WBTC_A);

        // Init WBTC-A ilk in Vat
        VatAbstract(MCD_VAT).init(ilk);
        // Init WBTC-A ilk in Jug
        JugAbstract(MCD_JUG).init(ilk);

        // Allow WBTC-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_WBTC_A);
        // Allow Cat to kick auctions in WBTC-A Flipper
        FlipAbstract(MCD_FLIP_WBTC_A).rely(MCD_CAT);
        // Allow End to yank auctions in WBTC-A Flipper
        FlipAbstract(MCD_FLIP_WBTC_A).rely(MCD_END);
        // Allow FlipperMom to access to the WBTC-A Flipper
        FlipAbstract(MCD_FLIP_WBTC_A).rely(FLIPPER_MOM);

        // Whitelist the Osm to read the Median data
        MedianAbstract(OsmAbstract(PIP_WBTC).src()).kiss(PIP_WBTC);
        // Allow OsmMom to access to the WBTC Osm
        OsmAbstract(PIP_WBTC).rely(OSM_MOM);
        // Whitelist Spotter to read the Osm data
        OsmAbstract(PIP_WBTC).kiss(MCD_SPOT);
        // Set WBTC Osm in the OsmMom for new ilk
        OsmMomAbstract(OSM_MOM).setOsm(ilk, PIP_WBTC);

        // Set the global debt ceiling to 153 MM
        VatAbstract(MCD_VAT).file("Line", 153 * MILLION * RAD);
        // Set the WBTC-A debt ceiling to 10 MM
        VatAbstract(MCD_VAT).file(ilk, "line", 10 * MILLION * RAD);
        // Set the WBTC-A dust
        VatAbstract(MCD_VAT).file(ilk, "dust", 20 * RAD);
        // Set the Lot size to 1 WBTC-A
        CatAbstract(MCD_CAT).file(ilk, "lump", 1 * WAD);
        // Set the WBTC-A liquidation penalty to 13%
        CatAbstract(MCD_CAT).file(ilk, "chop", 113 * RAY / 100);
        // Set the WBTC-A stability fee to 1%
        JugAbstract(MCD_JUG).file(ilk, "duty", ONE_PCT_RATE);
        // Set the WBTC-A percentage between bids to 3%
        FlipAbstract(MCD_FLIP_WBTC_A).file("beg", 103 * WAD / 100);
        // Set the WBTC-A time max time between bids to 6 hours
        FlipAbstract(MCD_FLIP_WBTC_A).file("ttl", 6 hours);
        // Set the WBTC-A max auction duration to 6 hours
        FlipAbstract(MCD_FLIP_WBTC_A).file("tau", 6 hours);
        // Set the WBTC-A min collateralization ratio to 150%
        SpotAbstract(MCD_SPOT).file(ilk, "mat", 150 * RAY / 100);

        // Execute the first poke in the Osm for the next value
        OsmAbstract(PIP_WBTC).poke();

        // Update WBTC-A spot value in Vat (will be zero as the Osm will not have any value as current yet)
        SpotAbstract(MCD_SPOT).poke(ilk);

        // MCD Risk Parameter Modifications

        // Set the USDC stability fee
        // https://vote.makerdao.com/polling-proposal/qmc9jj1dyycrmft3pe1yyq6zzz8xdjxzw1gxqzkaogiawe
        // Existing Rate: 6%
        // New Rate: 0%
        uint256 USDC_FEE = ZERO_PCT_RATE;
        JugAbstract(MCD_JUG).file("USDC-A", "duty", USDC_FEE);
    }
}

contract DssSpell {

    DSPauseAbstract  public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address          public action;
    bytes32          public tag;
    uint256          public eta;
    bytes            public sig;
    uint256          public expiration;
    bool             public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
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

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
