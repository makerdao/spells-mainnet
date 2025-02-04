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
import { DaiJoinAbstract } from "dss-interfaces/dss/DaiJoinAbstract.sol";
import { VatAbstract } from "dss-interfaces/dss/VatAbstract.sol";

interface DaiUsdsLike {
    function daiToUsds(address usr, uint256 wad) external;
}

interface SUsdsLike {
    function drip() external returns (uint256);
    function file(bytes32 what, uint256 data) external;
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/718790846590c531038a3ebd58fbea9a48a0f293/governance/votes/Executive%20vote%20-%20February%206%2C%202025.md' -q -O - 2>/dev/null)"
    string public constant override description = "2025-02-06 MakerDAO Executive Spell | Hash: 0xc89ebc18cbe250c96a4a72bdbdb45cf258b6634597b119fdb1fd0969e79cf629";

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
    uint256 internal constant ONE_PT_THREE_THREE_PCT     = 1000000000418960282689704878;  //  1.33%
    uint256 internal constant SEVEN_PT_TWO_FIVE_PCT      = 1000000002219443553326580536;  //  7.25%
    uint256 internal constant EIGHT_PT_SEVEN_FIVE_PCT    = 1000000002659864411854984565;  //  8.75%
    uint256 internal constant NINE_PT_FIVE_PCT           = 1000000002877801985002875644;  //  9.50%
    uint256 internal constant NINE_PT_SEVEN_FIVE_PCT     = 1000000002950116251408586949;  //  9.75%
    uint256 internal constant TEN_PT_TWO_FIVE_PCT        = 1000000003094251918120023627;  // 10.25%
    uint256 internal constant TEN_PT_FIVE_PCT            = 1000000003166074807451009595;  // 10.50%
    uint256 internal constant TEN_PT_SEVEN_FIVE_PCT      = 1000000003237735385034516037;  // 10.75%
    uint256 internal constant FOURTEEN_PCT               = 1000000004154878953532704765;  // 14.00%
    uint256 internal constant FOURTEEN_PT_TWO_FIVE_PCT   = 1000000004224341833701283597;  // 14.25%
    uint256 internal constant FOURTEEN_PT_SEVEN_FIVE_PCT = 1000000004362812761691191350;  // 14.75%

    // ---------- Math ----------
    uint256 internal constant WAD = 10 ** 18;
    uint256 internal constant RAY = 10 ** 27;

    // ---------- Contracts ----------
    GemAbstract internal immutable DAI      = GemAbstract(DssExecLib.dai());
    GemAbstract internal immutable MKR      = GemAbstract(DssExecLib.mkr());
    address internal immutable DAI_USDS     = DssExecLib.getChangelogAddress("DAI_USDS");
    address internal immutable SUSDS        = DssExecLib.getChangelogAddress("SUSDS");
    address internal immutable MCD_JOIN_DAI = DssExecLib.daiJoin();
    address internal immutable MCD_VAT      = DssExecLib.vat();
    address internal immutable MCD_VOW      = DssExecLib.vow();

    // ---------- Wallets ----------
    address internal constant INTEGRATION_BOOST_INITIATIVE = 0xD6891d1DFFDA6B0B1aF3524018a1eE2E608785F7;
    address internal constant GFXLABS                      = 0xa6e8772af29b29B9202a073f8E36f447689BEef6;

    // ---------- Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0xD5c59b7c1DD8D2663b4c826574ed968B2C8329C0;

    function actions() public override {
        // ---------- Rate Adjustments ----------
        // Forum: https://forum.sky.money/t/feb-6-2025-stability-scope-parameter-changes-21/25906
        // Forum: https://forum.sky.money/t/feb-6-2025-stability-scope-parameter-changes-21/25906/3
        // Forum: https://forum.sky.money/t/feb-6-2025-stability-scope-parameter-changes-21/25906/4

        // Reduce ETH-A Stability Fee by 3 percentage points from 12.75% to 9.75%
        DssExecLib.setIlkStabilityFee("ETH-A", NINE_PT_SEVEN_FIVE_PCT, /* doDrip = */ true);

        // Reduce ETH-B Stability Fee by 3 percentage points from 13.25% to 10.25%
        DssExecLib.setIlkStabilityFee("ETH-B", TEN_PT_TWO_FIVE_PCT, /* doDrip = */ true);

        // Reduce ETH-C Stability Fee by 3 percentage points from 12.50% to 9.50%
        DssExecLib.setIlkStabilityFee("ETH-C", NINE_PT_FIVE_PCT, /* doDrip = */ true);

        // Reduce WSTETH-A Stability Fee by 3 percentage points from 13.75% to 10.75%
        DssExecLib.setIlkStabilityFee("WSTETH-A", TEN_PT_SEVEN_FIVE_PCT, /* doDrip = */ true);

        // Reduce WSTETH-B Stability Fee by 3 percentage points from 13.50% to 10.50%
        DssExecLib.setIlkStabilityFee("WSTETH-B", TEN_PT_FIVE_PCT, /* doDrip = */ true);

        // Reduce WBTC-A Stability Fee by 2 percentage points from 16.25% to 14.25%
        DssExecLib.setIlkStabilityFee("WBTC-A", FOURTEEN_PT_TWO_FIVE_PCT, /* doDrip = */ true);

        // Reduce WBTC-B Stability Fee by 2 percentage points from 16.75% to 14.75%
        DssExecLib.setIlkStabilityFee("WBTC-B", FOURTEEN_PT_SEVEN_FIVE_PCT, /* doDrip = */ true);

        // Reduce WBTC-C Stability Fee by 2 percentage points from 16.00% to 14.00%
        DssExecLib.setIlkStabilityFee("WBTC-C", FOURTEEN_PCT, /* doDrip = */ true);

        // Reduce ALLOCATOR-SPARK-A Stability Fee by 4.04 percentage points from 5.37% to 1.33%
        DssExecLib.setIlkStabilityFee("ALLOCATOR-SPARK-A", ONE_PT_THREE_THREE_PCT, /* doDrip = */ true);

        // Reduce DSR from 11.25% to 7.25%
        DssExecLib.setDSR(SEVEN_PT_TWO_FIVE_PCT, /* doDrip = */ true);

        // Reduce SSR from 12.50% to 8.75%
        SUsdsLike(SUSDS).drip();
        SUsdsLike(SUSDS).file("ssr", EIGHT_PT_SEVEN_FIVE_PCT);

        // ---------- Sweep Dai from PauseProxy to Surplus Buffer ----------
        // Forum: https://forum.sky.money/t/consolfreight-rwa-003-cf4-drop-default/21745/23
        // Forum: https://forum.sky.money/t/consolfreight-rwa-003-cf4-drop-default/21745/24

        // Sweep 406,451.52 Dai returned by ConsolFreight from the PauseProxy to the Surplus Buffer
        // Note: Approve the DaiJoin for the amount returned
        DAI.approve(MCD_JOIN_DAI, 406_451.52 ether);
        // Note: Join the DaiJoin for the amount returned
        DaiJoinAbstract(MCD_JOIN_DAI).join(address(this), 406_451.52 ether);
        // Note: Move 406,451.52 Dai from the PauseProxy to the Vow
        VatAbstract(MCD_VAT).move(address(this), MCD_VOW, 406_451.52 ether * RAY);

        // ---------- Integration Boost Funding ----------
        // Forum: http://forum.sky.money/t/utilization-of-the-integration-boost-budget-a-5-2-1-2/25536/5
        // Atlas: https://sky-atlas.powerhouse.io/A.5.2.1.2_Integration_Boost/129f2ff0-8d73-8057-850b-d32304e9c91a%7C8d5a9e88cf49

        // Integration Boost - 3,000,000 USDS - 0xD6891d1DFFDA6B0B1aF3524018a1eE2E608785F7
        _transferUsds(INTEGRATION_BOOST_INITIATIVE, 3_000_000 * WAD);

        // ---------- Whistleblower Payment ----------
        // Forum: https://forum.sky.money/t/whistleblower-bounty-and-ad-penalty-for-misalignment/25911
        // Atlas: https://sky-atlas.powerhouse.io/A.1.5.19_Whistleblower_Bounty/fb2de9a9-8154-46b8-9631-a5dda875921e%7C0db3af4e955e

        // GFX Labs - 1,000 USDS - 0xa6e8772af29b29B9202a073f8E36f447689BEef6
        _transferUsds(GFXLABS, 1_000 * WAD);

        // ---------- Spark Proxy Spell ----------
        // Forum: https://forum.sky.money/t/feb-6-2025-proposed-changes-to-spark-for-upcoming-spell-actual/25888
        // Poll: https://vote.makerdao.com/polling/QmUMkWLQ
        // Poll: https://vote.makerdao.com/polling/QmTfntSm
        // Poll: https://vote.makerdao.com/polling/QmWCe4JD
        // Poll: https://vote.makerdao.com/polling/QmbSANrr
        // Poll: https://vote.makerdao.com/polling/QmRKhzad

        // Execute Spark Spell at 0xD5c59b7c1DD8D2663b4c826574ed968B2C8329C0
        // Note: Make sure to not revert the Core spell if the Spark spell reverts
        try ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()")) {

        } catch {}
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
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
