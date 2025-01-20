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
    function mkrToSky(address usr, uint256 wad) external;
    function rate() external view returns (uint256);
}

interface DaiUsdsLike {
    function daiToUsds(address usr, uint256 wad) external;
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

    // Note: by the previous convention it should be a comma-separated list of DAO resolutions IPFS hashes
    string public constant dao_resolutions = "bafkreieqcricvrwb7ndxep6unlhhm6iie3dlkr3cl4tdypinjws4pycalq";

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
    uint256 internal constant ELEVEN_PT_TWO_FIVE_PCT_RATE = 1000000003380572527855758393;

    // ---------- Math ----------
    uint256 internal constant WAD = 10 ** 18;

    // ---------- Timestamps ----------
    // 2025-02-01 00:00:00 UTC
    uint256 internal constant FEB_01_2025 = 1738368000;
    // 2025-12-31 23:59:59 UTC
    uint256 internal constant DEC_31_2025 = 1767225599;

    // ---------- Contracts ----------
    GemAbstract internal immutable DAI              = GemAbstract(DssExecLib.dai());
    GemAbstract internal immutable MKR              = GemAbstract(DssExecLib.mkr());
    GemAbstract internal immutable SKY              = GemAbstract(DssExecLib.getChangelogAddress("SKY"));
    address internal immutable DAI_USDS             = DssExecLib.getChangelogAddress("DAI_USDS");
    address internal immutable MKR_SKY              = DssExecLib.getChangelogAddress("MKR_SKY");
    address internal constant MCD_VEST_USDS         = 0xc447a9745aDe9A44Bb9E37B7F6C92f9582544110;
    address internal constant MCD_VEST_SKY_TREASURY = 0x67eaDb3288cceDe034cE95b0511DCc65cf630bB6;

    // ---------- Constant Values ----------
    uint256 internal immutable MKR_SKY_RATE = MkrSkyLike(DssExecLib.getChangelogAddress("MKR_SKY")).rate();

    // ---------- Wallets ----------
    address internal constant LAUNCH_PROJECT_FUNDING       = 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F;
    address internal constant INTEGRATION_BOOST_INITIATIVE = 0xD6891d1DFFDA6B0B1aF3524018a1eE2E608785F7;
    address internal constant BLUE                         = 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf;
    address internal constant BONAPUBLICA                  = 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3;
    address internal constant CLOAKY                       = 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818;
    address internal constant JULIACHANG                   = 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7;
    address internal constant VIGILANT                     = 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61;
    address internal constant PBG                          = 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2;
    address internal constant BYTERON                      = 0xc2982e72D060cab2387Dba96b846acb8c96EfF66;
    address internal constant CLOAKY_KOHLA_2               = 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a;
    address internal constant CLOAKY_ENNOIA                = 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b;
    address internal constant VOTEWIZARD                   = 0x9E72629dF4fcaA2c2F5813FbbDc55064345431b1;
    address internal constant JANSKY                       = 0xf3F868534FAD48EF5a228Fe78669cf242745a755;
    address internal constant ECOSYSTEM_FACILITATOR        = 0xFCa6e196c2ad557E64D9397e283C2AFe57344b75;
    address internal constant AAVE_V3_TREASURY             = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    function actions() public override {
        // ---------- Savings Rate Changes ----------
        // Forum: TODO

        // Decrease DSR by 0.25 percentage points from 11.50% to 11.25%
        DssExecLib.setDSR(ELEVEN_PT_TWO_FIVE_PCT_RATE, /* doDrip = */ true);

        // ---------- Launch Project Funding ----------
        // Forum: https://forum.sky.money/t/utilization-of-the-launch-project-under-the-accessibility-scope/21468/27?u=ecosystem-team
        // Atlas: https://sky-atlas.powerhouse.io/A.5.6_Launch_Project/1f433d9d-7cdb-406f-b7e8-f9bc4855eb77%7C8d5a

        // Transfer 10,000,000 USDS to 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        _transferUsds(LAUNCH_PROJECT_FUNDING, 10_000_000 * WAD);

        // Transfer 24,000,000 SKY to 0x3C5142F28567E6a0F172fd0BaaF1f2847f49D02F
        _transferSky(LAUNCH_PROJECT_FUNDING, 24_000_000 * WAD);

        // ---------- Integration Boost Funding ----------
        // Forum: https://forum.sky.money/t/utilization-of-the-integration-boost-budget-a-5-2-1-2/25536/4?u=ecosystem-team
        // Atlas: https://sky-atlas.powerhouse.io/A.5.2.1.2_Integration_Boost/129f2ff0-8d73-8057-850b-d32304e9c91a%7C8d5a9e88cf49

        // Integration Boost - 2,500,000 USDS - 0xD6891d1DFFDA6B0B1aF3524018a1eE2E608785F7
        _transferUsds(INTEGRATION_BOOST_INITIATIVE, 2_500_000 * WAD);

        // ---------- December 2024 AD USDS Compensation ----------
        // Forum: https://forum.sky.money/t/december-2024-aligned-delegate-compensation/25854
        // Atlas: https://sky-atlas.powerhouse.io/A.1.5.8_Budget_For_Prime_Delegate_Slots/e3e420fc-9b1f-4fdc-9983-fcebc45dd3aa%7C0db3af4ece0c

        // BLUE - 4,000 USDS - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferUsds(BLUE, 4_000 * WAD);

        // Bonapublica - 4,000 USDS - 0x167c1a762B08D7e78dbF8f24e5C3f1Ab415021D3
        _transferUsds(BONAPUBLICA, 4_000 * WAD);

        // Cloaky - 4,000 USDS - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        _transferUsds(CLOAKY, 4_000 * WAD);

        // JuliaChang - 4,000 USDS - 0x252abAEe2F4f4b8D39E5F12b163eDFb7fac7AED7
        _transferUsds(JULIACHANG, 4_000 * WAD);

        // vigilant - 4,000 USDS - 0x2474937cB55500601BCCE9f4cb0A0A72Dc226F61
        _transferUsds(VIGILANT, 4_000 * WAD);

        // PBG - 3,467 USDS - 0x8D4df847dB7FfE0B46AF084fE031F7691C6478c2
        _transferUsds(PBG, 3_467 * WAD);

        // Byteron - 1,935 USDS - 0xc2982e72D060cab2387Dba96b846acb8c96EfF66
        _transferUsds(BYTERON, 1_935 * WAD);

        // ---------- Atlas Core Development USDS Payments ----------
        // Forum: https://forum.sky.money/t/atlas-core-development-payment-requests-january-2025/25842

        // BLUE (Team) - 83,602 USDS - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferUsds(BLUE, 83_602 * WAD);

        // Kohla (Cloaky) - 10,000 USDS - 0x73dFC091Ad77c03F2809204fCF03C0b9dccf8c7a
        _transferUsds(CLOAKY_KOHLA_2, 10_000 * WAD);

        // Ennoia (Cloaky) - 10,000 USDS - 0xA7364a1738D0bB7D1911318Ca3FB3779A8A58D7b
        _transferUsds(CLOAKY_ENNOIA, 10_000 * WAD);

        // Cloaky (Team) - 18,836 USDS - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        _transferUsds(CLOAKY, 18_836 * WAD);

        // ---------- Atlas Core Development SKY Payments ----------
        // Forum: https://forum.sky.money/t/atlas-core-development-payment-requests-january-2025/25842
        // Atlas: https://sky-atlas.powerhouse.io/A.2.2.1_Atlas_Core_Development/1542d2db-be91-46f5-9d13-3a86c78b9af1%7C9e1f3b56

        // BLUE (Team) - 550,000 SKY - 0xb6C09680D822F162449cdFB8248a7D3FC26Ec9Bf
        _transferSky(BLUE, 550_000 * WAD);

        // Cloaky (Team) - 438,000 SKY - 0x869b6d5d8FA7f4FFdaCA4D23FFE0735c5eD1F818
        _transferSky(CLOAKY, 438_000 * WAD);

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
        MkrSkyLike(MKR_SKY).mkrToSky(address(this), 624 * WAD);

        // Approve new SKY vest (0x67eaDb3288cceDe034cE95b0511DCc65cf630bB6) to take total 14,256,000 SKY from the treasury (MCD_PAUSE_PROXY)
        SKY.approve(MCD_VEST_SKY_TREASURY, 14_256_000 * WAD);

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

        // ---------- Spark - AAVE Q4 Revenue Share Payment ----------
        // Forum: https://forum.sky.money/t/spark-aave-revenue-share-calculations-payments-6-q4-2024/25820

        // AAVE Revenue Share - 314,567 DAI - 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c
        DssExecLib.sendPaymentFromSurplusBuffer(AAVE_V3_TREASURY, 314_567);

        // ---------- TACO DAO Resolution ----------
        // Forum: https://forum.sky.money/t/project-andromeda-risk-legal-assessment/20969/12?u=steakhouse

        // Approve DAO Resolution with IPFS hash bafkreieqcricvrwb7ndxep6unlhhm6iie3dlkr3cl4tdypinjws4pycalq
        // Note: see `dao_resolutions` public variable declared above

        // ---------- Spark Proxy Spell ----------
        // Forum: https://forum.sky.money/t/jan-23-2025-proposed-changes-to-spark-for-upcoming-spell/25825
        // Poll: https://vote.makerdao.com/polling/QmRAavx5
        // Poll: https://vote.makerdao.com/polling/QmY4D1u8
        // Poll: https://vote.makerdao.com/polling/QmU3Xu4W
        // Forum: https://forum.sky.money/t/jan-23-2025-proposed-changes-to-spark-for-upcoming-spell-2/25837/3

        // Execute Spark Proxy Spell at TBC
        // TODO

        // ---------- Chainlog bump ----------

        // Note: Bump chainlog patch version as new keys are being added
        DssExecLib.setChangelogVersion("1.19.5");
    }

    /// @notice wraps the operations required to transfer USDS from the surplus buffer.
    /// @param usr The USDS receiver.
    /// @param wad The USDS amount in wad precision (10 ** 18).
    function _transferUsds(address usr, uint256 wad) internal {
        // Note: Enforce whole units to avoid rounding errors
        require(wad % WAD == 0, "transferUsds/non-integer-wad");
        // Note: DssExecLib currently only supports Dai transfers from the surplus buffer.
        DssExecLib.sendPaymentFromSurplusBuffer(address(this), wad / WAD);
        // Note: Approve DAI_USDS for the amount sent to be able to convert it.
        DAI.approve(DAI_USDS, wad);
        // Note: Convert Dai to USDS for `usr`.
        DaiUsdsLike(DAI_USDS).daiToUsds(usr, wad);
    }

    /// @notice wraps the operations required to transfer SKY from the treasury.
    /// @param usr The SKY receiver.
    /// @param wad The SKY amount in wad precision (10 ** 18).
    function _transferSky(address usr, uint256 wad) internal {
        // Note: Calculate the equivalent amount of MKR required
        uint256 mkrWad = wad / MKR_SKY_RATE;
        // Note: if rounding error is expected, add an extra wei of MKR
        if (wad % MKR_SKY_RATE != 0) { mkrWad++; }
        // Note: Approve MKR_SKY for the amount sent to be able to convert it
        MKR.approve(MKR_SKY, mkrWad);
        // Note: Convert the calculated amount to SKY for `PAUSE_PROXY`
        MkrSkyLike(MKR_SKY).mkrToSky(address(this), mkrWad);
        // Note: Transfer originally requested amount, leaving extra on the `PAUSE_PROXY`
        SKY.transfer(usr, wad);
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
