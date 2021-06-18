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

interface IlkRegistryLike {
    function list() external view returns (bytes32[] memory);
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/c424e1e507509bd5e721d4cf09979570a162a885/governance/votes/Executive%20vote%20-%20June%2018%2C%202021.md -q -O - 2> /dev/null)"
    string public constant description =
        "2021-06-18 MakerDAO Executive Spell | Hash: 0x3ba3d9609358d3f0c8c3d39c582a2dcc44bf5ed4b2ea88ec68f5ab6416a3c8e9";

    // Turn off office hours
    function officeHours() public override returns (bool) {
        return false;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;
    uint256 constant RAD = 10**45;

    address constant MCD_FLASH = 0x1EB4CF3A948E7D72A198fe073cCb8C7a948cD853;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //

    function actions() public override {
        address MCD_VAT         = DssExecLib.vat();
        address ILK_REGISTRY    = DssExecLib.getChangelogAddress("ILK_REGISTRY");

        // ---------- Increase the Dust Parameter for ETH-B Vault Type ---------

        DssExecLib.setIlkMinVaultAmount("ETH-B", 30_000);

        // -------------------- Increase the Dust Parameter --------------------

        bytes32[] memory ilks = IlkRegistryLike(ILK_REGISTRY).list();
        for (uint256 i = 0; i < ilks.length; i++) {
            bytes32 ilk = ilks[i];
            if (
                   ilk == "PSM-USDC-A"
                || ilk == "ETH-B"
                || ilk == "ETH-C"
                || ilk == "RWA001-A"
                || ilk == "RWA002-A"
            )  {
                continue;
            }
            DssExecLib.setIlkMinVaultAmount(ilk, 10_000);
        }

        // --------------------------- Add MCD_FLASH ---------------------------

        Fileable(MCD_FLASH).file("max", 500_000_000 * WAD);
        Fileable(MCD_FLASH).file("toll", 5 * WAD / 10000);
        DssExecLib.authorize(MCD_VAT, MCD_FLASH);
        DssExecLib.setChangelogAddress("MCD_FLASH", MCD_FLASH);

        // -------------------------- Update Chainlog --------------------------

        DssExecLib.setChangelogVersion("1.9.1");
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
