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

interface VatLike {
    function Line() external view returns (uint256);
    function file(bytes32 what, uint256 data) external;
    function ilks(bytes32 ilk) external view returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
}

interface VestLike {
    function yank(uint256, uint256) external;
}

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'https://raw.githubusercontent.com/makerdao/community/d9947f3e785e1d9b1d9d24242c9e18fa268926f9/governance/votes/Executive%20vote%20-%20April%2024%2C%202023.md' -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-04-24 MakerDAO Executive Spell | Hash: 0x6306ef3946bf3bcc63e15e5254ea6266b1c8ed54cf9d34b4f18f01d00b3be0fb";

    uint256 internal constant FOUR_NINE_PCT_RATE = 1000000001516911765932351183;

    uint256 internal constant WAD = 10 ** 18;

    address internal constant PE_CONTRIBUTOR = 0x18A0609b14dB84bbcC3d911915a07CA9a28b9263;

    uint256 internal constant END_VEST_TIMESTAMP = 1682899199; // Sun 30 Apr 23:59:59 UTC 2023

    VatLike  internal immutable vat  = VatLike(DssExecLib.vat());
    VestLike internal immutable vest = VestLike(DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY"));

    // Turn office hours off
    function officeHours() public pure override returns (bool) {
        return false;
    }

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

    function actions() public override {

        uint256 lineReduction;
        uint256 line;

        // ---------- RWA008-A Offboarding ----------
        // Poll: N/A
        // Forum: https://forum.makerdao.com/t/security-tokens-refinancing-mip6-application-for-ofh-tokens/10605/51

        // Set RWA008-A Debt Ceiling to 0
        (,,,line,) = vat.ilks("RWA008-A");
        lineReduction += line;
        DssExecLib.setIlkDebtCeiling("RWA008-A", 0);

        // ---------- First Stage of Offboarding ----------
        // Poll: https://vote.makerdao.com/polling/QmPwHhLT
        // Forum: https://forum.makerdao.com/t/decentralized-collateral-scope-parameter-changes-1-april-2023/20302

        // Set YFI-A line to 0
        (,,,line,) = vat.ilks("YFI-A");
        lineReduction += line;
        DssExecLib.removeIlkFromAutoLine("YFI-A");
        DssExecLib.setIlkDebtCeiling("YFI-A", 0);

        // Set MATIC-A line to 0
        (,,,line,) = vat.ilks("MATIC-A");
        lineReduction += line;
        DssExecLib.removeIlkFromAutoLine("MATIC-A");
        DssExecLib.setIlkDebtCeiling("MATIC-A", 0);

        // Set LINK-A line to 0
        (,,,line,) = vat.ilks("LINK-A");
        lineReduction += line;
        DssExecLib.removeIlkFromAutoLine("LINK-A");
        DssExecLib.setIlkDebtCeiling("LINK-A", 0);

        // Decrease Global Debt Ceiling in accordance with Offboarded Ilks
        vat.file("Line", vat.Line() - lineReduction);

        // ---------- Stability Fee Changes ----------
        // Poll: N/A
        // Forum: https://forum.makerdao.com/t/decentralized-collateral-scope-parameter-changes-1-april-2023/20302

        // Increase the WBTC-A Stability Fee from 1.75% to 4.90%
        DssExecLib.setIlkStabilityFee("WBTC-A", FOUR_NINE_PCT_RATE, /* doDrip = */ true);

        // Increase the WBTC-B Stability Fee from 3.25% to 4.90%
        DssExecLib.setIlkStabilityFee("WBTC-B", FOUR_NINE_PCT_RATE, /* doDrip = */ true);

        // Increase the WBTC-C Stability Fee from 1.00% to 4.90%
        DssExecLib.setIlkStabilityFee("WBTC-C", FOUR_NINE_PCT_RATE, /* doDrip = */ true);

        // Increase the GNO-A Stability Fee from 2.50% to 4.90%
        DssExecLib.setIlkStabilityFee("GNO-A",  FOUR_NINE_PCT_RATE, /* doDrip = */ true);

        // ---------- PE MKR Vesting Stream Cleanup ----------

        // PE-001 Contributor - 248 MKR - 0x18A0609b14dB84bbcC3d911915a07CA9a28b9263
        GemLike(DssExecLib.mkr()).transfer(PE_CONTRIBUTOR, 248 * WAD);

        // Yank MKR Stream ID 4 at timestamp 1682899199
        vest.yank(4, END_VEST_TIMESTAMP);

        // Yank MKR Stream ID 5 at timestamp 1682899199
        vest.yank(5, END_VEST_TIMESTAMP);

        // Yank MKR Stream ID 6 at timestamp 1682899199
        vest.yank(6, END_VEST_TIMESTAMP);

        // Yank MKR Stream ID 7 at timestamp 1682899199
        vest.yank(7, END_VEST_TIMESTAMP);

        // Yank MKR Stream ID 10 at timestamp 1682899199
        vest.yank(10, END_VEST_TIMESTAMP);

        // Yank MKR Stream ID 11 at timestamp 1682899199
        vest.yank(11, END_VEST_TIMESTAMP);

        // Yank MKR Stream ID 12 at timestamp 1682899199
        vest.yank(12, END_VEST_TIMESTAMP);

        // Yank MKR Stream ID 14 at timestamp 1682899199
        vest.yank(14, END_VEST_TIMESTAMP);

        // Yank MKR Stream ID 15 at timestamp 1682899199
        vest.yank(15, END_VEST_TIMESTAMP);

        // Yank MKR Stream ID 16 at timestamp 1682899199
        vest.yank(16, END_VEST_TIMESTAMP);

        // Yank MKR Stream ID 17 at timestamp 1682899199
        vest.yank(17, END_VEST_TIMESTAMP);

        // Yank MKR Stream ID 29 at timestamp 1682899199
        vest.yank(29, END_VEST_TIMESTAMP);

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
