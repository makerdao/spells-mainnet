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
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/0d5af5697be495ae7064a4067800d26072c49584/governance/votes/Executive%20vote%20-%20November%209%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-11-09 MakerDAO Executive Spell | Hash: 0x7a81bf01fb10ba896a8219a49780fc958b639e30d5d8ffefdf9b60583b9bebc7";


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

    // --- Wallets ---
    address internal constant STABLENODE_WALLET          = 0x3B91eBDfBC4B78d778f62632a4004804AC5d2DB0;
    address internal constant ULTRASCHUPPI_WALLET        = 0xCCffDBc38B1463847509dCD95e0D9AAf54D1c167;
    address internal constant FLIPFLOPFLAP_WALLET        = 0x688d508f3a6B0a377e266405A1583B3316f9A2B3;
    address internal constant FLIPSIDE_WALLET            = 0x62a43123FE71f9764f26554b3F5017627996816a;
    address internal constant FEEDBLACKLOOPS_WALLET      = 0x80882f2A36d49fC46C3c654F7f9cB9a2Bf0423e1;
    address internal constant PENNBLOCKCHAIN_WALLET      = 0x2165D41aF0d8d5034b9c266597c1A415FA0253bd;
    address internal constant JUSTIN_CASE_WALLET         = 0xE070c2dCfcf6C6409202A8a210f71D51dbAe9473;
    address internal constant MHONKASALOTEEMULAU_WALLET  = 0x97Fb39171ACd7C82c439b6158EA2F71D26ba383d;
    address internal constant ACREINVEST_WALLET          = 0x5b9C98e8A3D9Db6cd4B4B4C1F92D0A551D06F00D;
    address internal constant GFXLABS_WALLET             = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;
    address internal constant BLOCKCHAINCOLUMBIA_WALLET  = 0xdC1F98682F4F8a5c6d54F345F448437b83f5E432;
    address internal constant CHRISBLEC_WALLET           = 0xa3f0AbB4Ba74512b5a736C5759446e9B50FDA170;
    address internal constant LBSBLOCKCHAIN_WALLET       = 0xB83b3e9C8E3393889Afb272D354A7a3Bd1Fbcf5C;
    address internal constant FRONTIERRESEARCH_WALLET    = 0xA2d55b89654079987CF3985aEff5A7Bd44DA15A8;
    address internal constant ONESTONE_WALLET            = 0x4eFb12d515801eCfa3Be456B5F348D3CD68f9E8a;
    address internal constant CODEKNIGHT_WALLET          = 0x46dFcBc2aFD5DD8789Ef0737fEdb03489D33c428;
    address internal constant LLAMA_WALLET               = 0xA519a7cE7B24333055781133B13532AEabfAC81b;
    address internal constant PVL_WALLET                 = 0x6ebB1A9031177208A4CA50164206BF2Fa5ff7416;

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

        // ------------------ Delegate Compensation for October -----------------
        // https://forum.makerdao.com/t/recognized-delegate-compensation-october-2022/18658

        DssExecLib.sendPaymentFromSurplusBuffer(STABLENODE_WALLET,          12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(ULTRASCHUPPI_WALLET,        12_000);
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPFLOPFLAP_WALLET,        11_615);
        DssExecLib.sendPaymentFromSurplusBuffer(FLIPSIDE_WALLET,            11_395);
        DssExecLib.sendPaymentFromSurplusBuffer(FEEDBLACKLOOPS_WALLET,      10_671);
        DssExecLib.sendPaymentFromSurplusBuffer(PENNBLOCKCHAIN_WALLET,      10_390);
        DssExecLib.sendPaymentFromSurplusBuffer(JUSTIN_CASE_WALLET,          8_056);
        DssExecLib.sendPaymentFromSurplusBuffer(MHONKASALOTEEMULAU_WALLET,   7_545);
        DssExecLib.sendPaymentFromSurplusBuffer(ACREINVEST_WALLET,           6_682);
        DssExecLib.sendPaymentFromSurplusBuffer(GFXLABS_WALLET,              5_306);
        DssExecLib.sendPaymentFromSurplusBuffer(BLOCKCHAINCOLUMBIA_WALLET,   5_109);
        DssExecLib.sendPaymentFromSurplusBuffer(CHRISBLEC_WALLET,            5_057);
        DssExecLib.sendPaymentFromSurplusBuffer(LBSBLOCKCHAIN_WALLET,        2_995);
        DssExecLib.sendPaymentFromSurplusBuffer(FRONTIERRESEARCH_WALLET,     2_136);
        DssExecLib.sendPaymentFromSurplusBuffer(ONESTONE_WALLET,               271);
        DssExecLib.sendPaymentFromSurplusBuffer(CODEKNIGHT_WALLET,             270);
        DssExecLib.sendPaymentFromSurplusBuffer(LLAMA_WALLET,                  149);
        DssExecLib.sendPaymentFromSurplusBuffer(PVL_WALLET,                     65);

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
