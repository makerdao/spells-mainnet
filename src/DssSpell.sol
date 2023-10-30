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

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/344c183374c0cd9a91ec3537d0bbb0cb0c59945a/governance/votes/Executive%20Vote%20-%20October%2011%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-11-01 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return false;
    }

    // ----- USDP-PSM Facilitation Incentives -----
    // Forum: https://forum.makerdao.com/t/usdp-psm-facilitation-incentives/22331
    // Approve DAO Resolution hash QmWg43PNNGfEyXnTv1qN8dRXFJz5ZchrmZU8qH57Ki6D62

    // Comma-separated list of DAO resolutions IPFS hashes.
    string public constant dao_resolutions = "QmbrCPtpKsCaQ2pKc8qLnkL8TywRYcKHYaX6LEzhhKQqAw";

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

    GemLike  internal immutable MKR                        = GemLike(DssExecLib.mkr());

    address internal immutable MCD_ESM                         = DssExecLib.esm();

    address constant internal AAVE_GOVERNANCE_SUPPORT      = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;
    address constant internal IS_WALLET                    = 0xd1F2eEf8576736C1EbA36920B957cd2aF07280F4;

    address constant internal MCD_PSM_GUSD_A_JAR                = 0xf2E7a5B83525c3017383dEEd19Bb05Fe34a62C27;
    address constant internal MCD_PSM_GUSD_A_INPUT_CONDUIT_JAR  = 0x6934218d8B3E9ffCABEE8cd80F4c1C4167Afa638;
    address constant internal MCD_PSM_PAX_A_JAR                 = 0x8bF8b5C58bb57Ee9C97D0FEA773eeE042B10a787;
    address constant internal MCD_PSM_PAX_A_INPUT_CONDUIT_JAR   = 0xDa276Ab5F1505965e0B6cD1B6da2A18CcBB29515;

    function actions() public override {

        // ---------- Spark - AAVE Revenue Share Payment ----------
        // Forum: https://forum.makerdao.com/t/spark-aave-revenue-share-calculation-payment-1-q3-2023/22486
        // MIP: https://mips.makerdao.com/mips/details/MIP106#9-4-1-spark-protocol-aave-revenue-share

        // Send 2889 DAI from Surplus Buffer to 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c
        DssExecLib.sendPaymentFromSurplusBuffer(AAVE_GOVERNANCE_SUPPORT, 2889);

        // ---------- Immunefi CU MKR Vesting Transfer ----------
        // Immunefi CU - 6.34 MKR - 0xd1F2eEf8576736C1EbA36920B957cd2aF07280F4
        // Forum: https://forum.makerdao.com/t/mip39c3-sp13-removing-is-001/22392
        // MIP: https://mips.makerdao.com/mips/details/MIP40c3SP41#sentence-summary
        MKR.transfer(IS_WALLET, 6.34 ether); // NOTE: 'ether' is a keyword helper, only MKR is transferred here

        // ---------- Housekeeping - GUSD & USDP - Add Jar & Conduit Contracts to Chainlog ----------
        // Forum: https://forum.makerdao.com/t/proposed-housekeeping-items-upcoming-executive-spell-2023-11-01/22477

        // Add `RwaJar` at 0xf2E7a5B83525c3017383dEEd19Bb05Fe34a62C27 as MCD_PSM_GUSD_A_JAR
        DssExecLib.setChangelogAddress("MCD_PSM_GUSD_A_JAR", MCD_PSM_GUSD_A_JAR);

        // Add `RwaSwapInputOutputConduit2` at 0x6934218d8B3E9ffCABEE8cd80F4c1C4167Afa638 as MCD_PSM_GUSD_A_INPUT_CONDUIT_JAR
        DssExecLib.setChangelogAddress("MCD_PSM_GUSD_A_INPUT_CONDUIT_JAR", MCD_PSM_GUSD_A_INPUT_CONDUIT_JAR);

        // Add `RwaJar` at 0x8bF8b5C58bb57Ee9C97D0FEA773eeE042B10a787 as MCD_PSM_PAX_A_JAR
        DssExecLib.setChangelogAddress("MCD_PSM_PAX_A_JAR", MCD_PSM_PAX_A_JAR);

        // Add `RwaSwapInputConduit2` at 0xDa276Ab5F1505965e0B6cD1B6da2A18CcBB29515 as MCD_PSM_PAX_A_INPUT_CONDUIT_JAR
        DssExecLib.setChangelogAddress("MCD_PSM_PAX_A_INPUT_CONDUIT_JAR", MCD_PSM_PAX_A_INPUT_CONDUIT_JAR);

        // Authorize ESM
        DssExecLib.authorize(MCD_PSM_GUSD_A_INPUT_CONDUIT_JAR, MCD_ESM);
        DssExecLib.authorize(MCD_PSM_PAX_A_INPUT_CONDUIT_JAR, MCD_ESM);

        // Bump chainlog as it has been modified.
        DssExecLib.setChangelogVersion("1.17.1");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
