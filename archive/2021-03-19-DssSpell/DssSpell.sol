// SPDX-License-Identifier: GPL-3.0-or-later
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

// https://github.com/makerdao/ilk-registry/blob/master/src/IlkRegistry.sol
interface IlkRegistryLike {
    function list() external view returns (bytes32[] memory);
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/e0a37c7b58a98566ba637793a804179b4666b4c7/governance/votes/Executive%20vote%20-%20March%2019%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-03-19 MakerDAO Executive Spell | Hash: 0xa7979ce287cd7df9ecbf25251f2b41a52c27a47567721d7c5ddfc6f85885d4d7";


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //

    uint256 constant MILLION = 10**6;
    uint256 constant BILLION = 10**9;

    // Disable Office Hours
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {

        bytes32[] memory ilks = IlkRegistryLike(DssExecLib.reg()).list();

        // Increase Dust Parameter for most Ilks
        //
        // Loop over all ilks

        for (uint256 i = 0; i < ilks.length; i++) {
            // skip the rest of the loop for the following ilks:
            //
            // RWA001-A ilk is not included in the ilk registry

            if (ilks[i] == "ETH-B" ||
                ilks[i] == "PSM-USDC-A"
            ) { continue; }

            // Increase Dust Paramater
            //
            DssExecLib.setIlkMinVaultAmount(ilks[i], 5000);
        }


        // Increase Debt Ceiling
        DssExecLib.setIlkAutoLineDebtCeiling("ETH-A", 15 * BILLION);
        DssExecLib.setIlkAutoLineDebtCeiling("WBTC-A", 750 * MILLION);
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
