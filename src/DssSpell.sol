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
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/24a804f432fc5baddaebfee28300f689bae6083c/governance/votes/Executive%20Vote%20-%20December%202024%20out-of-schedule%20spell%203.md' -q -O - 2>/dev/null)"
    string public constant override description = "2024-12-OOS3 MakerDAO Executive Spell | Hash: 0x5c17e2befee2eb156503acf6cdd49cf07966d306d1466a53f6857c01df323fb6";

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
    uint256 internal constant SEVENTEEN_PT_FIVE_PCT_RATE        = 1000000005113779426955452540;
    uint256 internal constant EIGHTEEN_PT_ONE_THREE_PCT_RATE    = 1000000005283343715514990579;
    uint256 internal constant EIGHTEEN_PT_FIVE_PCT_RATE         = 1000000005382508087389505206;
    uint256 internal constant NINETEEN_PT_FIVE_PCT_RATE         = 1000000005648978497166602432;
    uint256 internal constant NINETEEN_PT_SEVEN_FIVE_PCT_RATE   = 1000000005715247679413371444;
    uint256 internal constant TWENTY_PT_TWO_FIVE_PCT_RATE       = 1000000005847372004595219844;
    uint256 internal constant TWENTY_PT_FIVE_PCT_RATE           = 1000000005913228294456064283;
    uint256 internal constant TWENTY_PT_SEVEN_FIVE_PCT_RATE     = 1000000005978948094503498507;
    uint256 internal constant TWENTYFOUR_PCT_RATE               = 1000000006821137124257914908;
    uint256 internal constant TWENTYFOUR_PT_TWO_FIVE_PCT_RATE   = 1000000006885003796806875073;
    uint256 internal constant TWENTYFOUR_PT_SEVEN_FIVE_PCT_RATE = 1000000007012352531040649627;

    // ---------- Addresses ----------
    address internal immutable SUSDS = DssExecLib.getChangelogAddress("SUSDS");

    function actions() public override {
        // ---------- Stability Fees Changes ----------
        // Forum: https://forum.sky.money/t/out-of-schedule-executive-proposal-stability-scope-parameter-changes-19-sfs-dsr-ssr-spark-effective-dai-borrow-rate-spark-liquidity-layer/25648/4

        // Increase ETH-A Stability Fee by 3.50 percentage points from 16.25% to 19.75%
        DssExecLib.setIlkStabilityFee("ETH-A", NINETEEN_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase ETH-B Stability Fee by 3.50 percentage points from 16.75% to 20.25%
        DssExecLib.setIlkStabilityFee("ETH-B", TWENTY_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase ETH-C Stability Fee by 3.50 percentage points from 16.00% to 19.50%
        DssExecLib.setIlkStabilityFee("ETH-C", NINETEEN_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WSTETH-A Stability Fee by 3.50 percentage points from 17.25% to 20.75%
        DssExecLib.setIlkStabilityFee("WSTETH-A", TWENTY_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WSTETH-B Stability Fee by 3.50 percentage points from 17.00% to 20.50%
        DssExecLib.setIlkStabilityFee("WSTETH-B", TWENTY_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-A Stability Fee by 4.00 percentage points from 20.25% to 24.25%
        DssExecLib.setIlkStabilityFee("WBTC-A", TWENTYFOUR_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-B Stability Fee by 4.00 percentage points from 20.75% to 24.75%
        DssExecLib.setIlkStabilityFee("WBTC-B", TWENTYFOUR_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-C Stability Fee by 4.00 percentage points from 20.00% to 24.00%
        DssExecLib.setIlkStabilityFee("WBTC-C", TWENTYFOUR_PCT_RATE, /* doDrip = */ true);

        // Increase ALLOCATOR-SPARK-A Stability Fee by 2.94 percentage points from 15.19% to 18.13%
        DssExecLib.setIlkStabilityFee("ALLOCATOR-SPARK-A", EIGHTEEN_PT_ONE_THREE_PCT_RATE, /* doDrip = */ true);

        // ---------- Savings Rate Changes ----------
        // Forum: https://forum.sky.money/t/out-of-schedule-executive-proposal-stability-scope-parameter-changes-19-sfs-dsr-ssr-spark-effective-dai-borrow-rate-spark-liquidity-layer/25648/4

        // Increase DSR by 3.00 percentage points from 14.50% to 17.50%
        DssExecLib.setDSR(SEVENTEEN_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase SSR by 3.00 percentage points from 15.50% to 18.50%
        SUsdsLike(SUSDS).drip();
        SUsdsLike(SUSDS).file("ssr", EIGHTEEN_PT_FIVE_PCT_RATE);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
