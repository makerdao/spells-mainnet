// Copyright (C) 2020, The Maker Foundation
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
import "lib/dss-interfaces/src/dss/PotAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmAbstract.sol";
import "lib/dss-interfaces/src/sai/SaiMomAbstract.sol";
import "lib/dss-interfaces/src/sai/SaiTopAbstract.sol";

contract SaiSlayer {
    uint256 constant public T2020_05_12_1600UTC = 1589299200;
    SaiTopAbstract constant public SAITOP = SaiTopAbstract(0x9b0ccf7C8994E19F39b2B4CF708e0A7DF65fA8a3);

    function cage() public {
        require(now >= T2020_05_12_1600UTC);
        SAITOP.cage();
    }
}

contract SpellAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    string  constant public description = "2020-04-24 MakerDAO Executive Spell";

    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.0.4/contracts.json
    //
    // Contract addresses pertaining to the SCD ecosystem can be found at:
    //     https://github.com/makerdao/sai#dai-v1-current-deployments
    address constant public MCD_JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public MCD_POT = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address constant public ETHUSD = 0x64DE91F5A373Cd4c28de3600cB34C7C6cE410C85;
    address constant public BTCUSD = 0xe0F30cb149fAADC7247E953746Be9BbBB6B5751f;

    address constant public SET_ETHUSD = 0x97C3e595e8f80169266B5534e4d7A1bB58BB45ab;
    address constant public DYDX_BTCUSD = 0xbf63446ecF3341e04c6569b226a57860B188edBc;
    address constant public SET_BTCUSD = 0x538038E526517680735568f9C5342c6E68bbDA12;

    function execute() external {

        // Drip Pot and Jugs prior to all modifications.
        PotAbstract(MCD_POT).drip();
        JugAbstract(MCD_JUG).drip("ETH-A");
        JugAbstract(MCD_JUG).drip("BAT-A");
        JugAbstract(MCD_JUG).drip("USDC-A");

        OsmAbstract(ETHUSD).kiss(SET_ETHUSD);
        OsmAbstract(BTCUSD).kiss(DYDX_BTCUSD);
        OsmAbstract(BTCUSD).kiss(SET_BTCUSD);
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
    SaiSlayer        public saiSlayer;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;

        saiSlayer = new SaiSlayer();
    }

    function description() public view returns (string memory) {
        return SpellAction(action).description();
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);

        // Set SaiSlayer to cage the system after May 12th, 2020 at 16:00 UTC
        saiSlayer.SAITOP().setOwner(address(saiSlayer));
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
