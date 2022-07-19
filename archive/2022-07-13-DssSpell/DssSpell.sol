// SPDX-FileCopyrightText: © 2021 Dai Foundation <www.daifoundation.org>
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

// Enable ABIEncoderV2 when onboarding collateral
// pragma experimental ABIEncoderV2;
import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

import { DssSpellCollateralAction } from "./DssSpellCollateral.sol";

contract DssSpellAction is DssAction, DssSpellCollateralAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/0114d88f41cd3cf49ba818d2b3c4f159490a6944/governance/votes/Executive%20vote%20-%20July%2013%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-07-13 MakerDAO Executive Spell | Hash: 0xb339556c10ffe677e6eac39f49444dcc65e5b7f993b824752adf9cb27afcf663";

    uint256 constant MILLION = 10 ** 6;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmX2QMoM1SZq2XMoTbMak8pZP86Y2icpgPAKDjQg4r4YHn
    //
    uint256 constant ZERO_PCT_RATE     = 1000000000000000000000000000;
    uint256 constant ONE_BPS_RATE      = 1000000000003170820659990704;
    uint256 constant TWO_FIVE_PCT_RATE = 1000000000782997609082909351;

    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {

        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralAction
        // onboardNewCollaterals();
        // offboardCollaterals();

        // MOMC Parameter Changes
        // https://vote.makerdao.com/polling/QmefrhsE#poll-detail

        // Increase the GUNIV3DAIUSDC1-A Stability Fee from 0% to 0.01%.
        DssExecLib.setIlkStabilityFee("GUNIV3DAIUSDC1-A", ONE_BPS_RATE, true);

        // Increase the UNIV2DAIUSDC-A Stability Fee from 0% to 0.01%.
        DssExecLib.setIlkStabilityFee("UNIV2DAIUSDC-A", ONE_BPS_RATE, true);

        // Increase the WSTETH-A Stability fee from 2.25% to 2.5%.
        DssExecLib.setIlkStabilityFee("WSTETH-A", TWO_FIVE_PCT_RATE, true);

        // Reduce the USDC-A Stability Fee from 1% to 0%.
        DssExecLib.setIlkStabilityFee("USDC-A", ZERO_PCT_RATE, true);

        // Reduce the PAXUSD-A Stability Fee from 1% to 0%.
        DssExecLib.setIlkStabilityFee("PAXUSD-A", ZERO_PCT_RATE, true);

        // Increase the UNIV2DAIUSDC-A Maximum Debt Ceiling from 250 million DAI to 300 million DAI.
        // Increase the UNIV2DAIUSDC-A Target Available Debt from 10 million DAI to 20 million DAI.
        DssExecLib.setIlkAutoLineParameters("UNIV2DAIUSDC-A", 300 * MILLION, 20 * MILLION, 8 hours);

        // Reduce the LINK-A Maximum Debt Ceiling from 50 million DAI to 25 million DAI.
        DssExecLib.setIlkAutoLineDebtCeiling("LINK-A", 25 * MILLION);

        // Reduce the WSTETH-A Maximum Debt Ceiling from 200 million DAI to 150 million DAI.
        DssExecLib.setIlkAutoLineDebtCeiling("WSTETH-A", 150 * MILLION);

        // Reduce the WSTETH-B Maximum Debt Ceiling from 150 million DAI to 100 million DAI.
        DssExecLib.setIlkAutoLineDebtCeiling("WSTETH-B", 100 * MILLION);

        // Reduce the YFI-A Maximum Debt Ceiling from 50 million DAI to 25 million DAI.
        DssExecLib.setIlkAutoLineDebtCeiling("YFI-A", 25 * MILLION);

        // Reduce the MATIC-A Maximum Debt Ceiling from 35 million DAI to 20 million DAI.
        // Reduce the MATIC-A Target Available Debt from 10 million DAI to 5 million DAI.
        DssExecLib.setIlkAutoLineParameters("MATIC-A", 20 * MILLION, 5 * MILLION, 8 hours);

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
