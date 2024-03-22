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
import { D3MInit, D3MCommonConfig, D3M4626PoolConfig, D3MOperatorPlanConfig } from "src/dependencies/dss-direct-deposit/D3MInit.sol";
import { D3MInstance } from "src/dependencies/dss-direct-deposit/D3MInstance.sol";

interface RwaOutputConduitLike {
    function kiss(address) external;
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget TODO -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-03-26 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // Note: by the previous convention it should be a comma-separated list of DAO resolutions IPFS hashes
    string public constant dao_resolutions = "Qmf8Nv4HnTFNDwRgcLzRgBdtVsVVfKY2FppaBimLK9XhxB,QmStrc9kMCmgzh2EVunjJkPsJLhsVRYyrNFBXBbJAJMrrf";

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
    uint256 internal constant THIRTEEN_PCT_RATE               = 1000000003875495717943815211;
    uint256 internal constant THIRTEEN_PT_TWO_FIVE_PCT_RATE   = 1000000003945572635100236468;
    uint256 internal constant THIRTEEN_PT_SEVEN_FIVE_PCT_RATE = 1000000004085263575156219812;
    uint256 internal constant FOURTEEN_PCT_RATE               = 1000000004154878953532704765;
    uint256 internal constant FOURTEEN_PT_TWO_FIVE_PCT_RATE   = 1000000004224341833701283597;
    uint256 internal constant FOURTEEN_PT_FIVE_PCT_RATE       = 1000000004293652882321576158;
    uint256 internal constant FOURTEEN_PT_SEVEN_FIVE_PCT_RATE = 1000000004362812761691191350;
    uint256 internal constant FIFTEEN_PT_TWO_FIVE_PCT_RATE    = 1000000004500681640286189459;

    // ---------- Math ----------
    uint256 internal constant THOUSAND = 10 ** 3;
    uint256 internal constant MILLION  = 10 ** 6;
    uint256 internal constant RAD      = 10 ** 45;

    // ---------- Addesses ----------
    address internal immutable MCD_VOW                 = DssExecLib.vow();
    address internal immutable MCD_FLAP                = DssExecLib.flap();

    address internal immutable D3M_HUB                 = DssExecLib.getChangelogAddress("DIRECT_HUB");
    address internal immutable D3M_MOM                 = DssExecLib.getChangelogAddress("DIRECT_MOM");
    address internal constant MORPHO_D3M_PLAN          = 0x374b5f915aaED790CBdd341E6f406910d648fD39;
    address internal constant MORPHO_D3M_POOL          = 0x9C259F14E5d9F35A0434cD3C4abbbcaA2f1f7f7E;
    address internal constant MORPHO_D3M_ORACLE        = 0xA5AA14DEE8c8204e424A55776E53bfff413b02Af;
    address internal constant MORPHO_D3M_OPERATOR      = address(0); // TODO: add actual operator address
    address internal constant SPARK_MORPHO_VAULT       = 0x73e65DBD630f90604062f6E02fAb9138e713edD9;

    address internal immutable RWA015_A_OUTPUT_CONDUIT = DssExecLib.getChangelogAddress("RWA015_A_OUTPUT_CONDUIT");
    address internal constant RWA015_A_CUSTODY_TACO    = 0x6759610547a36E9597Ef452aa0B9cace91291a2f;

    address internal constant SPARK_PROXY              = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL              = 0x210DF2e1764Eb5491d41A62E296Ea39Ab56F9B6d;

    function actions() public override {
        // ---------- Stability Fee Updates ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-11-under-sta-article-3-3/23910

        // ETH-A: Decrease the Stability Fee by 2 percentage points from 15.25% to 13.25%
        DssExecLib.setIlkStabilityFee("ETH-A", THIRTEEN_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // ETH-B: Decrease the Stability Fee by 2 percentage points from 15.75% to 13.75%
        DssExecLib.setIlkStabilityFee("ETH-B", THIRTEEN_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // ETH-C: Decrease the Stability Fee by 2 percentage points from 15.00% to 13.00%
        DssExecLib.setIlkStabilityFee("ETH-C", THIRTEEN_PCT_RATE, /* doDrip = */ true);

        // WSTETH-A: Decrease the Stability Fee by 2 percentage points from 16.25% to 14.25%
        DssExecLib.setIlkStabilityFee("WSTETH-A", FOURTEEN_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // WSTETH-B: Decrease the Stability Fee by 2 percentage points from 16.00% to 14.00%
        DssExecLib.setIlkStabilityFee("WSTETH-B", FOURTEEN_PCT_RATE, /* doDrip = */ true);

        // WBTC-A: Decrease the Stability Fee by 2 percentage points from 16.75% to 14.75%
        DssExecLib.setIlkStabilityFee("WBTC-A", FOURTEEN_PT_SEVEN_FIVE_PCT_RATE, /* doDrip = */ true);

        // WBTC-B: Decrease the Stability Fee by 2 percentage points from 17.25% to 15.25%
        DssExecLib.setIlkStabilityFee("WBTC-B", FIFTEEN_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // WBTC-C: Decrease the Stability Fee by 2 percentage points from 16.50% to 14.50%
        DssExecLib.setIlkStabilityFee("WBTC-C", FOURTEEN_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // ---------- SparkLend D3M update ----------
        // Forum: https://forum.makerdao.com/t/mar-6-2024-proposed-changes-to-sparklend-for-upcoming-spell/23791/

        // Increase the SparkLend D3M Maximum Debt Ceiling by 1.0 billion DAI from 1.5 billion DAI to 2.5 billion DAI.
        DssExecLib.setIlkAutoLineDebtCeiling("DIRECT-SPARK-DAI", 2_500 * MILLION);

        // ---------- Morpho D3M setup ----------
        // Forum: https://forum.makerdao.com/t/introduction-and-initial-parameters-for-ddm-overcollateralized-spark-metamorpho-ethena-vault/23925

        // Deploy DDM to Spark DAI Morpho Vault at 0x73e65DBD630f90604062f6E02fAb9138e713edD9
        // D3M DC-IAM Parameters:
        // line: 100 million DAI
        // gap: 100 million DAI
        // ttl: 24 hours
        // D3M Addresses:
        // oracle: 0xA5AA14DEE8c8204e424A55776E53bfff413b02Af
        // plan: 0x374b5f915aaED790CBdd341E6f406910d648fD39
        // pool: 0x9C259F14E5d9F35A0434cD3C4abbbcaA2f1f7f7E

        // Note: The following dependencies are copied from the original repository at
        // https://github.com/makerdao/dss-direct-deposit/tree/13916d8f7c0b88ca094ab6a31c1261ce27b98a7c/src/deploy
        // TODO: update commit hash when the PR is merged

        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);
        D3MInstance memory d3m = D3MInstance({
            plan:   MORPHO_D3M_PLAN,
            pool:   MORPHO_D3M_POOL,
            oracle: MORPHO_D3M_ORACLE
        });
        D3MCommonConfig memory cfg = D3MCommonConfig({
            hub:         D3M_HUB,
            mom:         D3M_MOM,
            ilk:         "DIRECT-SPARK-MORPHO-DAI",
            existingIlk: false,
            maxLine:     100 * MILLION * RAD, // Set line to 100 million DAI
            gap:         100 * MILLION * RAD, // Set gap to 100 million DAI
            ttl:         24 hours,            // Set ttl to 24 hours
            tau:         7 days               // TODO: update tau value to the one provided by the governance
        });
        D3M4626PoolConfig memory erc4626Cfg = D3M4626PoolConfig({
            vault: SPARK_MORPHO_VAULT
        });
        D3MOperatorPlanConfig memory operatorCfg = D3MOperatorPlanConfig({
            operator: MORPHO_D3M_OPERATOR
        });
        D3MInit.initCommon({
            dss:     dss,
            d3m:     d3m,
            cfg:     cfg
        });
        D3MInit.init4626Pool(
            dss,
            d3m,
            cfg,
            erc4626Cfg
        );
        D3MInit.initOperatorPlan(
            d3m,
            operatorCfg
        );

        // Additional actions:
        // Expand DIRECT_MOM breaker to also include Morpho D3M
        // Note: this is already done within D3MInit.sol line 209

        // ---------- DSR Change ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-11-under-sta-article-3-3/23910

        // DSR: Decrease the Dai Savings Rate by 2 percentage points from 15.00% to 13.00%
        DssExecLib.setDSR(THIRTEEN_PCT_RATE, /* doDrip = */ true);

        // ---------- SBE Parameter Updates ----------
        // Forum: https://forum.makerdao.com/t/smart-burn-engine-the-rate-of-mkr-accumulation-reconfiguration-and-transaction-analysis-parameter-reconfiguration-update-6/23888

        // Decrease the hop parameter for 7,884 seconds from 19,710 seconds to 11,826 seconds.
        DssExecLib.setValue(MCD_FLAP, "hop", 11_826);

        // Increase the bump parameter for 25,000 DAI from 50,000 DAI to 75,000 DAI.
        DssExecLib.setValue(MCD_VOW, "bump", 75 * THOUSAND * RAD);

        // ---------- Approve TACO Dao Resolution ----------
        // Forum: https://forum.makerdao.com/t/project-ethena-proposal-enacting-dao-resolutions/23923

        // Approve TACO Dao Resolution with IPFS hash Qmf8Nv4HnTFNDwRgcLzRgBdtVsVVfKY2FppaBimLK9XhxB
        // Note: see `dao_resolutions` variable declared above

        // kiss 0x6759610547a36E9597Ef452aa0B9cace91291a2f address in the RWA015-A output conduit
        RwaOutputConduitLike(RWA015_A_OUTPUT_CONDUIT).kiss(RWA015_A_CUSTODY_TACO);

        // ---------- Approve HVBank (RWA009-A) Dao Resolution ----------
        // Forum: https://forum.makerdao.com/t/huntingdon-valley-bank-transaction-documents-on-permaweb/16264/24

        // Approve HVBank (RWA009-A) Dao Resolution with IPFS hash QmStrc9kMCmgzh2EVunjJkPsJLhsVRYyrNFBXBbJAJMrrf
        // Note: see `dao_resolutions` variable declared above

        // ---------- Spark Proxy Spell ----------
        // Forum: https://forum.makerdao.com/t/mar-6-2024-proposed-changes-to-sparklend-for-upcoming-spell/23791/

        // Trigger Spark Proxy Spell at 0x210DF2e1764Eb5491d41A62E296Ea39Ab56F9B6d
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));

        // ---------- Chainlog bump ----------
        // Note: we need to increase chainlog version as D3MInit.initCommon added new keys
        DssExecLib.setChangelogVersion("1.17.3");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
