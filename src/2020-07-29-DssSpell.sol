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

contract SpellAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    string constant public description =
        "2020-07-29 MakerDAO Executive Spell | Off-cycle Executive";

    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.0.9/contracts.json

    address constant MCD_VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    // Decimals & precision
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant RAD      = 10 ** 45;

    function execute() external {
        // Set the global debt ceiling
        // Existing Line: 386m
        // New Line: 568m
        VatAbstract(MCD_VAT).file("Line", 568 * MILLION * RAD);

        // Set the ETH-A debt ceiling
        // Existing line: 260m
        // New line: 340m
        VatAbstract(MCD_VAT).file("ETH-A", "line", 340 * MILLION * RAD);

        // Set the BAT-A debt ceiling
        // Existing line: 3m
        // New line: 5m
        VatAbstract(MCD_VAT).file("BAT-A", "line", 5 * MILLION * RAD);

        // Set the USDC-A debt ceiling
        // Existing line: 80m
        // New line: 140m
        VatAbstract(MCD_VAT).file("USDC-A", "line", 140 * MILLION * RAD);

        // Set the WBTC-A debt ceiling
        // Existing line: 20m
        // New line: 40m
        VatAbstract(MCD_VAT).file("WBTC-A", "line", 40 * MILLION * RAD);

        // Set the USDC-B debt ceiling
        // Existing line: 10m
        // New line: 30m
        VatAbstract(MCD_VAT).file("USDC-B", "line", 30 * MILLION * RAD);

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
