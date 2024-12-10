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
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/7389accfac1b03d92b077d179206708c938e8aff/governance/votes/Executive%20vote%20-%20December%202024%20out-of-schedule%20spell%202.md' -q -O - 2>/dev/null)"
    string public constant override description = "2024-12-OOS2 MakerDAO Executive Spell | Hash: 0xcd88c3304dd5e4f3697fed10bb1949af6cd134ac5c832c61dd1589aff5993eee";

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
    uint256 internal constant FOURTEEN_PT_FIVE_PCT_RATE      = 1000000004293652882321576158;
    uint256 internal constant FIFTEEN_PT_ONE_NINE_PCT_RATE   = 1000000004484168989960140704;
    uint256 internal constant FIFTEEN_PT_FIVE_PCT_RATE       = 1000000004569391942636426248;
    uint256 internal constant SIXTEEN_PCT_RATE               = 1000000004706367499604668374;
    uint256 internal constant SIXTEEN_PT_TWO_FIVE_PCT_RATE   = 1000000004774634032180348552;
    uint256 internal constant SIXTEEN_PT_SEVEN_FIVE_PCT_RATE = 1000000004910727769570159235;
    uint256 internal constant SEVENTEEN_PCT_RATE             = 1000000004978556227818707070;
    uint256 internal constant SEVENTEEN_PT_TWO_FIVE_PCT_RATE = 1000000005046239908035965222;
    uint256 internal constant TWENTY_PCT_RATE                = 1000000005781378656804591712;
    uint256 internal constant TWENTY_PT_TWO_FIVE_PCT_RATE    = 1000000005847372004595219844;
    uint256 internal constant TWENTY_PT_SEVEN_FIVE_PCT_RATE  = 1000000005978948094503498507;

    // ---------- Addresses ----------
    address internal immutable SUSDS = DssExecLib.getChangelogAddress("SUSDS");

    function actions() public override {
        // ---------- Stability Fees Changes ----------
        // Forum: https://forum.sky.money/t/out-of-schedule-executive-proposal-stability-scope-parameter-changes-19-sfs-dsr-ssr-spark-effective-dai-borrow-rate-spark-liquidity-layer/25648/4

        // Increase ETH-A Stability Fee by 3.50 percentage points from 12.75% to 16.25%
        DssExecLib.setIlkStabilityFee("ETH-A", SIXTEEN_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase ETH-B Stability Fee by 3.50 percentage points from 13.25% to 16.75%
        DssExecLib.setIlkStabilityFee("ETH-B", SIXTEEN_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase ETH-C Stability Fee by 3.50 percentage points from 12.50% to 16.00%
        DssExecLib.setIlkStabilityFee("ETH-C", SIXTEEN_PCT_RATE, /* doDrip = */ true);

        // Increase WSTETH-A Stability Fee by 3.50 percentage points from 13.75% to 17.25%
        DssExecLib.setIlkStabilityFee("WSTETH-A", SEVENTEEN_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WSTETH-B Stability Fee by 3.50 percentage points from 13.50% to 17.00%
        DssExecLib.setIlkStabilityFee("WSTETH-B", SEVENTEEN_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-A Stability Fee by 4.00 percentage points from 16.25% to 20.25%
        DssExecLib.setIlkStabilityFee("WBTC-A", TWENTY_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-B Stability Fee by 4.00 percentage points from 16.75% to 20.75%
        DssExecLib.setIlkStabilityFee("WBTC-B", TWENTY_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase WBTC-C Stability Fee by 4.00 percentage points from 16.00% to 20.00%
        DssExecLib.setIlkStabilityFee("WBTC-C", TWENTY_PCT_RATE, /* doDrip = */ true);

        // Increase ALLOCATOR-SPARK-A Stability Fee by 2.94 percentage points from 12.25% to 15.19%
        DssExecLib.setIlkStabilityFee("ALLOCATOR-SPARK-A", FIFTEEN_PT_ONE_NINE_PCT_RATE, /* doDrip = */ true);

        // ---------- Savings Rate Changes ----------
        // Forum: https://forum.sky.money/t/out-of-schedule-executive-proposal-stability-scope-parameter-changes-19-sfs-dsr-ssr-spark-effective-dai-borrow-rate-spark-liquidity-layer/25648/4

        // Increase DSR by 3.00 percentage points from 11.50% to 14.50%
        DssExecLib.setDSR(FOURTEEN_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase SSR by 3.00 percentage points from 12.50% to 15.50%
        SUsdsLike(SUSDS).drip();
        SUsdsLike(SUSDS).file("ssr", FIFTEEN_PT_FIVE_PCT_RATE);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
