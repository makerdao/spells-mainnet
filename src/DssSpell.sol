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
import { VatAbstract, DaiJoinAbstract } from "dss-interfaces/Interfaces.sol";

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/[COMMIT]/governance/votes/Executive%20vote%20-%20April%2026%2C%202021.md -q -O - 2> /dev/null)" // TODO
    string public constant description =
        "2021-04-26 MakerDAO Executive Spell | Hash: "; // TODO


    // Units used
    // uint256 constant MILLION    = 10**6;
    uint256 constant WAD        = 10**18;
    // uint256 constant RAY        = 10**27;
    uint256 constant RAD        = 10**45;


    // Protocol Engineering constants

    // Protocol Engineering Multisig
    address constant PE_MULTISIG         = 0xe2c16c308b843eD02B09156388Cb240cEd58C01c;
    // Continuous Operation Multisig
    address constant PE_CO_MULTISIG      = 0x83e36aAA1c7b99E2D3d07789F7b70FCe46f0d45E;
    // Monthly expenses
    uint256 constant PE_MONTHLY_EXPENSES = 510_000;
    // Continuous Operation lump-sum
    uint256 constant PE_CO_LUMP_SUM      = 1_300_000;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    // uint256 constant ZERO_PCT           = 1000000000000000000000000000;
    // uint256 constant ONE_PCT            = 1000000000315522921573372069;
    // uint256 constant TWO_PCT            = 1000000000627937192491029810;
    // uint256 constant THREE_PCT          = 1000000000937303470807876289;
    // uint256 constant THREE_PT_FIVE_PCT  = 1000000001090862085746321732;
    // uint256 constant FOUR_PCT           = 1000000001243680656318820312;
    // uint256 constant FOUR_PT_FIVE_PCT   = 1000000001395766281313196627;
    // uint256 constant FIVE_PCT           = 1000000001547125957863212448;
    // uint256 constant TEN_PCT            = 1000000003022265980097387650;


    // Amendment Proposals

    // MIP4c2-SP7: MIP4 Amendments
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/15c887ab8aa761c1008261281669f5cba4bc9803/MIP4/MIP4c2-Subproposals/MIP4c2-SP7.md -q -O - 2> /dev/null)"
    string constant public MIP4c2SP7  = "0xf256d83a373ae5b5d0d1c75bee451b99d86db216683d3bec4086660a30ada857";

    // MIP4c2-SP8: MIP 9 Amendments
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/15c887ab8aa761c1008261281669f5cba4bc9803/MIP4/MIP4c2-Subproposals/MIP4c2-SP8.md -q -O - 2> /dev/null)"
    string constant public MIP4c2SP8  = "0x0dc7594e00080501f76e44855a2b5af3ef8af602b57b8ab579e2a6064dee7a8c";

    // MIP4c2-SP13: MIP0 Amendments
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/15c887ab8aa761c1008261281669f5cba4bc9803/MIP4/MIP4c2-Subproposals/MIP4c2-SP13.md -q -O - 2> /dev/null)"
    string constant public MIP4c2SP13 = "0xa2272f68ad3e290d9d62319f40ef9690ad6f559d5d740c6ae591db696e55719d";


    // Declaration of Intent Proposal

    // MIP13c3-SP10: Declaration of Intent - eurDai
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/15c887ab8aa761c1008261281669f5cba4bc9803/MIP13/MIP13c3-Subproposals/MIP13c3-SP10.md -q -O - 2> /dev/null)"
    string constant public MIP13c3SP10 = "0x8e178c6ca873abf6d0dd32cc91f4faf128a71e672a2300a7170a9927a0a0afd9";


    // Content Production Core Unit Onboarding Set

    // MIP39c2-SP5: Content Production Core Unit, MKT-001
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/15c887ab8aa761c1008261281669f5cba4bc9803/MIP39/MIP39c2-Subproposals/MIP39c2-SP5.md -q -O - 2> /dev/null)"
    string constant public MIP39c2SP5 = "0x9d23ee8bc0890c7b84a80c561e553cb6119bb53bbafa7acf4a656745c624d5ac";

    // MIP40c3-SP5: Core Unit Budget - MKT-001
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/15c887ab8aa761c1008261281669f5cba4bc9803/MIP40/MIP40c3-Subproposals/MIP40c3-SP5.md -q -O - 2> /dev/null)"
    string constant public MIP40c3SP5 = "0xea00ad9591bea85619bec30a88df41f3d63375aa5b6a4aaf686effdc05755e7f";

    // MIP41c4-SP5: Facilitator Onboarding, MKT-001
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/15c887ab8aa761c1008261281669f5cba4bc9803/MIP41/MIP41c4-Subproposals/MIP41c4-SP5.md -q -O - 2> /dev/null)"
    string constant public MIP41c4SP5 = "0x7f7f866c4a62c3b64467367b2428f97001b1537d65fafe84a156ca08cffcb33a";


    // Growth Core Unit Onboarding Set

    // MIP39c2-SP4: Growth Core Unit, GRO-001
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/15c887ab8aa761c1008261281669f5cba4bc9803/MIP39/MIP39c2-Subproposals/MIP39c2-SP4.md -q -O - 2> /dev/null)"
    string constant public MIP39c2SP4 = "0x8bfb5e77f533efc02cf89b42fc1eece340b0d3ef9d358b881dc2f45feabc3c6b";

    // MIP40c3-SP4: Core Unit Budget, GRO-001
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/15c887ab8aa761c1008261281669f5cba4bc9803/MIP40/MIP40c3-Subproposals/MIP40c3-SP4.md -q -O - 2> /dev/null)"
    string constant public MIP40c3SP4 = "0x3ffe025db79d0f2ce2b000a25d8ee07d84ac7e7e57865a98fc5bfddc4aa65eb7";

    // MIP41c4-SP4: Facilitator Onboarding, GRO-001
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/15c887ab8aa761c1008261281669f5cba4bc9803/MIP41/MIP41c4-Subproposals/MIP41c4-SP4.md -q -O - 2> /dev/null)"
    string constant public MIP41c4SP4 = "0xa7727ced59c0eca2611893278a4479b45e5386e32fba9d758a11ca8bc9997035";


    // Protocol Engineering Core Unit Onboarding Set

    // MIP39c2-SP7: Adding Protocol Engineering Core Unit
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/15c887ab8aa761c1008261281669f5cba4bc9803/MIP39/MIP39c2-Subproposals/MIP39c2-SP7.md -q -O - 2> /dev/null)"
    string constant public MIP39c2SP7 = "0x086350896419979fc0bd7efe9d4261b1b0dda0a516f22c2599beaa13fa7067df";

    // MIP40c3-SP7: Modify Protocol Engineering Core Unit Budget
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/15c887ab8aa761c1008261281669f5cba4bc9803/MIP40/MIP40c3-Subproposals/MIP40c3-SP7.md -q -O - 2> /dev/null)"
    string constant public MIP40c3SP7 = "0xcbc6d6da4fbfd923473656ccf5c7294407d0dc2d85846d495fcba5892be61a08";

    // MIP41c4-SP7: Facilitator Onboarding, Protocol Engineering Core Unit
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/15c887ab8aa761c1008261281669f5cba4bc9803/MIP41/MIP41c4-Subproposals/MIP41c4-SP7.md -q -O - 2> /dev/null)"
    string constant public MIP41c4SP7 = "0xed04b7f73b2e39a470d8b5bff6b2f5a3fb46700775775b084f5c2873734a2969";


    // Swag Shop Core Unit Onboarding Set

    // MIP39c2-SP6: MakerDAO Shop Core Unit, MDS-001
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/15c887ab8aa761c1008261281669f5cba4bc9803/MIP39/MIP39c2-Subproposals/MIP39c2-SP6.md -q -O - 2> /dev/null)"
    string constant public MIP39c2SP6 = "0x2f0189cf1b3e6ca83a4f2b9ebc77b23f39dcb9606f1087f8e184d6a28ef1289a";

    // MIP40c3-SP6: MakerDAO Shop Budget, MDS-001
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/15c887ab8aa761c1008261281669f5cba4bc9803/MIP40/MIP40c3-Subproposals/MIP40c3-SP6.md -q -O - 2> /dev/null)"
    string constant public MIP40c3SP6 = "0xeef22e1310f1c942387e900fe81d8879a65784b7045554c1a7c73dd461ad724f";

    // MIP41c4-SP6: MakerDAO Shop Facilitator Onboarding, MDS-001
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/15c887ab8aa761c1008261281669f5cba4bc9803/MIP41/MIP41c4-Subproposals/MIP41c4-SP6.md -q -O - 2> /dev/null)"
    string constant public MIP41c4SP6 = "0xcc00ac48fd505d52c4a75782a5ff143d7da412a0d749956e97f246d010d01b77";


    // Disable Office Hours
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // ------------- Get all the needed addresses from Chainlog -------------

        address MCD_VAT        = DssExecLib.vat();
        address MCD_VOW        = DssExecLib.vow();
        address MCD_JOIN_DAI   = DssExecLib.daiJoin();


        // Payments to the Protocol Engineering Core Unit

        // Payment of monthly expenses for May 2021
        DssExecLib.sendPaymentFromSurplusBuffer(PE_MULTISIG, PE_MONTHLY_EXPENSES);

        // Payment of continuous operation lump-sum
        DssExecLib.sendPaymentFromSurplusBuffer(PE_CO_MULTISIG, PE_CO_LUMP_SUM);
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 4 days, address(action_)) public {}
}
