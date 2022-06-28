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

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction, DssSpellCollateralAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/9e4a28dd9961cc802f37493fb9176674fd746dff/governance/votes/Executive%20vote%20-%20June%2029%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-06-29 MakerDAO Executive Spell | Hash: 0xb2521ac39ef97ccbb20120431edefa51eb424149ed4a9f7d2840a92920a23420";

    address constant RISK_WALLET_VEST = 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c;

    // Math
    uint256 constant WAD = 10**18;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmPgPVrVxDCGyNR5rGp9JC5AUxppLzUAqvncRJDcxQnX1u
    //

    function officeHours() public override returns (bool) {
        return true;
    }

    function actions() public override {
        // Risk Core Unit MKR Vesting Transfer
        // https://github.com/makerdao/community/blob/9e4a28dd9961cc802f37493fb9176674fd746dff/governance/votes/Executive%20vote%20-%20June%2029%2C%202022.md#rick-core-unit-mkr-vesting-transfer
        GemLike(DssExecLib.mkr()).transfer(RISK_WALLET_VEST, 175 * WAD);

        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralAction
        // onboardCollaterals();
        offboardCollaterals();

        // Housekeeping - add Starknet core contract to Chainlog
        // Contract address taken from https://github.com/starknet-community-libs/starknet-addresses
        DssExecLib.setChangelogAddress("STARKNET_CORE", 0xc662c410C0ECf747543f5bA90660f6ABeBD9C8c4);
        DssExecLib.setChangelogVersion("1.13.2");

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
