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

interface GemLike {
    function transfer(address, uint256) external returns (bool);
}

interface StarknetLike {
    function setMaxDeposit(uint256) external;
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/a8d026060aa4d2967185106222c85cb8b35086ff/governance/votes/Executive%20Vote%20-%20September%2028%2C%202022.md -q -O - 2>/dev/null)"

    string public constant override description =
        "2022-09-28 MakerDAO Executive Spell | Hash: 0xc4f6926109fbd767231352e650f96c1770688479152eabcca024d86fbf940bda";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //

    // --- CUs ---
    address internal constant RWF_WALLET    = 0x96d7b01Cc25B141520C717fa369844d34FF116ec;
    address internal constant CES_OP_WALLET = 0xD740882B8616B50d0B317fDFf17Ec3f4f853F44f;

    // --- Chainlog ---
    address internal constant PROXY_ACTIONS_END_CROPPER = 0x38f7C166B5B22906f04D8471E241151BA45d97Af;

    // --- Math ---
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

        // --- MKR Transfers ---
        GemLike mkr = GemLike(DssExecLib.mkr());

        // RWF-001 - 20 MKR - 0x96d7b01Cc25B141520C717fa369844d34FF116ec
        // https://mips.makerdao.com/mips/details/MIP40c3SP38
        mkr.transfer(RWF_WALLET, 20.00 ether);

        // CES-001 - 966.49 MKR - 0xD740882B8616B50d0B317fDFf17Ec3f4f853F44f
        // https://mips.makerdao.com/mips/details/MIP40c3SP30
        mkr.transfer(CES_OP_WALLET, 966.49 ether);
        // ---------------------

        // Increase Starknet Bridge Deposit Limit from 50 DAI to 1000 DAI
        // https://vote.makerdao.com/polling/QmbWkTvW
        StarknetLike(DssExecLib.getChangelogAddress("STARKNET_DAI_BRIDGE")).setMaxDeposit(1000 * WAD);

        // --- Chainlog Update ---
        // https://forum.makerdao.com/t/28th-september-executive-updating-the-proxy-actions-end-cropper-address/18057
        DssExecLib.setChangelogAddress("PROXY_ACTIONS_END_CROPPER", PROXY_ACTIONS_END_CROPPER);
        DssExecLib.setChangelogVersion("1.14.1");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
