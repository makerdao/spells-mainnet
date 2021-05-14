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

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";
import "dss-interfaces/dss/DssAutoLineAbstract.sol";
import "dss-interfaces/dss/LPOsmAbstract.sol";

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/098eabb0973a264de343457ad42e29084577c338/governance/votes/Executive%20vote%20-%20May%2014%2C%202021.md -q -O - 2> /dev/null)"
    string public constant description =
        "2021-05-14 MakerDAO Executive Spell | Hash: 0xd33a03015df3af9e045e54f62f3a78a5843514b01a0f282698afda166fdde202";

    address constant PIP_UNIV2DAIETH  = 0xFc8137E1a45BAF0030563EC4F0F851bd36a85b7D;
    address constant PIP_UNIV2WBTCETH = 0x8400D2EDb8B97f780356Ef602b1BdBc082c2aD07;
    address constant PIP_UNIV2USDCETH = 0xf751f24DD9cfAd885984D1bA68860F558D21E52A;
    address constant PIP_UNIV2DAIUSDC = 0x25D03C2C928ADE19ff9f4FFECc07d991d0df054B;
    address constant PIP_UNIV2ETHUSDT = 0x5f6dD5B421B8d92c59dC6D907C9271b1DBFE3016;
    address constant PIP_UNIV2LINKETH = 0xd7d31e62AE5bfC3bfaa24Eda33e8c32D31a1746F;
    address constant PIP_UNIV2UNIETH  = 0x8462A88f50122782Cc96108F476deDB12248f931;
    address constant PIP_UNIV2WBTCDAI = 0x5bB72127a196392cf4aC00Cf57aB278394d24e55;
    address constant PIP_UNIV2AAVEETH = 0x32d8416e8538Ac36272c44b0cd962cD7E0198489;
    address constant PIP_UNIV2DAIUSDT = 0x9A1CD705dc7ac64B50777BcEcA3529E58B1292F1;

    uint256 constant ONE_PCT   = 1000000000315522921573372069;
    uint256 constant THREE_PCT = 1000000000937303470807876289;
    uint256 constant FIVE_PCT  = 1000000001547125957863212448;

    uint256 constant MILLION = 10 ** 6;

    function replaceOracle(
        bytes32 ilk,
        bytes32 pipKey,
        address newOracle,
        address spotter,
        address end,
        address mom,
        bool orb0Med,
        bool orb1Med
    ) internal {
        address oldOracle = DssExecLib.getChangelogAddress(pipKey);
        address orb0 = LPOsmAbstract(newOracle).orb0();
        address orb1 = LPOsmAbstract(newOracle).orb1();
        require(LPOsmAbstract(newOracle).wat() == LPOsmAbstract(oldOracle).wat(), "DssSpell/not-matching-wat");
        require(LPOsmAbstract(newOracle).src() == LPOsmAbstract(oldOracle).src(), "DssSpell/not-matching-src");
        require(orb0 == LPOsmAbstract(oldOracle).orb0(), "DssSpell/not-matching-orb0");
        require(orb1 == LPOsmAbstract(oldOracle).orb1(), "DssSpell/not-matching-orb1");
        DssExecLib.setContract(spotter, ilk, "pip", newOracle);
        DssExecLib.authorize(newOracle, mom);
        DssExecLib.addReaderToOSMWhitelist(newOracle, spotter);
        DssExecLib.addReaderToOSMWhitelist(newOracle, end);
        if (orb0Med) {
            DssExecLib.addReaderToMedianWhitelist(orb0, newOracle);
            DssExecLib.removeReaderFromMedianWhitelist(orb0, oldOracle);
        }
        if (orb1Med) {
            DssExecLib.addReaderToMedianWhitelist(orb1, newOracle);
            DssExecLib.removeReaderFromMedianWhitelist(orb1, oldOracle);
        }
        DssExecLib.allowOSMFreeze(newOracle, ilk);
        DssExecLib.setChangelogAddress(pipKey, newOracle);
    }

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
        replaceOracle(
            "UNIV2DAIETH-A",
            "PIP_UNIV2DAIETH",
            PIP_UNIV2DAIETH,
            MCD_SPOT,
            MCD_END,
            OSM_MOM,
            false,
            true
        );

        // --------------------------------- UNIV2WBTCETH-A ---------------------------------
        replaceOracle(
            "UNIV2WBTCETH-A",
            "PIP_UNIV2WBTCETH",
            PIP_UNIV2WBTCETH,
            MCD_SPOT,
            MCD_END,
            OSM_MOM,
            true,
            true
        );

        // --------------------------------- UNIV2USDCETH-A ---------------------------------
        replaceOracle(
            "UNIV2USDCETH-A",
            "PIP_UNIV2USDCETH",
            PIP_UNIV2USDCETH,
            MCD_SPOT,
            MCD_END,
            OSM_MOM,
            false,
            true
        );

        // --------------------------------- UNIV2DAIUSDC-A ---------------------------------
        replaceOracle(
            "UNIV2DAIUSDC-A",
            "PIP_UNIV2DAIUSDC",
            PIP_UNIV2DAIUSDC,
            MCD_SPOT,
            MCD_END,
            OSM_MOM,
            false,
            false
        );

        // --------------------------------- UNIV2ETHUSDT-A ---------------------------------
        replaceOracle(
            "UNIV2ETHUSDT-A",
            "PIP_UNIV2ETHUSDT",
            PIP_UNIV2ETHUSDT,
            MCD_SPOT,
            MCD_END,
            OSM_MOM,
            true,
            true
        );

        // --------------------------------- UNIV2LINKETH-A ---------------------------------
        replaceOracle(
            "UNIV2LINKETH-A",
            "PIP_UNIV2LINKETH",
            PIP_UNIV2LINKETH,
            MCD_SPOT,
            MCD_END,
            OSM_MOM,
            true,
            true
        );

        // --------------------------------- UNIV2UNIETH-A ---------------------------------
        replaceOracle(
            "UNIV2UNIETH-A",
            "PIP_UNIV2UNIETH",
            PIP_UNIV2UNIETH,
            MCD_SPOT,
            MCD_END,
            OSM_MOM,
            true,
            true
        );

        // --------------------------------- UNIV2WBTCDAI-A ---------------------------------
        replaceOracle(
            "UNIV2WBTCDAI-A",
            "PIP_UNIV2WBTCDAI",
            PIP_UNIV2WBTCDAI,
            MCD_SPOT,
            MCD_END,
            OSM_MOM,
            true,
            false
        );

        // --------------------------------- UNIV2AAVEETH-A ---------------------------------
        replaceOracle(
            "UNIV2AAVEETH-A",
            "PIP_UNIV2AAVEETH",
            PIP_UNIV2AAVEETH,
            MCD_SPOT,
            MCD_END,
            OSM_MOM,
            true,
            true
        );

        // --------------------------------- UNIV2DAIUSDT-A ---------------------------------
        replaceOracle(
            "UNIV2DAIUSDT-A",
            "PIP_UNIV2DAIUSDT",
            PIP_UNIV2DAIUSDT,
            MCD_SPOT,
            MCD_END,
            OSM_MOM,
            false,
            true
        );

        // ---------------------------- Update Chainlog version ----------------------------
        DssExecLib.setChangelogVersion("1.7.0");
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
