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
import "lib/dss-interfaces/src/dapp/DSAuthorityAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmMomAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipperMomAbstract.sol";
import "lib/dss-interfaces/src/dss/ChainlogAbstract.sol";

contract SpellAction {
    // Office hours enabled if true
    bool constant public officeHours = true;

    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/active/contracts.json
    ChainlogAbstract constant CHANGELOG = ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    address constant MCD_ADM            = 0x0a3f6849f78076aefaDf113F5BED87720274dDC0;
    address constant VOTE_PROXY_FACTORY = 0x6FCD258af181B3221073A96dD90D1f7AE7eEc408;

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
        address MCD_PAUSE   = CHANGELOG.getAddress("MCD_PAUSE");
        address FLIPPER_MOM = CHANGELOG.getAddress("FLIPPER_MOM");
        address OSM_MOM     = CHANGELOG.getAddress("OSM_MOM");

        // Change MCD_ADM address in the changelog (Chief)
        CHANGELOG.setAddress("MCD_ADM", MCD_ADM);

        // Add VOTE_PROXY_FACTORY to the changelog (previous one was missing)
        CHANGELOG.setAddress("VOTE_PROXY_FACTORY", VOTE_PROXY_FACTORY);

        // Bump version
        CHANGELOG.setVersion("1.2.0");

        // Set new Chief in the Pause
        DSPauseAbstract(MCD_PAUSE).setAuthority(MCD_ADM);

        // Set new Chief in the FlipperMom
        FlipperMomAbstract(FLIPPER_MOM).setAuthority(MCD_ADM);

        // Set new Chief in the OsmMom
        OsmMomAbstract(OSM_MOM).setAuthority(MCD_ADM);

        // Set Pause delay to 48 hours
        DSPauseAbstract(MCD_PAUSE).setDelay(48 * 60 * 60);
    }
}

contract DssSpell {
    ChainlogAbstract constant CHANGELOG = ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    address MCD_PAUSE = CHANGELOG.getAddress("MCD_PAUSE");

    // SCD contracts that has the old chief as authority
    address constant SAI_MOM = 0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C;
    address constant SAI_TOP = 0x9b0ccf7C8994E19F39b2B4CF708e0A7DF65fA8a3;
    //

    DSPauseAbstract public pause = DSPauseAbstract(MCD_PAUSE);
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/9014856179684688ae29a8204f557fee53f552d5/governance/votes/Executive%20vote%20-%20December%202%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-12-02 MakerDAO Executive Spell | Hash: 0x2055ba0fea45996d1639e5a272ffaee7c7769422d771111c4cdede15c4c6af5d";

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

    modifier limited {
        require(nextCastTime() == now, "Outside office hours");
        _;
    }

    function nextCastTime() public returns (uint256) {
        require(eta != 0, "Spell not scheduled");
        uint256 castTime = now > eta ? now : eta;

        if(officeHours) {
            uint256 day    = (castTime / 1 days + 3) % 7;
            uint256 hour   = castTime / 1 hours % 24;
            uint256 minute = castTime / 1 minutes % 60;
            uint256 second = castTime % 60;

            if(day >= 5) castTime += 7 days - day * 86400;
            
            if (hour >= 22) {
                castTime += 24 hours - hour * 3600 + 15 hours; // Go to 10am next day
                castTime -= minute * 60 + second;              // 10am on the hour
            }
            else if (hour < 15) {
                castTime += 15 hours - hour * 3600; // Go to 10am same day
                castTime -= minute * 60 + second;   // 10am on the hour
            }
        }
        return castTime;
    }

    function schedule() external {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);

        // The old chief will be removed as authority of the SCD contracts.
        // This authority shouldn't be able to do anything in these contracts after shutdown,
        // however as a safety measure it's getting removed.
        DSAuthAbstract(SAI_MOM).setAuthority(address(0));
        DSAuthAbstract(SAI_TOP).setAuthority(address(0));
    }

    function cast() external {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
