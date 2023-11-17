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
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/5156da9ff964a917fa90d55413b2ad2f8f8341ac/governance/votes/Executive%20Vote%20-%20November%2015%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-11-15 MakerDAO Executive Spell | Hash: 0x5831e082f6599a8bdd8c772f43836bce1170f121e2d47218069a03feb3638ccc";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // ---------- Pass HVB Resolutions ----------
    // Forum: https://forum.makerdao.com/t/huntingdon-valley-bank-transaction-documents-on-permaweb/16264/19
    // Poll: https://vote.makerdao.com/polling/QmNgKzcG
    // Updated Standing Instructions to Escrow Agent - QmWVWXckY482WLTtCFv3x45DFioV1K8mfRM3FVrodqUDud
    // Approval of New Payment Instructions to Galaxy Digital Trading Cayman LLC - QmSbwqULr66CiCvNips93vwTrvoTe4i2rJVmho7QfmyqZG

    // Comma-separated list of DAO resolutions IPFS hashes.
    string public constant dao_resolutions = "QmWVWXckY482WLTtCFv3x45DFioV1K8mfRM3FVrodqUDud,QmSbwqULr66CiCvNips93vwTrvoTe4i2rJVmho7QfmyqZG";

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

    // --- MATH ---
    uint256 internal constant MILLION                = 10 ** 6;

    GemAbstract internal immutable MKR               = GemAbstract(DssExecLib.mkr());

    // ---------- Spark Proxy ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend/blob/d42587ba36523dcff24a4c827dc29ab71cd0808b/script/output/5/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY            = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;

    // ---------- Trigger Spark Proxy Spell ----------
    address internal constant SPARK_SPELL            = 0xDa69603384Ef825E52FD5B8bEF656ff62Fe19703;

    // ---------- Whistleblower Bounty ----------
    address internal constant VENICE_TREE            = 0xCDDd2A697d472d1e8a0B1B188646c756d097b058;

    // ---------- Launch Project Funds ----------
    address internal constant LAUNCH_PROJECT_FUNDING = 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F;

    // ---------- Delegates ----------
    address internal constant DEFENSOR               = 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9;
    address internal constant TRUENAME               = 0x612F7924c367575a0Edf21333D96b15F1B345A5d;
    address internal constant BONAPUBLICA            = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant CLOAKY                 = 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818;
    address internal constant NAVIGATOR              = 0x11406a9CC2e37425F15f920F494A51133ac93072;
    address internal constant VIGILANT               = 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61;
    address internal constant UPMAKER                = 0xbB819DF169670DC71A16F58F55956FE642cc6BcD;
    address internal constant PBG                    = 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2;
    address internal constant PALC                   = 0x78Deac4F87BD8007b9cb56B8d53889ed5374e83A;
    address internal constant BLUE                   = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;
    address internal constant JAG                    = 0x58D1ec57E4294E4fe650D1CB12b96AE34349556f;

    function actions() public override {
        // ---------- Spark Proxy-Spell ----------
        // Forum: https://forum.makerdao.com/t/proposal-to-adjust-sparklend-parameters/22542
        // Poll: https://vote.makerdao.com/polling/QmaBLbxP
        // Poll: https://vote.makerdao.com/polling/QmZwRgr5
        // Poll: https://vote.makerdao.com/polling/QmQPrHsm
        // Poll: https://vote.makerdao.com/polling/QmRG9qUp
        // Poll: https://vote.makerdao.com/polling/QmQjKpbU

        // Gnosis Chain - Increase wstETH Supply Cap to 10,000 wstETH
        // Ethereum - Set DAI Market Maximum Loan-to-Value to Zero Percent
        // Ethereum - Reactivate WBTC and Optimize Parameters for Current Market Conditions
        // Ethereum - Increase rETH & wstETH Supply Caps
        // Ethereum & Gnosis Chain - Adjust ETH Market Interest Rate Models
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));


        // ----- Adjust Spark Protocol D3M Maximum Debt Ceiling -----
        // Forum: https://forum.makerdao.com/t/proposal-to-adjust-sparklend-parameters/22542
        // Poll: https://vote.makerdao.com/polling/QmVbrypf#poll-detail

        // Increase the DIRECT-SPARK-DAI Maximum Debt Ceiling from 400 million DAI to 800 million DAI.
        // Keep gap and ttl at current settings (20 million and  hours respectively)
        DssExecLib.setIlkAutoLineDebtCeiling("DIRECT-SPARK-DAI", 800 * MILLION);


        // ---------- Launch Project Funds Transfer ----------
        // Forum: https://forum.makerdao.com/t/utilization-of-the-launch-project-under-the-accessibility-scope/21468/6

        // Launch Project - 2200000.00 DAI - 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        DssExecLib.sendPaymentFromSurplusBuffer(LAUNCH_PROJECT_FUNDING, 2_200_000);
        // Launch Project - 500.00 MKR - 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        MKR.transfer(LAUNCH_PROJECT_FUNDING, 500.00 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here


        // ---------- Whistleblower Bounty ----------
        // Forum: https://forum.makerdao.com/t/ads-derecognition-due-to-operational-security-breach/22532
        // MIP: https://mips.makerdao.com/mips/details/MIP101#2-6-6-aligned-delegate-operational-security

        // VeniceTree - 27.78 MKR - 0xCDDd2A697d472d1e8a0B1B188646c756d097b058
        MKR.transfer(VENICE_TREE, 27.78 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here


        // ---------- October Delegate Compensation  ----------
        // Forum: https://forum.makerdao.com/t/october-2023-aligned-delegate-compensation/22732

        // 0xDefensor - 41.67 MKR - 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9
        MKR.transfer(DEFENSOR,    41.67 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here
        // TRUE NAME - 41.67 MKR - 0x612f7924c367575a0edf21333d96b15f1b345a5d
        MKR.transfer(TRUENAME,    41.67 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here
        // BONAPUBLICA - 41.67 MKR - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        MKR.transfer(BONAPUBLICA, 41.67 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here
        // Cloaky - 41.67 MKR - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        MKR.transfer(CLOAKY,      41.67 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here
        // Navigator - 40.33 MKR - 0x11406a9CC2e37425F15f920F494A51133ac93072
        MKR.transfer(NAVIGATOR,   40.33 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here
        // vigilant - 13.84 MKR - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        MKR.transfer(VIGILANT,    13.84 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here
        // "UPMaker - 13.89 MKR - 	0xbb819df169670dc71a16f58f55956fe642cc6bcd"
        MKR.transfer(UPMAKER,     13.89 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here
        // PBG - 13.89 MKR - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        MKR.transfer(PBG,         13.89 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here
        // PALC - 13.44 MKR - 0x78Deac4F87BD8007b9cb56B8d53889ed5374e83A
        MKR.transfer(PALC,        13.44 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here
        // BLUE - 12.97 MKR - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        MKR.transfer(BLUE,        12.97 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here
        // JAG - 4.45 MKR - 0x58D1ec57E4294E4fe650D1CB12b96AE34349556f
        MKR.transfer(JAG,         4.45 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
