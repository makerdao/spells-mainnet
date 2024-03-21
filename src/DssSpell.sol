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
    // Hash: cast keccak -- "$(wget TODO -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-03-26 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // ---------- Approve HVBank (RWA009-A) Dao Resolution ----------
    // Forum: https://forum.makerdao.com/t/huntingdon-valley-bank-transaction-documents-on-permaweb/16264/24

    // Approve HVBank (RWA009-A) Dao Resolution with IPFS hash QmStrc9kMCmgzh2EVunjJkPsJLhsVRYyrNFBXBbJAJMrrf
    // Note: see dao_resolutions variable below

    // ---------- Approve TACO Dao Resolution ----------
    // Approve TACO Dao Resolution with IPFS hash TBD

    // Note: by the previous convention it should be a comma-separated list of DAO resolutions IPFS hashes
    string public constant dao_resolutions = "QmStrc9kMCmgzh2EVunjJkPsJLhsVRYyrNFBXBbJAJMrrf";

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
    uint256 internal constant THIRTEEN_PCT_RATE               = 1000000003875495717943815211;
    uint256 internal constant THIRTEEN_PT_TWO_FIVE_PCT_RATE   = 1000000003945572635100236468;
    uint256 internal constant THIRTEEN_PT_SEVEN_FIVE_PCT_RATE = 1000000004085263575156219812;
    uint256 internal constant FOURTEEN_PCT_RATE               = 1000000004154878953532704765;
    uint256 internal constant FOURTEEN_PT_TWO_FIVE_PCT_RATE   = 1000000004224341833701283597;
    uint256 internal constant FOURTEEN_PT_FIVE_PCT_RATE       = 1000000004293652882321576158;
    uint256 internal constant FOURTEEN_PT_SEVEN_FIVE_PCT_RATE = 1000000004362812761691191350;
    uint256 internal constant FIFTEEN_PT_TWO_FIVE_PCT_RATE    = 1000000004500681640286189459;

    // ---------- Math ----------
    uint256 internal constant THOUSAND = 10 ** 3;
    uint256 internal constant MILLION  = 10 ** 6;
    uint256 internal constant RAD      = 10 ** 45;

    // ---------- Addesses ----------
    address internal immutable MCD_VOW  = DssExecLib.vow();
    address internal immutable MCD_FLAP = DssExecLib.flap();

    function actions() public override {
        // ---------- Stability Fee Updates ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-11-under-sta-article-3-3/23910

        // ETH-A: Decrease the Stability Fee by 2 percentage points from 15.25% to 13.25%
        DssExecLib.setIlkStabilityFee("ETH-A", THIRTEEN_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // ETH-B: Decrease the Stability Fee by 2 percentage points from 15.75% to 13.75%
        DssExecLib.setIlkStabilityFee("ETH-B", THIRTEEN_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // ETH-C: Decrease the Stability Fee by 2 percentage points from 15.00% to 13.00%
        DssExecLib.setIlkStabilityFee("ETH-C", THIRTEEN_PCT_RATE, /* doDrip = */ true);

        // WSTETH-A: Decrease the Stability Fee by 2 percentage points from 16.25% to 14.25%
        DssExecLib.setIlkStabilityFee("WSTETH-A", FOURTEEN_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // WSTETH-B: Decrease the Stability Fee by 2 percentage points from 16.00% to 14.00%
        DssExecLib.setIlkStabilityFee("WSTETH-B", FOURTEEN_PCT_RATE, /* doDrip = */ true);

        // WBTC-A: Decrease the Stability Fee by 2 percentage points from 16.75% to 14.75%
        DssExecLib.setIlkStabilityFee("WBTC-A", FOURTEEN_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // WBTC-B: Decrease the Stability Fee by 2 percentage points from 17.25% to 15.25%
        DssExecLib.setIlkStabilityFee("WBTC-B", FIFTEEN_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // WBTC-C: Decrease the Stability Fee by 2 percentage points from 16.50% to 14.50%
        DssExecLib.setIlkStabilityFee("WBTC-C", FOURTEEN_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // ---------- SparkLend D3M update ----------
        // Forum: https://forum.makerdao.com/t/mar-6-2024-proposed-changes-to-sparklend-for-upcoming-spell/23791/

        // Increase the SparkLend D3M Maximum Debt Ceiling by 1.0 billion DAI from 1.5 billion DAI to 2.5 billion DAI.
        DssExecLib.setIlkAutoLineDebtCeiling("DIRECT-SPARK-DAI", 2_500 * MILLION);

        // ---------- Morpho D3M setup ----------
        // TODO

        // ---------- DSR Change ----------
        // Forum: TODO

        // DSR: Decrease the Dai Savings Rate by 2 percentage points from 15.00% to 13.00%
        DssExecLib.setDSR(THIRTEEN_PCT_RATE, /* doDrip = */ true);

        // ---------- SBE Parameter Updates ----------
        // Forum: https://forum.makerdao.com/t/smart-burn-engine-the-rate-of-mkr-accumulation-reconfiguration-and-transaction-analysis-parameter-reconfiguration-update-6/23888

        // Decrease the hop parameter for 7,884 seconds from 19,710 seconds to 11,826 seconds.
        DssExecLib.setValue(MCD_FLAP, "hop", 11_826);

        // Increase the bump parameter for 25,000 DAI from 50,000 DAI to 75,000 DAI.
        DssExecLib.setValue(MCD_VOW, "bump", 75 * THOUSAND * RAD);

        // ---------- Spark Proxy Spell ----------
        // Forum: https://forum.makerdao.com/t/mar-6-2024-proposed-changes-to-sparklend-for-upcoming-spell/23791/

        // Trigger Spark Proxy Spell at TBD
        // TODO
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
