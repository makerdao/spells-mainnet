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
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/PotAbstract.sol";

contract SpellAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/cc819c75fc8f1b622cbe06acfd0d11bf64545622/governance/votes/Executive%20vote%20-%20July%2027%2C%202020%20.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-07-29 MakerDAO Executive Spell | Off-cycle Executive";

    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.0.9/contracts.json

    address constant MCD_VAT             = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant MCD_JUG             = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant MCD_POT             = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;

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

    function execute() external {
        // Perform drips
        PotAbstract(MCD_POT).drip();

        JugAbstract(MCD_JUG).drip("ETH-A");
        JugAbstract(MCD_JUG).drip("BAT-A");
        JugAbstract(MCD_JUG).drip("USDC-A");
        JugAbstract(MCD_JUG).drip("USDC-B");
        JugAbstract(MCD_JUG).drip("TUSD-A");
        JugAbstract(MCD_JUG).drip("WBTC-A");
        JugAbstract(MCD_JUG).drip("KNC-A");
        JugAbstract(MCD_JUG).drip("ZRX-A");
        JugAbstract(MCD_JUG).drip("MANA-A");

        // Set the global debt ceiling
        // Existing Line: 386m
        // New Line: 550m
        VatAbstract(MCD_VAT).file("Line", 550 * MILLION * RAD);

        // Set the ETH-A debt ceiling
        // Existing line: 260m
        // New line: 340m
        VatAbstract(MCD_VAT).file("ETH-A", "line", 340 * MILLION * RAD); // 260 MM debt ceiling

        // Set the BAT-A debt ceiling
        // Existing line: 3m
        // New line: 5m
        VatAbstract(MCD_VAT).file("ETH-A", "line", 5 * MILLION * RAD); // 260 MM debt ceiling

        // Set the USDC-A debt ceiling
        // Existing line: 80m
        // New line: 140m
        VatAbstract(MCD_VAT).file("USDC-A", "line", 140 * MILLION * RAD); // 260 MM debt ceiling

        // Set the WBTC-A debt ceiling
        // Existing line: 20m
        // New line: 40m
        VatAbstract(MCD_VAT).file("WBTC-A", "line", 40 * MILLION * RAD); // 260 MM debt ceiling

        // Set the USDC-B debt ceiling
        // Existing line: 10m
        // New line: 30m
        VatAbstract(MCD_VAT).file("USDC-B", "line", 30 * MILLION * RAD); // 260 MM debt ceiling

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
        expiration = now + 4 days + 2 hours; // Extra window of 2 hours to get the spell set up in the Governance Portal and communicated
    }

    modifier officeHours {
        uint day = (now / 1 days + 3) % 7;
        require(day < 5, "Can only be cast on a weekday");
        uint hour = now / 1 hours % 24;
        require(hour >= 14 && hour < 21, "Outside office hours");
        _;
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

    function cast() public officeHours {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}

