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

interface PauseLike {
    function setDelay(uint256) external;
}

interface LineMomLike {
    function addIlk(bytes32 ilk) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/a90e4c4e5c44163fb78597f5d55690753e071711/governance/votes/Executive%20vote%20-%20March%2026%2C%202024.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-04-04 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
    }

    // Note: by the previous convention it should be a comma-separated list of DAO resolutions IPFS hashes
    string public constant dao_resolutions = "Qmf8Nv4HnTFNDwRgcLzRgBdtVsVVfKY2FppaBimLK9XhxB";

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
    uint256 internal constant BILLION = 10 ** 9;

    // ---------- Addesses ----------
    address internal immutable MCD_PAUSE = DssExecLib.getChangelogAddress("MCD_PAUSE");
    address internal immutable LINE_MOM  = DssExecLib.getChangelogAddress("LINE_MOM");

    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL = 0x7748C5E6EEda836247F2AfCd5a7c0dA3c5de9Da2;

    function actions() public override {
        // ---------- Increase the GSM Pause Delay ----------
        // Forum: https://forum.makerdao.com/t/gsm-pause-delay-increase-proposal/23929
        // Poll: https://vote.makerdao.com/polling/QmcLsYwj

        // Increase the GSM Pause Delay by 14 hours, from 16 hours to 30 hours -----
        PauseLike(MCD_PAUSE).setDelay(30 hours);

        // ---------- Add the following ilks to LINE_MOM ----------
        // Forum: https://forum.makerdao.com/t/gov12-1-2-bootstrapping-edit-proposal-gov10-2-3-1a-edit/24005
        // Poll: https://vote.makerdao.com/polling/QmZsAM36

        // ETH-A
        LineMomLike(LINE_MOM).addIlk("ETH-A");
        // ETH-B
        LineMomLike(LINE_MOM).addIlk("ETH-B");
        // ETH-C
        LineMomLike(LINE_MOM).addIlk("ETH-C");
        // WSTETH-A
        LineMomLike(LINE_MOM).addIlk("WSTETH-A");
        // WSTETH-B
        LineMomLike(LINE_MOM).addIlk("WSTETH-B");
        // WBTC-A
        LineMomLike(LINE_MOM).addIlk("WBTC-A");
        // WBTC-B
        LineMomLike(LINE_MOM).addIlk("WBTC-B");
        // WBTC-C
        LineMomLike(LINE_MOM).addIlk("WBTC-C");

        // ---------- Spark MetaMorpho Vault Parameters ----------
        // Forum: https://forum.makerdao.com/t/morpho-spark-dai-vault-update-1-april-2024/24006
        // Forum: https://forum.makerdao.com/t/morpho-spark-dai-vault-update-1-april-2024/24006/8

        // DDM DC-IAM Parameters: line: 1 billion DAI
        DssExecLib.setIlkAutoLineDebtCeiling("DIRECT-SPARK-MORPHO-DAI", 1 * BILLION);

        // ---------- Approve TACO Resolution ----------
        // Forum: https://forum.makerdao.com/t/bt-project-ethena-risk-legal-assessment/23978

        // Approve IPFS Resolutions: Qmf8Nv4HnTFNDwRgcLzRgBdtVsVVfKY2FppaBimLK9XhxB
        // Note: see `dao_resolutions` variable declared above

        // ---------- Spark Proxy Spell ----------
        // Forum: https://forum.makerdao.com/t/mar-21-2024-proposed-changes-to-sparklend-for-upcoming-spell/23918
        // Poll: https://vote.makerdao.com/polling/QmdjqTvL
        // Poll: https://vote.makerdao.com/polling/QmaEqEav
        // Poll: https://vote.makerdao.com/polling/QmbCWUAP

        // Trigger Spark Proxy Spell at 0x210DF2e1764Eb5491d41A62E296Ea39Ab56F9B6d
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
