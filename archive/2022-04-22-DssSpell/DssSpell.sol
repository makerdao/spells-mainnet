// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2021-2022 Dai Foundation
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
// Enable ABIEncoderV2 when onboarding collateral
// pragma experimental ABIEncoderV2;
import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol";

interface CurveLPOracleLike {
    function pool() external view returns (address);
    function src() external view returns (address);
    function wat() external view returns (bytes32);
    function ncoins() external view returns (uint256);
    function orbs(uint256) external view returns (address);
    function nonreentrant() external view returns (bool);
}

interface IlkRegistryLike {
    function update(bytes32) external;
}

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/6b4cedd333d710702f50b0e679b005286773b6d3/governance/votes/Executive%20vote%20-%20April%2022%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-04-22 MakerDAO Executive Spell | Hash: 0xe5e05856de3897fcc39b076c48452bd853ee5261f193100270f672e6c5870d53";

    // Math

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmPgPVrVxDCGyNR5rGp9JC5AUxppLzUAqvncRJDcxQnX1u
    //

    // --- Rates ---
    //uint256 constant FOUR_FIVE_PCT_RATE      = 1000000001395766281313196627;

    address constant internal OASIS_APP_OSM_READER = 0x55Dc2Be8020bCa72E58e665dC931E03B749ea5E0;

    address constant internal PIP_CRVV1ETHSTETH = 0xEa508F82728927454bd3ce853171b0e2705880D4;

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();

        // --------------------------------- Oasis.app OSM Whitelist ---------------------------------------
        // https://vote.makerdao.com/polling/QmZykRSM
        DssExecLib.addReaderToWhitelist(DssExecLib.getChangelogAddress("PIP_ETH"),    OASIS_APP_OSM_READER);
        DssExecLib.addReaderToWhitelist(DssExecLib.getChangelogAddress("PIP_WSTETH"), OASIS_APP_OSM_READER);
        DssExecLib.addReaderToWhitelist(DssExecLib.getChangelogAddress("PIP_WBTC"),   OASIS_APP_OSM_READER);
        //DssExecLib.addReaderToWhitelist(DssExecLib.getChangelogAddress("PIP_RENBTC"), OASIS_APP_OSM_READER); Same address as WBTC OSM
        DssExecLib.addReaderToWhitelist(DssExecLib.getChangelogAddress("PIP_YFI"),    OASIS_APP_OSM_READER);
        DssExecLib.addReaderToWhitelist(DssExecLib.getChangelogAddress("PIP_UNI"),    OASIS_APP_OSM_READER);
        DssExecLib.addReaderToWhitelist(DssExecLib.getChangelogAddress("PIP_LINK"),   OASIS_APP_OSM_READER);
        DssExecLib.addReaderToWhitelist(DssExecLib.getChangelogAddress("PIP_MANA"),   OASIS_APP_OSM_READER);

        // --------------------------------- Replace CRVV1ETHSTETH-A PIP -----------------------------------
        bytes32 _ilk  = "CRVV1ETHSTETH-A";

        address PIP_CRVV1ETHSTETH_OLD = DssExecLib.getChangelogAddress("PIP_CRVV1ETHSTETH");
        address MCD_CLIP_CRVV1ETHSTETH_A = DssExecLib.getChangelogAddress("MCD_CLIP_CRVV1ETHSTETH_A");

        address PIP_CRVV1ETHSTETH_ORBS_0 = CurveLPOracleLike(PIP_CRVV1ETHSTETH).orbs(0);
        address PIP_CRVV1ETHSTETH_ORBS_1 = CurveLPOracleLike(PIP_CRVV1ETHSTETH).orbs(1);

        // OSM Sanity Checks
        require(CurveLPOracleLike(PIP_CRVV1ETHSTETH).pool() == CurveLPOracleLike(PIP_CRVV1ETHSTETH_OLD).pool(), "DssSpell/pip-wrong-pool");
        require(CurveLPOracleLike(PIP_CRVV1ETHSTETH).src() == CurveLPOracleLike(PIP_CRVV1ETHSTETH_OLD).src(), "DssSpell/pip-wrong-src");
        require(CurveLPOracleLike(PIP_CRVV1ETHSTETH).wat() == CurveLPOracleLike(PIP_CRVV1ETHSTETH_OLD).wat(), "DssSpell/pip-wrong-wat");
        require(CurveLPOracleLike(PIP_CRVV1ETHSTETH).ncoins() == CurveLPOracleLike(PIP_CRVV1ETHSTETH_OLD).ncoins(), "DssSpell/pip-wrong-ncoins");
        require(PIP_CRVV1ETHSTETH_ORBS_0 == CurveLPOracleLike(PIP_CRVV1ETHSTETH_OLD).orbs(0), "DssSpell/pip-wrong-orbs0");
        require(PIP_CRVV1ETHSTETH_ORBS_1 == CurveLPOracleLike(PIP_CRVV1ETHSTETH_OLD).orbs(1), "DssSpell/pip-wrong-orbs1");
        require(CurveLPOracleLike(PIP_CRVV1ETHSTETH).nonreentrant(), "DssSpell/pip-reentrant");

        address OSM_MOM = DssExecLib.osmMom();
        address MCD_SPOT = DssExecLib.spotter();
        address CLIPPER_MOM = DssExecLib.clipperMom();
        address MCD_END = DssExecLib.end();

        // Revoke OsmMom to access the Old OSM
        DssExecLib.deauthorize(PIP_CRVV1ETHSTETH_OLD, OSM_MOM);

        // Remove Old CRVV1ETHSTETH-A OSM Whitelistings
        DssExecLib.removeReaderFromWhitelist(PIP_CRVV1ETHSTETH_ORBS_0, PIP_CRVV1ETHSTETH_OLD);
        DssExecLib.removeReaderFromWhitelist(PIP_CRVV1ETHSTETH_ORBS_1, PIP_CRVV1ETHSTETH_OLD);

        DssExecLib.removeReaderFromWhitelist(PIP_CRVV1ETHSTETH_OLD, MCD_SPOT);
        DssExecLib.removeReaderFromWhitelist(PIP_CRVV1ETHSTETH_OLD, MCD_CLIP_CRVV1ETHSTETH_A);
        DssExecLib.removeReaderFromWhitelist(PIP_CRVV1ETHSTETH_OLD, CLIPPER_MOM);
        DssExecLib.removeReaderFromWhitelist(PIP_CRVV1ETHSTETH_OLD, MCD_END);

        // ---- Replace CRVV1ETHSTETH-A PIP ----

        // Set the token PIP in the Spotter
        DssExecLib.setContract(MCD_SPOT, _ilk, "pip", PIP_CRVV1ETHSTETH);

        // Allow OsmMom to access the New OSM
        DssExecLib.authorize(PIP_CRVV1ETHSTETH, OSM_MOM);

        // Add New CRVV1ETHSTETH-A OSM Whitelistings
        DssExecLib.addReaderToWhitelist(PIP_CRVV1ETHSTETH_ORBS_0, PIP_CRVV1ETHSTETH);
        DssExecLib.addReaderToWhitelist(PIP_CRVV1ETHSTETH_ORBS_1, PIP_CRVV1ETHSTETH);

        DssExecLib.addReaderToWhitelist(PIP_CRVV1ETHSTETH, MCD_SPOT);
        DssExecLib.addReaderToWhitelist(PIP_CRVV1ETHSTETH, MCD_CLIP_CRVV1ETHSTETH_A);
        DssExecLib.addReaderToWhitelist(PIP_CRVV1ETHSTETH, CLIPPER_MOM);
        DssExecLib.addReaderToWhitelist(PIP_CRVV1ETHSTETH, MCD_END);

        // Set OSM in the OsmMom for the ilk
        DssExecLib.allowOSMFreeze(PIP_CRVV1ETHSTETH, _ilk);

        // Update pip in the ilk registry
        IlkRegistryLike(DssExecLib.reg()).update(_ilk);

        // Update pip in changelog
        DssExecLib.setChangelogAddress("PIP_CRVV1ETHSTETH", PIP_CRVV1ETHSTETH);

        // Update chaingelog version
        DssExecLib.setChangelogVersion("1.11.2");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
