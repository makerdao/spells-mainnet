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

import { DssSpellCollateralAction } from "./DssSpellCollateral.sol";

interface GemLike {
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
}

interface RwaUrnLike {
    function lock(uint256) external;
    function draw(uint256) external;
    function transfer(address, uint256) external returns (bool);
}

interface VestLike {
    function restrict(uint256) external;
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
}

contract DssSpellAction is DssAction, DssSpellCollateralAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/ef7c8c881c961e9b4b3cc9644619986a75ef83d7/governance/votes/Executive%20vote%20-%20October%205%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-10-05 MakerDAO Executive Spell | Hash: 0xf791ea9d7a97cace07a1cd79de48ce9a41dc79f53a43465faad83a30292dfc81";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //

    uint256 constant RWA007_DRAW_AMOUNT = 1_000_000 * WAD;

    uint256 constant AUG_01_2022 = 1659326400;
    uint256 constant AUG_01_2023 = 1690862400;
    uint256 constant SEP_28_2022 = 1664337600;
    uint256 constant SEP_28_2024 = 1727496000;

    // --- Wallets ---
    address internal constant GOV_WALLET1       = 0xbfDD0E744723192f7880493b66501253C34e1241;
    address internal constant GOV_WALLET2       = 0xbb147E995c9f159b93Da683dCa7893d6157199B9;
    address internal constant GOV_WALLET3       = 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73;
    address internal constant AMBASSADOR_WALLET = 0xF411d823a48D18B32e608274Df16a9957fE33E45;
    address internal constant STARKNET_WALLET   = 0x6D348f18c88D45243705D4fdEeB6538c6a9191F1;
    address internal constant SES_WALLET        = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;

    function actions() public override {
        // ---------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralAction
        onboardNewCollaterals();

        // lock RWA007 Token in the URN
        GemLike(RWA007).approve(RWA007_A_URN, 1 * WAD);
        RwaUrnLike(RWA007_A_URN).lock(1 * WAD);

        // --- MKR Vests ---
        GemLike mkr = GemLike(DssExecLib.mkr());
        VestLike vest = VestLike(
            DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY")
        );

        // Increase allowance by new vesting delta
        mkr.approve(address(vest), mkr.allowance(address(this), address(vest)) + 787.70 ether);

        // https://mips.makerdao.com/mips/details/MIP40c3SP80
        // GOV-001 | 2022-08-01 to 2023-08-01 | Cliff 2023-08-01 | 62.51 MKR | 0xbfDD0E744723192f7880493b66501253C34e1241
        vest.restrict(
            vest.create(
                GOV_WALLET1,                                             // usr
                62.50 ether,                                             // tot
                AUG_01_2022,                                             // bgn
                AUG_01_2023 - AUG_01_2022,                               // tau
                AUG_01_2023 - AUG_01_2022,                               // eta
                address(0)                                               // mgr
            )
        );

        // GOV-001 | 2022-08-01 to 2023-08-01 | Cliff 2023-08-01 | 32.69 MKR | 0xbb147E995c9f159b93Da683dCa7893d6157199B9
        vest.restrict(
            vest.create(
                GOV_WALLET2,                                             // usr
                32.69 ether,                                             // tot
                AUG_01_2022,                                             // bgn
                AUG_01_2023 - AUG_01_2022,                               // tau
                AUG_01_2023 - AUG_01_2022,                               // eta
                address(0)                                               // mgr
            )
        );

        // GOV-001 | 2022-08-01 to 2023-08-01 | Cliff 2023-08-01 | 152.51 MKR | 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73
        vest.restrict(
            vest.create(
                GOV_WALLET3,                                             // usr
                152.51 ether,                                            // tot
                AUG_01_2022,                                             // bgn
                AUG_01_2023 - AUG_01_2022,                               // tau
                AUG_01_2023 - AUG_01_2022,                               // eta
                address(0)                                               // mgr
            )
        );

        // SNE-001 | 2022-09-28 to 2024-09-28 | Cliff date = start = 2022-09-28 | 540 MKR | 0x6D348f18c88D45243705D4fdEeB6538c6a9191F1
        vest.restrict(
            vest.create(
                STARKNET_WALLET,                                         // usr
                540.00 ether,                                            // tot
                SEP_28_2022,                                             // bgn
                SEP_28_2024 - SEP_28_2022,                               // tau
                0,                                                       // eta
                address(0)                                               // mgr
            )
        );

        // --- MKR Transfers ---

        // https://mips.makerdao.com/mips/details/MIP40c3SP79
        // SNE-001 - 270 MKR - 0x6D348f18c88D45243705D4fdEeB6538c6a9191F1
        mkr.transfer(STARKNET_WALLET, 270.00 ether);

        // https://mips.makerdao.com/mips/details/MIP40c3SP17
        // SES-001 - 227.64 MKR - 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6
        mkr.transfer(SES_WALLET, 227.64 ether);

        // --- DAI Transfers ---

        // https://mips.makerdao.com/mips/details/MIP55c3SP7
        // Ambassadors  - 81,000.0 DAI - 0xF411d823a48D18B32e608274Df16a9957fE33E45
        DssExecLib.sendPaymentFromSurplusBuffer(AMBASSADOR_WALLET, 81_000);
        
        DssExecLib.setChangelogVersion("1.14.2");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
