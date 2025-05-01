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

import { GemAbstract } from "dss-interfaces/ERC/GemAbstract.sol";

interface DaiUsdsLike {
    function daiToUsds(address usr, uint256 wad) external;
}

interface MkrSkyLike {
    function mkrToSky(address usr, uint256 wad) external;
    function rate() external view returns (uint256);
}

interface PauseLike {
    function setDelay(uint256) external;
}

interface LitePsmLike {
    function kiss(address) external;
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/4ee57431afa70c85f5c643922a7cd066619f1927/governance/votes/Executive%20Vote%20-%20April%2030%2C%202025.md' -q -O - 2>/dev/null)"
    string public constant override description = "2025-04-30 MakerDAO Executive Spell | Hash: 0x5fb7937427fd3091b578b2c5a0149a679d1685081abf4eed96d7feb6785ad97e";

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
    uint256 internal constant WAD     = 10 ** 18;

    // ---------- Contracts ----------
    GemAbstract internal immutable DAI             = GemAbstract(DssExecLib.dai());
    GemAbstract internal immutable MKR             = GemAbstract(DssExecLib.mkr());
    GemAbstract internal immutable SKY             = GemAbstract(DssExecLib.getChangelogAddress("SKY"));
    address internal immutable DAI_USDS            = DssExecLib.getChangelogAddress("DAI_USDS");
    address internal immutable MKR_SKY             = DssExecLib.getChangelogAddress("MKR_SKY");
    address internal immutable MCD_PAUSE           = DssExecLib.getChangelogAddress("MCD_PAUSE");
    address internal immutable MCD_LITE_PSM_USDC_A = DssExecLib.getChangelogAddress("MCD_LITE_PSM_USDC_A");

    address internal constant ALM_PROXY        = 0x491EDFB0B8b608044e227225C715981a30F3A44E;
    address internal constant EMSP_SPBEAM_HALT = 0xDECF4A7E4b9CAa3c3751D163866941a888618Ac0;

    // ---------- Wallets ----------
    address internal constant LAUNCH_PROJECT_FUNDING       = 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F;
    address internal constant INTEGRATION_BOOST_INITIATIVE = 0xD6891d1DFFDA6B0B1aF3524018a1eE2E608785F7;

    // ---------- Constant Values ----------
    uint256 internal immutable MKR_SKY_RATE = MkrSkyLike(DssExecLib.getChangelogAddress("MKR_SKY")).rate();

    // ---------- Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0x9362B8a15ab78257b11a55F7CC272F4C4676C2fe;

    // ---------- STAR2 Proxy Spell ----------
    // Note: The deployment address for the Bloom Proxy can be found at https://forum.sky.money/t/technical-scope-of-the-star-2-allocator-launch/26190
    address internal constant BLOOM_PROXY = 0x1369f7b2b38c76B6478c0f0E66D94923421891Ba;
    address internal constant BLOOM_SPELL = 0x0c9CC5D5fF3baf096d29676039BD6fB94586111A;

    function actions() public override {
        // ---------- STAR2 Allocation System Updates ----------
        // Forum: https://forum.sky.money/t/technical-test-of-the-star2-allocation-system/26289
        // Poll: https://vote.makerdao.com/polling/QmepaQjk#poll-detail
        // Poll: https://vote.makerdao.com/polling/QmedB3hH

        // Whitelist STAR2 ALMProxy on the LitePSM with the following call:
        // MCD_LITE_PSM_USDC_A.kiss(0x491EDFB0B8b608044e227225C715981a30F3A44E)
        LitePsmLike(MCD_LITE_PSM_USDC_A).kiss(ALM_PROXY);

        // STAR2 Auto-line Changes
        // Increase DC-IAM gap by 40 million DAI from 10 million DAI to 50 million DAI.
        // Increase DC-IAM line by 90 million DAI from 10 million DAI to 100 million DAI.
        // Note: ttl is not specified in the exec sheet so it is left unchanged i.e. 24 hours
        DssExecLib.setIlkAutoLineParameters("ALLOCATOR-BLOOM-A", /* line = */ 100 * MILLION, /* gap = */ 50 * MILLION, /* ttl = */ 24 hours);

        // ---------- Increase GSM Pause Delay ----------
        // Forum: https://forum.sky.money/t/parameter-changes-poll-april-21-2025/26290
        // Poll: https://vote.makerdao.com/polling/QmedB3hH#poll-detail

        // Increase GSM delay by 30 hours from 18 hours to 48 hours.
        PauseLike(MCD_PAUSE).setDelay(48 hours);

        // ---------- Add Emergency Spell to Chainlog ----------
        // Forum: https://forum.sky.money/t/proposed-housekeeping-item-upcoming-executive-spell-2025-04-30/26304

        // Add EMSP_SPBEAM_HALT at 0xDECF4A7E4b9CAa3c3751D163866941a888618Ac0 to the Chainlog
        DssExecLib.setChangelogAddress("EMSP_SPBEAM_HALT", EMSP_SPBEAM_HALT);

        // Note: bump Chainlog version since a new key is being added
        DssExecLib.setChangelogVersion("1.19.10");

        // ---------- Top-up of the Integration Boost ----------
        // Forum: https://forum.sky.money/t/utilization-of-the-integration-boost-budget-a-5-2-1-2/25536/10
        // Atlas: https://sky-atlas.powerhouse.io/A.AG1.2.5.P13_Integration_Boost_Primitive/1c1f2ff0-8d73-81de-9e4f-c86f07474bf2%7C7896ed3326389fe3185c6795

        // Transfer 3,000,000 USDS to 0xD6891d1DFFDA6B0B1aF3524018a1eE2E608785F7
        _transferUsds(INTEGRATION_BOOST_INITIATIVE, 3_000_000 * WAD);

        // ---------- Launch Project Funding ----------
        // Forum: https://forum.sky.money/t/utilization-of-the-launch-project-under-the-accessibility-scope/21468/37
        // Atlas: https://sky-atlas.powerhouse.io/A.5.6_Launch_Project/1f433d9d-7cdb-406f-b7e8-f9bc4855eb77%7C8d5a

        // Transfer 5,000,000 USDS to 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        _transferUsds(LAUNCH_PROJECT_FUNDING, 5_000_000 * WAD);

        // Transfer 30,000,000 SKY to 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        _transferSky(LAUNCH_PROJECT_FUNDING, 30_000_000 * WAD);

        // ---------- Spark Proxy Spell ----------
        // Forum: https://forum.sky.money/t/may-1-2025-proposed-changes-to-spark-for-upcoming-spell/26288
        // Poll: https://vote.makerdao.com/polling/QmQM99z5
        // Poll: https://vote.makerdao.com/polling/QmfJ5yDF
        // Poll: https://vote.makerdao.com/polling/QmZ2vydY
        // Poll: https://vote.makerdao.com/polling/Qmdc28Ag
        // Poll: https://vote.makerdao.com/polling/Qmee2jez
        // Poll: https://vote.makerdao.com/polling/QmeNB8S1
        // Poll: https://vote.makerdao.com/polling/QmfBmrxq

        // Execute Spark Proxy spell at 0x9362B8a15ab78257b11a55F7CC272F4C4676C2fe
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));

        // ---------- STAR2 Proxy Spell ----------
        // Forum: https://forum.sky.money/t/technical-test-of-the-star2-allocation-system/26289
        // Poll: https://vote.makerdao.com/polling/QmepaQjk

        // Execute STAR2 Proxy spell at 0x0c9CC5D5fF3baf096d29676039BD6fB94586111A
        ProxyLike(BLOOM_PROXY).exec(BLOOM_SPELL, abi.encodeWithSignature("execute()"));
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
