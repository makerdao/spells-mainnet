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

interface RwaUrnLike {
    function draw(uint256) external;
}

interface VestLike {
    function yank(uint256) external;
    function restrict(uint256) external;
    function create(
        address usr,
        uint256 tot,
        uint256 bgn,
        uint256 tau,
        uint256 eta,
        address mgr
    ) external returns (uint256);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/585e2e732a5a13125a2df34245f75f0f95839c8e/governance/votes/Executive%20Vote%20-%20August%203%2C%202022.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-08-03 MakerDAO Executive Spell | Hash: 0x732b6178deb82f7df569adac9f94cc5aefb34966200a035e7585722ec01f1a8a";

    uint256 public constant WAD                = 10**18;
    uint256 public constant RWA009_DRAW_AMOUNT = 25_000_000 * WAD;
    uint256 public constant JUL_01_2022        = 1656633600;
    uint256 public constant FEB_01_2023        = 1675209600;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmX2QMoM1SZq2XMoTbMak8pZP86Y2icpgPAKDjQg4r4YHn
    //

    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {

        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralAction
        // onboardNewCollaterals();
        // offboardCollaterals();

        address RWA009_A_URN = DssExecLib.getChangelogAddress("RWA009_A_URN");
        address MCD_VEST_DAI = DssExecLib.getChangelogAddress("MCD_VEST_DAI");

        // Huntingdon Valley (HVBank) Vault Drawdown
        RwaUrnLike(RWA009_A_URN).draw(RWA009_DRAW_AMOUNT);


        // Keep3r Network Stream Re-Deployment
        VestLike(MCD_VEST_DAI).yank(8);
        VestLike(MCD_VEST_DAI).restrict(
            VestLike(MCD_VEST_DAI).create({
                usr: 0x37b375e3D418fbECba6b283e704F840AB32f3b3C,
                tot: 215_000 * WAD,
                bgn: JUL_01_2022,
                tau: FEB_01_2023 - JUL_01_2022,
                eta: 0,
                mgr: address(0) // 0x45fEEBbd5Cf86dF61be8F81025E22Ae07a07cB23
            })
        );
    }

}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
