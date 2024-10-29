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
import { BridgesConfig, TokenBridgeInit } from "./dependencies/base-token-bridge/TokenBridgeInit.sol";
import { L1TokenBridgeInstance } from "./dependencies/base-token-bridge/L1TokenBridgeInstance.sol";
import { L2TokenBridgeInstance } from "./dependencies/base-token-bridge/L2TokenBridgeInstance.sol";
import { AllocatorSharedInstance, AllocatorIlkInstance } from "./dependencies/dss-allocator/AllocatorInstances.sol";
import { AllocatorInit, AllocatorIlkConfig } from "./dependencies/dss-allocator/AllocatorInit.sol";

interface DssLitePsmLike {
    function kiss(address usr) external;
}

interface MedianLike {
    function lift(address[] memory a) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/71f200566736bdd5a3de20bd456181de1c7a2eb2/governance/votes/Executive%20vote%20-%20October%2031%2C%202024.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-10-31 MakerDAO Executive Spell | Hash: 0x6407f9203bf4f816cc353ebc95463d917e77ccb701f2e85945dcf91274b628ed";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // ---------- Math ----------
    uint256 internal constant RAY     = 10 ** 27;

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
    uint256 internal constant FIVE_PT_TWO_PCT_RATE = 1000000001607468111246255079;

    // --- Math ---
    uint256 internal constant RAD = 10 ** 45;

    address internal immutable USDS                    = DssExecLib.getChangelogAddress("USDS");
    address internal immutable SUSDS                   = DssExecLib.getChangelogAddress("SUSDS");
    address internal immutable ILK_REGISTRY            = DssExecLib.getChangelogAddress("ILK_REGISTRY");
    address internal immutable LITE_PSM                = DssExecLib.getChangelogAddress("MCD_LITE_PSM_USDC_A");
    address internal immutable MCD_PAUSE_PROXY         = DssExecLib.getChangelogAddress("MCD_PAUSE_PROXY");


    // ---------- BASE Token Bridge ----------
    // Mainnet addresses
    address internal constant BASE_GOV_RELAY           = 0x1Ee0AE8A993F2f5abDB51EAF4AC2876202b65c3b;
    address internal constant BASE_ESCROW              = 0x7F311a4D48377030bD810395f4CCfC03bdbe9Ef3;
    address internal constant BASE_TOKEN_BRIDGE        = 0xA5874756416Fa632257eEA380CAbd2E87cED352A;
    address internal constant BASE_TOKEN_BRIDGE_IMP    = 0xaeFd31c2e593Dc971f9Cb42cBbD5d4AD7F1970b6;
    address internal constant MESSENGER                = 0x866E82a600A1414e583f7F13623F1aC5d58b0Afa;
    // BASE addresses
    address internal constant L2_BASE_GOV_RELAY        = 0xdD0BCc201C9E47c6F6eE68E4dB05b652Bb6aC255;
    address internal constant L2_BASE_TOKEN_BRIDGE     = 0xee44cdb68D618d58F75d9fe0818B640BD7B8A7B7;
    address internal constant L2_BASE_TOKEN_BRIDGE_IMP = 0x289A37BE5D6CCeF7A8f2b90535B3BB6bD3905f72;
    address internal constant L2_USDS                  = 0x820C137fa70C8691f0e44Dc420a5e53c168921Dc;
    address internal constant L2_SUSDS                 = 0x5875eEE11Cf8398102FdAd704C9E96607675467a;
    address internal constant L2_SPELL                 = 0x6f29C3A29A3F056A71FB0714551C8D3547268D62;
    address internal constant L2_MESSENGER             = 0x4200000000000000000000000000000000000007;

    // ---------- Allocator System  ----------
    address internal constant ALLOCATOR_ROLES          = 0x9A865A710399cea85dbD9144b7a09C889e94E803;
    address internal constant ALLOCATOR_REGISTRY       = 0xCdCFA95343DA7821fdD01dc4d0AeDA958051bB3B;
    address internal constant PIP_ALLOCATOR            = 0xc7B91C401C02B73CBdF424dFaaa60950d5040dB7;
    address internal constant ALLOCATOR_SPARK_BUFFER   = 0xc395D150e71378B47A1b8E9de0c1a83b75a08324;
    address internal constant ALLOCATOR_SPARK_VAULT    = 0x691a6c29e9e96dd897718305427Ad5D534db16BA;
    address internal constant SPARK_ALM_PROXY          = 0x1601843c5E9bC251A3272907010AFa41Fa18347E;

    // ---------- Medians and Validators  ----------
    address internal constant ETH_GLOBAL_VALIDATOR     = 0xcfC62b2269521e3212Ce1b6670caE6F0e34E8bF3;
    address internal constant MANTLE_VALIDATOR         = 0xFa6eb665e067759ADdE03a8E6bD259adBd1D70c9;
    address internal constant NETHERMIND_VALIDATOR     = 0x91242198eD62F9255F2048935D6AFb0C2302D147;
    address internal constant EULER_VALIDATOR          = 0x1DCB8CcC022938e102814F1A299C7ae48A8BAAf6;
    address internal constant BTC_USD_MEDIAN           = 0xe0F30cb149fAADC7247E953746Be9BbBB6B5751f;
    address internal constant ETH_USD_MEDIAN           = 0x64DE91F5A373Cd4c28de3600cB34C7C6cE410C85;
    address internal constant WSTETH_USD_MEDIAN        = 0x2F73b6567B866302e132273f67661fB89b5a66F2;
    address internal constant MKR_USD_MEDIAN           = 0xdbBe5e9B1dAa91430cF0772fCEbe53F6c6f137DF;

    // ---------- Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY              = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;

    function actions() public override {
        // Note: multple actions in the spell depend on DssInstance
        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);

        // ---------- Init Base Native Bridge ----------
        // Forum: https://forum.sky.money/t/spell-contents-2024-10-31/25421/
        //
        // Set Escrow contract for L1 Bridge
        // Register USDS, sUSDS on L1 Bridge
        // Give max approval on Enscrow contract for L1 Bridge (USDS, sUSDS tokens)
        // Execute L2 Bridge spell through Gov Relay (register and set maxWithdrawals for USDS, sUSDS tokens on L2 Bridge)
        // Set BASE_GOV_RELAY, BASE_ENSCROW, BASE_TOKEN_BRIDGE and BASE_TOKEN_BRIDGE_IMP to CHAINLOG

        // Set l1BridgeInstance with the following parameters:
        L1TokenBridgeInstance memory l1BridgeInstance = L1TokenBridgeInstance({
            // Set parameter l1BridgeInstance.govRelay: (L1GovernanceRelay: 0x1Ee0AE8A993F2f5abDB51EAF4AC2876202b65c3b)
            govRelay: BASE_GOV_RELAY,
            // Set parameter l1BridgeInstance.escrow: (Escrow: 0x7F311a4D48377030bD810395f4CCfC03bdbe9Ef3)
            escrow: BASE_ESCROW,
            // Set parameter l1BridgeInstance.bridge: (ERC1967Proxy: 0xA5874756416Fa632257eEA380CAbd2E87cED352A)
            bridge: BASE_TOKEN_BRIDGE,
            // Set parameter l1BridgeInstance.bridgeImp: (L1TokenBridge: 0xaeFd31c2e593Dc971f9Cb42cBbD5d4AD7F1970b6)
            bridgeImp: BASE_TOKEN_BRIDGE_IMP
        });

        // Set l2BridgeInstance with the following parameters (Base Network):
        L2TokenBridgeInstance memory l2BridgeInstance = L2TokenBridgeInstance({
            // Set parameter l2BridgeInstance.govRelay: (L2GovernanceRelay: 0xdD0BCc201C9E47c6F6eE68E4dB05b652Bb6aC255)
            govRelay: L2_BASE_GOV_RELAY,
            // Set parameter l2BridgeInstance.bridge: (ERC1967Proxy: 0xee44cdb68D618d58F75d9fe0818B640BD7B8A7B7)
            bridge: L2_BASE_TOKEN_BRIDGE,
            // Set parameter l2BridgeInstance.bridgeImp: (L2TokenBridge: 0x289A37BE5D6CCeF7A8f2b90535B3BB6bD3905f72)
            bridgeImp: L2_BASE_TOKEN_BRIDGE_IMP,
            // Set parameter l2BridgeInstance.spell: (L2TokenBridgeSpell: 0x6f29C3A29A3F056A71FB0714551C8D3547268D62)
            spell: L2_SPELL
        });

        // Array with mainnet tokens
        address[] memory l1Tokens = new address[](2);
        l1Tokens[0] = USDS;
        l1Tokens[1] = SUSDS;

        // Array with Base tokens
        address[] memory l2Tokens = new address[](2);
        l2Tokens[0] = L2_USDS;
        l2Tokens[1] = L2_SUSDS;

        // Max withdrawals for Base tokens
        uint256[] memory maxWithdrawals = new uint256[](2);
        maxWithdrawals[0] = type(uint256).max;
        maxWithdrawals[1] = type(uint256).max;

        // Set cfg with the following parameters:
        BridgesConfig memory bridgeCfg = BridgesConfig({
            // Set parameter cfg.l1Messenger: (l1messenger 0x866E82a600A1414e583f7F13623F1aC5d58b0Afa)
            l1Messenger: MESSENGER,
            // Set parameter cfg.l2Messenger: (l2messenger 0x4200000000000000000000000000000000000007)
            l2Messenger: L2_MESSENGER,
            // Set parameter cfg.l1Tokens: (USDS, SUSDS on mainnet)
            l1Tokens: l1Tokens,
            // Set parameter cfg.l2Tokens: (USDS: 0x820C137fa70C8691f0e44Dc420a5e53c168921Dc, sUSDS: 0x5875eEE11Cf8398102FdAd704C9E96607675467a on Base chain)
            l2Tokens: l2Tokens,
            // Set parameter cfg.maxWithdraws: (type(uint256).max for each token)
            maxWithdraws: maxWithdrawals,
            // Set parameter cfg.minGasLimit: (500,000)
            minGasLimit: 500_000,
            // Set parameter cfg.govRelayCLKey: (chainlog key for govRelay -> BASE_GOV_RELAY)
            govRelayCLKey: "BASE_GOV_RELAY",
            // Set parameter cfg.escrowCLKey: (chainlog key for Escrow -> BASE_ESCROW)
            escrowCLKey: "BASE_ESCROW",
            // Set parameter cfg.l1BridgeCLKey: (chainlog key for L1TokenBridge -> BASE_TOKEN_BRIDGE)
            l1BridgeCLKey: "BASE_TOKEN_BRIDGE",
            // Set parameter cfg.l1BridgeImpCLKey: (chainlog key for L1TokenBridgeImp -> BASE_TOKEN_BRIDGE_IMP)
            l1BridgeImpCLKey: "BASE_TOKEN_BRIDGE_IMP"
        });

        // Init Base Token Bridge for USDS, sUSDS
        TokenBridgeInit.initBridges(dss, l1BridgeInstance, l2BridgeInstance, bridgeCfg);


        // ---------- Init Allocator System for Spark Subdao Proxy ----------
        // Forum: https://forum.sky.money/t/spell-contents-2024-10-31/25421/
        //
        // Init ALLOCATOR-SPARK-A ilk on vat, jug and spotter
        // Set duty on jug to 5.2%
        // Set line on vat
        // Increase Global Line on vat
        // Setup AutoLine for ALLOCATOR-SPARK-A:
        // line: 10_000_000
        // gap: 10_000_000
        // ttl: 86_400 seconds
        // Set spotter.pip for ALLOCATOR-SPARK-A to AllocatorOracle contract
        // Set spotter.mat for ALLOCATOR-SPARK-A to RAY
        // poke ALLOCATOR-SPARK-A (spotter.poke)
        // Add AllocatorBuffer address to AllocatorRegistry
        // Initiate the allocator vault by calling vat.slip & vat.grab
        // Set jug on AllocatorVault
        // Allow vault to pull funds from the buffer by giving max USDS approval
        // Set the allocator proxy as the ALLOCATOR-SPARK-A ilk admin instead of the Pause Proxy on AllocatorRoles
        // Move ownership of AllocatorVault & AllocatorBuffer to AllocatorProxy (SparkProxy)
        // Add Allocator contracts to chainlog (ALLOCATOR_ROLES, ALLOCATOR_REGISTRY, ALLOCATOR_SPARK_A_VAULT, ALLOCATOR_SPARK_A_BUFFER, PIP_ALLOCATOR_SPARK_A)
        // Add ALLOCATOR-SPARK-A ilk to IlkRegistry

        // Set sharedInstance with the following parameters:
        AllocatorSharedInstance memory allocatorSharedInstance = AllocatorSharedInstance({
            // Set parameter sharedInstance.oracle: (Allocator Oracle: 0xc7B91C401C02B73CBdF424dFaaa60950d5040dB7)
            oracle:   PIP_ALLOCATOR,
            // Set parameter sharedInstance.roles: (AllocatorRoles: 0x9A865A710399cea85dbD9144b7a09C889e94E803)
            roles:    ALLOCATOR_ROLES,
            // Set parameter sharedInstance.registry: (AllocatorRegistry: 0xCdCFA95343DA7821fdD01dc4d0AeDA958051bB3B)
            registry: ALLOCATOR_REGISTRY
        });

        // Set ilkInstance with the following parameters:
        AllocatorIlkInstance memory allocatorIlkInstance = AllocatorIlkInstance({
            // Set parameter ilkInstance.owner: (MCD_PAUSE_PROXY)
            owner:  MCD_PAUSE_PROXY,
            // Set parameter ilkInstance.vault: (AllocatorVault: 0x691a6c29e9e96dd897718305427Ad5D534db16BA)
            vault:  ALLOCATOR_SPARK_VAULT,
            // Set parameter ilkInstance.buffer: (AllocatorBuffer: 0xc395D150e71378B47A1b8E9de0c1a83b75a08324)
            buffer: ALLOCATOR_SPARK_BUFFER
        });

        // Set cfg with the following parameters:
        AllocatorIlkConfig memory allocatorIlkCfg = AllocatorIlkConfig({
            // Set parameter cfg.ilk: (ALLOCATOR-SPARK-A)
            ilk             : "ALLOCATOR-SPARK-A",
            // Set parameter cfg.duty: (5.2% -> 1000000001607468111246255079)
            duty            : FIVE_PT_TWO_PCT_RATE,
            // Set parameter cfg.gap: (10,000,000)
            maxLine         : 10_000_000 * RAD,
            // Set parameter cfg.maxLine: (10,000,000)
            gap             : 10_000_000 * RAD,
            // Set parameter cfg.ttl: (86,400 seconds)
            ttl             : 86_400 seconds,
            // Set parameter cfg.allocatorProxy: 0x3300f198988e4C9C63F75dF86De36421f06af8c4
            allocatorProxy  : SPARK_PROXY,
            // Set parameter cfg.ilkRegistry: 0x5a464c28d19848f44199d003bef5ecc87d090f87
            ilkRegistry     : ILK_REGISTRY
        });

        // Init shared components for Allocator System
        AllocatorInit.initShared(dss, allocatorSharedInstance);

        // Init Allocator ILK for Spark Subdao by calling
        AllocatorInit.initIlk(dss, allocatorSharedInstance, allocatorIlkInstance, allocatorIlkCfg);


        // ---------- Whitelist Spark ALM Proxy on the PSM ----------
        // Forum: https://forum.sky.money/t/spell-contents-2024-10-31/25421/

        DssLitePsmLike(LITE_PSM).kiss(SPARK_ALM_PROXY);


        // ---------- Add new validators for Median (Medianizer) ----------
        // Forum: https://forum.sky.money/t/spell-contents-2024-10-31/25421/

        address[] memory validators = new address[](4);
        // Add ETH Global validator 0xcfC62b2269521e3212Ce1b6670caE6F0e34E8bF3 to the following median contracts
        validators[0] = ETH_GLOBAL_VALIDATOR;
        // Add Mantle validator 0xFa6eb665e067759ADdE03a8E6bD259adBd1D70c9 to the following median contracts
        validators[1] = MANTLE_VALIDATOR;
        // Add Nethermind validator 0x91242198eD62F9255F2048935D6AFb0C2302D147 to the following median contracts
        validators[2] = NETHERMIND_VALIDATOR;
        // Add Euler validator 0x1DCB8CcC022938e102814F1A299C7ae48A8BAAf6to the following median contracts
        validators[3] = EULER_VALIDATOR;

        // Add all validators declared above to BTC/USD median contract at 0xe0F30cb149fAADC7247E953746Be9BbBB6B5751f
        MedianLike(BTC_USD_MEDIAN).lift(validators);

        // Add all validators declared above to ETH/USD median contract at 0x64DE91F5A373Cd4c28de3600cB34C7C6cE410C85
        MedianLike(ETH_USD_MEDIAN).lift(validators);

        // Add all validators declared above to WSTETH/USD median contract at 0x2F73b6567B866302e132273f67661fB89b5a66F2
        MedianLike(WSTETH_USD_MEDIAN).lift(validators);

        // Add all validators declared above to MKR/USD median contract at 0xdbBe5e9B1dAa91430cF0772fCEbe53F6c6f137DF
        MedianLike(MKR_USD_MEDIAN).lift(validators);


        // ---------- Chainlog bump ----------

        // Note: we have to patch chainlog version as new collateral is added
        DssExecLib.setChangelogVersion("1.19.3");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
