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

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/bed4423fe0b37ca9902865e69a4b5e14e8595495/governance/votes/Executive%20vote%20-%20August%2018%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-08-21 MakerDAO Executive Spell | Hash: 0xf2d66116128a66c268be1252477cebe8d16a48b599df641a01fbae20010d3277";

    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.0.9/contracts.json
    address constant MCD_JUG  = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;

    uint256 constant EIGHT_PCT       = 1000000002440418608258400030;
    uint256 constant FOURTY_SIX_PCT  = 1000000012000140727767957524;

    function execute() external {
        // drips
        JugAbstract(MCD_JUG).drip("USDC-B");
        JugAbstract(MCD_JUG).drip("MANA-A");

        // Set the USDC-B stability fee
        // Previous: 44%
        //      New: 46%
        JugAbstract(MCD_JUG).file("USDC-B", "duty", FOURTY_SIX_PCT);

        // Set the MANA-A stability fee
        // Previous: 6%
        //      New: 8%
        JugAbstract(MCD_JUG).file("MANA-A", "duty", EIGHT_PCT     );
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
