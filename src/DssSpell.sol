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

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/9d961acbbe5d2521b89af70d3e8aea8e89094301/governance/votes/Executive%20Vote%20-%20June%2027%2C%202024.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-06-27 MakerDAO Executive Spell | Hash: 0xe1b795a6561d35bf8cb74b429f498bb74da60d9776512c34632fb62ec6e22656";

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
    // uint256 internal constant X_PCT_1000000003022265980097387650RATE = ;

    // ---------- Payment addresses ----------
    address internal constant LAUNCH_PROJECT_FUNDING = 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F;

    // ---------- Contracts ----------
    GemAbstract internal immutable MKR               = GemAbstract(DssExecLib.mkr());
    address internal immutable MCD_VOW               = DssExecLib.vow();
    address internal immutable MCD_FLAP              = DssExecLib.flap();

    // ---------- Spark Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0xc96420Dbe9568e2a65DD57daAD069FDEd37265fa;

    function actions() public override {
        // ---------- SBE Parameter Updates ----------
        // Forum: http://forum.makerdao.com/t/smart-burn-engine-transaction-analysis-parameter-reconfiguration-update-8/24531/

        // Decrease the hop parameter for 1,577 seconds from 11,826 seconds to 10,249 seconds.
        DssExecLib.setValue(MCD_FLAP, "hop", 10_249);

        // Decrease the bump parameter for 10,000 DAI from 75,000 DAI to 65,000 DAI.
        DssExecLib.setSurplusAuctionAmount(65_000);

        // ---------- Launch Funding Transfers ----------
        // Forum: https://forum.makerdao.com/t/utilization-of-the-launch-project-under-the-accessibility-scope/21468/18
        // MIP: https://mips.makerdao.com/mips/details/MIP108#9-1-launch-project-budget

        // Launch Project - 4,500,000 DAI - 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        DssExecLib.sendPaymentFromSurplusBuffer(LAUNCH_PROJECT_FUNDING, 4_500_000);

        // Launch Project - 1,300.00 MKR - 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        MKR.transfer(LAUNCH_PROJECT_FUNDING, 1300.00 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // ---------- Spark Spell ----------
        // Forum: https://forum.makerdao.com/t/jun-12-2024-proposed-changes-to-sparklend-for-upcoming-spell/24489

        // Trigger Spark Proxy Spell at 0xc96420Dbe9568e2a65DD57daAD069FDEd37265fa
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
