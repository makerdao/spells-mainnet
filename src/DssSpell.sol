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
import "lib/dss-interfaces/src/dss/ChainlogAbstract.sol";

contract SpellAction {
    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.1.5/contracts.json
    ChainlogAbstract constant CHANGELOG = ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    // Decimals & precision
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

    function execute() external {
        address MCD_VAT = CHANGELOG.getAddress("MCD_VAT");
        // Set the global debt ceiling
        //
        // Existing Line: 1,481,750,000
        // New Line: 1,581,750,000
        VatAbstract(MCD_VAT).file("Line", 1_581_750_000 * RAD);

        // Set the ETH-A debt ceiling
        //
        // Existing debt: 490 million
        // New debt ceiling: 590 million
        VatAbstract(MCD_VAT).file("ETH-A", "line", 590_000_000 * RAD);
    }
}

contract DssSpell {
    ChainlogAbstract constant CHANGELOG = ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    address MCD_PAUSE = CHANGELOG.getAddress("MCD_PAUSE");

    DSPauseAbstract public pause = DSPauseAbstract(MCD_PAUSE);
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    // Office hours enabled if true
    bool   constant public officeHours = false;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/cf15becd1c655ebc10dada8ee2305061f5b640f0/governance/votes/Executive%20vote%20-%20November%2027%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-11-27 MakerDAO Executive Spell | Hash: 0xe6b128f757b3a42aeb30e79d1790773c91e33aec1cb0fc16ccbef70f8b0808b5";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
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
