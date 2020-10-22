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
import "lib/dss-interfaces/src/dss/MedianAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmAbstract.sol";
import "lib/dss-interfaces/src/dss/VowAbstract.sol";

contract SpellAction {
    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.1.3/contracts.json

    address constant MCD_VOW       = 0xA950524441892A31ebddF91d3cEEFa04Bf454466;
    address constant ETHUSD_MEDIAN = 0x64DE91F5A373Cd4c28de3600cB34C7C6cE410C85;
    address constant ETHUSD_OSM    = 0x81FE72B5A8d1A857d176C3E7d5Bd2679A9B85763;

    // spell-specific addresses

    // B Protocol
    address constant B_PROTOCOL_BUD_CONNECTOR = 0x2325aa20DEAa9770a978f1dc7C073589ffC79DC3;

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
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW

    // No rate chagnes this week.

    function execute() external {
        // Set the surplus buffer to 4,000,000 DAI
        VowAbstract(MCD_VOW).file("hump", 4 * MILLION * RAD);

        // Whitelist B Protocol to access the ETHUSD Medianizer
        MedianAbstract(ETHUSD_MEDIAN).kiss(B_PROTOCOL_BUD_CONNECTOR);

        // Whitelist B Protocol to access the ETHUSD OSM
        OsmAbstract(ETHUSD_OSM).kiss(B_PROTOCOL_BUD_CONNECTOR);
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
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/10f4fb51d9d6b292d7ffd3f852cbbc97bd920e84/governance/votes/Executive%20vote%20-%20October%2023%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-10-23 MakerDAO Executive Spell | Hash: 0x500dd161a37646be178bb4a33a1bbef78443f5e60aa660d6d3b480791326c964";

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

    function cast() public /* officeHours */ {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
