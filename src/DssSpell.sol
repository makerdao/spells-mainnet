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

import { VestAbstract } from "dss-interfaces/dss/VestAbstract.sol";
import { GemAbstract } from "dss-interfaces/ERC/GemAbstract.sol";

interface MkrSkyLike {
    function mkrToSky(address usr, uint256 mkrAmt) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description = "2025-01-23 MakerDAO Executive Spell | Hash: TODO";

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
    // uint256 internal constant X_PCT_RATE = ;

    // ---------- Math ----------
    uint256 internal constant WAD = 10 ** 18;

    // ---------- Timestamps ----------
    // 2025-02-01 00:00:00 UTC
    uint256 internal constant FEB_01_2025 = 1738368000;
    // 2025-12-31 23:59:59 UTC
    uint256 internal constant DEC_31_2025 = 1767225599;

    // ---------- Contracts ----------
    GemAbstract internal immutable MKR              = GemAbstract(DssExecLib.mkr());
    GemAbstract internal immutable SKY              = GemAbstract(DssExecLib.getChangelogAddress("SKY"));
    address internal immutable MCD_PAUSE_PROXY      = DssExecLib.pauseProxy();
    address internal immutable MKR_SKY              = DssExecLib.getChangelogAddress("MKR_SKY");
    address internal constant MCD_VEST_USDS         = 0xc447a9745aDe9A44Bb9E37B7F6C92f9582544110;
    address internal constant MCD_VEST_SKY_TREASURY = 0x67eaDb3288cceDe034cE95b0511DCc65cf630bB6;

    // ---------- Wallets ----------
    address internal constant VOTEWIZARD            = 0x9E72629dF4fcaA2c2F5813FbbDc55064345431b1;
    address internal constant JANSKY                = 0xf3F868534FAD48EF5a228Fe78669cf242745a755;
    address internal constant ECOSYSTEM_FACILITATOR = 0xFCa6e196c2ad557E64D9397e283C2AFe57344b75;

    function actions() public override {
        // ---------- Setup new Suckable USDS vest ----------
        // Forum: https://forum.sky.money/t/proposed-housekeeping-items-upcoming-executive-spell-2025-01-23/25852

        // Authorize new USDS vest (0xc447a9745aDe9A44Bb9E37B7F6C92f9582544110) to access the surplus buffer (MCD_VAT)
        DssExecLib.authorize(DssExecLib.vat(), MCD_VEST_USDS);

        // Set maximum vesting speed (cap) on the new USDS vest to 46,200 USDS per 30 days
        DssExecLib.setValue(MCD_VEST_USDS, "cap", 46_200 * WAD / 30 days);

        // Add new USDS vest (0xc447a9745aDe9A44Bb9E37B7F6C92f9582544110) to chainlog under MCD_VEST_USDS
        DssExecLib.setChangelogAddress("MCD_VEST_USDS", MCD_VEST_USDS);

        // ---------- Setup new Transferrable SKY vest ----------
        // Forum: https://forum.sky.money/t/proposed-housekeeping-items-upcoming-executive-spell-2025-01-23/25852

        // Note: we have to approve MKR_SKY contract to convert MKR into SKY
        MKR.approve(MKR_SKY, 624 * WAD);

        // Convert 624 MKR held in Pause Proxy to SKY (use MKR_SKY contract)
        MkrSkyLike(MKR_SKY).mkrToSky(MCD_PAUSE_PROXY, 624 * WAD);

        // Approve new SKY vest (0x67eaDb3288cceDe034cE95b0511DCc65cf630bB6) to take total 14,968,800 SKY from the treasury (MCD_PAUSE_PROXY)
        SKY.approve(MCD_VEST_SKY_TREASURY, 14_968_800 * WAD);

        // Set maximum vesting speed (cap) on the new SKY vest to 475,200 per 30 days
        DssExecLib.setValue(MCD_VEST_SKY_TREASURY, "cap", 475_200 * WAD / 30 days);

        // Add new SKY vest (0x67eaDb3288cceDe034cE95b0511DCc65cf630bB6) to chainlog under MCD_VEST_SKY_TREASURY
        DssExecLib.setChangelogAddress("MCD_VEST_SKY_TREASURY", MCD_VEST_SKY_TREASURY);

        // ---------- Set Facilitator USDS Payment Streams ----------
        // Atlas: https://sky-atlas.powerhouse.io/A.1.6.2.4.1_List_of_Facilitator_Budgets/c511460d-53df-47e9-a4a5-2e48a533315b%7C0db3343515519c4a

        // EndgameEdge | 2025-02-01 00:00:00 to 2025-12-31 23:59:59 | 462,000 USDS | 0x9E72629dF4fcaA2c2F5813FbbDc55064345431b1
        VestAbstract(MCD_VEST_USDS).restrict(
            VestAbstract(MCD_VEST_USDS).create(
                VOTEWIZARD,                // usr
                462_000 * WAD,             // tot
                FEB_01_2025,               // bgn
                DEC_31_2025 - FEB_01_2025, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // JanSky | 2025-02-01 00:00:00 to 2025-12-31 23:59:59 | 462,000 USDS | 0xf3F868534FAD48EF5a228Fe78669cf242745a755
        VestAbstract(MCD_VEST_USDS).restrict(
            VestAbstract(MCD_VEST_USDS).create(
                JANSKY,                    // usr
                462_000 * WAD,             // tot
                FEB_01_2025,               // bgn
                DEC_31_2025 - FEB_01_2025, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // Ecosystem | 2025-02-01 00:00:00 to 2025-12-31 23:59:59 | 462,000 USDS | 0xFCa6e196c2ad557E64D9397e283C2AFe57344b75
        VestAbstract(MCD_VEST_USDS).restrict(
            VestAbstract(MCD_VEST_USDS).create(
                ECOSYSTEM_FACILITATOR,     // usr
                462_000 * WAD,             // tot
                FEB_01_2025,               // bgn
                DEC_31_2025 - FEB_01_2025, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // ---------- Set Facilitator SKY Payment Streams ----------
        // Atlas: https://sky-atlas.powerhouse.io/A.1.6.2.4.1_List_of_Facilitator_Budgets/c511460d-53df-47e9-a4a5-2e48a533315b%7C0db3343515519c4a

        // EndgameEdge | 2025-02-01 00:00:00 to 2025-12-31 23:59:59 | 4,752,000 SKY | 0x9E72629dF4fcaA2c2F5813FbbDc55064345431b1
        VestAbstract(MCD_VEST_SKY_TREASURY).restrict(
            VestAbstract(MCD_VEST_SKY_TREASURY).create(
                VOTEWIZARD,                // usr
                4_752_000 * WAD,           // tot
                FEB_01_2025,               // bgn
                DEC_31_2025 - FEB_01_2025, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // JanSky | 2025-02-01 00:00:00 to 2025-12-31 23:59:59 | 4,752,000 SKY | 0xf3F868534FAD48EF5a228Fe78669cf242745a755
        VestAbstract(MCD_VEST_SKY_TREASURY).restrict(
            VestAbstract(MCD_VEST_SKY_TREASURY).create(
                JANSKY,                    // usr
                4_752_000 * WAD,           // tot
                FEB_01_2025,               // bgn
                DEC_31_2025 - FEB_01_2025, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // Ecosystem | 2025-02-01 00:00:00 to 2025-12-31 23:59:59 | 4,752,000 SKY | 0xFCa6e196c2ad557E64D9397e283C2AFe57344b75
        VestAbstract(MCD_VEST_SKY_TREASURY).restrict(
            VestAbstract(MCD_VEST_SKY_TREASURY).create(
                ECOSYSTEM_FACILITATOR,     // usr
                4_752_000 * WAD,           // tot
                FEB_01_2025,               // bgn
                DEC_31_2025 - FEB_01_2025, // tau
                0,                         // eta
                address(0)                 // mgr
            )
        );

        // ---------- Chainlog bump ----------

        // Note: Bump chainlog patch version as new keys are being added
        DssExecLib.setChangelogVersion("1.19.5");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
