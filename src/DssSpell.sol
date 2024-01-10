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

interface RwaLiquidationLike {
    function ilks(bytes32) external view returns (string memory, address, uint48, uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
}

interface VestLike {
    function yank(uint256 _id) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-01-12 MakerDAO Executive Spell | Hash: TODO";

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

    // ---------- Math ----------
    uint256 constant internal MILLION  = 10 **  6;

    // ----------- MKR transfer Addresses -----------

    // Delegates
    address internal constant DEFENSOR          = 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9;
    address internal constant BONAPUBLICA       = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant CLOAKY            = 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818;
    address internal constant TRUENAME          = 0x612F7924c367575a0Edf21333D96b15F1B345A5d;
    address internal constant BLUE              = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;
    address internal constant UPMAKER           = 0xbB819DF169670DC71A16F58F55956FE642cc6BcD;
    address internal constant VIGILANT          = 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61;
    address internal constant JAG               = 0x58D1ec57E4294E4fe650D1CB12b96AE34349556f;
    address internal constant PBG               = 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2;
    address internal constant WBC               = 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47;
    address internal constant NAVIGATOR         = 0x11406a9CC2e37425F15f920F494A51133ac93072;
    address internal constant PALC              = 0x78Deac4F87BD8007b9cb56B8d53889ed5374e83A;

    // BA Labs address
    address internal constant RISK_WALLET_VEST  = 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c;
    // SES address
    address internal constant SES_WALLET        = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;

    // ---------- Launch Project Funds ----------
    address internal constant LAUNCH_PROJECT_FUNDING = 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F;

    address internal immutable MCD_VEST_DAI             = DssExecLib.getChangelogAddress("MCD_VEST_DAI");
    address internal immutable MCD_VEST_DAI_LEGACY      = DssExecLib.getChangelogAddress("MCD_VEST_DAI_LEGACY");
    address internal immutable MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");
    GemAbstract internal immutable MKR                  = GemAbstract(DssExecLib.mkr());

    // Function from https://github.com/makerdao/spells-goerli/blob/7d783931a6799fe8278e416b5ac60d4bb9c20047/archive/2022-11-14-DssSpell/Goerli-DssSpell.sol#L59
    function _updateDoc(bytes32 ilk, string memory doc) internal {
        ( , address pip, uint48 tau, ) = RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).ilks(ilk);
        require(pip != address(0), "DssSpell/unexisting-rwa-ilk");

        // Init the RwaLiquidationOracle to reset the doc
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(
            ilk, // ilk to update
            0,   // price ignored if init() has already been called
            doc, // new legal document
            tau  // old tau value
        );
    }

    // ---------- Trigger Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend/blob/d42587ba36523dcff24a4c827dc29ab71cd0808b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;

    // ---------- Trigger Spark Proxy Spell ----------
    address internal constant SPARK_SPELL = 0x7E73CCAA4977A5429fD1815130804769EcAad4a7;

    function actions() public override {

        // ---------- November Delegate Compensation ----------
        // Forum: https://forum.makerdao.com/t/november-2023-aligned-delegate-compensation/23351

        // 0xDefensor - 41.67 MKR - 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9
        MKR.transfer(DEFENSOR, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // BONAPUBLICA - 41.67 MKR - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        MKR.transfer(BONAPUBLICA, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // Cloaky - 41.67 MKR - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        MKR.transfer(CLOAKY, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // TRUE NAME - 41.67 MKR - 0x612F7924c367575a0Edf21333D96b15F1B345A5d
        MKR.transfer(TRUENAME, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // BLUE - 13.95 MKR - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        MKR.transfer(BLUE, 13.95 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // UPMaker - 13.89 MKR - 0xbB819DF169670DC71A16F58F55956FE642cc6BcD
        MKR.transfer(UPMAKER, 13.89 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // vigilant - 13.89 MKR - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        MKR.transfer(VIGILANT, 13.89 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // JAG - 13.02 MKR - 0x58D1ec57E4294E4fe650D1CB12b96AE34349556f
        MKR.transfer(JAG, 13.02 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // PBG - 0.45 MKR - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        MKR.transfer(PBG, 0.45 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // ---------- December Delegate Compensation ----------
        // Forum: https://forum.makerdao.com/t/december-2023-aligned-delegate-compensation/23352

        // 0xDefensor - 41.67 MKR - 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9
        MKR.transfer(DEFENSOR, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // BONAPUBLICA - 41.67 MKR - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        MKR.transfer(BONAPUBLICA, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // Cloaky - 41.67 MKR - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        MKR.transfer(CLOAKY, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // TRUE NAME - 41.67 MKR - 0x612F7924c367575a0Edf21333D96b15F1B345A5d
        MKR.transfer(TRUENAME, 41.67 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // BLUE - 39.20 MKR - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        MKR.transfer(BLUE, 39.20 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // PBG - 13.89 MKR - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        MKR.transfer(PBG, 13.89 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // UPMaker - 13.89 MKR - 0xbB819DF169670DC71A16F58F55956FE642cc6BcD
        MKR.transfer(UPMAKER, 13.89 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // vigilant - 13.89 MKR - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        MKR.transfer(VIGILANT, 13.89 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // JAG - 12.95 MKR - 0x58D1ec57E4294E4fe650D1CB12b96AE34349556f
        MKR.transfer(JAG, 12.95 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // WBC - 11.28 MKR - 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47
        MKR.transfer(WBC, 11.28 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // ---------- Offboarded Delegate Buffer Payments ----------
        // Forum: https://forum.makerdao.com/t/october-2023-aligned-delegate-compensation/22732#october-compensation-2

        // Navigator - 20.84 MKR - 0x11406a9CC2e37425F15f920F494A51133ac93072
        MKR.transfer(NAVIGATOR, 20.84 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // PALC - 6.95 MKR - 0x78Deac4F87BD8007b9cb56B8d53889ed5374e83A
        MKR.transfer(PALC, 6.95 ether); // NOTE: ether is a keyword helper, only MKR is transferred here


        // ---------- yank Dai streams ----------

        // yank Dai stream 21 - DECO
        // Forum: https://forum.makerdao.com/t/mip39c3-sp12-core-unit-offboarding-deco/22333
        VestLike(MCD_VEST_DAI_LEGACY).yank(21);

        // yank Dai stream 15 - SES
        // Forum: https://forum.makerdao.com/t/mip39c3-sp11-core-unit-offboarding-ses/22332
        VestLike(MCD_VEST_DAI).yank(15);

        // ---------- CU MKR payments ----------
        // MIP: https://mips.makerdao.com/mips/details/MIP40c3SP25

        // BA Labs - 175.00 MKR - 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c
        MKR.transfer(RISK_WALLET_VEST, 175.00 ether); // NOTE: ether is a keyword helper, only MKR is transferred here
        // SES - 508.55 MKR - 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6
        MKR.transfer(SES_WALLET, 508.55 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // ---------- Launch Project Funding ----------
        // Forum: https://forum.makerdao.com/t/utilization-of-the-launch-project-under-the-accessibility-scope/21468/9

        // Launch Project - 4,500,000.00 DAI - 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        DssExecLib.sendPaymentFromSurplusBuffer(LAUNCH_PROJECT_FUNDING, 4_500_000);
        // Launch Project - 820.00 MKR - 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        MKR.transfer(LAUNCH_PROJECT_FUNDING, 820.00 ether); // NOTE: ether is a keyword helper, only MKR is transferred here

        // ---------- Update doc parameter ----------
        // Forum: https://forum.makerdao.com/t/rwa009-hvbank-mip21-token-ces-domain-team-assessment/15861/14

        // Update HVBank (RWA009-A) doc to QmfEgZuiw6wsTRUYerdPZNUrqDXSGM6Nm4fM3nG7nNbEjT
        _updateDoc("RWA009-A", "QmfEgZuiw6wsTRUYerdPZNUrqDXSGM6Nm4fM3nG7nNbEjT");

        // ---------- Spark D3M line increase ----------
        // Forum: https://forum.makerdao.com/t/spark-spell-proposed-changes/23298
        // Poll: https://vote.makerdao.com/polling/QmdQSuAc#poll-detail

        // Increase the line by 400 million from 800 million to 1.2 billion Dai
        DssExecLib.setIlkAutoLineDebtCeiling("DIRECT-SPARK-DAI", 1200 * MILLION);

        // ---------- Trigger Spark Proxy Spell ----------

        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
