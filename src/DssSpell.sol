// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
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
pragma solidity 0.6.11;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/e2929f286f2c486c0485637967284630643ddc8d/governance/votes/Executive%20vote%20-%20January%2029%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-01-29 MakerDAO Executive Spell | Hash: 0xbb7974fc8e89c016a6c42f5ced4b1f42e45671e5f4f4009535658affb6a98343";


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //

    /**
        @dev constructor (required)
        @param lib         address of the DssExecLib contract
        @param officeHours true if officehours enabled
    */
    constructor(address lib, bool officeHours) public DssAction(lib, officeHours) {}

    uint256 constant MILLION = 10**6;

    function actions() public override {
        //                           ilk            line           gap       ttl
        setIlkAutoLineParameters("ETH-A", 1500 * MILLION, 30 * MILLION, 12 hours);
    }
}

contract DssSpell is DssExec {
    address public constant LIB = 0xFC32E74e6e33D924bd2fBFC7A27b6F2177032760;
    DssSpellAction public spell = new DssSpellAction(LIB, false);
    constructor() DssExec(spell.description(), now + 30 days, address(spell)) public {}
}
