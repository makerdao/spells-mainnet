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
import { DssInstance, MCD } from "dss-test/MCD.sol";
import { L1TokenGatewayInstance } from "./dependencies/arbitrum-token-bridge/L1TokenGatewayInstance.sol";
import { L2TokenGatewayInstance } from "./dependencies/arbitrum-token-bridge/L2TokenGatewayInstance.sol";
import { GatewaysConfig, MessageParams, TokenGatewayInit } from "./dependencies/arbitrum-token-bridge/TokenGatewayInit.sol";
import { UniV2PoolWithdraw } from "./dependencies/univ2-pool-migrator/UniV2PoolWithdraw.sol";
import { GemAbstract } from "dss-interfaces/ERC/GemAbstract.sol";
import { DssAutoLineAbstract } from "dss-interfaces/dss/DssAutoLineAbstract.sol";

interface SUsdsLike {
    function drip() external returns (uint256);
    function file(bytes32 what, uint256 data) external;
}

interface ChainlogLike {
    function removeAddress(bytes32) external;
}

interface DaiUsdsLike {
    function daiToUsds(address usr, uint256 wad) external;
}

interface MkrSkyLike {
    function mkrToSky(address usr, uint256 wad) external;
    function rate() external view returns (uint256);
}

interface UsdsJoinLike {
    function join(address usr, uint256 wad) external;
}

interface StakingRewardsLike {
    function setRewardsDuration(uint256) external;
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/6774aae11f98ee634b3f7711b8cdfab37edb4b86/governance/votes/Executive%20vote%20-%20February%2021%2C%202025.md' -q -O - 2>/dev/null)"
    string public constant override description = "2025-02-21 MakerDAO Executive Spell | Hash: 0xead72cdc3e272b8b7384f318da766fd90391dbb535cf10848486477a952fc5bd";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
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
    uint256 internal constant THREE_PT_TWO_TWO_PCT_RATE     = 1000000001004960893848761962;
    uint256 internal constant FOUR_PT_SEVEN_FIVE_PCT_RATE   = 1000000001471536429740616381;
    uint256 internal constant SIX_PT_FIVE_PCT_RATE          = 1000000001996917783620820123;
    uint256 internal constant SEVEN_PT_FIVE_PCT_RATE        = 1000000002293273137447730714;
    uint256 internal constant SEVEN_PT_SEVEN_FIVE_PCT_RATE  = 1000000002366931224128103346;
    uint256 internal constant EIGHT_PT_TWO_FIVE_PCT_RATE    = 1000000002513736079215619839;
    uint256 internal constant EIGHT_PT_FIVE_PCT_RATE        = 1000000002586884420913935572;
    uint256 internal constant EIGHT_PT_SEVEN_FIVE_PCT_RATE  = 1000000002659864411854984565;
    uint256 internal constant TWELVE_PT_FIVE_PCT_RATE       = 1000000003734875566854894261;
    uint256 internal constant TWELVE_PT_SEVEN_FIVE_PCT_RATE = 1000000003805263591546724039;
    uint256 internal constant THIRTEEN_PT_TWO_FIVE_PCT_RATE = 1000000003945572635100236468;

    // ---------- Math ----------
    uint256 internal constant MILLION = 10 ** 6;
    uint256 internal constant BILLION = 10 ** 9;
    uint256 internal constant WAD     = 10 ** 18;
    uint256 internal constant RAD     = 10 ** 45;

    // ---------- Wallets ----------
    address internal constant BLUE                         = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;
    address internal constant BONAPUBLICA                  = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant BYTERON                      = 0xc2982e72D060cab2387Dba96b846acb8c96EfF66;
    address internal constant CLOAKY_2                     = 0x9244F47D70587Fa2329B89B6f503022b63Ad54A5;
    address internal constant JULIACHANG                   = 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7;
    address internal constant PBG                          = 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2;
    address internal constant INTEGRATION_BOOST_INITIATIVE = 0xD6891d1DFFDA6B0B1aF3524018a1eE2E608785F7;

    // ---------- Contracts ----------
    GemAbstract internal immutable DAI                       = GemAbstract(DssExecLib.dai());
    GemAbstract internal immutable MKR                       = GemAbstract(DssExecLib.mkr());
    GemAbstract internal immutable SKY                       = GemAbstract(DssExecLib.getChangelogAddress("SKY"));
    address internal immutable MCD_IAM_AUTO_LINE             = DssExecLib.getChangelogAddress("MCD_IAM_AUTO_LINE");
    address internal immutable DAI_USDS                      = DssExecLib.getChangelogAddress("DAI_USDS");
    address internal immutable MKR_SKY                       = DssExecLib.getChangelogAddress("MKR_SKY");
    address internal constant EMSP_CLIP_BREAKER_FAB          = 0x867852D30bb3CB1411fB4e404FAE28EF742b1023;
    address internal constant EMSP_LINE_WIPE_FAB             = 0x8646F8778B58a0dF118FacEdf522181bA7277529;
    address internal constant EMSP_LITE_PSM_HALT_FAB         = 0xB261b73698F6dBC03cB1E998A3176bdD81C3514A;
    address internal constant EMSP_SPLITTER_STOP             = 0x12531afC02aC18a9597Cfe8a889b7B948243a60b;
    address internal immutable USDS_JOIN                     = DssExecLib.getChangelogAddress("USDS_JOIN");
    address internal immutable MCD_VOW                       = DssExecLib.vow();
    address internal immutable MCD_SPLIT                     = DssExecLib.getChangelogAddress("MCD_SPLIT");
    address internal immutable REWARDS_LSMKR_USDS            = DssExecLib.getChangelogAddress("REWARDS_LSMKR_USDS");
    address internal immutable USDS                          = DssExecLib.getChangelogAddress("USDS");
    address internal immutable SUSDS                         = DssExecLib.getChangelogAddress("SUSDS");
    address internal constant ARBITRUM_ROUTER                = 0x72Ce9c846789fdB6fC1f34aC4AD25Dd9ef7031ef;
    address internal constant ARBITRUM_INBOX                 = 0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f;
    address internal constant ARBITRUM_TOKEN_BRIDGE          = 0x84b9700E28B23F873b82c1BEb23d86C091b6079E;
    address internal constant ARBITRUM_TOKEN_BRIDGE_IMP      = 0x12eDe82637d5507026D4CDb3515B4b022Ed157b1;
    // Arbitrum
    address internal constant L2_USDS                        = 0x6491c05A82219b8D1479057361ff1654749b876b;
    address internal constant L2_SUSDS                       = 0xdDb46999F8891663a8F2828d25298f70416d7610;
    address internal constant L2_ARBITRUM_TOKEN_BRIDGE       = 0x13F7F24CA959359a4D710D32c715D4bce273C793;
    address internal constant L2_ARBITRUM_TOKEN_BRIDGE_IMP   = 0xD404eD36D6976BdCad8ABbcCC9F09ef07e33A9A8;
    address internal constant L2_ARBITRUM_TOKEN_BRIDGE_SPELL = 0x3D4357c3944F7A5b6a0B5b67B36588BA45D3f49D;

    // ---------- Constant Values ----------
    uint256 internal immutable MKR_SKY_RATE = MkrSkyLike(DssExecLib.getChangelogAddress("MKR_SKY")).rate();

    // ---------- Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0x9EAa8d72BD731BE8eD71D768a912F6832492071e;

    function actions() public override {
        // Note: Multiple actions in the spell depend on DssInstance
        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);

        // ---------- Rate Adjustments ----------
        // Forum: https://forum.sky.money/t/feb-20-2025-stability-scope-parameter-changes-22/26003

        // Reduce ETH-A Stability Fee by 2.00 percentage points from 9.75% to 7.75%
        DssExecLib.setIlkStabilityFee("ETH-A", SEVEN_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Reduce ETH-B Stability Fee by 2.00 percentage points from 10.25% to 8.25%
        DssExecLib.setIlkStabilityFee("ETH-B", EIGHT_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // Reduce ETH-C Stability Fee by 2.00 percentage points from 9.50% to 7.50%
        DssExecLib.setIlkStabilityFee("ETH-C", SEVEN_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // Reduce WSTETH-A Stability Fee by 2.00 percentage points from 10.75% to 8.75%
        DssExecLib.setIlkStabilityFee("WSTETH-A", EIGHT_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Reduce WSTETH-B Stability Fee by 2.00 percentage points from 10.50% to 8.50%
        DssExecLib.setIlkStabilityFee("WSTETH-B", EIGHT_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // Reduce WBTC-A Stability Fee by 1.50 percentage points from 14.25% to 12.75%
        DssExecLib.setIlkStabilityFee("WBTC-A", TWELVE_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Reduce WBTC-B Stability Fee by 1.50 percentage points from 14.75% to 13.25%
        DssExecLib.setIlkStabilityFee("WBTC-B", THIRTEEN_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // Reduce WBTC-C Stability Fee by 1.50 percentage points from 14.00% to 12.50%
        DssExecLib.setIlkStabilityFee("WBTC-C", TWELVE_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // Increase ALLOCATOR-SPARK-A Stability Fee by 1.89 percentage points from 1.33% to 3.22%
        DssExecLib.setIlkStabilityFee("ALLOCATOR-SPARK-A", THREE_PT_TWO_TWO_PCT_RATE, /* doDrip = */ true);

        // Reduce DSR by 2.50 percentage points from 7.25% to 4.75%
        DssExecLib.setDSR(FOUR_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // Reduce SSR by 2.25 percentage points from 8.75% to 6.50%
        SUsdsLike(SUSDS).drip();
        SUsdsLike(SUSDS).file("ssr", SIX_PT_FIVE_PCT_RATE);

        // ---------- Init Arbitrum Token Bridge ----------
        // Forum: https://forum.sky.money/t/technical-scope-of-the-arbitrum-token-gateway-launch/25972
        // Forum: https://forum.sky.money/t/technical-scope-of-the-arbitrum-token-gateway-launch/25972/3
        // Poll: https://vote.makerdao.com/polling/QmcicBXG

        // Note: L1TokenGatewayInstance to pass in TokenGatewayInit.initGateways
        L1TokenGatewayInstance memory l1GatewayInstance = L1TokenGatewayInstance({
            // Set parameter l1GatewayInstance.gateway: (ERC1967Proxy: 0x84b9700E28B23F873b82c1BEb23d86C091b6079E)
            gateway: ARBITRUM_TOKEN_BRIDGE,
            // Set parameter l1GatewayInstance.gatewayImp: (L1TokenGateway: 0x12eDe82637d5507026D4CDb3515B4b022Ed157b1)
            gatewayImp: ARBITRUM_TOKEN_BRIDGE_IMP
        });

        // Note: L2TokenGatewayInstance to pass in TokenGatewayInit.initGateways
        L2TokenGatewayInstance memory l2GatewayInstance = L2TokenGatewayInstance({
            // Set parameter l2GatewayInstance.gateway: (ERC1967Proxy: 0x13F7F24CA959359a4D710D32c715D4bce273C793)
            gateway: L2_ARBITRUM_TOKEN_BRIDGE,
            // Set parameter l2GatewayInstance.gatewayImp: (L2TokenGateway: 0xD404eD36D6976BdCad8ABbcCC9F09ef07e33A9A8)
            gatewayImp: L2_ARBITRUM_TOKEN_BRIDGE_IMP,
            // Set parameter l2GatewayInstance.spell: (L2TokenGatewaySpell: 0x3D4357c3944F7A5b6a0B5b67B36588BA45D3f49D)
            spell: L2_ARBITRUM_TOKEN_BRIDGE_SPELL
        });

        // Note: Mainnet tokens for GatewaysConfig
        address[] memory l1Tokens = new address[](2);
        l1Tokens[0] = USDS;
        l1Tokens[1] = SUSDS;

        // Note: Arbitrum tokens for GatewaysConfig
        address[] memory l2Tokens = new address[](2);
        l2Tokens[0] = L2_USDS;
        l2Tokens[1] = L2_SUSDS;

        // Note: Arbitrum tokens max withdrawals for GatewaysConfig
        uint256[] memory maxWithdrawals = new uint256[](2);
        maxWithdrawals[0] = type(uint256).max;
        maxWithdrawals[1] = type(uint256).max;

        // Note: MessageParams for GatewaysConfig
        MessageParams memory xchainMsg = MessageParams({
            maxGas: 350_000,
            gasPriceBid: 100_000_000,
            maxSubmissionCost: 1_316_000_000_000_000
        });

        // Note: Create GatewaysConfig to pass in TokenGatewayInit.initGateways
        GatewaysConfig memory cfg = GatewaysConfig({
            // Set parameter cfg.l1Router: (L1GatewayRouter (ERC1967Proxy): 0x72Ce9c846789fdB6fC1f34aC4AD25Dd9ef7031ef)
            l1Router: ARBITRUM_ROUTER,
            // Set parameter cfg.inbox: (Inbox(ERC1967Proxy): 0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f)
            inbox: ARBITRUM_INBOX,
            // Set parameter cfg.l1Tokens: (array [`USDS`, `SUSDS`])
            l1Tokens: l1Tokens,
            // Set parameter cfg.l2Tokens: (array [Usds(ERC1967Proxy): 0x6491c05A82219b8D1479057361ff1654749b876b, SUsds(ERC1967Proxy): 0xdDb46999F8891663a8F2828d25298f70416d7610])
            l2Tokens: l2Tokens,
            // Set parameter cfg.maxWithdraws: (array [type(uint256).max, type(uint256).max])
            maxWithdraws: maxWithdrawals,
            // Set parameter cfg.xchainMsg.maxGas: 350000
            // Set parameter cfg.xchainMsg.gasPriceBid: 100000000
            // Set parameter cfg.xchainMsg.maxSubmissionCost: 1316000000000000
            xchainMsg: xchainMsg
        });

        // Init Arbitrum Token Bridge by calling TokenGatewayInit.initGateways using the following parameters:
        TokenGatewayInit.initGateways(
            dss,
            l1GatewayInstance,
            l2GatewayInstance,
            cfg
        );

        // ---------- Unwind SBE liquidity ----------
        // Forum: https://forum.sky.money/t/smart-burn-engine-liquidity-unwind/26027
        // Forum: https://forum.sky.money/t/smart-burn-engine-liquidity-unwind/26027/3

        // Note: Save Usds amount before withdraw
        uint256 pProxyUsdsPrev = GemAbstract(USDS).balanceOf(address(this));

        // Unwind SBE liquidity by calling UniV2PoolWithdraw.withdraw using the following parameter:
        UniV2PoolWithdraw.withdraw(
            // Note: Pass DssInstance
            dss,
            // Set parameter usdsToLeave: 7,500,000 * 1e18
            7_500_000 * WAD
        );

        // Note: Calculate the amount of Usds withdrawn
        uint256 withdrawnUsdsAmount = GemAbstract(USDS).balanceOf(address(this)) - pProxyUsdsPrev;

        // Sweep USDS returned by the SBE from the PauseProxy to the Surplus Buffer
        // Note: instruction is done in multiple actions below

        // Note: Approve UsdsJoin for the amount returned
        GemAbstract(USDS).approve(USDS_JOIN, withdrawnUsdsAmount);

        // Note: Move Usds to surplus buffer
        UsdsJoinLike(USDS_JOIN).join(MCD_VOW, withdrawnUsdsAmount);

        // ---------- SBE Parameter Changes ----------
        // Forum: https://forum.sky.money/t/smart-burn-engine-parameter-update-feb-21-spell/26033

        // Decrease vow.hump by 50 million DAI, from 120 million to 70 million DAI
        DssExecLib.setValue(MCD_VOW, "hump", 70 * MILLION * RAD);

        // Decrease vow.bump by 15,000 DAI, from 25,000 to 10,000 DAI
        DssExecLib.setValue(MCD_VOW, "bump", 10_000 * RAD);

        // Increase splitter.burn by 30.00 percentage points, from 70% to 100%
        DssExecLib.setValue(MCD_SPLIT, "burn", WAD);

        // Decrease splitter.hop by 14,773 seconds, from 15,649 seconds to 876 seconds
        DssExecLib.setValue(MCD_SPLIT, "hop", 876);

        // Note: Update farm rewards duration
        StakingRewardsLike(REWARDS_LSMKR_USDS).setRewardsDuration(876);

        // ---------- ALLOCATOR-SPARK-A DC-IAM parameter changes ----------
        // Forum: https://forum.sky.money/t/feb-20-2025-proposed-changes-to-spark-for-upcoming-spell/25951
        // Forum: https://forum.sky.money/t/feb-20-2025-proposed-changes-to-spark-for-upcoming-spell/25951/6
        // Poll: https://vote.makerdao.com/polling/QmXpKEFg

        // Increase DC-IAM gap by 400 million, from 100 million to 500 million USDS
        // Increase DC-IAM line by 4 billion USDS, from 1 billion USDS to 5 billion USDS
        // ttl: 86,400 seconds (unchanged)
        DssExecLib.setIlkAutoLineParameters("ALLOCATOR-SPARK-A", /* amount = */ 5 * BILLION, /* gap = */ 500 * MILLION, /* ttl = */ 24 hours);

        // ---------- Modify emergency spells in the chainlog ----------
        // Forum: https://forum.sky.money/t/atlas-edit-weekly-cycle-proposal-for-week-of-february-17-2025/25979
        // Poll: https://vote.makerdao.com/polling/QmQW5mb1

        // Update the value of EMSP_CLIP_BREAKER_FAB in the Chainlog to 0x867852D30bb3CB1411fB4e404FAE28EF742b1023
        // Note: remove the old address
        ChainlogLike(DssExecLib.LOG).removeAddress("EMSP_CLIP_BREAKER_FAB");
        DssExecLib.setChangelogAddress("EMSP_CLIP_BREAKER_FAB", EMSP_CLIP_BREAKER_FAB);

        // Update the value of EMSP_LINE_WIPE_FAB in the Chainlog to 0x8646F8778B58a0dF118FacEdf522181bA7277529
        // Note: remove the old address
        ChainlogLike(DssExecLib.LOG).removeAddress("EMSP_LINE_WIPE_FAB");
        DssExecLib.setChangelogAddress("EMSP_LINE_WIPE_FAB", EMSP_LINE_WIPE_FAB);

        // Add Standby spell to the chainlog, key: EMSP_LITE_PSM_HALT_FAB ,value: 0xB261b73698F6dBC03cB1E998A3176bdD81C3514A
        DssExecLib.setChangelogAddress("EMSP_LITE_PSM_HALT_FAB", EMSP_LITE_PSM_HALT_FAB);

        // Add Standby spell to the chainlog, key: EMSP_SPLITTER_STOP ,value: 0x12531afC02aC18a9597Cfe8a889b7B948243a60b
        DssExecLib.setChangelogAddress("EMSP_SPLITTER_STOP", EMSP_SPLITTER_STOP);

        // ---------- AD Compensation ----------
        // Forum: https://forum.sky.money/t/january-2025-aligned-delegate-compensation/25993
        // Atlas: https://sky-atlas.powerhouse.io/A.1.5.8_Budget_For_Prime_Delegate_Slots/e3e420fc-9b1f-4fdc-9983-fcebc45dd3aa%7C0db3af4ece0c

        // BLUE - 4,000 USDS - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferUsds(BLUE, 4_000 * WAD);

        // Bonapublica - 4,000 USDS - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        _transferUsds(BONAPUBLICA, 4_000 * WAD);

        // Byteron - 4,000 USDS - 0xc2982e72D060cab2387Dba96b846acb8c96EfF66
        _transferUsds(BYTERON, 4_000 * WAD);

        // Cloaky - 4,000 USDS - 0x9244F47D70587Fa2329B89B6f503022b63Ad54A5
        _transferUsds(CLOAKY_2, 4_000 * WAD);

        // JuliaChang - 4,000 USDS - 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7
        _transferUsds(JULIACHANG, 4_000 * WAD);

        // PBG - 387 USDS - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        _transferUsds(PBG, 387 * WAD);

        // ---------- Atlas Core Development USDS Payments ----------
        // Forum: https://forum.sky.money/t/atlas-core-development-payment-requests-february-2025/25921
        // Forum: https://forum.sky.money/t/atlas-core-development-payment-requests-february-2025/25921/6

        // BLUE - 83,601 USDS - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferUsds(BLUE, 83_601 * WAD);

        // Cloaky - 18,835 USDS - 0x9244F47D70587Fa2329B89B6f503022b63Ad54A5
        _transferUsds(CLOAKY_2, 18_835 * WAD);

        // ---------- Atlas Core Development SKY Payments ----------
        // Forum: https://forum.sky.money/t/atlas-core-development-payment-requests-february-2025/25921
        // Forum: https://forum.sky.money/t/atlas-core-development-payment-requests-february-2025/25921/6

        // BLUE - 550,000 SKY - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferSky(BLUE, 550_000 * WAD);

        // Cloaky - 438,000 SKY - 0x9244F47D70587Fa2329B89B6f503022b63Ad54A5
        _transferSky(CLOAKY_2, 438_000 * WAD);

        // ---------- Top-up of the Integration Boost ----------
        // Forum: https://forum.sky.money/t/utilization-of-the-integration-boost-budget-a-5-2-1-2/25536/6
        // Atlas: https://sky-atlas.powerhouse.io/A.5.2.1.2_Integration_Boost/129f2ff0-8d73-8057-850b-d32304e9c91a%7C8d5a9e88cf49

        // Integration Boost - 3,000,000 USDS - 0xD6891d1DFFDA6B0B1aF3524018a1eE2E608785F7
        _transferUsds(INTEGRATION_BOOST_INITIATIVE, 3_000_000 * WAD);

        // ---------- Spark Proxy Spell ----------
        // Forum: https://forum.sky.money/t/feb-20-2025-proposed-changes-to-spark-for-upcoming-spell/25951
        // Forum: https://forum.sky.money/t/feb-20-2025-proposed-changes-to-spark-for-upcoming-spell-2/25961
        // Poll: https://vote.makerdao.com/polling/QmWQcu5A
        // Poll: https://vote.makerdao.com/polling/Qmdr4yqX
        // Poll: https://vote.makerdao.com/polling/QmUEJbje
        // Poll: https://vote.makerdao.com/polling/QmWbSTxi
        // Poll: https://vote.makerdao.com/polling/QmcicBXG

        // Note: The spark spell below expects the new auto-line settings to be effective.
        DssAutoLineAbstract(MCD_IAM_AUTO_LINE).exec("ALLOCATOR-SPARK-A");

        // Execute Spark Spell at 0x9EAa8d72BD731BE8eD71D768a912F6832492071e
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));

        // ---------- Chainlog bump ----------

        // Note: Bump chainlog patch version as multiple keys are being added
        DssExecLib.setChangelogVersion("1.19.6");
    }

    // ---------- Helper Functions ----------

    /// @notice wraps the operations required to transfer USDS from the surplus buffer.
    /// @param usr The USDS receiver.
    /// @param wad The USDS amount in wad precision (10 ** 18).
    function _transferUsds(address usr, uint256 wad) internal {
        // Note: Enforce whole units to avoid rounding errors
        require(wad % WAD == 0, "transferUsds/non-integer-wad");
        // Note: DssExecLib currently only supports Dai transfers from the surplus buffer.
        DssExecLib.sendPaymentFromSurplusBuffer(address(this), wad / WAD);
        // Note: Approve DAI_USDS for the amount sent to be able to convert it.
        DAI.approve(DAI_USDS, wad);
        // Note: Convert Dai to USDS for `usr`.
        DaiUsdsLike(DAI_USDS).daiToUsds(usr, wad);
    }

    /// @notice wraps the operations required to transfer SKY from the treasury.
    /// @param usr The SKY receiver.
    /// @param wad The SKY amount in wad precision (10 ** 18).
    function _transferSky(address usr, uint256 wad) internal {
        // Note: Calculate the equivalent amount of MKR required
        uint256 mkrWad = wad / MKR_SKY_RATE;
        // Note: if rounding error is expected, add an extra wei of MKR
        if (wad % MKR_SKY_RATE != 0) { mkrWad++; }
        // Note: Approve MKR_SKY for the amount sent to be able to convert it
        MKR.approve(MKR_SKY, mkrWad);
        // Note: Convert the calculated amount to SKY for `PAUSE_PROXY`
        MkrSkyLike(MKR_SKY).mkrToSky(address(this), mkrWad);
        // Note: Transfer originally requested amount, leaving extra on the `PAUSE_PROXY`
        GemAbstract(SKY).transfer(usr, wad);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
