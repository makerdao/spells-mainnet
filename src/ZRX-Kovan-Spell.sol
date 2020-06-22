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
import "lib/dss-interfaces/src/dss/PipAbstract.sol";
import "lib/dss-interfaces/src/dss/SpotAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmMomAbstract.sol";
import "lib/dss/lib/ds-value/src/value.sol";

contract MedianAbstract {
    function kiss(address) public;
}

contract FlipFabAbstract {
    function newFlip(address, bytes32) public returns (address);
}

contract SpellAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    string constant public description = "Kovan Spell for ZRX";

    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.0.5/contracts.json
    //
    // Contract addresses pertaining to the SCD ecosystem can be found at:
    //     https://github.com/makerdao/sai#dai-v1-current-deployments
    address constant public MCD_VAT = 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9;
    address constant public MCD_CAT = 0x0511674A67192FE51e86fE55Ed660eB4f995BDd6;
    address constant public MCD_JUG = 0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD;
    address constant public MCD_SPOT = 0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D;
    address constant public MCD_POT = 0xEA190DBDC7adF265260ec4dA6e9675Fd4f5A78bb;
    address constant public MCD_END = 0x24728AcF2E2C403F5d2db4Df6834B8998e56aA5F;
    address constant public FLIPPER_MOM = 0xf3828caDb05E5F22844f6f9314D99516D68a0C84;
    // address constant public OSM_MOM = 0x5dA9D1C3d4f1197E5c52Ff963916Fe84D2F5d8f3;
    address constant public FLIP_FAB = 0xFfB0382CA7Cfdc4Fc4d5Cc8913af1393d7eE1EF1;

    address constant public ZRX = 0x8d30A2E1Fb98E87ada72e86b22817d684E95bddd;
    address constant public MCD_JOIN_ZRX_A = 0x28b12c7386DacD5A4cCC5Bab9535403584AdC101;
    address constant public PIP_ZRX = 0x9d309ef37Ce287C220E636475178dD9469f0D960; // DSValue contract

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
        JugAbstract(MCD_JUG).drip("TUSD-A");
        JugAbstract(MCD_JUG).drip("USDC-B");
        JugAbstract(MCD_JUG).drip("WBTC-A");

        bytes32 ilk = "ZRX-A";

        address MCD_FLIP_ZRX_A = FlipFabAbstract(FLIP_FAB).newFlip(MCD_VAT, ilk);

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_ZRX_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_ZRX_A).ilk() == ilk,     "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_ZRX_A).gem() == ZRX,     "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_ZRX_A).dec() == 18,      "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_ZRX_A).vat() == MCD_VAT,    "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_ZRX_A).ilk() == ilk,        "flip-ilk-not-match");

        // Set the ZRX PIP in the Spotter
        SpotAbstract(MCD_SPOT).file(ilk, "pip", PIP_ZRX);

        // Set the ZRX-A Flipper in the Cat
        CatAbstract(MCD_CAT).file(ilk, "flip", MCD_FLIP_ZRX_A);

        // Init ZRX-A ilk in Vat
        VatAbstract(MCD_VAT).init(ilk);
        // Init ZRX-A ilk in Jug
        JugAbstract(MCD_JUG).init(ilk);

        // Allow ZRX-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_ZRX_A);
        // Allow Cat to kick auctions in ZRX-A Flipper
        FlipAbstract(MCD_FLIP_ZRX_A).rely(MCD_CAT);
        // Allow End to yank auctions in ZRX-A Flipper
        FlipAbstract(MCD_FLIP_ZRX_A).rely(MCD_END);
        // Allow FlipperMom to access to the ZRX-A Flipper
        FlipAbstract(MCD_FLIP_ZRX_A).rely(FLIPPER_MOM);

        // Whitelist the Osm to read the Median data
        // MedianAbstract(OsmAbstract(PIP_ZRX).src()).kiss(PIP_ZRX);
        // Allow OsmMom to access to the ZRX Osm
        // OsmAbstract(PIP_ZRX).rely(OSM_MOM);
        // Whitelist Spotter to read the Osm data
        // OsmAbstract(PIP_ZRX).kiss(MCD_SPOT);
        // Set ZRX Osm in the OsmMom for new ilk
        // OsmMomAbstract(OSM_MOM).setOsm(ilk, PIP_ZRX);

        // Set the global debt ceiling to 153 MM
        VatAbstract(MCD_VAT).file("Line", 195 * MILLION * RAD);
        // Set the ZRX-A debt ceiling to 10 MM
        VatAbstract(MCD_VAT).file(ilk, "line", 10 * MILLION * RAD);
        // Set the ZRX-A dust
        VatAbstract(MCD_VAT).file(ilk, "dust", 5 * RAD);
        // Set the Lot size to 1 ZRX-A
        CatAbstract(MCD_CAT).file(ilk, "lump", 1 * WAD);
        // Set the ZRX-A liquidation penalty to 13%
        CatAbstract(MCD_CAT).file(ilk, "chop", 113 * RAY / 100);
        // Set the ZRX-A stability fee to 1%
        JugAbstract(MCD_JUG).file(ilk, "duty", ONE_PCT_RATE);
        // Set the ZRX-A percentage between bids to 3%
        FlipAbstract(MCD_FLIP_ZRX_A).file("beg", 103 * WAD / 100);
        // Set the ZRX-A time max time between bids to 6 hours
        FlipAbstract(MCD_FLIP_ZRX_A).file("ttl", 6 hours);
        // Set the ZRX-A max auction duration to 6 hours
        FlipAbstract(MCD_FLIP_ZRX_A).file("tau", 6 hours);
        // Set the ZRX-A min collateralization ratio to 150%
        SpotAbstract(MCD_SPOT).file(ilk, "mat", 150 * RAY / 100);

        // // Execute the first poke in the Osm for the next value 
        // PipAbstract(PIP_ZRX).poke(bytes32(35 * WAD / 100)); // ZRX price of $0.35

        // Update ZRX-A spot value in Vat (will be zero as the Osm will not have any value as current yet)
        SpotAbstract(MCD_SPOT).poke(ilk);
    }
}

contract DssSpell {

    DSPauseAbstract  public pause =
        DSPauseAbstract(0x8754E6ecb4fe68DaA5132c2886aB39297a5c7189);
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
