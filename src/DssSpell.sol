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
import "lib/dss-interfaces/src/dss/ChainlogAbstract.sol";
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
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/1b36aea23b5baeda96a420b4afc3cd743e708b8d/governance/votes/Executive%20vote%20-%20December%2011%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-12-02 MakerDAO Executive Spell | Hash: 0xa2aeed0dab500692caf4fa55c99bc87b57853792de711724668012a21e9bb83a";

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
        expiration = now + 4 days + 2 hours;
    }

    function nextCastTime() external returns (uint256) {
        require(eta != 0, "DSSSpell/spell-not-scheduled");
        uint256 castTime = now > eta ? now : eta;

        if (SpellAction(action).officeHours()) {
            uint256 day    = (castTime / 1 days + 3) % 7;
            uint256 hour   = castTime / 1 hours % 24;
            uint256 minute = castTime / 1 minutes % 60;
            uint256 second = castTime % 60;

            if (day >= 5) {
                castTime += 6 days - day * 86400;               // Go to Sunday 
                castTime += 24 hours - hour * 3600 + 14 hours;  // Go to 14:00 UTC Monday
                castTime -= minute * 60 + second;               // 14:00 UTC on the hour
                return castTime;
            }

            if (hour >= 21) {
                if (day == 4) castTime += 2 days;               // If Friday, fast forward to Sunday night
                castTime += 24 hours - hour * 3600 + 14 hours;  // Go to 14:00 UTC next day
                castTime -= minute * 60 + second;               // 14:00 UTC on the hour
            } else if (hour < 14) {
                castTime += 14 hours - hour * 3600;             // Go to 14:00 UTC same day
                castTime -= minute * 60 + second;               // 14:00 UTC on the hour
            }
        }
        return castTime;
    }

    function schedule() external {
        require(now <= expiration, "DSSSpell/spell-has-expired");
        require(eta == 0, "DSSSpell/spell-already-scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "DSSSpell/spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
