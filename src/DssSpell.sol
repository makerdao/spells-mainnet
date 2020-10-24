// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
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

pragma solidity 0.5.12;

import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";

contract SpellAction {
    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.1.3/contracts.json

    // Decimals & precision
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW

    function execute() external { }
}

contract DssSpell {
    DSPauseAbstract public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/<commit>/governance/votes/Executive%20vote%20-%20October%2026%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-10-26 MakerDAO Executive Spell | Hash: ";

    // MIP14: Protocol Dai Transfer
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/482a316c96428beae899e0c90a8a75e59a1cb180/MIP14/MIP14c2-Subproposal-Template.md -q -O - 2>/dev/null)"
    string constant public MIP15 = "0x61591fd490f5b8939622986bf66eb3c3e817c3f7789032fa30bc4fe516c4a3d8";

    // MIP20: Target Price Adjustment Module (Vox)
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/c8efd2826274a4eb175ee68606887d602e644989/MIP20/mip20.md -q -O - 2>/dev/null)"
    string constant public MIP20 = "0xfec4da66f1c567bc0fdaeab074f2568932953e82ddb0e4b256815ad38918802f";

    // MIP21: Real World Assets - Off-Chain Asset Backed Lender
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/f4647ee2d5f8d16b92b45402c273996fb45ecced/MIP21/MIP21.md -q -O - 2>/dev/null)"
    string constant public MIP21 = "0x6cee952dc6fbbf871e00193cc3958171f64884d7b260bc4401be862afd8b0ce3";

    // MIP22: Centrifuge Direct Liquidation Module
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/06a9cb1607ab79b0c0d57dd40b1ba6be4c21f8de/MIP22/mip22.md -q -O - 2>/dev/null)"
    string constant public MIP22 = "0xa6f24c19ac911679da2873a5f6d8f127034eb43e88fd8d9bde3ad32931376087";

    // MIP23: Domain Structure and Roles
    // Hash: seth keccak -- "$(wget <link> -q -O - 2>/dev/null)"
    string constant public MIP23 = "";

    // MIP13c3-SP3: Declaration of Intent - Strategic Reserves Fund
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/060d1d144ca216558399b4ad89c8c7eb82884669/MIP13/MIP13c3-Subproposals/MIP13c3-SP3.md -q -O - 2>/dev/null)"
    string constant public MIP13c3SP3 = "0xa3b7bd40055d7577b9be079bc4bce063d7b2863cf8ee54c9b8b530c410746d7c";

    // MIP13c3-SP4: Declaration of Intent & Commercial Points - Off-Chain Asset Backed Lender to onboard Real World Assets as Collateral for a DAI loan
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/8dd2d714065476a53635e87cc861e07de8a74a83/MIP13/MIP13c3-Subproposals/MIP13c3-SP4.md -q -O - 2>/dev/null)"
    string constant public MIP13c3SP4 = "0x8d852d29031a1bc7caabe642e1010880fc6b22e5f659b38ed73e0d5c9d7680b0";

    // MIP13c3-SP5: Declaration of Intent: Maker to commence onboarding work of Centrifuge based Collateral
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/60ee14995e61ba0bf52f2a863d430c3fcac19a29/MIP13/MIP13c3-Subproposals/MIP13c3-SP5.md -q -O - 2>/dev/null)"
    string constant public MIP13c3SP5 = "0xda7fc22f756a2b0535c44d187fd0316d986adcacd397ee2060007d20b515956c";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    modifier officeHours {
        uint day = (now / 1 days + 3) % 7;
        require(day < 5, "Can only be cast on a weekday");
        uint hour = now / 1 hours % 24;
        require(hour >= 14 && hour < 21, "Outside office hours");
        _;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public /* officeHours */ {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
