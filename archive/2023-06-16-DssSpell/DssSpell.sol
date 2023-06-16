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

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/4b8f4ba042910b2fd8d27ccd06a15988ff23c113/governance/votes/Executive%20vote%20-%20June%2016%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-06-16 MakerDAO Executive Spell | Hash: 0xecdc5a5a1be69f23d299235ad966c82c7e03365e45aaed69ed1eb2f03daff4a6";

    // ----- 2023-06-16 DAO Resolutions -----
    // Emergency Proposal: Out-of-Schedule Executive to Fortify Elasticity of On-chain 1:1 Liquidity of USDC
    // Forum: https://forum.makerdao.com/t/out-of-schedule-executive-to-fortify-elasticity-of-on-chain-1-1-liquidity-of-usdc/21168
    // MIP:   https://mips.makerdao.com/mips/details/MIP24

    // Comma-separated list of DAO resolutions IPFS hashes.
    string public constant dao_resolutions = "QmYPbYoPjrSzBu5gt9tip78siG1gFvY8K4HTkHEFJgMmM8";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
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

    function actions() public override {

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
