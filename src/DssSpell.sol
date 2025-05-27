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
import { MCD, DssInstance } from "dss-test/MCD.sol";

import { BridgesConfig, TokenBridgeInit } from "./dependencies/op-token-bridge/TokenBridgeInit.sol";
import { L1TokenBridgeInstance } from "./dependencies/op-token-bridge/L1TokenBridgeInstance.sol";
import { L2TokenBridgeInstance } from "./dependencies/op-token-bridge/L2TokenBridgeInstance.sol";

import { VestAbstract } from "dss-interfaces/dss/VestAbstract.sol";
import { GemAbstract } from "dss-interfaces/ERC/GemAbstract.sol";

interface PauseLike {
    function setDelay(uint256) external;
}

interface VestedRewardsDistributionLike {
    function distribute() external;
}

interface VestedRewardsDistributionJobLike {
    function rem(address) external;
    function set(address, uint256) external;
}

interface DssVestLike {
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    // function file(bytes32, uint256) external;
    function restrict(uint256) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description = "2025-05-15 MakerDAO Executive Spell | Hash: TODO";

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

    // ---------- Math ----------
    uint256 internal constant MILLION = 10 ** 6;
    uint256 internal constant WAD = 10 ** 18;

    //  ---------- Contracts ----------
    address internal immutable USDS                         = DssExecLib.getChangelogAddress("USDS");
    address internal immutable SUSDS                        = DssExecLib.getChangelogAddress("SUSDS");

    // ---------- MKR to SKY Upgrade Phase Two ----------
    GemAbstract internal immutable SKY                      = GemAbstract(DssExecLib.getChangelogAddress("SKY"));
    address internal immutable MCD_SPLIT                    = DssExecLib.getChangelogAddress("MCD_SPLIT");
    address internal immutable MCD_PAUSE                    = DssExecLib.getChangelogAddress("MCD_PAUSE");
    address internal immutable MCD_VAT                      = DssExecLib.getChangelogAddress("MCD_VAT");
    address internal immutable LOCKSTAKE_MIGRATOR           = DssExecLib.getChangelogAddress("LOCKSTAKE_MIGRATOR");
    address internal immutable MCD_VEST_SKY                 = DssExecLib.getChangelogAddress("MCD_VEST_SKY");
    address internal immutable REWARDS_DIST_USDS_SKY        = DssExecLib.getChangelogAddress("REWARDS_DIST_USDS_SKY");
    address internal immutable MCD_VEST_SKY_TREASURY        = DssExecLib.getChangelogAddress("MCD_VEST_SKY_TREASURY");
    address internal immutable CRON_REWARDS_DIST_JOB        = DssExecLib.getChangelogAddress("CRON_REWARDS_DIST_JOB");
    address internal constant REWARDS_DIST_USDS_SKY_NEW     = 0xC8d67Fcf101d3f89D0e1F3a2857485A84072a63F;

    // ---------- Unichain Token Bridge ----------
    // Mainnet addresses
    address internal constant UNICHAIN_ESCROW               = 0x1196F688C585D3E5C895Ef8954FFB0dCDAfc566A;
    address internal constant UNICHAIN_GOV_RELAY            = 0xb383070Cf9F4f01C3a2cfD0ef6da4BC057b429b7;
    address internal constant UNICHAIN_TOKEN_BRIDGE         = 0xDF0535a4C96c9Cd8921d8FeC92A7680b281681d2;
    address internal constant UNICHAIN_TOKEN_BRIDGE_IMP     = 0x8A925ccFd5F7f46332E2D719A916f8b4a643599F;
    address internal constant UNICHAIN_MESSENGER            = 0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6;
    // Unichain addresses
    address internal constant L2_UNICHAIN_GOV_RELAY         = 0x3510a7F16F549EcD0Ef018DE0B3c2ad7c742990f;
    address internal constant L2_UNICHAIN_TOKEN_BRIDGE      = 0xa13152006D0216Fe4627a0D3B006087A6a55D752;
    address internal constant L2_UNICHAIN_TOKEN_BRIDGE_IMP  = 0xd78292C12707CF28E8EB7bf06fA774D1044C2dF5;
    address internal constant L2_UNICHAIN_USDS              = 0x7E10036Acc4B56d4dFCa3b77810356CE52313F9C;
    address internal constant L2_UNICHAIN_SUSDS             = 0xA06b10Db9F390990364A3984C04FaDf1c13691b5;
    address internal constant L2_UNICHAIN_SPELL             = 0x32760698c87834c02ED9AFF2d4FC3e16c029B936;
    address internal constant L2_UNICHAIN_MESSENGER         = 0x4200000000000000000000000000000000000007;

    // ---------- Optimism Token Bridge ----------
    // Mainnet addresses
    address internal constant OPTIMISM_ESCROW               = 0x467194771dAe2967Aef3ECbEDD3Bf9a310C76C65;
    address internal constant OPTIMISM_GOV_RELAY            = 0x09B354CDA89203BB7B3131CC728dFa06ab09Ae2F;
    address internal constant OPTIMISM_TOKEN_BRIDGE         = 0x3d25B7d486caE1810374d37A48BCf0963c9B8057;
    address internal constant OPTIMISM_TOKEN_BRIDGE_IMP     = 0xA50adBad34c1e9786979bD44220F8fd46e43A6B0;
    address internal constant OPTIMISM_MESSENGER            = 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1;
    // Optimism addresses
    address internal constant L2_OPTIMISM_GOV_RELAY         = 0x10E6593CDda8c58a1d0f14C5164B376352a55f2F;
    address internal constant L2_OPTIMISM_TOKEN_BRIDGE      = 0x8F41DBF6b8498561Ce1d73AF16CD9C0d8eE20ba6;
    address internal constant L2_OPTIMISM_TOKEN_BRIDGE_IMP  = 0xc2702C859016db756149716cc4d2B7D7A436CF04;
    address internal constant L2_OPTIMISM_USDS              = 0x4F13a96EC5C4Cf34e442b46Bbd98a0791F20edC3;
    address internal constant L2_OPTIMISM_SUSDS             = 0xb5B2dc7fd34C249F4be7fB1fCea07950784229e0;
    address internal constant L2_OPTIMISM_SPELL             = 0x99892216eD34e8FD924A1dBC758ceE61a9109409;
    address internal constant L2_OPTIMISM_MESSENGER         = 0x4200000000000000000000000000000000000007;

    function actions() public override {
        // Note: multple actions in the spell depend on DssInstance
        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);

        // ----- MKR to SKY Upgrade Phase Two -----

        // Activate USDS rewards on the LSEV2-SKY-A contract
        // Reduce splitter.burn by 50 percentage points from 100% to 50%
        DssExecLib.setValue(MCD_SPLIT, "burn", WAD / 2); // Note: 100% == 1 WAD

        // LSEV2-SKY-A AutoLine Addition
        // Add LSEV2-SKY-A to the AutoLine
        // Set line to 50,000,000 USDS
        // Set gap to 25,000,000 USDS
        // Set ttl to 86,400 seconds
        DssExecLib.setIlkAutoLineParameters("LSEV2-SKY-A", 50 * MILLION, 25 * MILLION, 86_400);

        // Adjust GSM Pause Delay
        // Reduce GSM Pause Delay by 24 hours from 48 hours to 24 hours
        PauseLike(MCD_PAUSE).setDelay(24 hours);

        // Revoke Migrator Authority Over Vat Contract
        // Revoke LOCKSTAKE_MIGRATOR's authority over the vat
        DssExecLib.deauthorize(MCD_VAT, LOCKSTAKE_MIGRATOR);

        // Change Source of SKY For USDS -> SKY Farm
        // yank MCD_VEST_SKY stream ID 2
        VestAbstract(MCD_VEST_SKY).yank(2);

        // Claim the remaining tokens from the old DssVest by calling VestedRewardsDistribution.distribute() on REWARDS_DIST_USDS_SKY
        VestedRewardsDistributionLike(REWARDS_DIST_USDS_SKY).distribute();

        // Set cap on MCD_VEST_SKY_TREASURY to `151,250,000 * WAD / 182 days`
        DssExecLib.setValue(MCD_VEST_SKY_TREASURY, "cap", 151_250_000 * WAD / uint256(182 days));

        // Increase sky.approve(MCD_VEST_SKY_TREASURY, ...) by 137,500,000 SKY to account for new vesting stream
        uint256 currentAllowance = SKY.allowance(address(this), MCD_VEST_SKY_TREASURY);
        SKY.approve(MCD_VEST_SKY_TREASURY, currentAllowance + 137_500_000 * WAD);

        // Remove old REWARDS_USDS_SKY_DIST from the keeper job by calling `CRON_REWARDS_DIST_JOB.rem()` with the current REWARDS_USDS_SKY_DIST
        VestedRewardsDistributionJobLike(CRON_REWARDS_DIST_JOB).rem(REWARDS_DIST_USDS_SKY);

        // Update chainlog value for REWARDS_USDS_SKY_DIST to the new VestedRewardsDistribution contract at 0xC8d67Fcf101d3f89D0e1F3a2857485A84072a63F
        DssExecLib.setChangelogAddress("REWARDS_DIST_USDS_SKY", REWARDS_DIST_USDS_SKY_NEW);

        // Note: Bump chainlog version
        DssExecLib.setChangelogVersion("1.20.1");

        // Add new REWARDS_USDS_SKY_DIST to the keeper job by calling `CRON_REWARDS_DIST_JOB.set()` with the new REWARDS_USDS_SKY_DIST
        VestedRewardsDistributionJobLike(CRON_REWARDS_DIST_JOB).set(REWARDS_DIST_USDS_SKY_NEW, 601200); // TODO: Confirm frequency

        // Deploy new MCD_VEST_SKY_TREASURY stream with the following parameters: usr(REWARDS_USDS_SKY_DIST), tot(137,500,000 SKY), bgn(block.timestamp), tau(182 days), cliff: none, manager, none
        uint256 vestId = DssVestLike(MCD_VEST_SKY_TREASURY).create(
            REWARDS_DIST_USDS_SKY_NEW,
            137_500_000 * WAD,
            block.timestamp,
            182 days,
            0,
            address(0)
        );

        // Restrict the new stream, res: 1
        DssVestLike(MCD_VEST_SKY_TREASURY).restrict(vestId);

        // file the id of the newly created stream to the new REWARDS_USDS_SKY_DIST contract
        DssExecLib.setValue(REWARDS_DIST_USDS_SKY_NEW, "vestId", vestId);

        // ----- Init Unichain Native Bridge -----

        // Set l1BridgeInstance with the following parameters:
        L1TokenBridgeInstance memory l1BridgeInstance = L1TokenBridgeInstance({
            // Set parameter l1BridgeInstance.govRelay: (L1GovernanceRelay: 0xb383070Cf9F4f01C3a2cfD0ef6da4BC057b429b7)
            govRelay: UNICHAIN_GOV_RELAY,
            // Set parameter l1BridgeInstance.escrow: (Escrow: 0x1196F688C585D3E5C895Ef8954FFB0dCDAfc566A)
            escrow: UNICHAIN_ESCROW,
            // Set parameter l1BridgeInstance.bridge: (ERC1967Proxy: 0xDF0535a4C96c9Cd8921d8FeC92A7680b281681d2)
            bridge: UNICHAIN_TOKEN_BRIDGE,
            // Set parameter l1BridgeInstance.bridgeImp: (L1TokenBridge: 0x8A925ccFd5F7f46332E2D719A916f8b4a643599F)
            bridgeImp: UNICHAIN_TOKEN_BRIDGE_IMP
        });

        // Set l2BridgeInstance with the following parameters (Unichain Network):
        L2TokenBridgeInstance memory l2BridgeInstance = L2TokenBridgeInstance({
            // Set parameter l2BridgeInstance.govRelay: (L2GovernanceRelay: 0x3510a7F16F549EcD0Ef018DE0B3c2ad7c742990f)
            govRelay: L2_UNICHAIN_GOV_RELAY,
            // Set parameter l2BridgeInstance.bridge: (ERC1967Proxy: 0xa13152006D0216Fe4627a0D3B006087A6a55D752)
            bridge: L2_UNICHAIN_TOKEN_BRIDGE,
            // Set parameter l2BridgeInstance.bridgeImp: (L2TokenBridge: 0xd78292C12707CF28E8EB7bf06fA774D1044C2dF5)
            bridgeImp: L2_UNICHAIN_TOKEN_BRIDGE_IMP,
            // Set parameter l2BridgeInstance.spell: (L2TokenBridgeSpell: 0x32760698c87834c02ED9AFF2d4FC3e16c029B936)
            spell: L2_UNICHAIN_SPELL
        });

        // Note: Array with mainnet tokens
        address[] memory l1Tokens = new address[](2);
        l1Tokens[0] = USDS;
        l1Tokens[1] = SUSDS;

        // Note: Array with Unichain tokens
        address[] memory l2Tokens = new address[](2);
        l2Tokens[0] = L2_UNICHAIN_USDS;
        l2Tokens[1] = L2_UNICHAIN_SUSDS;

        // Note: Max withdrawals for tokens
        uint256[] memory maxWithdrawals = new uint256[](2);
        maxWithdrawals[0] = type(uint256).max;
        maxWithdrawals[1] = type(uint256).max;


        // Set cfg with the following parameters:
        BridgesConfig memory bridgeCfg = BridgesConfig({
            // Set parameter cfg.l1Messenger: (l1messenger 0x9A3D64E386C18Cb1d6d5179a9596A4B5736e98A6)
            l1Messenger: UNICHAIN_MESSENGER,
            // Set parameter cfg.l2Messenger: (l2messenger 0x4200000000000000000000000000000000000007)
            l2Messenger: L2_UNICHAIN_MESSENGER,
            // Set parameter cfg.l1Tokens: (USDS, SUSDS on mainnet)
            l1Tokens: l1Tokens,
            // Set parameter cfg.l2Tokens: (USDS: 0x7E10036Acc4B56d4dFCa3b77810356CE52313F9C, sUSDS: 0xA06b10Db9F390990364A3984C04FaDf1c13691b5 on Unichain)
            l2Tokens: l2Tokens,
            // Set parameter cfg.maxWithdraws: (type(uint256).max for each token)
            maxWithdraws: maxWithdrawals,
            // Set parameter cfg.minGasLimit: (500,000)
            minGasLimit: 500_000,
            // Set parameter cfg.govRelayCLKey: (chainlog key for govRelay -> UNICHAIN_GOV_RELAY)
            govRelayCLKey: "UNICHAIN_GOV_RELAY",
            // Set parameter cfg.escrowCLKey: (chainlog key for Escrow -> UNICHAIN_ESCROW)
            escrowCLKey: "UNICHAIN_ESCROW",
            // Set parameter cfg.l1BridgeCLKey: (chainlog key for L1TokenBridge -> UNICHAIN_TOKEN_BRIDGE)
            l1BridgeCLKey: "UNICHAIN_TOKEN_BRIDGE",
            // Set parameter cfg.l1BridgeImpCLKey: (chainlog key for L1TokenBridgeImp -> UNICHAIN_TOKEN_BRIDGE_IMP)
            l1BridgeImpCLKey: "UNICHAIN_TOKEN_BRIDGE_IMP"
        });

        // Init Unichain Token Bridge for USDS, sUSDS by calling TokenBridgeInit.initBridges using the following parameters:
        TokenBridgeInit.initBridges(dss, l1BridgeInstance, l2BridgeInstance, bridgeCfg);

        // ----- Init Optimism Native Bridge -----

        // Set l1BridgeInstance with the following parameters:
        l1BridgeInstance = L1TokenBridgeInstance({
            // Set parameter l1BridgeInstance.govRelay: (L1GovernanceRelay: 0x09B354CDA89203BB7B3131CC728dFa06ab09Ae2F)
            govRelay: OPTIMISM_GOV_RELAY,
            // Set parameter l1BridgeInstance.escrow: (Escrow: 0x467194771dAe2967Aef3ECbEDD3Bf9a310C76C65)
            escrow: OPTIMISM_ESCROW,
            // Set parameter l1BridgeInstance.bridge: (ERC1967Proxy: 0x3d25B7d486caE1810374d37A48BCf0963c9B8057)
            bridge: OPTIMISM_TOKEN_BRIDGE,
            // Set parameter l1BridgeInstance.bridgeImp: (L1TokenBridge: 0xA50adBad34c1e9786979bD44220F8fd46e43A6B0)
            bridgeImp: OPTIMISM_TOKEN_BRIDGE_IMP
        });

        // Set l2BridgeInstance with the following parameters (Optimism Network):
        l2BridgeInstance = L2TokenBridgeInstance({
            // Set parameter l2BridgeInstance.govRelay: (L2GovernanceRelay: 0x10E6593CDda8c58a1d0f14C5164B376352a55f2F)
            govRelay: L2_OPTIMISM_GOV_RELAY,
            // Set parameter l2BridgeInstance.bridge: (ERC1967Proxy: 0x8F41DBF6b8498561Ce1d73AF16CD9C0d8eE20ba6)
            bridge: L2_OPTIMISM_TOKEN_BRIDGE,
            // Set parameter l2BridgeInstance.bridgeImp: (L2TokenBridge: 0xc2702C859016db756149716cc4d2B7D7A436CF04)
            bridgeImp: L2_OPTIMISM_TOKEN_BRIDGE_IMP,
            // Set parameter l2BridgeInstance.spell: (L2TokenBridgeSpell: 0x99892216eD34e8FD924A1dBC758ceE61a9109409)
            spell: L2_OPTIMISM_SPELL
        });

        // Note: Array with Optimism tokens
        l2Tokens[0] = L2_OPTIMISM_USDS;
        l2Tokens[1] = L2_OPTIMISM_SUSDS;

        // Set cfg with the following parameters:
        bridgeCfg = BridgesConfig({
            // Set parameter cfg.l1Messenger: (l1messenger: 0x25ace71c97B33Cc4729CF772ae268934F7ab5fA1)
            l1Messenger: OPTIMISM_MESSENGER,
            // Set parameter cfg.l2Messenger: (l2messenger: 0x4200000000000000000000000000000000000007)
            l2Messenger: L2_OPTIMISM_MESSENGER,
            // Set parameter cfg.l1Tokens: (USDS, SUSDS on mainnet)
            l1Tokens: l1Tokens,
            // Set parameter cfg.l2Tokens: (USDS: 0x4F13a96EC5C4Cf34e442b46Bbd98a0791F20edC3, sUSDS: 0xb5B2dc7fd34C249F4be7fB1fCea07950784229e0 on Optimism)
            l2Tokens: l2Tokens,
            // Set parameter cfg.maxWithdraws: (type(uint256).max for each token)
            maxWithdraws: maxWithdrawals,
            // Set parameter cfg.minGasLimit: (500,000)
            minGasLimit: 500_000,
            // Set parameter cfg.govRelayCLKey: (chainlog key for govRelay -> OPTIMISM_GOV_RELAY)
            govRelayCLKey: "OPTIMISM_GOV_RELAY",
            // Set parameter cfg.escrowCLKey: (chainlog key for Escrow -> OPTIMISM_ESCROW)
            escrowCLKey: "OPTIMISM_ESCROW",
            // Set parameter cfg.l1BridgeCLKey: (chainlog key for L1TokenBridge -> OPTIMISM_TOKEN_BRIDGE)
            l1BridgeCLKey: "OPTIMISM_TOKEN_BRIDGE",
            // Set parameter cfg.l1BridgeImpCLKey: (chainlog key for L1TokenBridgeImp -> OPTIMISM_TOKEN_BRIDGE_IMP)
            l1BridgeImpCLKey: "OPTIMISM_TOKEN_BRIDGE_IMP"
        });

        // Init Optimism Token Bridge for USDS, sUSDS by calling TokenBridgeInit.initBridges using the following parameters:
        TokenBridgeInit.initBridges(dss, l1BridgeInstance, l2BridgeInstance, bridgeCfg);

        // ----- Deactivate SparkLend DDM -----

        // Remove DIRECT-SPARK-DAI from the AutoLine

        // Set Debt Ceiling to 0 USDS

        // Reduce Global Debt Ceiling to account for this change

        // ----- Transfer Ownership of SPK Token to SPK Company Multisig -----

        // Rely 0x6FE588FDCC6A34207485cc6e47673F59cCEDF92B on 0xc20059e0317DE91738d13af027DfC4a50781b066

        // Deny MCD_PAUSE_PROXY on 0xc20059e0317DE91738d13af027DfC4a50781b066

        // ----- Increase ALLOCATOR-SPARK-A Maximum Debt Ceiling -----

        // Increase ALLOCATOR-SPARK-A line by 5 billion USDS from 5 billion USDS to 10 billion USDS

        // gap remains unchanged at 500 million USDS

        // ttl remains unchanged at 86,400 seconds

        // ----- Launch Project Funding -----

        // Transfer 5,000,000 USDS to 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F

        // ----- Delegate Compensation for April 2025 -----

        // BLUE - 4,000 USDS - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf

        // Bonapublica - 4,000 USDS - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3

        // Byteron - 4,000 USDS - 0xc2982e72D060cab2387Dba96b846acb8c96EfF66

        // Cloaky - 4,000 USDS - 0x9244F47D70587Fa2329B89B6f503022b63Ad54A5

        // JuliaChang - 4,000 USDS - 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7

        // PBG - 3,867 USDS - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2

        // WBC - 2,400 USDS - 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47

        // ----- Atlas Core Development USDS Payments for May 2025 -----

        // BLUE - 50,167 USDS - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf

        // Cloaky - 16,417 USDS - 0x9244F47D70587Fa2329B89B6f503022b63Ad54A5

        // Kohla - 11,000 USDS - 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a

        // ----- Atlas Core Development SKY Payments for May 2025 -----

        // BLUE - 330,000 SKY - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf

        // Cloaky - 288,000 SKY - 0x9244F47D70587Fa2329B89B6f503022b63Ad54A5

        // ----- Execute Spark Proxy Spell -----

        // Execute Spark Proxy Spell at address xyz
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
