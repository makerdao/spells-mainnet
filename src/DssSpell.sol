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

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/eae06d4b38346a7d90d92cd951beff16a3d548c9/governance/votes/Executive%20vote%20-%20May%2024%2C%202021.md -q -O - 2> /dev/null)"
    string public constant description =
        "2021-05-24 MakerDAO Executive Spell | Hash: 0xca4176704005e00b4357c0ef4ebb1812c88b21e57463bdfbb90da1c8189b406d";

    // SES auditors Multisig
    address constant SES_AUDITORS_MULTISIG = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;
    // Monthly expenses
    uint256 constant SES_AUDITORS_AMOUNT = 1_153_480;

    // MIP50: Direct Deposit Module
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/c23fd23b340ecf66a16f0e1ecfe7b55a5232864d/MIP50/mip50.md -q -O - 2> /dev/null)"
    string constant public MIP50 = "0xb6ba98197a58fab2af683951e753dfac802e0fef29d736ef58dd91a35706fb61";

    // MIP51: Monthly Governance Cycle
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/c23fd23b340ecf66a16f0e1ecfe7b55a5232864d/MIP51/mip51.md -q -O - 2> /dev/null)"
    string constant public MIP51 = "0xa9e81bc611853444ebfe5e3cca2f14b48a8490612ed4077ba7aa52a302db2366";

    // MIP4c2-SP14: MIP Amendment Subproposals
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/c23fd23b340ecf66a16f0e1ecfe7b55a5232864d/MIP4/MIP4c2-Subproposals/MIP4c2-SP14.md -q -O - 2> /dev/null)"
    string constant public MIP4c2SP14 = "0x466c906898858488c5083ef8e9d67bf5c26e86c372064bd483de3a203285b1a2";

    // MIP39c2-SP10: Adding Sustainable Ecosystem Scaling Core Unit
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/c23fd23b340ecf66a16f0e1ecfe7b55a5232864d/MIP39/MIP39c2-Subproposals/MIP39c2-SP10.md -q -O - 2> /dev/null)"
    string constant public MIP39c2SP10 = "0x29b327498fe5b300cd0f81b2fa0eacd886916162b188b967fb5bb330f5b68b94";

    // MIP40c3-SP10: Modify Core Unit Budget
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/c23fd23b340ecf66a16f0e1ecfe7b55a5232864d/MIP40/MIP40c3-Subproposals/MIP40c3-SP10.md -q -O - 2> /dev/null)"
    string constant public MIP40c3SP10 = "0xa3afb63a4710cb30ad67082cdbb8156a11b315cadb251bfe6af7732c08303aa6";

    // MIP41c4: Facilitator Onboarding (Subproposal Process) Template
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/c23fd23b340ecf66a16f0e1ecfe7b55a5232864d/MIP41/MIP41c4-Subproposals/MIP41c4-SP10.md -q -O - 2> /dev/null)"
    string constant public MIP41c4SP10 = "0xe37c37e3ffc8a2c638500f05f179b1d07d00e5aa35ae37ac88a1e10d43e77728";

    // Disable Office Hours
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // Payment of SES auditors budget
        DssExecLib.sendPaymentFromSurplusBuffer(SES_AUDITORS_MULTISIG, SES_AUDITORS_AMOUNT);
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 4 days, address(action_)) public {}
}
