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
import "lib/dss-interfaces/src/dss/GemJoinAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipAbstract.sol";
import "lib/dss-interfaces/src/dss/SpotAbstract.sol";

contract MedianAbstract {
    function kiss(address) public;
}

contract SpellAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    string constant public description = "Remove Sai collateral from MCD";

    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.0.6/contracts.json
    //
    // Contract addresses pertaining to the SCD ecosystem can be found at:
    //     https://github.com/makerdao/sai#dai-v1-current-deployments
    address constant public MCD_VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public MCD_CAT = 0x78F2c2AF65126834c51822F56Be0d7469D7A523E;
    address constant public MCD_SPOT = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant public MCD_END = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;
    address constant public FLIPPER_MOM = 0x9BdDB99625A711bf9bda237044924E34E8570f75;

    address constant public SAI = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    address constant public MCD_JOIN_SAI = 0xad37fd42185Ba63009177058208dd1be4b136e6b;
    address constant public MCD_FLIP_SAI = 0x5432b2f3c0DFf95AA191C45E5cbd539E2820aE72;

    address constant public MCD_JOIN_DAI = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;

    uint256 constant public THOUSAND = 10**3;
    uint256 constant public MILLION = 10**6;
    uint256 constant public WAD = 10**18;
    uint256 constant public RAY = 10**27;
    uint256 constant public RAD = 10**45;

    function execute() external {

        bytes32 ilk = "SAI";

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_SAI).ilk() == ilk, "join-ilk-not-match");
        require(FlipAbstract(MCD_FLIP_SAI).ilk() == ilk, "flip-ilk-not-match");

        // Remove the SAI PIP in the Spotter
        SpotAbstract(MCD_SPOT).file(ilk, "pip", address(0));

        // Remove the SAI Flipper in the Cat
        CatAbstract(MCD_CAT).file(ilk, "flip", address(0));

        // Set the SAI debt ceiling to 0
        VatAbstract(MCD_VAT).file(ilk, "line", 0);
        // Set the SAI dust
        VatAbstract(MCD_VAT).file(ilk, "dust", 0);

        // Set the Lot size to 0 SAI
        CatAbstract(MCD_CAT).file(ilk, "lump", 0);

        // Set the SAI liquidation penalty to 0%
        CatAbstract(MCD_CAT).file(ilk, "chop", 0);

        // Cage the Sai join adapter
        GemJoinAbstract(MCD_JOIN_SAI).cage();

        // Disallow SAI to modify Vat registry
        VatAbstract(MCD_VAT).deny(MCD_JOIN_SAI);
        // Disallow Cat to kick auctions in SAI Flipper
        FlipAbstract(MCD_FLIP_SAI).deny(MCD_CAT);
        // Disallow End to yank auctions in SAI Flipper
        FlipAbstract(MCD_FLIP_SAI).deny(MCD_END);
        // Disallow FlipperMom to access to the SAI Flipper
        FlipAbstract(MCD_FLIP_SAI).deny(FLIPPER_MOM);
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
