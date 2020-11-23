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
import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dss/ChainlogAbstract.sol";

contract SpellAction {
    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.1.5/contracts.json
    ChainlogAbstract constant CHANGELOG = ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

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

    function execute() external {
        // Proving the Pause Proxy has access to the MCD core system at the execution time
        address MCD_VAT = CHANGELOG.getAddress("MCD_VAT");
        require(VatAbstract(MCD_VAT).wards(address(this)) == 1, "no-access");
    }
}

contract DssSpell {
    ChainlogAbstract constant CHANGELOG = ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    address MCD_PAUSE = CHANGELOG.getAddress("MCD_PAUSE");

    DSPauseAbstract public pause = DSPauseAbstract(MCD_PAUSE);
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    // Office hours enabled if true
    bool   constant public officeHours = false;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/a7c8ddb3f8d8ea71cb123b9aa45d9d7eaed8d6f0/governance/votes/Executive%20vote%20-%20November%2023%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-11-23 MakerDAO Executive Spell | Hash: 0x3567e2282249022428233fe24a48a25ebc34468f2183869109f2bd590f48ef28";

    // MIP24: Emergency Voting System
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5f81894b407c26373391fe6c18803eb832944d3a/MIP24/mip24.md -q -O - 2>/dev/null)"
    string constant public MIP24 = "0x6d39f78a3343fb030da792962abdd12ca1b0c9384b92f496e8a070e97cf3c1c6";

    // MIP25: Flash Mint Module
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/bda3f65b83668f2025e69be7897a48cb23af0bd9/MIP25/mip25.md -q -O - 2>/dev/null)"
    string constant public MIP25 = "0xd2550d2b15464b6bf3e49bc424a85e6411abf27e72247c4325f6d9b2ba4d9100";

    // MIP27: Debt Ceiling Instant Access Module
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/c3d5f1dc77c48b858794c2308e630a4c98f7a8e4/MIP27/mip27.md -q -O - 2>/dev/null)"
    string constant public MIP27 = "0x2848c1ef785a2182d9ccd7171e90eba847330f3da2106500f0f3e097a3bf5553";

    // MIP28: Operational Support Domain Definition
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5f81894b407c26373391fe6c18803eb832944d3a/MIP28/mip28.md -q -O - 2>/dev/null)"
    string constant public MIP28 = "0x63aa04048b723e496190b080d9d25e1ba90c7d8eeb9060404ca50d665506e915";

    // MIP4c2-SP6: Calendar Exceptions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5f81894b407c26373391fe6c18803eb832944d3a/MIP4/MIP4c2-Subproposals/MIP4c2-SP6.md -q -O - 2>/dev/null)"
    string constant public MIP4c2SP6 = "0xab503375dd94caebafadf3a7eed7809cca49441877cc22056645d6cc94ba4105";

    // MIP13c3-SP6: SourceCred Funding
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5f81894b407c26373391fe6c18803eb832944d3a/MIP13/MIP13c3-Subproposals/MIP13c3-SP6.md -q -O - 2>/dev/null)"
    string constant public MIP13c3SP6 = "0xe76bd18dfb2eb9aa893e81d4bfa6703e71f17954e4c4800937c672aa6d8b84f6";

    // MIP28c7-SP1: Subproposal for Operational Support Domain Facilitator Onboarding
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/5f81894b407c26373391fe6c18803eb832944d3a/MIP28/MIP28c7-Subproposals/MIP28c7-SP1.md -q -O - 2>/dev/null)"
    string constant public MIP28c7SP1 = "0x685efd19c76135ad5f3313b28c556e5c918ad5e121b11ddd9a60c793ad78cc94";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 4 days + 2 hours;
    }

    modifier limited {
        if (officeHours) {
            uint day = (now / 1 days + 3) % 7;
            require(day < 5, "Can only be cast on a weekday");
            uint hour = now / 1 hours % 24;
            require(hour >= 14 && hour < 21, "Outside office hours");
        }
        _;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public limited {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
