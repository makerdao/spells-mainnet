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

import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/MedianAbstract.sol";
import "lib/dss-interfaces/src/dss/SpotAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";

// TODO: add to dss-interfaces?
interface GemJoin6Like {
    function setImplementation(address, uint256) external;
}

contract SpellAction {

    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.1.1/contracts.json
    address constant MCD_JOIN_TUSD_A  = 0x4454aF7C8bb9463203b66C816220D41ED7837f44;
    address constant MCD_JUG          = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant MCD_SPOT         = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant MCD_VAT          = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant TUSD_IMPL_NEW    = 0x7a9701453249e84fd0D5AfE5951e9cBe9ed2E90f;
    address constant MEDIAN_MANAUSD   = 0x681c4F8f69cF68852BAd092086ffEaB31F5B812c;
    address constant GITCOIN_FEED_OLD = 0xA4188B523EccECFbAC49855eB52eA0b55c4d56dd;
    address constant GITCOIN_FEED_NEW = 0x77EB6CF8d732fe4D92c427fCdd83142DB3B742f7;

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
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    uint256 constant FOUR_PCT_RATE   = 1000000001243680656318820312;
    uint256 constant EIGHT_PCT_RATE  = 1000000002440418608258400030;
    uint256 constant TWELVE_PCT_RATE = 1000000003593629043335673582;
    uint256 constant FIFTY_PCT_RATE  = 1000000012857214317438491659;

    function execute() external {
        /*** Risk Parameter Adjustments ***/

        // Set the global debt ceiling to 1,196,000,000
        // 948 (current DC) + 200 (USDC-A increase) + 48 (TUSD-A increase)
        VatAbstract(MCD_VAT).file("Line", 1196 * MILLION * RAD);

        // Set the USDC-A debt ceiling
        //
        // Existing debt ceiling: 200 million
        // New debt ceiling: 400 million
        VatAbstract(MCD_VAT).file("USDC-A", "line", 400 * MILLION * RAD);

        // Set the TUSD-A debt ceiling
        //
        // Existing debt ceiling: 2 million
        // New debt ceiling: 50 million
        VatAbstract(MCD_VAT).file("TUSD-A", "line", 50 * MILLION * RAD);

        // Set USDC-A collateralization ratio
        //
        // Existing ratio: 103%
        // New ratio: 101%
        SpotAbstract(MCD_SPOT).file("USDC-A", "mat", 101 * RAY / 100); // 101% coll. ratio
        SpotAbstract(MCD_SPOT).poke("USDC-A");

        // Set PAXUSD-A collateralization ratio
        //
        // Existing ratio: 103%
        // New ratio: 101%
        SpotAbstract(MCD_SPOT).file("PAXUSD-A", "mat", 101 * RAY / 100); // 101% coll. ratio
        SpotAbstract(MCD_SPOT).poke("PAXUSD-A");

        // Set TUSD-A collateralization ratio
        //
        // Existing ratio: 120%
        // New ratio: 101%
        SpotAbstract(MCD_SPOT).file("TUSD-A", "mat", 101 * RAY / 100); // 101% coll. ratio
        SpotAbstract(MCD_SPOT).poke("TUSD-A");

        // Set the TUSD-A stability fee
        //
        // Previous: 0%
        // New: 4%
        JugAbstract(MCD_JUG).drip("TUSD-A"); // drip right before
        JugAbstract(MCD_JUG).file("TUSD-A", "duty", FOUR_PCT_RATE);

        // Set the USDT-A stability fee
        //
        // Previous: 6%
        // New: 8%
        JugAbstract(MCD_JUG).drip("USDT-A"); // drip right before
        JugAbstract(MCD_JUG).file("USDT-A", "duty", EIGHT_PCT_RATE);

        // Set the PAXUSD-A stability fee
        //
        // Previous: 2%
        // New: 4%
        JugAbstract(MCD_JUG).drip("PAXUSD-A"); // drip right before
        JugAbstract(MCD_JUG).file("PAXUSD-A", "duty", FOUR_PCT_RATE);

        // Set the USDC-A stability fee
        //
        // Previous: 2%
        // New: 4%
        JugAbstract(MCD_JUG).drip("USDC-A"); // drip right before
        JugAbstract(MCD_JUG).file("USDC-A", "duty", FOUR_PCT_RATE);

        // Set the USDC-B stability fee
        //
        // Previous: 48%
        // New: 50%
        JugAbstract(MCD_JUG).drip("USDC-B"); // drip right before
        JugAbstract(MCD_JUG).file("USDC-B", "duty", FIFTY_PCT_RATE);

        // Set the BAT-A stability fee
        //
        // Previous: 2%
        // New: 4%
        JugAbstract(MCD_JUG).drip("BAT-A"); // drip right before
        JugAbstract(MCD_JUG).file("BAT-A", "duty", FOUR_PCT_RATE);

        // Set the WBTC-A stability fee
        //
        // Previous: 2%
        // New: 4%
        JugAbstract(MCD_JUG).drip("WBTC-A"); // drip right before
        JugAbstract(MCD_JUG).file("WBTC-A", "duty", FOUR_PCT_RATE);

        // Set the KNC-A stability fee
        //
        // Previous: 2%
        // New: 4%
        JugAbstract(MCD_JUG).drip("KNC-A"); // drip right before
        JugAbstract(MCD_JUG).file("KNC-A", "duty", FOUR_PCT_RATE);

        // Set the ZRX-A stability fee
        //
        // Previous: 2%
        // New: 4%
        JugAbstract(MCD_JUG).drip("ZRX-A"); // drip right before
        JugAbstract(MCD_JUG).file("ZRX-A", "duty", FOUR_PCT_RATE);

        // Set the MANA-A stability fee
        //
        // Previous: 10%
        // New: 12%
        JugAbstract(MCD_JUG).drip("MANA-A"); // drip right before
        JugAbstract(MCD_JUG).file("MANA-A", "duty", TWELVE_PCT_RATE);

        /*** Maintenance Actions ***/

        // Whitelist new TUSD implementation
        GemJoin6Like(MCD_JOIN_TUSD_A).setImplementation(TUSD_IMPL_NEW, 1);        

        // Replace Gitcoin feed key on MANAUSD Oracle
        address[] memory drops = new address[](1);
        drops[0] = GITCOIN_FEED_OLD;
        MedianAbstract(MEDIAN_MANAUSD).drop(drops);

        address[] memory lifts = new address[](1);
        lifts[0] = GITCOIN_FEED_NEW;
        MedianAbstract(MEDIAN_MANAUSD).lift(lifts);
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
    string constant public description =
        "2020-09-18 MakerDAO Executive Spell | Hash: 0xe942f72e80295685e39e303f8979560523beae8569daccfcea2f000b14a14abf";

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

    function cast() public /*officeHours*/ {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
