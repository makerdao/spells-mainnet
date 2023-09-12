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

interface DenyLike {
    function deny(address usr) external;
}

interface ChainlogLike {
    function removeAddress(bytes32) external;
}

interface ProxyLike {
    function exec(address target, bytes calldata args) external payable returns (bytes memory out);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/64b0d8425a316c40d1fc464c084d800e3b17c1f3/governance/votes/Executive%20vote%20-%20August%2030%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-09-13 MakerDAO Executive Spell | Hash: 0xd4f061429b564e422f18f0289a0f956f0229edbeead40b51ad69d52b27f7e591";

    GemAbstract internal immutable MKR      = GemAbstract(DssExecLib.mkr());

    address internal immutable MCD_VAT         = DssExecLib.vat();
    address internal immutable MCD_CAT         = DssExecLib.cat();
    address internal immutable MCD_PAUSE_PROXY = DssExecLib.pauseProxy();

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }
    // ----- Approve HV Bank (RWA009-A) DAO Resolution -----
    // Forum: http://forum.makerdao.com/t/request-to-poll-offboarding-legacy-legal-recourse-assets/21582
    // Poll: https://vote.makerdao.com/polling/QmNgKzcG
    // Approve DAO resolution hash QmXU2TwsRpVevGY74NVFbD9bKwtsw1mSuSce7My1zinD9m

    // Comma-separated list of DAO resolutions IPFS hashes.
    string public constant dao_resolutions = "QmXU2TwsRpVevGY74NVFbD9bKwtsw1mSuSce7My1zinD9m";

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

    uint256 internal constant THREE_PT_FOUR_FIVE_PCT_RATE   = 1000000001075539644270067964;
    uint256 internal constant THREE_PT_SEVEN_ZERO_PCT_RATE  = 1000000001152077919467240095;
    uint256 internal constant FOUR_PT_TWO_ZERO_PCT_RATE     = 1000000001304602465690389263;
    // ----------- MKR transfer Addresses -----------
    address internal constant DECO_001 = 0xF482D1031E5b172D42B2DAA1b6e5Cbf6519596f7;
    address internal constant SES_001  = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;

    address internal constant DEFENSOR     = 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9;
    address internal constant TRUE_NAME    = 0x612F7924c367575a0Edf21333D96b15F1B345A5d;
    address internal constant BONAPUBLICA  = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant VIGILANT     = 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61;
    address internal constant NAVIGATOR    = 0x11406a9CC2e37425F15f920F494A51133ac93072;
    address internal constant QGOV         = 0xB0524D8707F76c681901b782372EbeD2d4bA28a6;
    address internal constant UPMAKER      = 0xbB819DF169670DC71A16F58F55956FE642cc6BcD;
    address internal constant PALC         = 0x78Deac4F87BD8007b9cb56B8d53889ed5374e83A;
    address internal constant PBG          = 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2;
    address internal constant CLOAKY       = 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818;
    address internal constant WBC          = 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47;
    address internal constant BLUE         = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;

    //  ---------- Math ----------
    uint256 internal constant MILLION = 10 ** 6;

        // ---------- Spark Proxy ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend/blob/d42587ba36523dcff24a4c827dc29ab71cd0808b/script/output/5/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;

    // ---------- Trigger Spark Proxy Spell ----------
    address internal constant SPARK_SPELL = 0x95bcf659653d2E0b44851232d61F6F9d2e933fB1;

    function actions() public override {
        // ---------- Stability Scope Parameter Changes ----------
        // MIP: https://mips.makerdao.com/mips/details/MIP104#0-the-stability-scope
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-5/21969
        // Increase the ETH-A Stability Fee (SF) by 0.12% from 3.58% to 3.70%.
        DssExecLib.setIlkStabilityFee("ETH-A", THREE_PT_SEVEN_ZERO_PCT_RATE, /* doDrip = */ true);

        // Increase the ETH-B Stability Fee (SF) by 0.12% from 4.08% to 4.20%.
        DssExecLib.setIlkStabilityFee("ETH-B", FOUR_PT_TWO_ZERO_PCT_RATE, /* doDrip = */ true);

        // Increase the ETH-C Stability Fee (SF) by 0.12% from 3.33% to 3.45%.
        DssExecLib.setIlkStabilityFee("ETH-C", THREE_PT_FOUR_FIVE_PCT_RATE, /* doDrip = */ true);

        // Activate DC-IAM for PSM-PAX-A
        // Maximum Debt Ceiling (line): 120M
        // Target Available Debt (gap): 50 million DAI
        // Ceiling Increase Cooldown (ttl): 24 hours
        DssExecLib.setIlkAutoLineParameters("PSM-PAX-A", /* line */ 120 * MILLION, /* gap */ 50 * MILLION, /* ttl */ 24 hours);

        // ---------- Spark Protocol DC-IAM changes ----------
        // Forum: http://forum.makerdao.com/t/upcoming-spell-proposed-changes/21801
        // Poll: https://vote.makerdao.com/polling/QmQnUhZt#vote-breakdown
        // Increase the Maximum Debt Ceiling from 200 million DAI to 400 million DAI.
        // and
        // Increase the Ceiling Increase Cooldown from 8 hours to 12 hours.
        DssExecLib.setIlkAutoLineParameters("DIRECT-SPARK-DAI", /* line */ 400 * MILLION, /* gap */ 20 * MILLION, /* ttl */ 12 hours);

        // ---------- Aligned Delegate Compensation for August ----------
        // Forum: https://forum.makerdao.com/t/august-2023-aligned-delegate-compensation/21983
        // NOTE: Skip on goerli

        // 0xDefensor - 41.67 - 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9
        MKR.transfer(DEFENSOR, 41.67 ether);

        // TRUE NAME - 41.67 - 0x612f7924c367575a0edf21333d96b15f1b345a5d
        MKR.transfer(TRUE_NAME, 41.67 ether);

        // BONAPUBLICA - 41.67 - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        MKR.transfer(BONAPUBLICA, 41.67 ether);

        // vigilant - 41.67 - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        MKR.transfer(VIGILANT, 41.67 ether);

        // Navigator - 28.23 - 0x11406a9CC2e37425F15f920F494A51133ac93072
        MKR.transfer(NAVIGATOR, 28.23 ether);

        // QGov - 20.16 - 0xB0524D8707F76c681901b782372EbeD2d4bA28a6
        MKR.transfer(QGOV, 20.16 ether);

        // UPMaker - 13.89 - 0xbb819df169670dc71a16f58f55956fe642cc6bcd
        MKR.transfer(UPMAKER, 13.89 ether);

        // PALC - 13.89 - 0x78Deac4F87BD8007b9cb56B8d53889ed5374e83A
        MKR.transfer(PALC, 13.89 ether);

        // PBG - 13.89 - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        MKR.transfer(PBG, 13.89 ether);

        // Cloaky - 7.17 - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        MKR.transfer(CLOAKY, 7.17 ether);

        // WBC - 6.72 - 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47
        MKR.transfer(WBC, 6.72 ether);

        // BLUE - 1.25 - 0xb6c09680d822f162449cdfb8248a7d3fc26ec9bf
        MKR.transfer(BLUE, 1.25 ether);

        // ---------- Decrease Debt Ceiling for Fortunafi (RWA005-A) to 0 ----------
        // Decrease Debt Ceiling from 15 million DAI to 0 (zero)
        // Forum: http://forum.makerdao.com/t/request-to-poll-offboarding-legacy-legal-recourse-assets/21582
        // Poll: https://vote.makerdao.com/polling/Qmcb1c9x

        DssExecLib.decreaseIlkDebtCeiling("RWA005-A", 15 * MILLION, /* global = */ true);

        // ---------- Trigger Spark Proxy Spell ----------
        // Poll: https://vote.makerdao.com/polling/QmQrkxud
        // Poll 2: https://vote.makerdao.com/polling/QmbCDKof
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));


        // ---------- Core Unit MKR Vesting Transfers ----------
        // DECO-001 - 125 MKR - 0xF482D1031E5b172D42B2DAA1b6e5Cbf6519596f7
        // MIP: https://mips.makerdao.com/mips/details/MIP40c3SP36#sentence-summary
        MKR.transfer(DECO_001, 125 ether);

        // SES-001 - 34.94 MKR - 0x87acdd9208f73bfc9207e1f6f0fde906bca95cc6
        // MIP: https://mips.makerdao.com/mips/details/MIP40c3SP17#sentence-summary
        MKR.transfer(SES_001, 34.94 ether);

        // ---------- Scuttle MCD_CAT ----------
        // Forum: http://forum.makerdao.com/t/proposal-to-scuttle-mcd-cat-upcoming-executive-spell-2023-09-13/21958

        // Remove MCD_CAT from the Chainlog
        ChainlogLike(DssExecLib.LOG).removeAddress("MCD_CAT");

        // Revoke MCD_CAT access to MCD_VAT: vat.deny(cat)
        DenyLike(MCD_VAT).deny(MCD_CAT);

        // Yield ownership of MCD_CAT: cat.deny(pauseProxy)
        DenyLike(MCD_CAT).deny(MCD_PAUSE_PROXY);

        // Bump chainlog version
        // Justification: The MINOR version is updated as core MCD_CAT contract is being removed in this spell
        DssExecLib.setChangelogVersion("1.17.0");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
