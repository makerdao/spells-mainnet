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

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";

import { DssSpellCollateralOnboardingAction } from "./DssSpellCollateralOnboarding.sol";

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO/governance/votes/TODO -q -O - 2>/dev/null)"
    string public constant override description =
        "2022-02-04 MakerDAO Executive Spell | Hash: TODO";

    address constant NEW_MCD_ESM = address(0x09e05fF6142F2f9de8B6B65855A1d56B6cfE4c58);
    bytes32 constant MCD_ESM = "MCD_ESM";

    // Math
    uint256 constant MILLION = 10**6;
    uint256 constant WAD = 10**18;

    function actions() public override {

        // Includes changes from the DssSpellCollateralOnboardingAction
        // onboardNewCollaterals();

        address OLD_MCD_ESM = DssExecLib.getChangelogAddress(MCD_ESM);
        address addr;

        // Set the ESM threshold to 100k MKR
        // https://vote.makerdao.com/polling/QmQSVmrh?network=mainnet#poll-detail
        DssExecLib.setValue(NEW_MCD_ESM, "min", 100_000 * WAD);

        // MCD_END
        addr = DssExecLib.getChangelogAddress("MCD_END");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_ETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_ETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_ETH_B
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_ETH_B");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_ETH_C
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_ETH_C");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_BAT_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_BAT_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_USDC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_USDC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_USDC_B
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_USDC_B");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_TUSD_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_TUSD_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_WBTC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_WBTC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_ZRX_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_ZRX_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_KNC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_KNC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_MANA_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_MANA_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_USDT_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_USDT_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_PAXUSD_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_PAXUSD_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_COMP_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_COMP_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_LRC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_LRC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_LINK_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_LINK_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_BAL_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_BAL_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_YFI_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_YFI_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_GUSD_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_GUSD_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNI_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNI_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_RENBTC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_RENBTC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_AAVE_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_AAVE_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_PSM_USDC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_PSM_USDC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_MATIC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_MATIC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2DAIETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2DAIETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2WBTCETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2WBTCETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2USDCETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2USDCETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2DAIUSDC_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2DAIUSDC_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2ETHUSDT_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2ETHUSDT_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2LINKETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2LINKETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2UNIETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2UNIETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2WBTCDAI_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2WBTCDAI_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2AAVEETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2AAVEETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_UNIV2DAIUSDT_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_UNIV2DAIUSDT_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_PSM_PAX_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_PSM_PAX_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_GUNIV3DAIUSDC1_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_GUNIV3DAIUSDC1_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_WSTETH_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_WSTETH_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_WBTC_B
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_WBTC_B");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_WBTC_C
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_WBTC_C");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_PSM_GUSD_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_PSM_GUSD_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_GUNIV3DAIUSDC2_A
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_GUNIV3DAIUSDC2_A");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_VAT
        addr = DssExecLib.getChangelogAddress("MCD_VAT");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_CLIP_DIRECT_AAVEV2_DAI
        addr = DssExecLib.getChangelogAddress("MCD_CLIP_DIRECT_AAVEV2_DAI");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // OPTIMISM_DAI_BRIDGE
        addr = DssExecLib.getChangelogAddress("OPTIMISM_DAI_BRIDGE");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // OPTIMISM_ESCROW
        addr = DssExecLib.getChangelogAddress("OPTIMISM_ESCROW");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // OPTIMISM_GOV_RELAY
        addr = DssExecLib.getChangelogAddress("OPTIMISM_GOV_RELAY");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // ARBITRUM_DAI_BRIDGE
        addr = DssExecLib.getChangelogAddress("ARBITRUM_DAI_BRIDGE");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // ARBITRUM_ESCROW
        addr = DssExecLib.getChangelogAddress("ARBITRUM_ESCROW");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // ARBITRUM_GOV_RELAY
        addr = DssExecLib.getChangelogAddress("ARBITRUM_GOV_RELAY");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        // MCD_JOIN_DIRECT_AAVEV2_DAI
        addr = DssExecLib.getChangelogAddress("MCD_JOIN_DIRECT_AAVEV2_DAI");
        DssExecLib.deauthorize(addr, OLD_MCD_ESM);
        DssExecLib.authorize(addr, NEW_MCD_ESM);

        DssExecLib.setChangelogAddress(MCD_ESM, NEW_MCD_ESM);
        DssExecLib.setChangelogVersion("1.10.0");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
