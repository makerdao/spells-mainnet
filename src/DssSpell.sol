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
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/94c78956105c9ff0cb5aa3662e371f75bfb4fa5f/governance/votes/Executive%20Vote%20-%20March%206%2C%202024.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-03-06 MakerDAO Executive Spell | Hash: 0x58137ea863fa6ff936cfa4aa430826c5c548b1e863acf4da8df0cdc465f7090c";

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

    //  ---------- Math ----------
    uint256 internal constant MILLION                = 10 ** 6;

    // ---------- Contract addresses ----------
    GemAbstract internal immutable MKR               = GemAbstract(DssExecLib.mkr());
    address internal immutable MCD_FLAP              = DssExecLib.flap();

    // ---------- Launch Project Funds ----------
    address internal constant LAUNCH_PROJECT_FUNDING = 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F;

    // ---------- Whistleblower Bounty ----------
    address internal constant VENICE_TREE            = 0xCDDd2A697d472d1e8a0B1B188646c756d097b058;

    // ---------- Delegate Compensation ----------
    address internal constant BLUE                   = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;
    address internal constant BONAPUBLICA            = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant CLOAKY                 = 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818;
    address internal constant TRUENAME               = 0x612F7924c367575a0Edf21333D96b15F1B345A5d;
    address internal constant DEFENSOR               = 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9;
    address internal constant JAG                    = 0x58D1ec57E4294E4fe650D1CB12b96AE34349556f;
    address internal constant UPMAKER                = 0xbB819DF169670DC71A16F58F55956FE642cc6BcD;
    address internal constant VIGILANT               = 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61;
    address internal constant PBG                    = 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2;
    address internal constant PIPKIN                 = 0x0E661eFE390aE39f90a58b04CF891044e56DEDB7;
    address internal constant QGOV                   = 0xB0524D8707F76c681901b782372EbeD2d4bA28a6;
    address internal constant WBC                    = 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47;

    // ---------- Trigger Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY            = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    address internal constant SPARK_SPELL            = 0xf3449d6D5827F0F6e0eE4a941f058307056D3736;

    function actions() public override {
        // ---------- Delegate Compensation for February 2024 ----------
        // Forum: https://forum.makerdao.com/t/february-2024-aligned-delegate-compensation/23766

        // BLUE - 41.67 MKR - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        MKR.transfer(BLUE, 41.67 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // BONAPUBLICA - 41.67 MKR - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        MKR.transfer(BONAPUBLICA, 41.67 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // Cloaky - 41.67 MKR - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        MKR.transfer(CLOAKY, 41.67 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // TRUE NAME - 41.67 MKR - 0x612F7924c367575a0Edf21333D96b15F1B345A5d
        MKR.transfer(TRUENAME, 41.67 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // 0xDefensor - 23.71 MKR - 0x9542b441d65B6BF4dDdd3d4D2a66D8dCB9EE07a9
        MKR.transfer(DEFENSOR, 23.71 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // JAG - 13.89 MKR - 0x58D1ec57E4294E4fe650D1CB12b96AE34349556f
        MKR.transfer(JAG, 13.89 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // UPMaker - 13.89 MKR - 0xbB819DF169670DC71A16F58F55956FE642cc6BcD
        MKR.transfer(UPMAKER, 13.89 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // vigilant - 13.89 MKR - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        MKR.transfer(VIGILANT, 13.89 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // PBG - 13.44 MKR - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        MKR.transfer(PBG, 13.44 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // Pipkin - 5.82 MKR - 0x0E661eFE390aE39f90a58b04CF891044e56DEDB7
        MKR.transfer(PIPKIN, 5.82 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // QGov - 4.48 MKR - 0xB0524D8707F76c681901b782372EbeD2d4bA28a6
        MKR.transfer(QGOV, 4.48 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // WBC - 4.03 MKR - 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47
        MKR.transfer(WBC, 4.03 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here


        // ---------- Smart Burn Engine `hop` Update ----------
        // Forum: https://forum.makerdao.com/t/smart-burn-engine-the-rate-of-mkr-accumulation-reconfiguration-and-transaction-analysis-parameter-reconfiguration-update-5/23737
        // Poll: https://vote.makerdao.com/polling/Qmat6oFs

        // Decrease the hop by 6,570 seconds from 26,280 seconds to 19,710 seconds.
        DssExecLib.setValue(MCD_FLAP, "hop", 19_710);


        // ---------- Launch Project Funding ----------
        // Forum: https://forum.makerdao.com/t/utilization-of-the-launch-project-under-the-accessibility-scope/21468/12
        // MIP: https://mips.makerdao.com/mips/details/MIP108#9-launch-project

        // Transfer 3,000,000 DAI to the Launch Project at 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        DssExecLib.sendPaymentFromSurplusBuffer(LAUNCH_PROJECT_FUNDING, 3_000_000);

        // Transfer 500 MKR to the Launch Project at 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        MKR.transfer(LAUNCH_PROJECT_FUNDING, 500.00 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here


        // ---------- Whistleblower Bounty Payment ----------
        // Forum: https://forum.makerdao.com/t/ad-derecognition-due-to-operational-security-breach-02-02-2024/23619/10

        // Transfer 20.84 MKR to whistleblower at 0xCDDd2A697d472d1e8a0B1B188646c756d097b058
        MKR.transfer(VENICE_TREE, 20.84 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here


        // ---------- WBTC vault gap Changes ----------
        // Forum: https://forum.makerdao.com/t/stability-scope-parameter-changes-10-wbtc-a-c-dc-iam-gap/23765

        // Increase the WBTC-A gap by 2 million DAI from 2 million DAI to 4 million DAI
        DssExecLib.setIlkAutoLineParameters("WBTC-A", /* line = */ 500 * MILLION, /* gap = */ 4 * MILLION, /* ttl = */ 24 hours);

        // Increase the WBTC-C gap by 6 million DAI from 2 million DAI to 8 million DAI
        DssExecLib.setIlkAutoLineParameters("WBTC-C", /* line = */ 500 * MILLION, /* gap = */ 8 * MILLION, /* ttl = */ 24 hours);


        // ---------- Spark Proxy Spell ----------
        // Forum: https://forum.makerdao.com/t/feb-22-2024-proposed-changes-to-sparklend-for-upcoming-spell/23739
        // Poll: https://vote.makerdao.com/polling/QmUE5xr8
        // Poll: https://vote.makerdao.com/polling/QmRU6mmi

        // Trigger Spark Proxy Spell at 0xf3449d6D5827F0F6e0eE4a941f058307056D3736
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
