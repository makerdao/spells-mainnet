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

import { VatAbstract } from "dss-interfaces/dss/VatAbstract.sol";
import { GemAbstract } from "dss-interfaces/ERC/GemAbstract.sol";
import { VestAbstract } from "dss-interfaces/dss/VestAbstract.sol";
import { DssInstance, MCD } from "dss-test/MCD.sol";

import { SPBEAMInit, SPBEAMConfig, SPBEAMRateConfig } from "./dependencies/sp-beam/SPBEAMInit.sol";
import { SPBEAMInstance } from "./dependencies/sp-beam/SPBEAMInstance.sol";


interface DaiUsdsLike {
    function daiToUsds(address usr, uint256 wad) external;
}

interface MkrSkyLike {
    function mkrToSky(address usr, uint256 wad) external;
    function rate() external view returns (uint256);
}

interface StakingRewardsLike {
    function setRewardsDuration(uint256) external;
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

interface VestedRewardsDistributionLike {
    function distribute() external returns (uint256 amount);
    function file(bytes32 what, uint256 data) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description = "2025-04-17 MakerDAO Executive Spell | Hash: TODO";

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
    uint256 internal constant WAD = 10 ** 18;

    // ---------- Contracts ----------
    GemAbstract internal immutable DAI                  = GemAbstract(DssExecLib.dai());
    GemAbstract internal immutable MKR                  = GemAbstract(DssExecLib.mkr());
    GemAbstract internal immutable SKY                  = GemAbstract(DssExecLib.getChangelogAddress("SKY"));
    address internal immutable MCD_VAT                  = DssExecLib.vat();
    address internal immutable MCD_SPLIT                = DssExecLib.getChangelogAddress("MCD_SPLIT");
    address internal immutable DAI_USDS                 = DssExecLib.getChangelogAddress("DAI_USDS");
    address internal immutable MKR_SKY                  = DssExecLib.getChangelogAddress("MKR_SKY");
    address internal immutable REWARDS_LSMKR_USDS       = DssExecLib.getChangelogAddress("REWARDS_LSMKR_USDS");
    address internal immutable MCD_VEST_SKY             = DssExecLib.getChangelogAddress("MCD_VEST_SKY");
    address internal immutable REWARDS_DIST_USDS_SKY    = DssExecLib.getChangelogAddress("REWARDS_DIST_USDS_SKY");

    address internal constant MCD_SPBEAM = 0x36B072ed8AFE665E3Aa6DaBa79Decbec63752b22;
    address internal constant SPBEAM_MOM = 0xf0C6e6Ec8B367cC483A411e595D3Ba0a816d37D0;
    address internal constant SPBEAM_BUD = 0xe1c6f81D0c3CD570A77813b81AA064c5fff80309;

    // ---------- Wallets ----------
    address internal constant LAUNCH_PROJECT_FUNDING    = 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F;
    address internal constant AAVE_V3_TREASURY          = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;
    address internal constant BLUE                      = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;
    address internal constant BONAPUBLICA               = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant CLOAKY_2                  = 0x9244F47D70587Fa2329B89B6f503022b63Ad54A5;
    address internal constant JULIACHANG                = 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7;
    address internal constant WBC                       = 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47;
    address internal constant PBG                       = 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2;
    address internal constant BYTERON                   = 0xc2982e72D060cab2387Dba96b846acb8c96EfF66;
    address internal constant CLOAKY_ENNOIA             = 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b;
    address internal constant CLOAKY_KOHLA_2            = 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a;

    // ---------- Constant Values ----------
    uint256 internal immutable MKR_SKY_RATE = MkrSkyLike(DssExecLib.getChangelogAddress("MKR_SKY")).rate();

    // ---------- Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = address(0xA8FF99Ac98Fc0C3322F639a9591257518514455c);

    function actions() public override {

        // ---------- SP BEAM Initialization ----------
        // Forum: https://forum.sky.money/t/technical-scope-sp-beam-initialization-spell/26266
        // Forum: https://forum.sky.money/t/atlas-edit-weekly-cycle-proposal-week-of-april-14-2025/26262/2
        // Poll: https://vote.makerdao.com/polling/QmWc4toZ

        // Init SP BEAM by calling SPBEAMInit.init with the following parameters:
        // Note: Create SPBEAMInstance with the following parameters:
        SPBEAMInstance memory spbeamInstance = SPBEAMInstance({
            // inst.spbeam: 0x36B072ed8AFE665E3Aa6DaBa79Decbec63752b22
            spbeam: MCD_SPBEAM,
            // inst.mom: 0xf0C6e6Ec8B367cC483A411e595D3Ba0a816d37D0
            mom: SPBEAM_MOM
        });

        // Note: Create SPBEAMRateConfig array to include all 14 requested ilks
        SPBEAMRateConfig[] memory spbeamIlkConfigs = new SPBEAMRateConfig[](14);

        // For the following cfg.ilks.id:
        // ETH-A, ETH-B, ETH-C, WSTETH-A, WSTETH-B, WBTC-A, WBTC-B, WBTC-C, SSR
        // cfg.ilks.min: 200 basis points
        // cfg.ilks.max: 3,000 basis points
        // cfg.ilks.step: 400 basis points
        // Note: This is done in the following steps

        // Note: Add config for ETH-A to ilk configs array
        spbeamIlkConfigs[0] = SPBEAMRateConfig({
            id: "ETH-A",
            min: 200,
            max: 3_000,
            step: 400
        });

        // Note: Add config for ETH-B to ilk configs array
        spbeamIlkConfigs[1] = SPBEAMRateConfig({
            id: "ETH-B",
            min: 200,
            max: 3_000,
            step: 400
        });

        // Note: Add config for ETH-C to ilk configs array
        spbeamIlkConfigs[2] = SPBEAMRateConfig({
            id: "ETH-C",
            min: 200,
            max: 3_000,
            step: 400
        });

        // Note: Add config for WSTETH-A to ilk configs array
        spbeamIlkConfigs[3] = SPBEAMRateConfig({
            id: "WSTETH-A",
            min: 200,
            max: 3_000,
            step: 400
        });

        // Note: Add config for WSTETH-B to ilk configs array
        spbeamIlkConfigs[4] = SPBEAMRateConfig({
            id: "WSTETH-B",
            min: 200,
            max: 3_000,
            step: 400
        });

        // Note: Add config for WBTC-A to ilk configs array
        spbeamIlkConfigs[5] = SPBEAMRateConfig({
            id: "WBTC-A",
            min: 200,
            max: 3_000,
            step: 400
        });

        // Note: Add config for WBTC-B to ilk configs array
        spbeamIlkConfigs[6] = SPBEAMRateConfig({
            id: "WBTC-B",
            min: 200,
            max: 3_000,
            step: 400
        });

        // Note: Add config for WBTC-C to ilk configs array
        spbeamIlkConfigs[7] = SPBEAMRateConfig({
            id: "WBTC-C",
            min: 200,
            max: 3_000,
            step: 400
        });

        // Note: Add config for SSR to ilk configs array
        spbeamIlkConfigs[8] = SPBEAMRateConfig({
            id: "SSR",
            min: 200,
            max: 3_000,
            step: 400
        });

        // Note: Add config for ETH-A to ilk configs array
        spbeamIlkConfigs[9] = SPBEAMRateConfig({
            id: "ETH-A",
            min: 200,
            max: 3_000,
            step: 400
        });

        // For the following cfg.ilks.id: ALLOCATOR-SPARK-A, ALLOCATOR-NOVA-A, ALLOCATOR-BLOOM-A, DSR
        // cfg.ilks.min: 0 basis points
        // cfg.ilks.max: 3,000 basis points
        // cfg.ilks.step: 400 basis points
        // Note: This is done in the following steps

        // Note: Add config for ALLOCATOR-SPARK-A to ilk configs array
        spbeamIlkConfigs[10] = SPBEAMRateConfig({
            id: "ALLOCATOR-SPARK-A",
            min: 0,
            max: 3_000,
            step: 400
        });

        // Note: Add config for ALLOCATOR-NOVA-A to ilk configs array
        spbeamIlkConfigs[11] = SPBEAMRateConfig({
            id: "ALLOCATOR-NOVA-A",
            min: 0,
            max: 3_000,
            step: 400
        });

        // Note: Add config for ALLOCATOR-BLOOM-A to ilk configs array
        spbeamIlkConfigs[12] = SPBEAMRateConfig({
            id: "ALLOCATOR-BLOOM-A",
            min: 0,
            max: 3_000,
            step: 400
        });

        // Note: Add config for DSR to ilk configs array
        spbeamIlkConfigs[13] = SPBEAMRateConfig({
            id: "DSR",
            min: 0,
            max: 3_000,
            step: 400
        });

        // Note: Create SPBEAMConfig with the following parameters:
        SPBEAMConfig memory spbeamConfig = SPBEAMConfig({
            // cfg.tau: 57,600 seconds
            tau: 57_600,
            // Note: Use the SPBEAMRateConfig array created above
            ilks: spbeamIlkConfigs,
            // cfg.bud: 0xe1c6f81D0c3CD570A77813b81AA064c5fff80309
            bud: SPBEAM_BUD
        });

        // Note: We also need dss as an input parameter for SPBEAMInit.init
        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);

        // Note: Now we can call SPBEAMInit.init with the instance and config created above
        SPBEAMInit.init(dss, spbeamInstance, spbeamConfig);

        // Add SPBEAM to the Chainlog as `MCD_SPBEAM` at 0x36B072ed8AFE665E3Aa6DaBa79Decbec63752b22
        DssExecLib.setChangelogAddress("MCD_SPBEAM", MCD_SPBEAM);

        // Add SPBEAMMom to the Chainlog as `SPBEAM_MOM` at 0xf0C6e6Ec8B367cC483A411e595D3Ba0a816d37D0
        DssExecLib.setChangelogAddress("SPBEAM_MOM", SPBEAM_MOM);

        // Note: bump Chainlog version as multiple keys are being added
        DssExecLib.setChangelogVersion("1.19.9");

        // ---------- Sky Token Rewards rebalance ----------
        // Forum: https://forum.sky.money/t/sky-token-rewards-update-april-17-spell/26254

        // Yank MCD_VEST_SKY vest with ID 1
        VestAbstract(MCD_VEST_SKY).yank(1);

        // VestedRewardsDistribution.distribute()
        VestedRewardsDistributionLike(REWARDS_DIST_USDS_SKY).distribute();

        // Note: Set the Rewards Distribution Cap first
        VestAbstract(MCD_VEST_SKY).file("cap", 176_000_000 * WAD);

        // Create a new MCD_VEST_SKY stream:
        VestAbstract(MCD_VEST_SKY).create(
            // Note: Set User to Vested Rewards Distribution Contract
            REWARDS_DIST_USDS_SKY,
            // Rewards Distribution: 160,000,000
            160_000_000 * WAD,
            // Rewards Distribution Cap: 176,000,000
            // Note: This is done in the step above
            // bgn: block.timestamp
            block.timestamp,
            // fin: block.timestamp + 182 days
            (block.timestamp + 182 days) - block.timestamp,
            0,
            address(0)
        );

        // res: 1 (restricted)
        VestAbstract(MCD_VEST_SKY).restrict(streamId);

        // MCD_VEST_SKY Vest Stream  | from 'block.timestamp' to 'block.timestamp + 15,724,800 seconds' | 160M * WAD SKY | 0x2F0C88e935Db5A60DDA73b0B4EAEef55883896d9
        // Note: This is done above

        // File the new stream ID on REWARDS_DIST_USDS_SKY
        VestedRewardsDistributionLike(REWARDS_DIST_USDS_SKY).file("vestId", streamId);

        // ---------- Set Aave Prime DDM DC to 0 ----------
        // Forum: https://forum.sky.money/t/spark-aave-lido-market-usds-allocation/25311/24
        // Forum: https://forum.sky.money/t/spark-aave-lido-market-usds-allocation/25311/25

        // Remove DIRECT-SPK-AAVE-LIDO-USDS from autoline
        DssExecLib.removeIlkFromAutoLine("DIRECT-SPK-AAVE-LIDO-USDS");

        // Note: In order to update the global debt ceiling, we need to fetch the current line
        (,,,uint256 line,) = VatAbstract(MCD_VAT).ilks("DIRECT-SPK-AAVE-LIDO-USDS");

        // Set DIRECT-SPK-AAVE-LIDO-USDS DC to zero
        DssExecLib.setIlkDebtCeiling("DIRECT-SPK-AAVE-LIDO-USDS", 0);

        // Note: Update global debt ceiling
        VatAbstract(MCD_VAT).file("Line", VatAbstract(MCD_VAT).Line() - line);

        // ---------- SBE Changes ----------
        // Forum: https://forum.sky.money/t/smart-burn-engine-parameter-update-april-17-spell/26253

        // Increase Splitter.hop for 493 seconds from 1,235 seconds to 1,728 seconds
        DssExecLib.setValue(MCD_SPLIT, "hop", 1_728);

        // Note: Update farm rewards duration to match Splitter.hop
        StakingRewardsLike(REWARDS_LSMKR_USDS).setRewardsDuration(1_728);

        // ---------- Launch Project Funding ----------
        // Forum: https://forum.sky.money/t/utilization-of-the-launch-project-under-the-accessibility-scope/21468/30
        // Atlas: https://sky-atlas.powerhouse.io/A.5.6_Launch_Project/1f433d9d-7cdb-406f-b7e8-f9bc4855eb77%7C8d5a

        // Transfer 5,000,000 USDS to 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        _transferUsds(LAUNCH_PROJECT_FUNDING, 5_000_000 * WAD);

        // Transfer 24,000,000 SKY to 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        _transferSky(LAUNCH_PROJECT_FUNDING, 24_000_000 * WAD);

        // ---------- Spark - Aave revenue share transfer ----------
        // Forum: https://forum.sky.money/t/spark-aave-revenue-share-calculation-payment-7-q1-2025/26219

        // AAVE Revenue Share - 256,888 DAI - 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c
        DssExecLib.sendPaymentFromSurplusBuffer(AAVE_V3_TREASURY, 256_888);

        // ---------- AD Compensation ----------
        // Forum: https://forum.sky.money/t/march-2025-aligned-delegate-compensation/26255
        // Atlas: https://sky-atlas.powerhouse.io/A.1.5.8_Budget_For_Prime_Delegate_Slots/e3e420fc-9b1f-4fdc-9983-fcebc45dd3aa%7C0db3af4ece0c

        // BLUE - 4,000 USDS - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferUsds(BLUE, 4_000 * WAD);

        // Bonapublica - 4,000 USDS - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        _transferUsds(BONAPUBLICA, 4_000 * WAD);

        // Cloaky - 4,000 USDS - 0x9244F47D70587Fa2329B89B6f503022b63Ad54A5
        _transferUsds(CLOAKY_2, 4_000 * WAD);

        // JuliaChang - 4,000 USDS - 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7
        _transferUsds(JULIACHANG, 4_000 * WAD);

        // WBC - 4,000 USDS - 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47
        _transferUsds(WBC, 4_000 * WAD);

        // PBG - 3,355 USDS - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        _transferUsds(PBG, 3_355 * WAD);

        // Byteron - 645 USDS - 0xc2982e72D060cab2387Dba96b846acb8c96EfF66
        _transferUsds(BYTERON, 645 * WAD);

        // ---------- Atlas Core Development April 2025 USDS Payments ----------
        // Forum: https://forum.sky.money/t/atlas-core-development-payment-requests-april-2025/26221

        // BLUE - 50,167 USDS - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferUsds(BLUE, 50_167 * WAD);

        // Ennoia - 20,000 USDS - 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b
        _transferUsds(CLOAKY_ENNOIA, 20_000 * WAD);

        // Cloaky - 16,417 USDS - 0x9244F47D70587Fa2329B89B6f503022b63Ad54A5
        _transferUsds(CLOAKY_2, 16_417 * WAD);

        // Kohla - 11,000 USDS - 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a
        _transferUsds(CLOAKY_KOHLA_2, 11_000 * WAD);

        // ---------- Atlas Core Development April 2025 SKY Payments ----------
        // Forum: https://forum.sky.money/t/atlas-core-development-payment-requests-april-2025/26221

        // BLUE - 330,000 SKY - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferSky(BLUE, 330_000 * WAD);

        // Cloaky - 288,000 SKY - 0x9244F47D70587Fa2329B89B6f503022b63Ad54A5
        _transferSky(CLOAKY_2, 288_000 * WAD);

        // ---------- Spark Proxy Spell ----------

        // Execute Spark Proxy spell at 0xA8FF99Ac98Fc0C3322F639a9591257518514455c
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
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
