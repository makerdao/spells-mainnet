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
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-10-31 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
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

    // ---------- BASE Token Bridge ----------
    // Mainnet addresses
    address internal constant BASE_GOV_RELAY           = 0x1Ee0AE8A993F2f5abDB51EAF4AC2876202b65c3b;
    address internal constant BASE_ESCROW              = 0x7F311a4D48377030bD810395f4CCfC03bdbe9Ef3;
    address internal constant BASE_TOKEN_BRIDGE        = 0xA5874756416Fa632257eEA380CAbd2E87cED352A;
    address internal constant BASE_TOKEN_BRIDGE_IMP    = 0xaeFd31c2e593Dc971f9Cb42cBbD5d4AD7F1970b6;
    address internal constant MESSANGER                = 0x866E82a600A1414e583f7F13623F1aC5d58b0Afa;
    // BASE addresses
    address internal constant BASE_GOV_RELAY_L2        = 0xdD0BCc201C9E47c6F6eE68E4dB05b652Bb6aC255;
    address internal constant BASE_TOKEN_BRIDGE_L2     = 0xee44cdb68D618d58F75d9fe0818B640BD7B8A7B7;
    address internal constant BASE_TOKEN_BRIDGE_IMP_L2 = 0x289A37BE5D6CCeF7A8f2b90535B3BB6bD3905f72;
    address internal constant USDS_L2                  = 0x820C137fa70C8691f0e44Dc420a5e53c168921Dc;
    address internal constant SUSDS_L2                 = 0x5875eEE11Cf8398102FdAd704C9E96607675467a;
    address internal constant SPELL_L2                 = 0x6f29C3A29A3F056A71FB0714551C8D3547268D62;
    address internal constant MESSANGER_L2             = 0x4200000000000000000000000000000000000007;

    // ---------- Allocator System  ----------
    address internal constant ALLOCATOR_ROLES          = 0x9A865A710399cea85dbD9144b7a09C889e94E803;
    address internal constant ALLOCATOR_REGISTRY       = 0xCdCFA95343DA7821fdD01dc4d0AeDA958051bB3B;
    address internal constant PIP_ALLOCATOR_SPARK_A    = 0xc7B91C401C02B73CBdF424dFaaa60950d5040dB7;
    address internal constant ALLOCATOR_SPARK_BUFFER   = 0xc395D150e71378B47A1b8E9de0c1a83b75a08324;
    address internal constant ALLOCATOR_SPARK_VAULT    = 0x691a6c29e9e96dd897718305427Ad5D534db16BA;
    address internal constant ALLOCATOR_SPARK_OWNER    = 0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;

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

        // ---------- Init Base Token Bridge for USDS and sUSDS tokens ----------
        // Forum: TODO
        //
        // Set Escrow contract for L1 Bridge
        // Register USDS, sUSDS on L1 Bridge
        // Give max approval on Enscrow contract for L1 Bridge (USDS, sUSDS tokens)
        // Execute L2 Bridge spell through Gov Relay (register nad set maxWithdrawals for USDS, sUSDS tokens on L2 Bridge)
        // Set BASE_GOV_RELAY, BASE_ENSCROW, BASE_TOKEN_BRIDGE and BASE_TOKEN_BRIDGE_IMP ro CHAINLOG

        // Mainnet Token Bridge instace
        L1TokenBridgeInstance memory l1BridgeInstance = L1TokenBridgeInstance({
            govRelay: BASE_GOV_RELAY,
            escrow: BASE_ESCROW,
            bridge: BASE_TOKEN_BRIDGE,
            bridgeImp: BASE_TOKEN_BRIDGE_IMP
        });

        // Base Token Bridge instace
        L2TokenBridgeInstance memory l2BridgeInstance = L2TokenBridgeInstance({
            govRelay: BASE_GOV_RELAY_L2,
            bridge: BASE_TOKEN_BRIDGE_L2,
            bridgeImp: BASE_TOKEN_BRIDGE_IMP_L2,
            spell: SPELL_L2
        });

        // Array with mainnet tokens
        address[] memory l1Tokens = new address[](2);
        l1Tokens[0] = USDS;
        l1Tokens[1] = SUSDS;

        // Array with Base tokens
        address[] memory l2Tokens = new address[](2);
        l2Tokens[0] = USDS_L2;
        l2Tokens[1] = SUSDS_L2;

        // Max withdrawals for Base tokens
        uint256[] memory maxWithdrawals = new uint256[](2);
        maxWithdrawals[0] = type(uint256).max;
        maxWithdrawals[1] = type(uint256).max;

        BridgesConfig memory bridgeCfg = BridgesConfig({
            // Mainnet CrossDomain Messanger
            l1Messenger: MESSANGER,
            // Base CrossDomain Messanger
            l2Messenger: MESSANGER_L2,
            // Mainnet tokens (USDS, sUSDS)
            l1Tokens: l1Tokens,
            // Base tokens (USDS, sUSDS)
            l2Tokens: l2Tokens,
            // Max withdrawals for USDS, sUSDS
            maxWithdraws: maxWithdrawals,
            // Min gas for bridging
            minGasLimit: 500_000,
            // Chainlog key for Base Gov Relay Contract
            govRelayCLKey: "BASE_GOV_RELAY",
            // Chainlog key for Base Escrow Contract
            escrowCLKey: "BASE_ESCROW",
            // Chainlog key for Base Token Bridge Contract
            l1BridgeCLKey: "BASE_TOKEN_BRIDGE",
            // Chainlog key for Base Token Bridge Implementaion Contract
            l1BridgeImpCLKey: "BASE_TOKEN_BRIDGE_IMP"
        });

        // Init Base Token Bridge for USDS and sUSDS
        TokenBridgeInit.initBridges(dss, l1BridgeInstance, l2BridgeInstance, bridgeCfg);


        // ---------- Init Allocator ILK for Spark Subdao ----------
        // Forum: TODO
        //
        // Init ALLOCATOR-SPARK-A ilk on vat, jug and spotter
        // Set duty on jug to 5.2%
        // Set line on vat
        // Increase Global Line on vat
        // Setup AutoLine for ALLOCATOR-SPARK-A:
        // line: 10_000_000
        // gap: 2_500_000
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


        // Allocator shared contracts instance
        AllocatorSharedInstance memory allocatorSharedInstance = AllocatorSharedInstance({
            oracle:   PIP_ALLOCATOR_SPARK_A,
            roles:    ALLOCATOR_ROLES,
            registry: ALLOCATOR_REGISTRY
        });

        // Allocator ALLOCATOR-SPARK-A ilk contracts instance
        AllocatorIlkInstance memory allocatorIlkInstance = AllocatorIlkInstance({
            owner:  ALLOCATOR_SPARK_OWNER,
            vault:  ALLOCATOR_SPARK_VAULT,
            buffer: ALLOCATOR_SPARK_BUFFER
        });

        // Allocator init config
        AllocatorIlkConfig memory allocatorIlkCfg = AllocatorIlkConfig({
            // Init ilk for ALLOCATOR-SPARK-A
            ilk             : "ALLOCATOR-SPARK-A",
            // jug.duty      -> 5.2%
            duty            : FIVE_PT_TWO_PCT_RATE,
            // Autoline line -> 10_000_000
            maxLine         : 10_000_000 * RAD,
            // Autoline gap  -> 2_500_000
            gap             : 2_500_000 * RAD,
            // Autoline ttl  -> 1 day
            ttl             : 86_400 seconds,
            // Spark Proxy   -> 0x3300f198988e4C9C63F75dF86De36421f06af8c4
            allocatorProxy  : SPARK_PROXY,
            // Ilk Registry  -> 0x5a464c28d19848f44199d003bef5ecc87d090f87
            ilkRegistry     : ILK_REGISTRY
        });

        // Init allocator shared contracts
        AllocatorInit.initShared(dss, allocatorSharedInstance);

        // Init allocator system for ALLOCATOR-SPARK-A ilk
        AllocatorInit.initIlk(dss, allocatorSharedInstance, allocatorIlkInstance, allocatorIlkCfg);


        // ---------- Whitelist Spark ALM Proxy on the PSM ----------
        // Forum: TODO
        DssLitePsmLike(LITE_PSM).kiss(SPARK_PROXY);


        // ---------- Add new validators for Median (Medianizer) ----------
        // Forum: TODO

        address[] memory validators = new address[](4);
        validators[0] = ETH_GLOBAL_VALIDATOR;
        validators[1] = MANTLE_VALIDATOR;
        validators[2] = NETHERMIND_VALIDATOR;
        validators[3] = EULER_VALIDATOR;

        MedianLike(BTC_USD_MEDIAN).lift(validators);
        MedianLike(ETH_USD_MEDIAN).lift(validators);
        MedianLike(WSTETH_USD_MEDIAN).lift(validators);
        MedianLike(MKR_USD_MEDIAN).lift(validators);


        // ---------- Set up Governance Facilitator Streams ----------
        // Forum: TODO


        // ---------- September 2024 AD compensation ----------
        // Forum: TODO


        // ---------- Chainlog bump ----------
        // Note: we need to increase chainlog version as D3MInit.initCommon added new keys
        DssExecLib.setChangelogVersion("1.19.3");


        // ---------- Chainlog bump ----------

        // Note: we have to patch chainlog version as new collateral is added
        DssExecLib.setChangelogVersion("1.19.3");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
