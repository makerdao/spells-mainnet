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

interface StarknetDaiBridgeLike {
    function close() external;
}

interface InputConduitJarLike {
    function push(uint256) external;
}

interface JarLike {
    function void() external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-06-13 MakerDAO Executive Spell | Hash: TODO";

    // Set office hours according to the summary
    function officeHours() public pure override returns (bool) {
        return true;
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
    // uint256 internal constant X_PCT_1000000003022265980097387650RATE = ;

    // ---------- Payment addresses ----------
    address internal constant BLUE                   = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;
    address internal constant CLOAKY                 = 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818;
    address internal constant JULIACHANG             = 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7;
    address internal constant PIPKIN                 = 0x0E661eFE390aE39f90a58b04CF891044e56DEDB7;
    address internal constant BYTERON                = 0xc2982e72D060cab2387Dba96b846acb8c96EfF66;
    address internal constant BONAPUBLICA            = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant WBC                    = 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47;
    address internal constant PBG                    = 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2;
    address internal constant ROCKY                  = 0xC31637BDA32a0811E39456A59022D2C386cb2C85;
    address internal constant VIGILANT               = 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61;
    address internal constant UPMAKER                = 0xbB819DF169670DC71A16F58F55956FE642cc6BcD;
    address internal constant IAMMEEOH               = 0x47f7A5d8D27f259582097E1eE59a07a816982AE9;
    address internal constant DAI_VINCI              = 0x9ee47F0f82F1A6F45C4E1D25Ce95C321D8C8356a;
    address internal constant OPENSKY_2              = 0xf44f97f4113759E0a57756bE49C0655d490Cf19F;
    address internal constant RES                    = 0x8c5c8d76372954922400e4654AF7694e158AB784;
    address internal constant HARMONY_2              = 0xE20A2e231215e9b7Aa308463F1A7490b2ECE55D3;
    address internal constant LIBERTAS               = 0xE1eBfFa01883EF2b4A9f59b587fFf1a5B44dbb2f;
    address internal constant SEEDLATAMETH_2         = 0xd43b89621fFd48A8A51704f85fd0C87CbC0EB299;
    address internal constant ROOT                   = 0xC74392777443a11Dc26Ce8A3D934370514F38A91;
    address internal constant LAUNCH_PROJECT_FUNDING = 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F;

    // ---------- Contracts ----------
    address internal immutable STARKNET_DAI_BRIDGE             = DssExecLib.getChangelogAddress("STARKNET_DAI_BRIDGE");
    address internal immutable MCD_PSM_PAX_A_INPUT_CONDUIT_JAR = DssExecLib.getChangelogAddress("MCD_PSM_PAX_A_INPUT_CONDUIT_JAR");
    address internal immutable MCD_PSM_PAX_A_JAR               = DssExecLib.getChangelogAddress("MCD_PSM_PAX_A_JAR");
    GemAbstract internal immutable MKR                         = GemAbstract(DssExecLib.mkr());

    function actions() public override {
        // ---------- Starknet DAI Bridge Handover ----------
        // Forum: https://forum.makerdao.com/t/starknet-dai-handover/22033/12

        // Call close on STARKNET_DAI_BRIDGE
        StarknetDaiBridgeLike(STARKNET_DAI_BRIDGE).close();

        // ---------- May 2024 AD Compensation ----------
        // Forum: https://forum.makerdao.com/t/may-2024-aligned-delegate-compensation/24441
        // MIP: https://mips.makerdao.com/mips/details/MIP101#2-6-3-aligned-delegate-income-and-participation-requirements

        // BLUE - 41.67 MKR - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        MKR.transfer(BLUE, 41.67 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Cloaky - 41.67 MKR - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        MKR.transfer(CLOAKY, 41.67 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // JuliaChang - 41.67 MKR - 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7
        MKR.transfer(JULIACHANG, 41.67 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Pipkin - 34.26 MKR - 0x0E661eFE390aE39f90a58b04CF891044e56DEDB7
        MKR.transfer(PIPKIN, 34.26 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Byteron - 12.50 MKR - 0xc2982e72D060cab2387Dba96b846acb8c96EfF66
        MKR.transfer(BYTERON, 12.50 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // BONAPUBLICA - 11.11 MKR - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        MKR.transfer(BONAPUBLICA, 11.11 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // WBC - 11.11 MKR - 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47
        MKR.transfer(WBC, 11.11 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // PBG - 8.49 MKR - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        MKR.transfer(PBG, 8.49 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Rocky - 3.70 MKR - 0xC31637BDA32a0811E39456A59022D2C386cb2C85
        MKR.transfer(ROCKY, 3.70 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // vigilant - 2.78 MKR - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        MKR.transfer(VIGILANT, 2.78 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // UPMaker - 1.85 MKR - 0xbB819DF169670DC71A16F58F55956FE642cc6BcD
        MKR.transfer(UPMAKER, 1.85 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // ---------- Q2 2024 AVC Member Compensation ----------
        // Forum: https://forum.makerdao.com/t/avc-member-participation-rewards-q2-2024/24442/1

        // IamMeeoh - 12.51 MKR - 0x47f7A5d8D27f259582097E1eE59a07a816982AE9
        MKR.transfer(IAMMEEOH, 12.51 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // DAI-Vinci - 12.51 MKR - 0x9ee47F0f82F1A6F45C4E1D25Ce95C321D8C8356a
        MKR.transfer(DAI_VINCI, 12.51 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // opensky - 12.51 MKR - 0xf44f97f4113759E0a57756bE49C0655d490Cf19F
        MKR.transfer(OPENSKY_2, 12.51 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Res - 12.51 MKR - 0x8c5c8d76372954922400e4654AF7694e158AB784
        MKR.transfer(RES, 12.51 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Harmony - 12.51 MKR - 0xE20A2e231215e9b7Aa308463F1A7490b2ECE55D3
        MKR.transfer(HARMONY_2, 12.51 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // Libertas - 12.51 MKR - 0xE1eBfFa01883EF2b4A9f59b587fFf1a5B44dbb2f
        MKR.transfer(LIBERTAS, 12.51 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // seedlatam.eth - 12.51 MKR - 0xd43b89621fFd48A8A51704f85fd0C87CbC0EB299
        MKR.transfer(SEEDLATAMETH_2, 12.51 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // 0xRoot - 12.51 MKR - 0xC74392777443a11Dc26Ce8A3D934370514F38A91
        MKR.transfer(ROOT, 12.51 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // ---------- Launch Project Funding ----------
        // Forum: https://forum.makerdao.com/t/utilization-of-the-launch-project-under-the-accessibility-scope/21468/17

        // Transfer 5,000,000 DAI to the Launch Project at 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        DssExecLib.sendPaymentFromSurplusBuffer(LAUNCH_PROJECT_FUNDING, 5_000_000);

        // Transfer 450.00 MKR to the Launch Project at 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        MKR.transfer(LAUNCH_PROJECT_FUNDING, 450.00 ether); // Note: 'ether' is a keyword helper, only MKR is transferred here

        // ---------- Spark Spell ----------
        // Forum: https://forum.makerdao.com/t/may-31-2024-proposed-changes-to-sparklend-for-upcoming-spell/24413
        // Vote: https://vote.makerdao.com/polling/QmPmVeDx

        // Trigger Spark Proxy Spell at ???
        // TODO

        // ---------- USDP Jar Housekeeping ----------
        // Forum: https://forum.makerdao.com/t/proposed-housekeeping-items-upcoming-executive-spell-2024-04-18/24084/4

        // Raise PSM-PAX-A DC to 2,000 DAI
        DssExecLib.setIlkDebtCeiling("PSM-PAX-A", 2_000);

        // Call push() on MCD_PSM_PAX_A_INPUT_CONDUIT_JAR (use push(uint256 amt)) to push 1,159 USDP
        InputConduitJarLike(MCD_PSM_PAX_A_INPUT_CONDUIT_JAR).push(1_159 ether); // Note: `ether` is only a keyword helper

        // Call void() on MCD_PSM_PAX_A_JAR
        JarLike(MCD_PSM_PAX_A_JAR).void();

        // Set PSM-PAX-A DC to 0 DAI
        DssExecLib.setIlkDebtCeiling("PSM-PAX-A", 0);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
