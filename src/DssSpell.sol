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
pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

import { DssSpellCollateralAction } from "./DssSpellCollateral.sol";

interface StarknetBridgeLike {
    function close() external;
}

interface StarknetGovRelayLike {
    function relay(uint256 spell) external;
}

interface StarknetEscrowLike {
    function approve(address token, address spender, uint256 value) external;
}


contract DssSpellAction is DssAction, DssSpellCollateralAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/27dc14fd37c03c152eca32296076f5603c9fd4db/governance/votes/Executive%20vote%20-%20October%2026%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-10-26 MakerDAO Executive Spell | Hash: 0x2e8fa79dc9702f6d3b8b03523fc45c4f3f95751a833e52958d64182b0ec8b2a5";

    // Turn office hours on
    function officeHours() public override returns (bool) {
        return true;
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
    // uint256 constant THREE_PCT_RATE          = 1000000000937303470807876289;
    
    // --- Math ---
    // uint256 internal constant WAD = 10 ** 18;

    function actions() public override {

        // ---------------------------------------------------------------------
        // rETH Onboarding
        // Vote: https://vote.makerdao.com/polling/QmfMswF2#poll-detail
        // Vote: https://vote.makerdao.com/polling/QmS7dBuQ#poll-detail
        // Forum: https://forum.makerdao.com/t/reth-collateral-onboarding-risk-evaluation/15286

        // Includes changes from the DssSpellCollateralAction
        collateralAction();

        // Starknet Bridge Fee Upgrade
        // Vote: https://vote.makerdao.com/polling/QmbWkTvW#poll-detail
        // Forum: https://forum.makerdao.com/t/starknet-changes-for-2022-10-26-executive-spell/18468

        // Close the current bridge
        address currentStarknetDAIBridge = DssExecLib.getChangelogAddress("STARKNET_DAI_BRIDGE");
        (bool currentBridgeClosed,) = currentStarknetDAIBridge.call(abi.encodeWithSignature("close()"));

        // Approve new bridge and cast spell only if the current bridge has closed successfully
        if(currentBridgeClosed == true && StarknetBridgeLike(currentStarknetDAIBridge).isOpen() == 0){
            // Bridge code at time of casting: https://github.com/makerdao/starknet-dai-bridge/blob/ad9f53425582c39c29cb3a7420e430ab01a46d4d/contracts/l1/L1DAIBridge.sol
            address NEW_STARKNET_DAI_BRIDGE = TODO;
            address starknetEscrow = DssExecLib.getChangelogAddress("STARKNET_ESCROW");
            address dai = DssExecLib.getChangelogAddress("MCD_DAI");
            StarknetEscrowLike(starknetEscrow).approve(dai, NEW_STARKNET_DAI_BRIDGE, type(uint).max);
            // Relay the L2 spell content
            // See: TODO insert L2 content voyager explorer #code URL
            address starknetGovRelay = DssExecLib.getChangelogAddress("STARKNET_GOV_RELAY");
            uint256 L2_FEE_SPELL = TODO;
            StarknetGovRelayLike(starknetGovRelay).relay(L2_FEE_SPELL);
            // ChangeLog
            DssExecLib.setChangelogAddress("STARKNET_DAI_BRIDGE", NEW_STARKNET_DAI_BRIDGE);
            DssExecLib.setChangelogAddress("STARKNET_DAI_BRIDGE_LEGACY", currentStarknetDAIBridge);
        }

        // Bump changelog version either way, due to rETH onboarding
        DssExecLib.setChangelogVersion("1.14.3");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
