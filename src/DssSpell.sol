// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
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

import {Fileable} from "dss-exec-lib/DssExecLib.sol";
import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";
import "dss-interfaces/dss/ClipAbstract.sol";

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/d2eaa6d2b4ac8e286b998e8e1c2177fcd7733e8d/governance/votes/Executive%20vote%20-%20June%2011%2C%202021.md -q -O - 2> /dev/null)"
    string public constant description =
        "2021-06-11 MakerDAO Executive Spell | Hash: 0xDEADBEEF";

    uint256 constant RAY = 10**27;
    uint256 constant RAD = 10**45;

    uint256 constant POINT_FIVE_PCT       = 1000000000158153903837946257;
    uint256 constant ONE_PCT              = 1000000000315522921573372069;
    uint256 constant TWO_PCT              = 1000000000627937192491029810;
    uint256 constant TWO_POINT_FIVE_PCT   = 1000000000782997609082909351;
    uint256 constant THREE_PCT            = 1000000000937303470807876289;
    uint256 constant THREE_POINT_FIVE_PCT = 1000000001090862085746321732;
    uint256 constant FOUR_PCT             = 1000000001243680656318820312;
    uint256 constant NINE_PCT             = 1000000002732676825177582095;

    function actions() public override {
        address MCD_DOG               = DssExecLib.getChangelogAddress("MCD_DOG");
        address YEARN_UNI_OSM_READER  = 0x6987e6471D4e7312914Edce4a6f92737C5fd0A8A;
        address YEARN_LINK_OSM_READER = 0xCd73F1Ed2b1078EA35DAB29a8B35d335e0137c83;
        address YEARN_AAVE_OSM_READER = 0x17b20900320D7C23866203cA6808F857B2b3fdA3;
        address YEARN_COMP_OSM_READER = 0x4e9452CD5ba694de87ea1d791aBfdc4a250800f4;

        // ----------------------------- Ilk AutoLine Updates ---------------------------
        //                                  ilk               DC              gap          ttl
        DssExecLib.setIlkAutoLineParameters("ETH-A",          15_000_000_000, 100_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("ETH-B",             300_000_000,  10_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("ETH-C",           2_000_000_000, 100_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("BAT-A",               7_000_000,   1_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("WBTC-A",            750_000_000,  30_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("ZRX-A",               3_000_000,     500_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("MANA-A",              5_000_000,   1_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("COMP-A",             20_000_000,   2_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("LRC-A",               3_000_000,     500_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("LINK-A",            140_000_000,   7_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("BAL-A",              30_000_000,   3_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("YFI-A",             130_000_000,   7_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNI-A",              50_000_000,   5_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("RENBTC-A",           10_000_000,   1_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("AAVE-A",             50_000_000,   5_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2DAIETH-A",      50_000_000,   5_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2WBTCETH-A",     20_000_000,   3_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2USDCETH-A",     50_000_000,   5_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2DAIUSDC-A",     50_000_000,  10_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2ETHUSDT-A",     10_000_000,   2_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2LINKETH-A",     20_000_000,   2_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2UNIETH-A",      20_000_000,   3_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2WBTCDAI-A",     20_000_000,   3_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2AAVEETH-A",     20_000_000,   2_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2DAIUSDT-A",     10_000_000,   2_000_000, 8 hours);

        // ----------------------------- Stability Fee updates --------------------------
        DssExecLib.setIlkStabilityFee("ETH-A", THREE_POINT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("ETH-B", NINE_PCT, true);
        DssExecLib.setIlkStabilityFee("ETH-C", ONE_PCT, true);
        DssExecLib.setIlkStabilityFee("WBTC-A", THREE_POINT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("LINK-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("YFI-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("UNI-A", TWO_PCT, true);
        DssExecLib.setIlkStabilityFee("AAVE-A", TWO_PCT, true);
        DssExecLib.setIlkStabilityFee("BAT-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("RENBTC-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2DAIETH-A", TWO_POINT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2USDCETH-A", THREE_POINT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2WBTCETH-A", THREE_POINT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2UNIETH-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2ETHUSDT-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2LINKETH-A", THREE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2AAVEETH-A", THREE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2DAIUSDT-A", TWO_PCT, true);

        // ----------------------------- UNIV2DAIUSDC-A SF and CR -----------------------
        DssExecLib.setIlkLiquidationRatio("UNIV2DAIUSDC-A", 10200);
        DssExecLib.setIlkStabilityFee("UNIV2DAIUSDC-A", POINT_FIVE_PCT, true);

        // ----------------------------- ETH Auction Params -----------------------------
        Fileable(MCD_DOG).file("ETH-A", "hole", 30_000_000 * RAD);
        Fileable(MCD_DOG).file("ETH-B", "hole", 15_000_000 * RAD);
        Fileable(MCD_DOG).file("ETH-C", "hole", 20_000_000 * RAD);
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_CALC_ETH_B")).file(
            "step", 60 seconds
        );
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_ETH_B")).file(
            "buf", 120 * RAY / 100
        );

        // ----------------------------- Yearn OSM Whitelist ----------------------------
        DssExecLib.addReaderToOSMWhitelist(
            DssExecLib.getChangelogAddress("PIP_UNI"), YEARN_UNI_OSM_READER
        );
        DssExecLib.addReaderToOSMWhitelist(
            DssExecLib.getChangelogAddress("PIP_LINK"), YEARN_LINK_OSM_READER
        );
        DssExecLib.addReaderToOSMWhitelist(
            DssExecLib.getChangelogAddress("PIP_AAVE"), YEARN_AAVE_OSM_READER
        );
        DssExecLib.addReaderToOSMWhitelist(
            DssExecLib.getChangelogAddress("PIP_COMP"), YEARN_COMP_OSM_READER
        );
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
