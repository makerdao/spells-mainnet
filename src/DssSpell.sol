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

interface GemLike {
    function approve(address, uint256) external returns (bool);
}

interface RwaUrnLike {
    function lock(uint256) external;
    function draw(uint256) external;
    function transfer(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction, DssSpellCollateralAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/0344515b4f9ef9de6e589b5b873f5bafcf274b38/governance/votes/Executive%20Vote%20-%20September%2028%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-09-28 MakerDAO Executive Spell | Hash: 0x2ec09ea8a5fad89c49737c249313db441abebdefb9786c9503c4df5f74b3e983";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //

    // --- CUs ---
    address internal constant RWF_WALLET       = 0x96d7b01Cc25B141520C717fa369844d34FF116ec;
    address internal constant CES_OP_WALLET    = 0xD740882B8616B50d0B317fDFf17Ec3f4f853F44f;
    address internal constant RISK_WALLET_VEST = 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c;

    // --- Chainlog ---
    address internal constant PROXY_ACTIONS_END_CROPPER = 0x38f7C166B5B22906f04D8471E241151BA45d97Af;

    // Turn office hours off
    function officeHours() public override returns (bool) {
        return true;
    }

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralAction
        onboardNewCollaterals();

        // lock RWA007 Token in the URN
        GemLike(RWA007).approve(RWA007_A_URN, 1 * WAD);
        RwaUrnLike(RWA007_A_URN).lock(1 * WAD);
        
        DssExecLib.setChangelogVersion("1.14.2");

        // MIP65 Deployment - 1 million Pilot Transaction (RWA-007-A)
        // https://vote.makerdao.com/polling/QmXHM6us


        // --- MKR Vests ---
        

        // --- MKR Transfers ---
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
