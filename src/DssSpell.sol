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

interface InputConduitJarLike {
    function push(uint256) external;
}

interface JarLike {
    function void() external;
}

interface RwaOutputConduitLike {
    function kiss(address) external;
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

    // ---------- Contract addresses ----------
    GemAbstract internal immutable MKR = GemAbstract(DssExecLib.mkr());

    InputConduitJarLike internal immutable MCD_PSM_PAX_A_INPUT_CONDUIT_JAR = InputConduitJarLike(DssExecLib.getChangelogAddress("MCD_PSM_PAX_A_INPUT_CONDUIT_JAR"));
    JarLike internal immutable MCD_PSM_PAX_A_JAR                           = JarLike(DssExecLib.getChangelogAddress("MCD_PSM_PAX_A_JAR"));

    // ----------- Payment addresses -----------
    address internal constant BONAPUBLICA = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant CLOAKY      = 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818;
    address internal constant TRUENAME    = 0x612F7924c367575a0Edf21333D96b15F1B345A5d;
    address internal constant BLUE        = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;
    address internal constant VIGILANT    = 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61;
    address internal constant PIPKIN      = 0x0E661eFE390aE39f90a58b04CF891044e56DEDB7;
    address internal constant JAG         = 0x58D1ec57E4294E4fe650D1CB12b96AE34349556f;
    address internal constant UPMAKER     = 0xbB819DF169670DC71A16F58F55956FE642cc6BcD;

    address internal constant IAMMEEOH       = 0x47f7A5d8D27f259582097E1eE59a07a816982AE9;
    address internal constant DAI_VINCI      = 0x9ee47F0f82F1A6F45C4E1D25Ce95C321D8C8356a;
    address internal constant OPENSKY_2      = 0xf44f97f4113759E0a57756bE49C0655d490Cf19F;
    address internal constant ACREDAOS       = 0xBF9226345F601150F64Ea4fEaAE7E40530763cbd;
    address internal constant RES            = 0x8c5c8d76372954922400e4654AF7694e158AB784;
    address internal constant HARMONY_2      = 0xE20A2e231215e9b7Aa308463F1A7490b2ECE55D3;
    address internal constant LIBERTAS       = 0xE1eBfFa01883EF2b4A9f59b587fFf1a5B44dbb2f;
    address internal constant SEEDLATAMETH_2 = 0xd43b89621fFd48A8A51704f85fd0C87CbC0EB299;
    address internal constant ROOT           = 0xC74392777443a11Dc26Ce8A3D934370514F38A91;

    address internal constant AAVE_V3_TREASURY = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    // ---------- Whitelist new address in the RWA015-A output conduit ----------
    address internal constant RWA015_A_CUSTODY_TACO                 = 0x6759610547a36E9597Ef452aa0B9cace91291a2f;
    RwaOutputConduitLike internal immutable RWA015_A_OUTPUT_CONDUIT = RwaOutputConduitLike(DssExecLib.getChangelogAddress("RWA015_A_OUTPUT_CONDUIT"));

    // ---------- Trigger Spark Proxy Spell ----------
    // Spark Proxy: https://github.com/marsfoundation/sparklend-deployments/blob/bba4c57d54deb6a14490b897c12a949aa035a99b/script/output/1/primary-sce-latest.json#L2
    address internal constant SPARK_PROXY = 0x3300f198988e4C9C63F75dF86De36421f06af8c4;
    // TODO: Update with the correct spell address
    address internal constant SPARK_SPELL = address(0);

    function actions() public override {
        // ---------- AD Compensation ----------
        // Forum: https://forum.makerdao.com/t/march-2024-aligned-delegate-compensation/24088
        // MIP: https://mips.makerdao.com/mips/details/MIP101#2-6-3-aligned-delegate-income-and-participation-requirements

        // BONAPUBLICA - 41.67 MKR - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        MKR.transfer(BONAPUBLICA, 41.67 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // Cloaky - 41.67 MKR - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        MKR.transfer(CLOAKY, 41.67 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // TRUE NAME - 41.67 MKR - 0x612F7924c367575a0Edf21333D96b15F1B345A5d
        MKR.transfer(TRUENAME, 41.67 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // BLUE - 39.75 MKR - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        MKR.transfer(BLUE, 39.75 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // vigilant - 13.89 MKR - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        MKR.transfer(VIGILANT, 13.89 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // Pipkin - 13.89 MKR - 0x0E661eFE390aE39f90a58b04CF891044e56DEDB7
        MKR.transfer(PIPKIN, 13.89 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // JAG - 13.89 MKR - 0x58D1ec57E4294E4fe650D1CB12b96AE34349556f
        MKR.transfer(JAG, 13.89 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // UPMaker - 12.93 MKR - 0xbB819DF169670DC71A16F58F55956FE642cc6BcD
        MKR.transfer(UPMAKER, 12.93 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // ---------- AVC Member Compensation ----------
        // Forum: https://forum.makerdao.com/t/avc-member-participation-rewards-q1-2024/24083
        // MIP: https://mips.makerdao.com/mips/details/MIP101#2-5-10-avc-member-participation-rewards

        // IamMeeoh - 20.85 MKR - 0x47f7A5d8D27f259582097E1eE59a07a816982AE9
        MKR.transfer(IAMMEEOH, 20.85 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // DAI-Vinci - 20.85 MKR - 0x9ee47F0f82F1A6F45C4E1D25Ce95C321D8C8356a
        MKR.transfer(DAI_VINCI, 20.85 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // opensky - 20.85 MKR - 0xf44f97f4113759E0a57756bE49C0655d490Cf19F
        MKR.transfer(OPENSKY_2, 20.85 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // ACRE DAOs - 20.85 MKR - 0xBF9226345F601150F64Ea4fEaAE7E40530763cbd
        MKR.transfer(ACREDAOS, 20.85 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // Res - 20.85 MKR - 0x8c5c8d76372954922400e4654AF7694e158AB784
        MKR.transfer(RES, 20.85 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // Harmony - 20.85 MKR - 0xE20A2e231215e9b7Aa308463F1A7490b2ECE55D3
        MKR.transfer(HARMONY_2, 20.85 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // Libertas - 20.85 MKR - 0xE1eBfFa01883EF2b4A9f59b587fFf1a5B44dbb2f
        MKR.transfer(LIBERTAS, 20.85 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // seedlatam.eth - 20.85 MKR - 0xd43b89621fFd48A8A51704f85fd0C87CbC0EB299
        MKR.transfer(SEEDLATAMETH_2, 20.85 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // 0xRoot - 8.34 MKR - 0xC74392777443a11Dc26Ce8A3D934370514F38A91
        MKR.transfer(ROOT, 8.34 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // ---------- Aave Revenue Share ----------
        // Forum: https://forum.makerdao.com/t/spark-aave-revenue-share-calculation-payment-3-q1-2024/24014

        // Transfer 238,339 DAI to 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c
        DssExecLib.sendPaymentFromSurplusBuffer(AAVE_V3_TREASURY, 238_339);

        // ---------- Whitelist new address in the RWA015-A output conduit ----------
        // Forum: https://forum.makerdao.com/t/proposed-housekeeping-items-upcoming-executive-spell-2024-04-18/24084

        // Call kiss on RWA015_A_OUTPUT_CONDUIT with address 0x6759610547a36E9597Ef452aa0B9cace91291a2f
        RWA015_A_OUTPUT_CONDUIT.kiss(RWA015_A_CUSTODY_TACO);

        // ---------- Push USDP out of input conduit ----------
        // Forum: https://forum.makerdao.com/t/proposed-housekeeping-items-upcoming-executive-spell-2024-04-18/24084

        // Raise PSM-PAX-A DC to 100,000 DAI
        DssExecLib.setIlkDebtCeiling("PSM-PAX-A", 100_000);

        // Call push() on MCD_PSM_PAX_A_INPUT_CONDUIT_JAR (use push(uint256 amt)) to push 84,211.27 USDP
        MCD_PSM_PAX_A_INPUT_CONDUIT_JAR.push(84_211.27 ether); // Note: `ether` is only a keyword helper

        // Call void() on MCD_PSM_PAX_A_JAR
        MCD_PSM_PAX_A_JAR.void();

        // Set PSM-PAX-A DC to 0 DAI to 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c
        DssExecLib.setIlkDebtCeiling("PSM-PAX-A", 0);

        // ---------- Spark Proxy Spell ----------
        // Forum: https://forum.makerdao.com/t/apr-4-2024-proposed-changes-to-sparklend-for-upcoming-spell/24033

        // Trigger Spark Proxy Spell at TBD
        ProxyLike(SPARK_PROXY).exec(SPARK_SPELL, abi.encodeWithSignature("execute()"));
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
