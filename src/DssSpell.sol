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
pragma solidity 0.6.11;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";

interface ChainlogAbstract {
    function removeAddress(bytes32) external;
}

interface LPOracle {
    function orb0() external view returns (address);
    function orb1() external view returns (address);
}

interface Fileable {
    function file(bytes32,uint256) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/46cbe46a16b7836d6b219201e3a07d40b01a7db4/governance/votes/Community%20Executive%20vote%20-%20February%2026%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-03-01 MakerDAO Executive Spell | Hash: TODO";


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //

    uint256 constant WAD        = 10**18;
    uint256 constant RAD        = 10**45;
    uint256 constant MILLION    = 10**6;

    address constant LERP = 0x7b3799b30f268BA55f926d7F714a3001aF89d359;

    // Turn off office hours
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        VatAbstract vat = VatAbstract(DssExecLib.vat());

        // De-authorize the lerp contract from adjusting the PSM-USDC-A DC
        DssExecLib.deauthorize(address(vat), LERP);

        // Increase PSM-USDC-A to 1 Billion from its current value.
        DssExecLib.setIlkDebtCeiling("PSM-USDC-A", 1000 * MILLION);

        // Decrease the USDC-A Debt Ceiling to zero from its current value.
        (,,,uint256 line,) = vat.ilks("USDC-A");
        DssExecLib.setIlkDebtCeiling("USDC-A", 0);

        // Global debt ceiling for PSM was previously set to the end lerp value of 500M
        // Increase it by another 500M to match the 1B target debt ceiling
        // Also subtract out the USDC-A line
        vat.file("Line", vat.Line() + 500 * MILLION * RAD - line);
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}
