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

contract SpellAction {
    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.1.2/contracts.json

    //address constant MCD_JUG         = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;

    // Decimals & precision
    //uint256 constant THOUSAND = 10 ** 3;
    //uint256 constant MILLION  = 10 ** 6;
    //uint256 constant WAD      = 10 ** 18;
    //uint256 constant RAY      = 10 ** 27;
    //uint256 constant RAD      = 10 ** 45;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    uint256 constant        ZERO_PCT_RATE = 1000000000000000000000000000;
    uint256 constant         ONE_PCT_RATE = 1000000000315522921573372069;
    uint256 constant         TWO_PCT_RATE = 1000000000627937192491029810;
    uint256 constant         SIX_PCT_RATE = 1000000001847694957439350562;
    uint256 constant         TEN_PCT_RATE = 1000000003022265980097387650;
    uint256 constant FOURTYEIGHT_PCT_RATE = 1000000012431573129530493155;

    function execute() external {

        // Set the ETH-A stability fee
        //
        // Previous: 2%
        // New: 0%
        //JugAbstract(MCD_JUG).drip("ETH-A"); // drip right before
        //JugAbstract(MCD_JUG).file("ETH-A", "duty", ZERO_PCT_RATE);

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
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/<tbd> -q -O - 2>/dev/null)"
    string constant public description =
        "2020-10-09 MakerDAO Executive Spell | Hash: 0x0";

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
