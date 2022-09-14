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

pragma solidity 0.6.12;
// Enable ABIEncoderV2 when onboarding collateral through `DssExecLib.addNewCollateral()`
// pragma experimental ABIEncoderV2;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

// import { DssSpellCollateralAction } from "./DssSpellCollateral.sol";

interface VestLike {
    function restrict(uint256) external;
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function vest(uint256) external;
}

interface RwaLiquidationLike {
    function ilks(bytes32) external returns (string memory, address, uint48, uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/a4eee9428aba7acf79d1b473db0fff7211405d62/governance/votes/Executive%20vote%20-%20September%2014%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-09-14 MakerDAO Executive Spell | Hash: 0xe2f55ebabb2b0a86919f33226ad04586bd8fbc3298ecc4dd33d16aba25649c6b";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // --- Rates ---

    // HVB (RWA009-A) legal update doc
    string constant DOC = "QmQx3bMtjncka2jUsGwKu7ButuPJFn9yDEEvpg9xZ71ECh";

    // wallet addresses
    address internal constant DAIF_WALLET         = 0x34D8d61050Ef9D2B48Ab00e6dc8A8CA6581c5d63;
    address internal constant DAIF_RESERVE_WALLET = 0x5F5c328732c9E52DfCb81067b8bA56459b33921f;
    address internal constant ORA_WALLET          = 0x2d09B7b95f3F312ba6dDfB77bA6971786c5b50Cf;
    address internal constant BIBTA_WALLET        = 0x173d85CD1754daD73cfc673944D9C8BF11A01D3F;
    address internal constant MIP65_WALLET        = 0x29408abeCe474C85a12ce15B05efBB6A1e8587fe;

    // dates (times in GMT)
    uint256 constant JUL_01_2022 = 1656633600; // Friday,   July      1, 2022 12:00:00 AM
    uint256 constant OCT_01_2022 = 1664582400; // Saturday, October   1, 2022 12:00:00 AM
    uint256 constant OCT_31_2022 = 1667260799; // Monday,   October  31, 2022 11:59:59 PM
    uint256 constant NOV_01_2022 = 1667260800; // Tuesday,  November  1, 2022 12:00:00 AM
    uint256 constant JUN_30_2023 = 1688169599; // Friday,   June     30, 2023 11:59:59 PM
    uint256 constant AUG_31_2023 = 1693526399; // Thursday, August   31, 2023 11:59:59 PM
    uint256 constant DEC_31_2022 = 1672531199; // Saturday, December 31, 2022 11:59:59 PM

    // math
    uint256 internal constant WAD = 10**18;

    // Turn office hours off
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralAction
        // onboardNewCollaterals();
        // offboardCollaterals();

        // ---------------------- CU DAI Vesting Streams -----------------------
        // https://vote.makerdao.com/polling/QmQJ9hYq#poll-detail
        VestLike vest = VestLike(
            DssExecLib.getChangelogAddress("MCD_VEST_DAI")
        );

        // https://mips.makerdao.com/mips/details/MIP40c3SP74
        // DAIF-001 | 2022-10-01 to 2022-10-31 | 67,863 DAI
        vest.restrict(
            vest.create(
                DAIF_WALLET,                                             // usr
                67_863 * WAD,                                            // tot
                OCT_01_2022,                                             // bgn
                OCT_31_2022 - OCT_01_2022,                               // tau
                0,                                                       // eta
                address(0)                                               // mgr
            )
        );

        // https://mips.makerdao.com/mips/details/MIP40c3SP74
        // DAIF-001 | 2022-11-01 to 2023-08-31 | 329,192 DAI
        vest.restrict(
            vest.create(
                DAIF_WALLET,                                             // usr
                329_192 * WAD,                                           // tot
                NOV_01_2022,                                             // bgn
                AUG_31_2023 - NOV_01_2022,                               // tau
                0,                                                       // eta
                address(0)                                               // mgr
            )
        );

        // https://mips.makerdao.com/mips/details/MIP40c3SP74
        // DAIF-001 | 2022-10-01 to 2022-12-31 | 270,000 DAI
        vest.restrict(
            vest.create(
                DAIF_RESERVE_WALLET,                                     // usr
                270_000 * WAD,                                           // tot
                OCT_01_2022,                                             // bgn
                DEC_31_2022 - OCT_01_2022,                               // tau
                0,                                                       // eta
                address(0)                                               // mgr
            )
        );

        // https://mips.makerdao.com/mips/details/MIP40c3SP75
        // ORA-001 | 2022-07-01 to 2023-06-30 | 2,337,804 DAI
        vest.restrict(
            vest.create(
                ORA_WALLET,                                              // usr
                2_337_804 * WAD,                                         // tot
                JUL_01_2022,                                             // bgn
                JUN_30_2023 - JUL_01_2022,                               // tau
                0,                                                       // eta
                address(0)                                               // mgr
            )
        );

        // ---------------------- SPF Funding Transfers ------------------------
        // https://forum.makerdao.com/t/mip55c3-sp6-legal-domain-work-on-greenlit-collateral-bibta-special-purpose-fund/17166
        // https://vote.makerdao.com/polling/QmdaG8mo#vote-breakdown
        DssExecLib.sendPaymentFromSurplusBuffer(BIBTA_WALLET, 50_000);
        DssExecLib.sendPaymentFromSurplusBuffer(MIP65_WALLET, 30_000);

        // ------------------- GRO-001 MKR Stream Clean-up ---------------------
        // https://forum.makerdao.com/t/executive-inclusion-gro-001-mkr-vesting-stream-clean-up/17820
        vest = VestLike(
            DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY")
        );
        vest.vest(2);

        // -------------------- Update HVB Legal Documents ---------------------
        // https://forum.makerdao.com/t/poll-inclusion-request-hvbank-legal-update/17547
        // https://vote.makerdao.com/polling/QmX81EhP#vote-breakdown
        bytes32 ilk                      = "RWA009-A";
        address MIP21_LIQUIDATION_ORACLE = DssExecLib.getChangelogAddress(
            "MIP21_LIQUIDATION_ORACLE"
        );

        ( , address pip, uint48 tau, ) = RwaLiquidationLike(
            MIP21_LIQUIDATION_ORACLE
        ).ilks(ilk);

        require(pip != address(0), "Abort spell execution: pip must be set");

        // Init the RwaLiquidationOracle to reset the doc
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(
            ilk,       // ilk to update
            0,         // price ignored if init() has already been called
            DOC,       // new legal document
            tau        // old tau value
        );
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
