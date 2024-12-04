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

interface SUsdsLike {
    function file(bytes32, uint256) external;
    function drip() external returns (uint256);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description = "2024-12-06 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // ---------- Rates ----------
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // uint256 internal constant X_PCT_RATE = ;
    uint256 internal constant ELEVEN_PT_FIVE_PCT_RATE         = 1000000003451750542235895695;
    uint256 internal constant TWELVE_PT_TWO_FIVE_PCT_RATE     = 1000000003664330950215446102;
    uint256 internal constant TWELVE_PT_FIVE_PCT_RATE         = 1000000003734875566854894261;
    uint256 internal constant TWELVE_PT_SEVEN_FIVE_PCT_RATE   = 1000000003805263591546724039;
    uint256 internal constant THIRTEEN_PT_TWO_FIVE_PCT_RATE   = 1000000003945572635100236468;
    uint256 internal constant THIRTEEN_PT_FIVE_PCT_RATE       = 1000000004015495027511808328;
    uint256 internal constant THIRTEEN_PT_SEVEN_FIVE_PCT_RATE = 1000000004085263575156219812;
    uint256 internal constant SIXTEEN_PCT_RATE                = 1000000004706367499604668374;
    uint256 internal constant SIXTEEN_PT_TWO_FIVE_PCT_RATE    = 1000000004774634032180348552;
    uint256 internal constant SIXTEEN_PT_SEVEN_FIVE_PCT_RATE  = 1000000004910727769570159235;

    // ---------- Addresses ----------
    address internal immutable SUSDS = DssExecLib.getChangelogAddress("SUSDS");

    function actions() public override {
        // ---------- Stability Fees Changes ----------
        // Forum: https://forum.sky.money/t/out-of-schedule-executive-proposal-stability-scope-parameter-changes-19-sfs-dsr-ssr-spark-effective-dai-borrow-rate-spark-liquidity-layer/25648

        // Increase ETH-A Stability Fee by 3.50 percentage points from 9.25% to 12.75%
        DssExecLib.setIlkStabilityFee("ETH-A", TWELVE_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase ETH-B Stability Fee by 3.50 percentage points from 9.75% to 13.25%
        DssExecLib.setIlkStabilityFee("ETH-B", THIRTEEN_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase ETH-C Stability Fee by 3.50 percentage points from 9.00% to 12.50%
        DssExecLib.setIlkStabilityFee("ETH-C", TWELVE_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WSTETH-A Stability Fee by 3.50 percentage points from 10.25% to 13.75%
        DssExecLib.setIlkStabilityFee("WSTETH-A", THIRTEEN_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WSTETH-B Stability Fee by 3.50 percentage points from 10.00% to 13.50%
        DssExecLib.setIlkStabilityFee("WSTETH-B", THIRTEEN_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-A Stability Fee by 4.00 percentage points from 12.25% to 16.25%
        DssExecLib.setIlkStabilityFee("WBTC-A", SIXTEEN_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-B Stability Fee by 4.00 percentage points from 12.75% to 16.75%
        DssExecLib.setIlkStabilityFee("WBTC-B", SIXTEEN_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-C Stability Fee by 4.00 percentage points from 12.00% to 16.00%
        DssExecLib.setIlkStabilityFee("WBTC-C", SIXTEEN_PCT_RATE, /* doDrip = */ true);

        // Increase ALLOCATOR-SPARK-A Stability Fee by 2.94 percentage points from 9.31% to 12.25%
        DssExecLib.setIlkStabilityFee("ALLOCATOR-SPARK-A", TWELVE_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // ---------- Savings Rate Changes ----------
        // Forum: https://forum.sky.money/t/out-of-schedule-executive-proposal-stability-scope-parameter-changes-19-sfs-dsr-ssr-spark-effective-dai-borrow-rate-spark-liquidity-layer/25648

        // Increase DSR by 3 percentage points from 8.50% to 11.50%
        DssExecLib.setDSR(ELEVEN_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase SSR by 3 percentage points from 9.50% to 12.50%
        SUsdsLike(SUSDS).drip();
        SUsdsLike(SUSDS).file("ssr", TWELVE_PT_FIVE_PCT_RATE);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
