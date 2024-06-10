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

    function actions() public override {
        // ---------- Starknet DAI Bridge Handover ----------
        // Forum: https://forum.makerdao.com/t/starknet-dai-handover/22033/12

        // Call close on STARKNET_DAI_BRIDGE
        // TODO

        // ---------- May 2024 AD Compensation ----------
        // Forum: https://forum.makerdao.com/t/may-2024-aligned-delegate-compensation/24441
        // MIP: https://mips.makerdao.com/mips/details/MIP101#2-6-3-aligned-delegate-income-and-participation-requirements

        // BLUE - 41.67 MKR - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        // TODO

        // Cloaky - 41.67 MKR - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        // TODO

        // JuliaChang - 41.67 MKR - 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7
        // TODO

        // Pipkin - 34.26 MKR - 0x0E661eFE390aE39f90a58b04CF891044e56DEDB7
        // TODO

        // Byteron - 12.50 MKR - 0xc2982e72D060cab2387Dba96b846acb8c96EfF66
        // TODO

        // BONAPUBLICA - 11.11 MKR - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        // TODO

        // WBC - 11.11 MKR - 0xeBcE83e491947aDB1396Ee7E55d3c81414fB0D47
        // TODO

        // PBG - 8.49 MKR - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        // TODO

        // Rocky - 3.70 MKR - 0xC31637BDA32a0811E39456A59022D2C386cb2C85
        // TODO

        // vigilant - 2.78 MKR - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        // TODO

        // UPMaker - 1.85 MKR - 0xbB819DF169670DC71A16F58F55956FE642cc6BcD
        // TODO

        // ---------- Q2 2024 AVC Member Compensation ----------
        // Forum: https://forum.makerdao.com/t/avc-member-participation-rewards-q2-2024/24442/1

        // IamMeeoh - 12.51 MKR - 0x47f7A5d8D27f259582097E1eE59a07a816982AE9
        // TODO

        // DAI-Vinci - 12.51 MKR - 0x9ee47F0f82F1A6F45C4E1D25Ce95C321D8C8356a
        // TODO

        // opensky - 12.51 MKR - 0xf44f97f4113759E0a57756bE49C0655d490Cf19F
        // TODO

        // Res - 12.51 MKR - 0x8c5c8d76372954922400e4654AF7694e158AB784
        // TODO

        // Harmony - 12.51 MKR - 0xE20A2e231215e9b7Aa308463F1A7490b2ECE55D3
        // TODO

        // Libertas - 12.51 MKR - 0xE1eBfFa01883EF2b4A9f59b587fFf1a5B44dbb2f
        // TODO

        // seedlatam.eth - 12.51 MKR - 0xd43b89621fFd48A8A51704f85fd0C87CbC0EB299
        // TODO

        // 0xRoot - 12.51 MKR - 0xC74392777443a11Dc26Ce8A3D934370514F38A91
        // TODO

        // ---------- Launch Project Funding ----------
        // Forum: https://forum.makerdao.com/t/utilization-of-the-launch-project-under-the-accessibility-scope/21468/17

        // Transfer 5,000,000 DAI to the Launch Project at 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        // TODO

        // Transfer 450.00 MKR to the Launch Project at 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        // TODO

        // ---------- Spark Spell ----------
        // Forum: https://forum.makerdao.com/t/may-31-2024-proposed-changes-to-sparklend-for-upcoming-spell/24413
        // Vote: https://vote.makerdao.com/polling/QmPmVeDx

        // Trigger Spark Proxy Spell at ???
        // TODO

        // ---------- USDP Jar Housekeeping ----------
        // Forum: https://forum.makerdao.com/t/proposed-housekeeping-items-upcoming-executive-spell-2024-04-18/24084/4

        // Raise PSM-PAX-A DC to 2,000 DAI
        // TODO

        // Call push() on MCD_PSM_PAX_A_INPUT_CONDUIT_JAR (use push(uint256 amt)) to push 1,159 USDP
        // TODO

        // Call void() on MCD_PSM_PAX_A_JAR
        // TODO

        // Set PSM-PAX-A DC to 0 DAI
        // TODO
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
