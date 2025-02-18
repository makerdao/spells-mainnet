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

import { GemAbstract } from "dss-interfaces/ERC/GemAbstract.sol";

interface PauseLike {
    function setDelay(uint256) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/2025-02-18-oos-spell/1b0010f35154ef5471007ad74a4a407e3055f051/Executive%20vote%20-%20February%2018%2C%202025.md?token=GHSAT0AAAAAAC46W7DIC55DYQAX2ZHGVWBIZ5VCLHQ' -q -O - 2>/dev/null)"
    string public constant override description = "2025-02-18 MakerDAO Emergency Executive Spell | Hash: 0xa788e118495fc4b7ac23a3e078ea52bcb0719d9de885955ffe0a02ae52c6f4ba";

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
    uint256 internal constant TWENTY_PCT_RATE = 1000000005781378656804591712;

    // ---------- Math ----------
    uint256 internal constant MILLION = 10 ** 6;
    uint256 internal constant WAD     = 10 ** 18;

    // ---------- Contracts ----------
    GemAbstract internal immutable MKR          = GemAbstract(DssExecLib.mkr());
    address internal immutable LOCKSTAKE_ENGINE = DssExecLib.getChangelogAddress("LOCKSTAKE_ENGINE");
    address internal immutable MCD_PAUSE        = DssExecLib.getChangelogAddress("MCD_PAUSE");

    function actions() public override {
        // ---------- Seal Engine Changes ----------

        // Stability fee to 20%
        DssExecLib.setIlkStabilityFee("LSE-MKR-A", TWENTY_PCT_RATE, /* _doDrip */ true);

        // Debt ceiling to 45m
        // Gap to 45m
        // TTL to 30 min
        DssExecLib.setIlkAutoLineParameters("LSE-MKR-A", /* amount */ 45 * MILLION, /* gap */ 45 * MILLION, /* ttl */ 30 minutes);

        // Liquidation Ratio to 125%
        DssExecLib.setIlkLiquidationRatio("LSE-MKR-A", /* _pct_bps */ 125_00);

        // Exit fee to 0%
        DssExecLib.setValue(LOCKSTAKE_ENGINE, "fee", 0);

        // ---------- Reduce GSM delay ----------

        // GSM delay to 18h
        PauseLike(MCD_PAUSE).setDelay(18 hours);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
