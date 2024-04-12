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

interface InputConduitJarLike {
    function push(uint256) external;
}

interface JarLike {
    function void() external;
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-04-18 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
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

    // ----------- Payment Addresses -----------

    // AAVE
    address constant internal AAVE_V3_TREASURY = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    // ---------- Contracts ----------
    InputConduitJarLike internal immutable MCD_PSM_PAX_A_INPUT_CONDUIT_JAR = InputConduitJarLike(DssExecLib.getChangelogAddress("MCD_PSM_PAX_A_INPUT_CONDUIT_JAR"));
    JarLike internal immutable MCD_PSM_PAX_A_JAR                           = JarLike(DssExecLib.getChangelogAddress("MCD_PSM_PAX_A_JAR"));

    // ---------- Trigger Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend/blob/d42587ba36523dcff24a4c827dc29ab71cd0808b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    // TODO: Update with the correct spell address
    address internal constant SPARK_SPELL = address(0);

    function actions() public override {
        // ---------- AD Compensation ----------
        // Forum: TODO

        // TBD

        // ---------- AVC Member Compensation ----------
        // Forum: TODO

        // TBD

        // ---------- Aave Revenue Share ----------
        // Forum: https://forum.makerdao.com/t/spark-aave-revenue-share-calculation-payment-3-q1-2024/24014

        // Transfer 238,339 DAI to 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c
        DssExecLib.sendPaymentFromSurplusBuffer(AAVE_V3_TREASURY, 238_339);

        // ---------- Whitelist new address in the RWA015-A output conduit ----------
        // Forum: TODO

        // TBD

        // ---------- Push USDP out of input conduit ----------
        // Forum: TODO

        // Raise PSM-PAX-A DC to 100,000 DAI
        DssExecLib.setIlkDebtCeiling("PSM-PAX-A", 100_000);

        // Call push() on MCD_PSM_PAX_A_INPUT_CONDUIT_JAR (use push(uint256 amt)) to push 84,211.27 USDP
        MCD_PSM_PAX_A_INPUT_CONDUIT_JAR.push(84_211.27 ether); // Note: `ether` is only a keyword helper

        // Call void() on MCD_PSM_PAX_A_JAR
        MCD_PSM_PAX_A_JAR.void();

        // Set PSM-PAX-A DC to 0 DAI to 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c
        DssExecLib.setIlkDebtCeiling("PSM-PAX-A", 0);

        // ---------- Spark Proxy Spell ----------
        // Forum: TODO

        // Trigger Spark Proxy Spell at TBD
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
