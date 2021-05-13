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

import {Fileable, ChainlogLike} from "dss-exec-lib/DssExecLib.sol";
import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";
import "dss-interfaces/dss/DssAutoLineAbstract.sol";

struct Collateral {
    bytes32 ilk;
    address vat;
    address vow;
    address spotter;
    address cat;
    address dog;
    address end;
    address esm;
    address flipperMom;
    address clipperMom;
    address ilkRegistry;
    address pip;
    address clipper;
    address flipper;
    address calc;
    uint256 hole;
    uint256 chop;
    uint256 buf;
    uint256 tail;
    uint256 cusp;
    uint256 chip;
    uint256 tip;
    uint256 cut;
    uint256 step;
    uint256 tolerance;
    bytes32 clipKey;
    bytes32 calcKey;
    bytes32 flipKey;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community//governance/votes/Executive%20vote%20-%20May%214%2C%202021.md -q -O - 2> /dev/null)"
    string public constant description =
        "2021-05-14 MakerDAO Executive Spell | Hash: ";

    address constant PIP_UNIV2DAIETH  = address(0);
    address constant PIP_UNIV2WBTCETH = address(0);
    address constant PIP_UNIV2USDCETH = address(0);
    address constant PIP_UNIV2DAIUSDC = address(0);
    address constant PIP_UNIV2ETHUSDT = address(0);
    address constant PIP_UNIV2LINKETH = address(0);
    address constant PIP_UNIV2UNIETH  = address(0);
    address constant PIP_UNIV2WBTCDAI = address(0);
    address constant PIP_UNIV2AAVEETH = address(0);
    address constant PIP_UNIV2DAIUSDT = address(0);

    uint256 constant ONE_PCT   = 1000000000315522921573372069;
    uint256 constant THREE_PCT = 1000000000937303470807876289;
    uint256 constant FIVE_PCT  = 1000000001547125957863212448;

    uint256 constant MILLION = 10 ** 6;

    function actions() public override {
        address MCD_SPOT = DssExecLib.spotter();
        address MCD_END  = DssExecLib.end();
        address OSM_MOM  = DssExecLib.osmMom();

        // ----------------------------- Stability Fee updates ----------------------------
        DssExecLib.setIlkStabilityFee("KNC-A", FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("TUSD-A", ONE_PCT, true);
        DssExecLib.setIlkStabilityFee("PAXUSD-A", ONE_PCT, true);
        DssExecLib.setIlkStabilityFee("ETH-C", THREE_PCT, true);

        // ------------------------------ Debt ceiling updates -----------------------------
        DssExecLib.setIlkAutoLineDebtCeiling("KNC-A", 0);
        DssAutoLineAbstract(DssExecLib.autoLine()).exec("KNC-A"); // Sets line to 0 and decreases global one
        DssExecLib.setIlkDebtCeiling("PAXUSD-A", 0); // -100M
        DssExecLib.setIlkDebtCeiling("USDC-B", 0); // -30M
        DssExecLib.decreaseGlobalDebtCeiling(130 * MILLION);

        // --------------------------------- UNIV2DAIETH-A ---------------------------------
        DssExecLib.setContract(MCD_SPOT, "UNIV2DAIETH-A", "pip", PIP_UNIV2DAIETH);
        DssExecLib.authorize(PIP_UNIV2DAIETH, OSM_MOM);
        DssExecLib.addReaderToMedianWhitelist(LPOsmAbstract(PIP_UNIV2DAIETH).orb1(), PIP_UNIV2DAIETH);
        DssExecLib.removeReaderFromMedianWhitelist(LPOsmAbstract(PIP_UNIV2DAIETH).orb1(), DssExecLib.getChangelogAddress("PIP_UNIV2DAIETH"));
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2DAIETH, MCD_SPOT);
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2DAIETH, MCD_END);
        DssExecLib.allowOSMFreeze(PIP_UNIV2DAIETH, "UNIV2DAIETH-A");
        DssExecLib.setChangelogAddress("PIP_UNIV2DAIETH", PIP_UNIV2DAIETH);

        // --------------------------------- UNIV2WBTCETH-A ---------------------------------
        DssExecLib.setContract(MCD_SPOT, "UNIV2WBTCETH-A", "pip", PIP_UNIV2WBTCETH);
        DssExecLib.authorize(PIP_UNIV2WBTCETH, OSM_MOM);
        DssExecLib.addReaderToMedianWhitelist(LPOsmAbstract(PIP_UNIV2WBTCETH).orb0(), PIP_UNIV2WBTCETH);
        DssExecLib.addReaderToMedianWhitelist(LPOsmAbstract(PIP_UNIV2WBTCETH).orb1(), PIP_UNIV2WBTCETH);
        DssExecLib.removeReaderFromMedianWhitelist(LPOsmAbstract(PIP_UNIV2WBTCETH).orb0(), DssExecLib.getChangelogAddress("PIP_UNIV2WBTCETH"));
        DssExecLib.removeReaderFromMedianWhitelist(LPOsmAbstract(PIP_UNIV2WBTCETH).orb1(), DssExecLib.getChangelogAddress("PIP_UNIV2WBTCETH"));
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2WBTCETH, MCD_SPOT);
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2WBTCETH, MCD_END);
        DssExecLib.allowOSMFreeze(PIP_UNIV2WBTCETH, "UNIV2WBTCETH-A");
        DssExecLib.setChangelogAddress("PIP_UNIV2WBTCETH", PIP_UNIV2WBTCETH);

        // --------------------------------- UNIV2USDCETH-A ---------------------------------
        DssExecLib.setContract(MCD_SPOT, "UNIV2USDCETH-A", "pip", PIP_UNIV2USDCETH);
        DssExecLib.authorize(PIP_UNIV2USDCETH, OSM_MOM);
        DssExecLib.addReaderToMedianWhitelist(LPOsmAbstract(PIP_UNIV2USDCETH).orb1(), PIP_UNIV2USDCETH);
        DssExecLib.removeReaderFromMedianWhitelist(LPOsmAbstract(PIP_UNIV2USDCETH).orb1(), DssExecLib.getChangelogAddress("PIP_UNIV2USDCETH"));
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2USDCETH, MCD_SPOT);
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2USDCETH, MCD_END);
        DssExecLib.allowOSMFreeze(PIP_UNIV2USDCETH, "UNIV2USDCETH-A");
        DssExecLib.setChangelogAddress("PIP_UNIV2USDCETH", PIP_UNIV2USDCETH);

        // --------------------------------- UNIV2DAIUSDC-A ---------------------------------
        DssExecLib.setContract(MCD_SPOT, "UNIV2DAIUSDC-A", "pip", PIP_UNIV2DAIUSDC);
        DssExecLib.authorize(PIP_UNIV2DAIUSDC, OSM_MOM);
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2DAIUSDC, MCD_SPOT);
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2DAIUSDC, MCD_END);
        DssExecLib.allowOSMFreeze(PIP_UNIV2DAIUSDC, "UNIV2DAIUSDC-A");
        DssExecLib.setChangelogAddress("PIP_UNIV2DAIUSDC", PIP_UNIV2DAIUSDC);

        // --------------------------------- UNIV2ETHUSDT-A ---------------------------------
        DssExecLib.setContract(MCD_SPOT, "UNIV2ETHUSDT-A", "pip", PIP_UNIV2ETHUSDT);
        DssExecLib.authorize(PIP_UNIV2ETHUSDT, OSM_MOM);
        DssExecLib.addReaderToMedianWhitelist(LPOsmAbstract(PIP_UNIV2ETHUSDT).orb0(), PIP_UNIV2ETHUSDT);
        DssExecLib.addReaderToMedianWhitelist(LPOsmAbstract(PIP_UNIV2ETHUSDT).orb1(), PIP_UNIV2ETHUSDT);
        DssExecLib.removeReaderFromMedianWhitelist(LPOsmAbstract(PIP_UNIV2ETHUSDT).orb0(), DssExecLib.getChangelogAddress("PIP_UNIV2ETHUSDT"));
        DssExecLib.removeReaderFromMedianWhitelist(LPOsmAbstract(PIP_UNIV2ETHUSDT).orb1(), DssExecLib.getChangelogAddress("PIP_UNIV2ETHUSDT"));
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2ETHUSDT, MCD_SPOT);
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2ETHUSDT, MCD_END);
        DssExecLib.allowOSMFreeze(PIP_UNIV2ETHUSDT, "UNIV2ETHUSDT-A");
        DssExecLib.setChangelogAddress("PIP_UNIV2ETHUSDT", PIP_UNIV2ETHUSDT);

        // --------------------------------- UNIV2LINKETH-A ---------------------------------
        DssExecLib.setContract(MCD_SPOT, "UNIV2LINKETH-A", "pip", PIP_UNIV2LINKETH);
        DssExecLib.authorize(PIP_UNIV2LINKETH, OSM_MOM);
        DssExecLib.addReaderToMedianWhitelist(LPOsmAbstract(PIP_UNIV2LINKETH).orb0(), PIP_UNIV2LINKETH);
        DssExecLib.addReaderToMedianWhitelist(LPOsmAbstract(PIP_UNIV2LINKETH).orb1(), PIP_UNIV2LINKETH);
        DssExecLib.removeReaderFromMedianWhitelist(LPOsmAbstract(PIP_UNIV2LINKETH).orb0(), DssExecLib.getChangelogAddress("PIP_UNIV2LINKETH"));
        DssExecLib.removeReaderFromMedianWhitelist(LPOsmAbstract(PIP_UNIV2LINKETH).orb1(), DssExecLib.getChangelogAddress("PIP_UNIV2LINKETH"));
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2LINKETH, MCD_SPOT);
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2LINKETH, MCD_END);
        DssExecLib.allowOSMFreeze(PIP_UNIV2LINKETH, "UNIV2LINKETH-A");
        DssExecLib.setChangelogAddress("PIP_UNIV2LINKETH", PIP_UNIV2LINKETH);

        // --------------------------------- UNIV2UNIETH-A ---------------------------------
        DssExecLib.setContract(MCD_SPOT, "UNIV2UNIETH-A", "pip", PIP_UNIV2UNIETH);
        DssExecLib.authorize(PIP_UNIV2UNIETH, OSM_MOM);
        DssExecLib.addReaderToMedianWhitelist(LPOsmAbstract(PIP_UNIV2UNIETH).orb0(), PIP_UNIV2UNIETH);
        DssExecLib.addReaderToMedianWhitelist(LPOsmAbstract(PIP_UNIV2UNIETH).orb1(), PIP_UNIV2UNIETH);
        DssExecLib.removeReaderFromMedianWhitelist(LPOsmAbstract(PIP_UNIV2UNIETH).orb0(), DssExecLib.getChangelogAddress("PIP_UNIV2UNIETH"));
        DssExecLib.removeReaderFromMedianWhitelist(LPOsmAbstract(PIP_UNIV2UNIETH).orb1(), DssExecLib.getChangelogAddress("PIP_UNIV2UNIETH"));
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2UNIETH, MCD_SPOT);
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2UNIETH, MCD_END);
        DssExecLib.allowOSMFreeze(PIP_UNIV2UNIETH, "UNIV2UNIETH-A");
        DssExecLib.setChangelogAddress("PIP_UNIV2UNIETH", PIP_UNIV2UNIETH);

        // --------------------------------- UNIV2WBTCDAI-A ---------------------------------
        DssExecLib.setContract(MCD_SPOT, "UNIV2WBTCDAI-A", "pip", PIP_UNIV2WBTCDAI);
        DssExecLib.authorize(PIP_UNIV2WBTCDAI, OSM_MOM);
        DssExecLib.addReaderToMedianWhitelist(LPOsmAbstract(PIP_UNIV2WBTCDAI).orb0(), PIP_UNIV2WBTCDAI);
        DssExecLib.removeReaderFromMedianWhitelist(LPOsmAbstract(PIP_UNIV2WBTCDAI).orb0(), DssExecLib.getChangelogAddress("PIP_UNIV2WBTCDAI"));
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2WBTCDAI, MCD_SPOT);
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2WBTCDAI, MCD_END);
        DssExecLib.allowOSMFreeze(PIP_UNIV2WBTCDAI, "UNIV2WBTCDAI-A");
        DssExecLib.setChangelogAddress("PIP_UNIV2WBTCDAI", PIP_UNIV2WBTCDAI);

        // --------------------------------- UNIV2AAVEETH-A ---------------------------------
        DssExecLib.setContract(MCD_SPOT, "UNIV2AAVEETH-A", "pip", PIP_UNIV2AAVEETH);
        DssExecLib.authorize(PIP_UNIV2AAVEETH, OSM_MOM);
        DssExecLib.addReaderToMedianWhitelist(LPOsmAbstract(PIP_UNIV2AAVEETH).orb0(), PIP_UNIV2AAVEETH);
        DssExecLib.addReaderToMedianWhitelist(LPOsmAbstract(PIP_UNIV2AAVEETH).orb1(), PIP_UNIV2AAVEETH);
        DssExecLib.removeReaderFromMedianWhitelist(LPOsmAbstract(PIP_UNIV2AAVEETH).orb0(), DssExecLib.getChangelogAddress("PIP_UNIV2AAVEETH"));
        DssExecLib.removeReaderFromMedianWhitelist(LPOsmAbstract(PIP_UNIV2AAVEETH).orb1(), DssExecLib.getChangelogAddress("PIP_UNIV2AAVEETH"));
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2AAVEETH, MCD_SPOT);
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2AAVEETH, MCD_END);
        DssExecLib.allowOSMFreeze(PIP_UNIV2AAVEETH, "UNIV2AAVEETH-A");
        DssExecLib.setChangelogAddress("PIP_UNIV2AAVEETH", PIP_UNIV2AAVEETH);

        // --------------------------------- UNIV2DAIUSDT-A ---------------------------------
        DssExecLib.setContract(MCD_SPOT, "UNIV2DAIUSDT-A", "pip", PIP_UNIV2DAIUSDT);
        DssExecLib.authorize(PIP_UNIV2DAIUSDT, OSM_MOM);
        DssExecLib.addReaderToMedianWhitelist(LPOsmAbstract(PIP_UNIV2DAIUSDT).orb1(), PIP_UNIV2DAIUSDT);
        DssExecLib.removeReaderFromMedianWhitelist(LPOsmAbstract(PIP_UNIV2DAIUSDT).orb1(), DssExecLib.getChangelogAddress("PIP_UNIV2DAIUSDT"));
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2DAIUSDT, MCD_SPOT);
        DssExecLib.addReaderToOSMWhitelist(PIP_UNIV2DAIUSDT, MCD_END);
        DssExecLib.allowOSMFreeze(PIP_UNIV2DAIUSDT, "UNIV2DAIUSDT-A");
        DssExecLib.setChangelogAddress("PIP_UNIV2DAIUSDT", PIP_UNIV2DAIUSDT);

        // ---------------------------- Update Chainlog version ----------------------------
        DssExecLib.setChangelogVersion("1.7.0");
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
