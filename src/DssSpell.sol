// SPDX-FileCopyrightText: © 2020 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
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

pragma solidity 0.8.16;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

interface Fileable {
    function file(bytes32, bytes32, uint256) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/54731a9e15d6da097d578d8050bec900cf7223f5/governance/votes/Executive%20Vote%20-%20February%2022%2C%202023.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-02-22 MakerDAO Executive Spell | Hash: 0xa3cbfacc53bcdef9863383b0a0e16bd805fb2cd9df5957a05e0bbe91373fb1b8";

    // Turn office hours on
    function officeHours() public pure override returns (bool) {
        return true;
    }

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // uint256 internal constant X_PCT_RATE      = ;

    // uint256 constant ZERO_FIVE_PCT_RATE = 1000000000158153903837946257;

    uint256 constant RAY = 10 ** 27;

    address immutable MCD_SPOT = DssExecLib.spotter();

    function actions() public override {
        // https://forum.makerdao.com/t/usdc-a-usdp-a-gusd-a-proposed-offboarding-parameters/19474
        Fileable(MCD_SPOT).file("USDC-A",   "mat", 15 * RAY); // 1500% collateralization ratio
        Fileable(MCD_SPOT).file("PAXUSD-A", "mat", 15 * RAY);
        Fileable(MCD_SPOT).file("GUSD-A",   "mat", 15 * RAY);
        DssExecLib.updateCollateralPrice("USDC-A");
        DssExecLib.updateCollateralPrice("PAXUSD-A");
        DssExecLib.updateCollateralPrice("GUSD-A");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
