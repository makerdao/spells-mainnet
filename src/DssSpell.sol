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

interface Doable {
    function done() external returns (bool);
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/3e69d2d9403ad0db916a370be66b9b77970b9a4d/governance/votes/Executive%20vote%20-%20July%2016%2C%202021.md -q -O - 2> /dev/null)"
    string public constant override description =
        "2021-07-16 MakerDAO Executive Spell | Hash: 0x3797ab3aade24e8dbc3c859932f2a4fde3acbef215447b133e1622c21813dfab";

    // Turn off office hours
    function officeHours() public override returns (bool) {
        return false;
    }

    uint256 constant MILLION = 10 ** 6;

    // Growth Core Unit
    address constant GRO_MULTISIG        = 0x7800C137A645c07132886539217ce192b9F0528e;
    // Content Production Core Unit
    address constant MKT_MULTISIG        = 0xDCAF2C84e1154c8DdD3203880e5db965bfF09B60;
    // GovAlpha Core Unit
    address constant GOV_MULTISIG        = 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73;
    // Real-World Finance Core Unit
    address constant RWF_MULTISIG        = 0x9e1585d9CA64243CE43D42f7dD7333190F66Ca09;
    // Risk Core Unit
    address constant RISK_CU_EOA         = 0xd98ef20520048a35EdA9A202137847A62120d2d9;
    // Protocol Engineering Multisig
    address constant PE_MULTISIG         = 0xe2c16c308b843eD02B09156388Cb240cEd58C01c;
    // Oracles Core Unit (Operating)
    address constant ORA_MULTISIG        = 0x2d09B7b95f3F312ba6dDfB77bA6971786c5b50Cf;
    // Oracles Core Unit (Emergency Fund)
    address constant ORA_ER_MULTISIG     = 0x53CCAA8E3beF14254041500aCC3f1D4edb5B6D24;

    address constant PREV_SPELL = 0xEC782b5aC1f0Fc096Ad30950f3348670980f7FD3;

    function actions() public override {

        // https://vote.makerdao.com/polling/QmUNouQ7?network=mainnet#poll-detail
        // Will also increase the global debt ceiling.
        DssExecLib.increaseIlkDebtCeiling(bytes32("RWA002-A"), 15 * MILLION, true);

        // https://vote.makerdao.com/polling/Qmb65Ynh?network=mainnet#poll-detail
        DssExecLib.setSurplusAuctionBidDuration(30 minutes);

        if (!Doable(PREV_SPELL).done()) {
            // Core Unit Budget Distributions - July
            DssExecLib.sendPaymentFromSurplusBuffer(GRO_MULTISIG,    126_117);
            DssExecLib.sendPaymentFromSurplusBuffer(MKT_MULTISIG,     44_375);
            DssExecLib.sendPaymentFromSurplusBuffer(GOV_MULTISIG,    273_334);
            DssExecLib.sendPaymentFromSurplusBuffer(RWF_MULTISIG,    155_000);
            DssExecLib.sendPaymentFromSurplusBuffer(RISK_CU_EOA,     182_000);
            DssExecLib.sendPaymentFromSurplusBuffer(PE_MULTISIG,     510_000);
            DssExecLib.sendPaymentFromSurplusBuffer(ORA_MULTISIG,    419_677);
            DssExecLib.sendPaymentFromSurplusBuffer(ORA_ER_MULTISIG, 800_000);
            //                                                     _________
            //                                         TOTAL DAI:  2,510,503
        }
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}
