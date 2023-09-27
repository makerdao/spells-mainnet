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

interface RwaLiquidationOracleLike {
    function ilks(bytes32) external view returns (string memory doc, address pip, uint48 tau, uint48 toc);
    function init(bytes32 ilk, uint256 val, string memory doc, uint48 tau) external;
    function tell(bytes32 ilk) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/c0eb5feb51cf5a8d0dcdcd4436976d3b4f3da913/governance/votes/Executive%20vote%20-%20September%2027%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-09-30 MakerDAO Executive Spell | Hash: 0x3906bcfefa6d515aae83aba7dae150afde5772699e6a0741f3e89d344315aa36";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // -----  RWA007-A (Clydesdale) DAO Resolution -----
    // Poll: https://vote.makerdao.com/polling/Qmb45PDU
    // Forum: https://forum.makerdao.com/t/proposal-to-revise-asset-allocation-of-jat1-and-jat2/21718
    // Approve the DAO Resolution with hash QmZ94FG8YXK4seyBHBi2FfTfW5URtBqbCb7JZAB1HGkTNF

    // Comma-separated list of DAO resolutions IPFS hashes.
    string public constant dao_resolutions = "QmZ94FG8YXK4seyBHBi2FfTfW5URtBqbCb7JZAB1HGkTNF";

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

    //  ---------- MCD Contracts ----------

    address internal immutable MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");

    // ---------- Spark Proxy ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend/blob/d42587ba36523dcff24a4c827dc29ab71cd0808b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;

    // ---------- Trigger Spark Proxy Spell ----------
    address internal constant SPARK_SPELL = 0x9FfFbc278119Ad854b58C3d219212849E8B54eF8;

    function _updateDoc(bytes32 ilk, string memory doc) internal {
        ( , address pip, uint48 tau, ) = RwaLiquidationOracleLike(MIP21_LIQUIDATION_ORACLE).ilks(ilk);
        require(pip != address(0), "DssSpell/unexisting-rwa-ilk");

        // Init the RwaLiquidationOracle to reset the doc
        RwaLiquidationOracleLike(MIP21_LIQUIDATION_ORACLE).init(
            ilk, // ilk to update
            0,   // price ignored if init() has already been called
            doc, // new legal document
            tau  // old tau value
        );
    }

    function actions() public override {
        // ----- RWA007-A (Clydesdale) DAO Resolution -----
        // Poll: https://vote.makerdao.com/polling/Qmb45PDU
        // Forum: https://forum.makerdao.com/t/proposal-to-revise-asset-allocation-of-jat1-and-jat2/21718

        // Update the Doc variable for RWA007-A (Clydesdale) to QmWo3UVtEDKVwS5k34uLt1J6u9px3rjHYkTLK2rYQ31E3G
        _updateDoc("RWA007-A", "QmWo3UVtEDKVwS5k34uLt1J6u9px3rjHYkTLK2rYQ31E3G");

        // ----- RWA009-A (HV Bank) DAO Resolution -----
        // Executive Vote: https://forum.makerdao.com/t/proposal-to-revise-asset-allocation-of-jat1-and-jat2/21718
        // Forum: https://forum.makerdao.com/t/rwa009-hvbank-mip21-token-ces-domain-team-assessment/15861/13

        // Update the Doc variable for RWA009-A (HV Bank) to QmYjvAZEeGCs8kMuLQz6kU8PWgsbG1i8QWd2jrwkSipcRx
        _updateDoc("RWA009-A", "QmYjvAZEeGCs8kMuLQz6kU8PWgsbG1i8QWd2jrwkSipcRx");

        // ----- Place the RWA005-A (Fortunafi) vault into "Soft Liquidation" -----
        // Executive Vote: https://vote.makerdao.com/executive/template-executive-vote-stability-scope-parameter-changes-spark-protocol-d3m-parameter-changes-set-fortunafi-debt-ceiling-to-zero-dai-dao-resolution-for-hv-bank-delegate-compensation-and-other-actions-september-13-2023
        // Forum: https://forum.makerdao.com/t/request-to-poll-offboarding-legacy-legal-recourse-assets/21582/12

        // Call tell() from RWA005-A (Fortunafi)
        RwaLiquidationOracleLike(MIP21_LIQUIDATION_ORACLE).tell("RWA005-A");

        // ---------- Trigger Spark Proxy Spell ----------
        // Poll: https://vote.makerdao.com/polling/QmVcxd7J
        // Forum: https://forum.makerdao.com/t/proposal-for-activation-of-gnosis-chain-instance/22098/8
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
