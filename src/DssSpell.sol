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

interface TeleportJoinLike {
    function file(bytes32,bytes32,address) external;
    function file(bytes32,bytes32,uint256) external;
}

interface TeleportRouterLike {
    function file(bytes32,bytes32,address) external;
}

interface TeleportFeeLike {
    function fee() external view returns (uint256);
    function ttl() external view returns (uint256);
}

interface EscrowLike {
    function approve(address,address,uint256) external;
}

interface TeleportBridgeLike {
    function l1Escrow() external view returns (address);
    function l1TeleportRouter() external view returns (address);
    function l1Token() external view returns (address);
}

interface StarknetTeleportBridgeLike is TeleportBridgeLike {
    function l2TeleportGateway() external view returns (uint256); // uniquely returning uint256 on starknet
    function starkNet() external view returns (address);
}

contract DssSpellAction is DssAction, DssSpellCollateralAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/Executive%20vote%20-%20TODO.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-11-09 MakerDAO Executive Spell | Hash: TODO";


    // Turn office hours off
    function officeHours() public override returns (bool) {
        return false;
    }

    address internal immutable DAI = DssExecLib.dai();

    address internal immutable TELEPORT_JOIN = DssExecLib.getChangelogAddress("MCD_JOIN_TELEPORT_FW_A");
    address internal immutable ROUTER        = DssExecLib.getChangelogAddress("MCD_ROUTER_TELEPORT_FW_A");

    bytes32 internal constant ILK        = "TELEPORT-FW-A";
    bytes32 internal constant DOMAIN_STA = "STA-MAIN-A";

    address internal constant TELEPORT_GATEWAY_STA    = 0x95D8367B74ef8C5d014ff19C212109E243748e28;
    uint256 internal constant TELEPORT_L2_GATEWAY_STA = 0x05b20d8c7b85456c07bdb8eaaeab52a6bf3770a586af6da8d3f5071ef0dcf234;
    address internal constant LINEAR_FEE_STA          = 0x2123159d2178f07E3899d9d22aad2Fb177B59C48;

    address internal immutable ESCROW_STA     = DssExecLib.getChangelogAddress("STARKNET_ESCROW");
    address internal immutable DAI_BRIDGE_STA = DssExecLib.getChangelogAddress("STARKNET_DAI_BRIDGE");
    address internal immutable STARKNET_CORE  = DssExecLib.getChangelogAddress("STARKNET_CORE");

    uint256 internal constant CEILING = 100_000; // Whole Dai units

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
    uint256 internal constant SEVEN_PT_FIVE_PERCENT_RATE = 1000000002293273137447730714;

    // --- Math ---
    uint256 internal constant WAD = 10 ** 18;
    uint256 internal constant MILLION = 10 ** 6;

    function actions() public override {

        // Includes changes from the DssSpellCollateralAction
        // collateralAction();

        // ------------------ Setup Starknet Teleport Fast Withdrawals -----------------
        // https://vote.makerdao.com/polling/QmZxRgvG
        // https://forum.makerdao.com/t/request-for-poll-starknet-bridge-deposit-limit-and-starknet-teleport-fees/17187

        // Run sanity checks
        require(TeleportFeeLike(LINEAR_FEE_STA).fee() == WAD / 10000);
        require(TeleportFeeLike(LINEAR_FEE_STA).ttl() == 12 hours); // finalization time on Mainnet
        require(StarknetTeleportBridgeLike(TELEPORT_GATEWAY_STA).l1Escrow() == ESCROW_STA);
        require(StarknetTeleportBridgeLike(TELEPORT_GATEWAY_STA).l1TeleportRouter() == ROUTER);
        require(StarknetTeleportBridgeLike(TELEPORT_GATEWAY_STA).l1Token() == DAI);
        require(StarknetTeleportBridgeLike(TELEPORT_GATEWAY_STA).l2TeleportGateway() == TELEPORT_L2_GATEWAY_STA);
        require(StarknetTeleportBridgeLike(TELEPORT_GATEWAY_STA).starkNet() == STARKNET_CORE);

        // Increase system debt ceilings
        DssExecLib.increaseIlkDebtCeiling(ILK, CEILING, true);

        // Configure TeleportJoin
        TeleportJoinLike(TELEPORT_JOIN).file("fees", DOMAIN_STA, LINEAR_FEE_STA);
        TeleportJoinLike(TELEPORT_JOIN).file("line", DOMAIN_STA, CEILING * WAD);

        // Configure TeleportRouter
        TeleportRouterLike(ROUTER).file("gateway", DOMAIN_STA, TELEPORT_GATEWAY_STA);

        // Authorize TeleportGateway to use the escrow
        EscrowLike(ESCROW_STA).approve(DAI, TELEPORT_GATEWAY_STA, type(uint256).max);

        // Configure Chainlog
        DssExecLib.setChangelogAddress("STARKNET_TELEPORT_BRIDGE", TELEPORT_GATEWAY_STA);
        DssExecLib.setChangelogAddress("STARKNET_TELEPORT_FEE", LINEAR_FEE_STA);

        DssExecLib.setChangelogVersion("1.14.4");

        // ------------------ MOMC Parameter Changes -----------------
        // https://vote.makerdao.com/polling/QmahDuNx#poll-detail

        // Increase the MANA-A Stability Fee from 4.5% to 7.5%
        DssExecLib.setIlkStabilityFee("MANA-A", SEVEN_PT_FIVE_PERCENT_RATE, true);

        // Decrease the MANA-A line from 17 million DAI to 10 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("MANA-A", 10 * MILLION);
    }
}

contract DssSpell is DssExec {

    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
