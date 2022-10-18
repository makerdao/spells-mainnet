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

pragma solidity 0.6.12;
// Enable ABIEncoderV2 when onboarding collateral through `DssExecLib.addNewCollateral()`
// pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

import { DssSpellCollateralAction } from "./DssSpellCollateral.sol";

contract DssSpellAction is DssAction, DssSpellCollateralAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/57700b7c1eab15c213e5c92cd9ebf5de9df44f24/governance/votes/Executive%20vote%20-%20October%2019%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-10-19 MakerDAO Executive Spell | Hash: 0x300ef27d3eee7338f3619ea697a6e9f1c85e14f6547342c8f4a40d05f26ccd1f";

    // Turn office hours off
    function officeHours() public override returns (bool) {
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
    // --- Rates ---

    // --- Math ---
    uint256 internal constant WAD = 10 ** 18;

    function actions() public override {
        // Includes changes from DssSpellCollateralAction
        // onboardNewCollaterals();
        updateCollaterals();
        // offboardCollaterals();

        // ---------------------------------------------------------------------
        // Vote: https://vote.makerdao.com/polling/QmYffkvR#poll-detail
        // Forum: https://forum.makerdao.com/t/signal-request-change-psm-gusd-a-parameters/18142
        address MCD_PSM_GUSD_A = DssExecLib.getChangelogAddress("MCD_PSM_GUSD_A");
        DssExecLib.setIlkAutoLineParameters({
            _ilk:    "PSM-GUSD-A",
            _amount: 500 * MILLION,
            _gap:    50 * MILLION,
            _ttl:    24 hours
        });
        DssExecLib.setValue(MCD_PSM_GUSD_A, "tout", 20 * WAD / 100_00);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
