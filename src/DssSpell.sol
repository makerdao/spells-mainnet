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

import { DssInstance, MCD } from "dss-test/MCD.sol";

// Note: source code matches https://github.com/makerdao/dss-flappers/blob/95431f3d4da66babf81c6e1138bd05f5ddc5e516/deploy/FlapperInit.sol
import { FlapperInit, FlapperUniV2Config } from "src/dependencies/dss-flappers/FlapperInit.sol";

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget 'TODO' -q -O - 2>/dev/null)"
    string public constant override description =
        "2024-09-26 MakerDAO Executive Spell | Hash: TODO";

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
    uint256 internal constant WAD      = 10 ** 18;
    uint256 internal constant RAD      = 10 ** 45;

    // ---------- Addesses ----------
    address internal immutable USDS                     = DssExecLib.getChangelogAddress("USDS");
    address internal immutable MCD_SPLIT                = DssExecLib.getChangelogAddress("MCD_SPLIT");
    address internal immutable MCD_VOW                  = DssExecLib.getChangelogAddress("MCD_VOW");
    address internal constant UNIV2USDSSKY              = 0x2621CC0B3F3c079c1Db0E80794AA24976F0b9e3c;
    address internal constant SWAP_ONLY_FLAPPER         = 0x374D9c3d5134052Bc558F432Afa1df6575f07407;
    address internal constant SWAP_ONLY_FLAP_SKY_ORACLE = 0x61A12E5b1d5E9CC1302a32f0df1B5451DE6AE437;

    function actions() public override {
        // Note: DssInstance is required by multiple init libraries below
        DssInstance memory dss = MCD.loadFromChainlog(DssExecLib.LOG);

        // ---------- SBE Updates ----------
        // Forum: https://forum.makerdao.com/t/smart-burn-engine-transaction-analysis-and-parameter-reconfiguration-update-9/25078
        // Poll: https://vote.makerdao.com/polling/QmSxswGN

        // Increase hop by 1386 seconds from 10249 seconds to 11635 seconds
        DssExecLib.setValue(MCD_SPLIT, "hop", 11_635);

        // Decrease bump by 40000 USDS from 65000 USDS to 25000 USDS
        DssExecLib.setValue(MCD_VOW, "bump", 25_000 * RAD);

        FlapperInit.initFlapperUniV2(
            // Note: DssInstance is required by the init library
            dss,

            // Update flapper in splitter from FlapperUniV2 (0x0c10Ae443cCB4604435Ba63DA80CCc63311615Bc) to FlapperUniV2SwapOnly (0x374D9c3d5134052Bc558F432Afa1df6575f07407)
            SWAP_ONLY_FLAPPER,

            FlapperUniV2Config({
                // Set want parameter to 0.98 * WAD
                want: 98 * WAD / 100,

                // Update pip to SWAP_ONLY_FLAP_SKY_ORACLE (0x61A12E5b1d5E9CC1302a32f0df1B5451DE6AE437)
                pip: SWAP_ONLY_FLAP_SKY_ORACLE,

                // Set pair parameter to USDS/SKY UniV2 (0x2621CC0B3F3c079c1Db0E80794AA24976F0b9e3c)
                pair: UNIV2USDSSKY,

                // Note: USDS address is required by the init library
                usds: USDS,

                // Note: Splitter address is required by the init library
                splitter: MCD_SPLIT,

                // Note: This is set to 0 to save gas, since chainlog key doesn't need to be changed
                prevChainlogKey: bytes32(0),

                // Update chainlog value for MCD_FLAP to FlapperUniV2SwapOnly (0x374D9c3d5134052Bc558F432Afa1df6575f07407)
                chainlogKey: "MCD_FLAP"
            })
        );

        FlapperInit.initOracleWrapper(
            // Note: DssInstance is required by the init library
            dss,

            // TODO: add instruction
            SWAP_ONLY_FLAP_SKY_ORACLE,

            // Note: this value is a sanity check to ensure the new oracle correctly operates with SKY
            24_000,

            // TODO: add instruction
            "FLAP_SKY_ORACLE"
        );

        // Note: bump chainlog minor version due to the new flapper contract
        DssExecLib.setChangelogVersion("1.19.0");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}
