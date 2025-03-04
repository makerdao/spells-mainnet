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
import { AllocatorSharedInstance, AllocatorIlkInstance } from "./dependencies/dss-allocator/AllocatorInstances.sol";
import { AllocatorInit, AllocatorIlkConfig } from "./dependencies/dss-allocator/AllocatorInit.sol";
import { GemAbstract } from "dss-interfaces/ERC/GemAbstract.sol";

interface AllocatorBufferLike {
    function approve(address asset, address spender, uint256 amount) external;
}

interface AllocatorRolesLike {
    function setUserRole(bytes32 ilk, address who, uint8 role, bool enabled) external;
}

interface ChainlogLike {
    function removeAddress(bytes32) external;
}

interface DaiUsdsLike {
    function daiToUsds(address usr, uint256 wad) external;
}

interface LineMomLike {
    function addIlk(bytes32 ilk) external;
}

interface MkrSkyLike {
    function mkrToSky(address usr, uint256 wad) external;
    function rate() external view returns (uint256);
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

interface StakingRewardsLike {
    function setRewardsDuration(uint256) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description = "2025-03-06 MakerDAO Executive Spell | Hash: TODO";

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
    uint256 internal constant THREE_PT_SEVEN_FOUR_PCT_RATE = 1000000001164306917698440949;
    uint256 internal constant FIVE_PT_FIVE_PCT_RATE        = 1000000001697766583380253701;

    // --- Math ---
    uint256 internal constant WAD = 10 ** 18;
    uint256 internal constant RAY = 10 ** 27;
    uint256 internal constant RAD = 10 ** 45;

    // ---------- Contracts ----------
    GemAbstract internal immutable DAI                    = GemAbstract(DssExecLib.dai());
    GemAbstract internal immutable MKR                    = GemAbstract(DssExecLib.mkr());
    GemAbstract internal immutable SKY                    = GemAbstract(DssExecLib.getChangelogAddress("SKY"));
    address internal immutable ALLOCATOR_ROLES            = DssExecLib.getChangelogAddress("ALLOCATOR_ROLES");
    address internal immutable ALLOCATOR_REGISTRY         = DssExecLib.getChangelogAddress("ALLOCATOR_REGISTRY");
    address internal immutable DAI_USDS                   = DssExecLib.getChangelogAddress("DAI_USDS");
    address internal immutable ILK_REGISTRY               = DssExecLib.getChangelogAddress("ILK_REGISTRY");
    address internal immutable LINE_MOM                   = DssExecLib.getChangelogAddress("LINE_MOM");
    address internal immutable MCD_PAUSE_PROXY            = DssExecLib.getChangelogAddress("MCD_PAUSE_PROXY");
    address internal immutable MCD_SPLIT                  = DssExecLib.getChangelogAddress("MCD_SPLIT");
    address internal immutable MKR_SKY                    = DssExecLib.getChangelogAddress("MKR_SKY");
    address internal immutable PIP_ALLOCATOR              = DssExecLib.getChangelogAddress("PIP_ALLOCATOR_SPARK_A");
    address internal immutable REWARDS_LSMKR_USDS         = DssExecLib.getChangelogAddress("REWARDS_LSMKR_USDS");
    address internal immutable USDS                       = DssExecLib.getChangelogAddress("USDS");
    address internal constant  ALLOCATOR_NOVA_A_VAULT     = 0xe4470DD3158F7A905cDeA07260551F72d4bB0e77;
    address internal constant  ALLOCATOR_NOVA_A_BUFFER    = 0x065E5De3D3A08c9d14BF79Ce5A6d3D0E8794640c;
    address internal constant  ALLOCATOR_NOVA_A_OPERATOR  = 0x0f72935f6de6C54Ce8056FD040d4Ddb012B7cd54;
    address internal immutable MCD_BLOW2                  = 0x81EFc7Dd25241acd8E5620F177E42F4857A02B79;

    // ---------- Wallets ----------
    address internal constant INTEGRATION_BOOST_INITIATIVE = 0xD6891d1DFFDA6B0B1aF3524018a1eE2E608785F7;
    address internal constant LAUNCH_PROJECT_FUNDING       = 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F;

    // ---------- Constant Values ----------
    uint256 internal immutable MKR_SKY_RATE = MkrSkyLike(DssExecLib.getChangelogAddress("MKR_SKY")).rate();

    // ---------- Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0xBeA5FA2bFC4F6a0b6060Eb8EC23F25db8259cEE0;

    function actions() public override {
        // ---------- Init Nova Allocator Instance ----------
        // Forum: https://forum.sky.money/t/technical-scope-of-the-nova-allocator-instance/26031
        // Forum: https://forum.sky.money/t/technical-scope-of-the-nova-allocator-instance/26031/4

        // Rename chainlog key PIP_ALLOCATOR_SPARK_A into PIP_ALLOCATOR
        // Note: Renaming is done by deleting the old key and adding the new one with the same address
        ChainlogLike(DssExecLib.LOG).removeAddress("PIP_ALLOCATOR_SPARK_A");
        DssExecLib.setChangelogAddress("PIP_ALLOCATOR", PIP_ALLOCATOR);

        // Init new Allocator instance by calling AllocatorInit.initIlk with:
        // Note: Set sharedInstance with the following parameters:
        AllocatorSharedInstance memory allocatorSharedInstance = AllocatorSharedInstance({
            // sharedInstance.oracle:  PIP_ALLOCATOR from chainlog
            oracle:   PIP_ALLOCATOR,
            // sharedInstance.roles: ALLOCATOR_ROLES from chainlog
            roles:    ALLOCATOR_ROLES,
            // sharedInstance.registry: ALLOCATOR_REGISTRY from chainlog
            registry: ALLOCATOR_REGISTRY
        });

        // Note: Set ilkInstance with the following parameters:
        AllocatorIlkInstance memory allocatorIlkInstance = AllocatorIlkInstance({
            // ilkInstance.owner: MCD_PAUSE_PROXY from chainlog
            owner:  MCD_PAUSE_PROXY,
            // ilkInstance.vault: 0xe4470DD3158F7A905cDeA07260551F72d4bB0e77
            vault:  ALLOCATOR_NOVA_A_VAULT,
            // ilkInstance.buffer: 0x065E5De3D3A08c9d14BF79Ce5A6d3D0E8794640c
            buffer: ALLOCATOR_NOVA_A_BUFFER
        });

        // Note: Set cfg with the following parameters:
        AllocatorIlkConfig memory allocatorIlkCfg = AllocatorIlkConfig({
            // cfg.ilk: ALLOCATOR-NOVA-A
            ilk             : "ALLOCATOR-NOVA-A",
            // cfg.duty: 0
            duty            : RAY,
            // cfg.gap: 1 million
            maxLine         : 1_000_000 * RAD,
            // cfg.maxLine: 60 million
            gap             : 60_000_000 * RAD,
            // cfg.ttl: 20 hours
            ttl             : 72_000 seconds,
            // cfg.allocatorProxy: MCD_PAUSE_PROXY from chainlog
            allocatorProxy  : MCD_PAUSE_PROXY,
            // cfg.ilkRegistry: ILK_REGISTRY from chainlog
            ilkRegistry     : ILK_REGISTRY
        });

        // Note: We also need dss as an input parameter for initIlk
        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);

        // Note: Now we can execute the initial instruction with all the relevant parameters by calling AllocatorInit.initIlk
        AllocatorInit.initIlk(dss, allocatorSharedInstance, allocatorIlkInstance, allocatorIlkCfg);

        // Remove newly created PIP_ALLOCATOR_NOVA_A from chainlog
        // Note: PIP_ALLOCATOR_NOVA_A was added to the chainlog when calling AllocatorInit.initIlk above
        ChainlogLike(DssExecLib.LOG).removeAddress("PIP_ALLOCATOR_NOVA_A");

        // Approve Operator to transfer USDS out of the AllocatorBuffer with:
        // address asset: USDS from chainlog
        // address spender: 0x0f72935f6de6C54Ce8056FD040d4Ddb012B7cd54
        // uint256 amount: type(uint256).max
        AllocatorBufferLike(ALLOCATOR_NOVA_A_BUFFER).approve(USDS, ALLOCATOR_NOVA_A_OPERATOR, type(uint256).max);

        // Allow Operator to call “draw” and “wipe” functions using ALLOCATOR_ROLES, with:
        // bytes32 ilk: ALLOCATOR-NOVA-A
        // address who: 0x0f72935f6de6C54Ce8056FD040d4Ddb012B7cd54
        // uint8 role: 0
        // bool enabled: true
        AllocatorRolesLike(ALLOCATOR_ROLES).setUserRole("ALLOCATOR-NOVA-A", ALLOCATOR_NOVA_A_OPERATOR, 0, true);

        // Add ALLOCATOR-NOVA-A ilk to the LINE_MOM
        LineMomLike(LINE_MOM).addIlk("ALLOCATOR-NOVA-A");

        // ---------- Smart Burn Engine Parameter Update ----------
        // Forum: https://forum.sky.money/t/smart-burn-engine-parameter-update-march-6-spell/26055
        // Forum: https://forum.sky.money/t/smart-burn-engine-parameter-update-march-6-spell/26055/5

        // Increase hop for 1284 seconds, from 876 seconds to 2160 seconds
        DssExecLib.setValue(MCD_SPLIT, "hop", 2_160);

        // Note: Update farm rewards duration
        StakingRewardsLike(REWARDS_LSMKR_USDS).setRewardsDuration(2_160);

        // ---------- Rates Changes ----------
        // Forum: https://forum.sky.money/t/march-6-2025-stability-scope-parameter-changes-23/26078
        // Forum: https://forum.sky.money/t/march-6-2025-stability-scope-parameter-changes-23/26078/2

        // Increase ALLOCATOR-SPARK-A Stability Fee by 0.52 percentage points from 3.22% to 3.74%
        DssExecLib.setIlkStabilityFee("ALLOCATOR-SPARK-A", THREE_PT_SEVEN_FOUR_PCT_RATE, /* doDrip = */ true);

        // Increase DSR by 0.75 percentage points from 4.75% to 5.50%
        DssExecLib.setDSR(FIVE_PT_FIVE_PCT_RATE, /* doDrip = */ true);

        // ---------- Launch Project Funding ----------
        // Forum: https://forum.sky.money/t/utilization-of-the-launch-project-under-the-accessibility-scope/21468/29
        // Atlas: https://sky-atlas.powerhouse.io/A.5.6_Launch_Project/1f433d9d-7cdb-406f-b7e8-f9bc4855eb77%7C8d5a

        // Transfer 5,000,000 USDS to 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        _transferUsds(LAUNCH_PROJECT_FUNDING, 5_000_000 * WAD);

        // Transfer 9,600,000 SKY to 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        _transferSky(LAUNCH_PROJECT_FUNDING, 9_600_000 * WAD);

        // ---------- Top-up of the Integration Boost ----------
        // Forum: https://forum.sky.money/t/utilization-of-the-integration-boost-budget-a-5-2-1-2/25536/7
        // Atlas: https://sky-atlas.powerhouse.io/A.5.2.1.2_Integration_Boost/129f2ff0-8d73-8057-850b-d32304e9c91a%7C8d5a9e88cf49

        // Integration Boost - 3,000,000 USDS - 0xD6891d1DFFDA6B0B1aF3524018a1eE2E608785F7
        _transferUsds(INTEGRATION_BOOST_INITIATIVE, 3_000_000 * WAD);

        // ---------- Add DssBlow2 to the Chainlog ----------
        // Forum: https://forum.sky.money/t/proposed-housekeeping-item-upcoming-executive-spell-2025-03-06/26063
        // Forum: https://forum.sky.money/t/proposed-housekeeping-item-upcoming-executive-spell-2025-03-06/26063/2

        // Add DssBlow2 to the Chainlog as `MCD_BLOW2` at 0x81EFc7Dd25241acd8E5620F177E42F4857A02B79
        DssExecLib.setChangelogAddress("MCD_BLOW2", MCD_BLOW2);

        // ---------- Spark Proxy Spell ----------
        // Forum: https://forum.sky.money/t/march-6-2025-proposed-changes-to-spark-for-upcoming-spell/26036
        // Poll: https://vote.makerdao.com/polling/QmQrGdQz
        // Poll: https://vote.makerdao.com/polling/QmfM4SBB
        // Poll: https://vote.makerdao.com/polling/QmbDzZ3F

        // Trigger Spark Proxy Spell at 0xBeA5FA2bFC4F6a0b6060Eb8EC23F25db8259cEE0
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));

        // ---------- Chainlog bump ----------

        // Note: Bump chainlog patch version as new keys are being added
        DssExecLib.setChangelogVersion("1.19.7");
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
