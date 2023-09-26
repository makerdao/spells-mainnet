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

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-09-30 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }
    // ----- Approve HV Bank (RWA009-A) DAO Resolution -----
    // Forum: http://forum.makerdao.com/t/request-to-poll-offboarding-legacy-legal-recourse-assets/21582
    // Poll: https://vote.makerdao.com/polling/QmNgKzcG
    // Approve DAO resolution hash QmXU2TwsRpVevGY74NVFbD9bKwtsw1mSuSce7My1zinD9m

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // uint256 internal constant X_PCT_RATE      = ;

    //  ---------- Math ----------

    // ---------- Spark Proxy ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend/blob/d42587ba36523dcff24a4c827dc29ab71cd0808b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;

    // ---------- Trigger Spark Proxy Spell ----------
    address internal constant SPARK_SPELL = address(0); // TODO

    function actions() public override {

        // ---------- Section Separator ----------

        // ---------- Trigger Spark Proxy Spell ----------
        // TODO
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
