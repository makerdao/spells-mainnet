// SPDX-License-Identifier: AGPL-3.0-or-later
// 
// Copyright (C) 2021 Dai Foundation
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

pragma solidity 0.6.12;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/Executive%20vote%20-%20September%2017%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-09-24 MakerDAO Executive Spell | Hash: TODO";

    // Math
    uint256 constant MILLION  = 10 ** 6;

    // Turn off office hours
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {

        // Adjusting Auction Parameters for ETH-A, ETH-B, ETH-C, and WBTC-A
        // https://vote.makerdao.com/polling/QmfGk3Dm?network=mainnet#poll-detail

        // Decrease the Auction Price Multiplier (buf) for ETH-A, ETH-C, and WBTC-A vaults from 1.3 to 1.2
        DssExecLib.setStartingPriceMultiplicativeFactor("ETH-A",  12000);
        DssExecLib.setStartingPriceMultiplicativeFactor("ETH-C",  12000);
        DssExecLib.setStartingPriceMultiplicativeFactor("WBTC-A", 12000);

        // Increase the Local Liquidation Limit (ilk.hole)
        DssExecLib.setIlkMaxLiquidationAmount("ETH-A",  40 * MILLION); //  from 30 Million DAI to 40 Million DAI
        DssExecLib.setIlkMaxLiquidationAmount("ETH-B",  25 * MILLION); //  from 15 Million DAI to 25 Million DAI
        DssExecLib.setIlkMaxLiquidationAmount("ETH-C",  30 * MILLION); //  from 20 Million DAI to 30 Million DAI
        DssExecLib.setIlkMaxLiquidationAmount("WBTC-A", 25 * MILLION); //  from 15 Million DAI to 25 Million DAI
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
