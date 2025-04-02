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

interface ChainlogLike {
    function removeAddress(bytes32) external;
}

interface LineMomLike {
    function addIlk(bytes32 ilk) external;
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
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/d5a63907ac05e2fa109bf1e44f2e00a6769635e1/governance/votes/Executive%20vote%20-%20April%203%2C%202025.md' -q -O - 2>/dev/null)"
    string public constant override description = "2025-04-03 MakerDAO Executive Spell | Hash: 0x472d46618b06928e248b7ff6d99a1ab343828ed8a3e7bcd8db4433c99aae777f";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
    }

    // Note: by the previous convention it should be a comma-separated list of DAO resolutions IPFS hashes
    string public constant dao_resolutions = "bafkreidmumjkch6hstk7qslyt3dlfakgb5oi7b3aab7mqj66vkds6ng2de";

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
    uint256 internal constant ZERO_PCT_RATE = 1000000000000000000000000000;

    // ---------- Math ----------
    uint256 internal constant RAD = 10 ** 45;

    // ---------- Contracts ----------
    address internal immutable MCD_PAUSE_PROXY    = DssExecLib.pauseProxy();
    address internal immutable ILK_REGISTRY       = DssExecLib.reg();
    address internal immutable PIP_ALLOCATOR      = DssExecLib.getChangelogAddress("PIP_ALLOCATOR");
    address internal immutable ALLOCATOR_ROLES    = DssExecLib.getChangelogAddress("ALLOCATOR_ROLES");
    address internal immutable ALLOCATOR_REGISTRY = DssExecLib.getChangelogAddress("ALLOCATOR_REGISTRY");
    address internal immutable LINE_MOM           = DssExecLib.getChangelogAddress("LINE_MOM");
    address internal immutable MCD_SPLIT          = DssExecLib.getChangelogAddress("MCD_SPLIT");
    address internal immutable REWARDS_LSMKR_USDS = DssExecLib.getChangelogAddress("REWARDS_LSMKR_USDS");

    address internal constant ALLOCATOR_BLOOM_A_VAULT    = 0x26512A41C8406800f21094a7a7A0f980f6e25d43;
    address internal constant ALLOCATOR_BLOOM_A_BUFFER   = 0x629aD4D779F46B8A1491D3f76f7E97Cb04D8b1Cd;
    address internal constant ALLOCATOR_BLOOM_A_SUBPROXY = 0x1369f7b2b38c76B6478c0f0E66D94923421891Ba;

    // ---------- Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0x6B34C0E12C84338f494efFbf49534745DDE2F24b;

    function actions() public override {
        // ---------- Init Star 2 Allocator Instance Step 1 ----------
        // Forum: https://forum.sky.money/t/technical-scope-of-the-star-2-allocator-launch/26190
        // Forum: https://forum.sky.money/t/technical-scope-of-the-star-2-allocator-launch/26190/3

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
            // ilkInstance.vault: 0x26512A41C8406800f21094a7a7A0f980f6e25d43
            vault:  ALLOCATOR_BLOOM_A_VAULT,
            // ilkInstance.buffer: 0x629aD4D779F46B8A1491D3f76f7E97Cb04D8b1Cd
            buffer: ALLOCATOR_BLOOM_A_BUFFER
        });

        // Note: Set cfg with the following parameters:
        AllocatorIlkConfig memory allocatorIlkCfg = AllocatorIlkConfig({
            // cfg.ilk: ALLOCATOR-BLOOM-A
            ilk:            "ALLOCATOR-BLOOM-A",
            // cfg.duty: 0%
            duty:           ZERO_PCT_RATE,
            // cfg.gap: 10 million USDS
            gap:            10_000_000  * RAD,
            // cfg.maxLine: 10 million USDS
            maxLine:        10_000_000 * RAD,
            // cfg.ttl: 86400 seconds
            ttl:            86_400,
            // cfg.allocatorProxy: 0x1369f7b2b38c76B6478c0f0E66D94923421891Ba
            allocatorProxy: ALLOCATOR_BLOOM_A_SUBPROXY,
            // cfg.ilkRegistry: ILK_REGISTRY from chainlog
            ilkRegistry:    ILK_REGISTRY
        });

        // Note: We also need dss as an input parameter for initIlk
        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);

        // Note: Now we can execute the initial instruction with all the relevant parameters by calling AllocatorInit.initIlk
        AllocatorInit.initIlk(dss, allocatorSharedInstance, allocatorIlkInstance, allocatorIlkCfg);

        // Remove newly created PIP_ALLOCATOR_BLOOM_A from the chainlog
        // Note: PIP_ALLOCATOR_BLOOM_A was added to the chainlog when calling AllocatorInit.initIlk above
        ChainlogLike(DssExecLib.LOG).removeAddress("PIP_ALLOCATOR_BLOOM_A");

        // Add ALLOCATOR-BLOOM-A to the LineMOM
        LineMomLike(LINE_MOM).addIlk("ALLOCATOR-BLOOM-A");

        // ---------- Smart Burn Engine Parameter Update ----------
        // Forum: https://forum.sky.money/t/smart-burn-engine-parameter-update-april-3-spell/26201
        // Poll: https://vote.makerdao.com/polling/Qmf3cZuM

        // Reduce Splitter.hop by 493 seconds from 1,728 seconds to 1,235 seconds
        DssExecLib.setValue(MCD_SPLIT, "hop", 1_235);

        // Note: Update farm rewards duration
        StakingRewardsLike(REWARDS_LSMKR_USDS).setRewardsDuration(1_235);

        // ---------- DAO Resolution ----------
        // Forum: https://forum.sky.money/t/spark-tokenization-grand-prix-legal-overview-of-selected-products/26154
        // Forum: https://forum.sky.money/t/spark-tokenization-grand-prix-legal-overview-of-selected-products/26154/2

        // Approve DAO Resolution with hash bafkreidmumjkch6hstk7qslyt3dlfakgb5oi7b3aab7mqj66vkds6ng2de
        // Note: see `dao_resolutions` public variable declared above

        // Note: bump Chainlog version as multiple keys are being added
        DssExecLib.setChangelogVersion("1.19.8");

        // ---------- Spark Proxy Spell ----------
        // Forum: https://forum.sky.money/t/april-3-2025-proposed-changes-to-spark-for-upcoming-spell-2/26203
        // Forum: https://forum.sky.money/t/april-3-2025-proposed-changes-to-spark-for-upcoming-spell/26155
        // Poll: https://vote.makerdao.com/polling/QmehvjH9
        // Poll: https://vote.makerdao.com/polling/QmNZVfSq
        // Poll: https://vote.makerdao.com/polling/QmSwQ6Wc
        // Poll: https://vote.makerdao.com/polling/QmSytTo4
        // Poll: https://vote.makerdao.com/polling/QmT87a3p
        // Poll: https://vote.makerdao.com/polling/QmTE29em
        // Poll: https://vote.makerdao.com/polling/QmWQCbns
        // Poll: https://vote.makerdao.com/polling/QmXAJTvs
        // Poll: https://vote.makerdao.com/polling/QmY6tE6h
        // Poll: https://vote.makerdao.com/polling/QmZGQhkG

        // Execute Spark Proxy spell at 0x6B34C0E12C84338f494efFbf49534745DDE2F24b
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
