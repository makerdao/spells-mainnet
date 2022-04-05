// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2021-2022 Dai Foundation
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

import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol";

interface DssVestLike {
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function restrict(uint256) external;
    function yank(uint256) external;
}

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/a7095d5b92ee825bef28b6f5d22baec50718d438/governance/votes/Executive%20vote%20-%20April%201%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-04-08 MakerDAO Executive Spell | Hash: TODO";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //

    // --- Rates ---
    uint256 constant ZERO_PCT_RATE           = 1000000000000000000000000000;
    uint256 constant ZERO_ZERO_FIVE_PCT_RATE = 1000000000015850933588756013;
    uint256 constant TWO_TWO_FIVE_PCT_RATE   = 1000000000705562181084137268;
    uint256 constant THREE_TWO_FIVE_PCT_RATE = 1000000001014175731521720677;
    uint256 constant FOUR_FIVE_PCT_RATE      = 1000000001395766281313196627;

    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // onboardNewCollaterals();

        // Rates Proposal - April 08, 2022
        // https://vote.makerdao.com/polling/QmdS8mCx#poll-detail

        // Decrease the WSTETH-A Stability Fee from 2.5% to 2.25%
        DssExecLib.setIlkStabilityFee("WSTETH-A", TWO_TWO_FIVE_PCT_RATE, true);

        // Decrease the CRVV1ETHSTETH-A Stability Fee from 3.5% to 2.25%
        DssExecLib.setIlkStabilityFee("CRVV1ETHSTETH-A", TWO_TWO_FIVE_PCT_RATE, true);

        // Decrease the WBTC-A Stability Fee from 3.75% to 3.25%
        DssExecLib.setIlkStabilityFee("WBTC-A", THREE_TWO_FIVE_PCT_RATE, true);

        // Decrease the WBTC-B Stability Fee from 5.0% to 4.5%
        DssExecLib.setIlkStabilityFee("WBTC-B", FOUR_FIVE_PCT_RATE, true);

        // Decrease the GUNIV3DAIUSDC1-A Stability Fee from 0.1% to 0%
        DssExecLib.setIlkStabilityFee("GUNIV3DAIUSDC1-A", ZERO_PCT_RATE, true);

        // Decrease the GUNIV3DAIUSDC2-A Stability Fee from 0.25% to 0.05%
        DssExecLib.setIlkStabilityFee("GUNIV3DAIUSDC2-A", ZERO_ZERO_FIVE_PCT_RATE, true);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
