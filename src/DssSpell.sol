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
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/8ec1c4a85d86c80711782068c0c1841d4a22cb2c/governance/votes/Executive%20vote%20-%20March%2022%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-03-22 MakerDAO Executive Spell | Hash: 0x6340de8661da4482d004b9dc9c0eb7dfd725cad4ea0441f5df33405e8bc878bc";

    // MIP38: DAO Primitives State
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP38/mip38.md -q -O - 2>/dev/null)"
    string constant public MIP38 = "0x45ba0a20e7c72334b3c735b33a4726a23a75d92b36f111dc4d09f2ecdf420fea";

    // MIP39: Core Unit Framework
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP39/mip39.md -q -O - 2>/dev/null)"
    string constant public MIP39 = "0xbdf82a7fe0dbe8e93738792d43bfab0327fa2db500718b178f48257f219ff89a";

    // MIP40: Budget Framework
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP40/mip40.md -q -O - 2>/dev/null)"
    string constant public MIP40 = "0xf873b83231f506fed45fa55c2cf073fd8b9bf36cbe4e9d29c2611ccf2dd3bddb";

    // MIP41: Facilitator Framework
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP41/mip41.md -q -O - 2>/dev/null)"
    string constant public MIP41 = "0x2f5cba5b9ca5b15d0c2a896224105763bd0346d2722cbc03a88d7ed01a666b95";

    // MIP4c2-SP12: MIP16 Amendments
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP4/MIP4c2-Subproposals/MIP4c2-SP12.md -q -O - 2>/dev/null)"
    string constant public MIP4c2SP12 = "0x0a9c87c613deeea92efc3bc4cc00f036af415a6017883aaa1c1e3dc206c843dd";

    // MIP4c2-SP10: MIP0 Amendments
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP4/MIP4c2-Subproposals/MIP4c2-SP10.md -q -O - 2>/dev/null)"
    string constant public MIP4c2SP10 = "0x5f6ce94d58b206e9c3c72dced5f44ff57ae6975eb93877e91a7b48ff15736009";

    // MIP39c2-SP1: Adding Core Unit Real-World Finance
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP39/MIP39c2-Subproposals/MIP39c2-SP1.md -q -O - 2>/dev/null)"
    string constant public MIP39c2SP1 = "0xaa2b1fa7b3c4f64e3130c86bd8e8164868ca597bdebfe542917dddc13ed30a1e";

    // MIP40c2-SP1: Modify Core Unit Budget Real-World Finance
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP40/MIP40c2-Subproposals/MIP40c2-SP1.md -q -O - 2>/dev/null)"
    string constant public MIP40c2SP1 = "0x674d51a98f5cf80923b9ccf310f64a5890ae424386cf69dee5b11c54e2488aaf";

    // MIP41c4-SP1: Facilitator Onboarding Real-World Finance
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP41/MIP41c4-Subproposals/MIP41c4-SP1.md -q -O - 2>/dev/null)"
    string constant public MIP41c4SP1 = "0x347266a80c162643a3ad94373dc1318b9878790e3cd94c4806768912054f00a7";

    // MIP39c2-SP2: Adding Risk Core Unit
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP39/MIP39c2-Subproposals/MIP39c2-SP2.md -q -O - 2>/dev/null)"
    string constant public MIP39c2SP2 = "0xd1989672d982ca42dccbaf6d2682e68fd0ecc8c0b9537f2c970665af25c593c3";

    // MIP40c2-SP2: Add Core Unit Budget Risk Core Unit
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP40/MIP40c2-Subproposals/MIP40c2-SP2.md -q -O - 2>/dev/null)"
    string constant public MIP40c2SP2 = "0xf1a5ef4150b678fe6de3367be171f2ea809262c089bb13095e4e5391fbcf5ae8";

    // MIP41c4-SP2: Risk Core Unit Facilitator Onboarding
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP41/MIP41c4-Subproposals/MIP41c4-SP2.md -q -O - 2>/dev/null)"
    string constant public MIP41c4SP2 = "0xe589a0ffe300708fdd1be72729dba211c4681f5a78b5bc285b4a34c053bcef2d";

    // MIP39c2-SP3: Governance Core Unit - GOV-001
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP39/MIP39c2-Subproposals/MIP39c2-SP3.md -q -O - 2>/dev/null)"
    string constant public MIP39c2SP3 = "0x4476ffdb3a354f629e30766aaa0d6747490e2644f0f49d91f9dd2586c33c8c6e";

    // MIP40c2-SP3: Core Unit Budget - GOV-001
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP40/MIP40c2-Subproposals/MIP40c2-SP3.md -q -O - 2>/dev/null)"
    string constant public MIP40c2SP3 = "0x697448c9661344aacae3f73bb1d8af706f4ce2de10813fccb0911e2ac6c4a7b9";

    // MIP41c4-SP3: Core Unit Facilitator Onboarding
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP41/MIP41c4-Subproposals/MIP41c4-SP3.md -q -O - 2>/dev/null)"
    string constant public MIP41c4SP3 = "0x75177fbec9175c15ab50be6efcc909ce86e7fa60776078353858d9af824a46b8";

    // MIP34: Keg Streaming Payments Module
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP34/mip34.md -q -O - 2>/dev/null)"
    string constant public MIP34 = "0x72302509ab818d46cf2430f68b3f73b042e5bc2f3874392fd7342cf5fa83428d";

    // MIP48: Streaming Payments via the Keg
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP48/MIP48.md -q -O - 2>/dev/null)"
    string constant public MIP48 = "0x3705522884a1ca064a48e5f4169d776a18d9d3c1644ab000d6647ddc6bc7f0ee";

    // MIP43 - Term Lending Module TLM
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP43/mip43.md -q -O - 2>/dev/null)"
    string constant public MIP43 = "0x2d25bb60678daf9f7aa42da47341f11123362d19f092d34d0045b23f839546a8";

    // MIP45: Liquidations 2.0 LIQ-2.0 - Liquidation System Redesign
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP45/mip45.md -q -O - 2>/dev/null)"
    string constant public MIP45 = "0x5a9b309a1e21943f5ccca4b10554514e778d2a582580d421a750f5365e0f2536";

    // MIP46: Parameter Proposal Groups
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP46/MIP46.md -q -O - 2>/dev/null)"
    string constant public MIP46 = "0x1758d3b5cb0ec5c2f50548d31682432938a6c856786585e4035aca70ee68d813";

    // MIP47: MakerDAO Multisignature Wallet Management
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5c981b8b24c966d110f133c792d27e7728cc77ab/MIP47/MIP47.md -q -O - 2>/dev/null)"
    string constant public MIP47 = "0xbddccb8186167ab5288466928d78a9578301ddbfa09e0e83826fadbf9fc394be";

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //

    // Disable Office Hours
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 4 days, address(action_)) public {}
}
