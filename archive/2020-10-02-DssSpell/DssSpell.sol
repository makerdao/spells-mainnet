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
import "lib/dss-interfaces/src/dss/GemJoinImplementationAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";

contract SpellAction {
    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.1.2/contracts.json

    address constant MCD_VAT         = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant MCD_JUG         = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;

    // TUSD-A specific addresses
    address constant TUSD_IMPL       = 0xffc40F39806F1400d8278BfD33823705b5a4c196;
    address constant MCD_JOIN_TUSD_A = 0x4454aF7C8bb9463203b66C816220D41ED7837f44;

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
    uint256 constant    TWO = 1000000000627937192491029810;
    uint256 constant  THREE = 1000000000937303470807876289;
    uint256 constant   FOUR = 1000000001243680656318820312;
    uint256 constant  EIGHT = 1000000002440418608258400030;
    uint256 constant TWELVE = 1000000003593629043335673582;
    uint256 constant  FIFTY = 1000000012857214317438491659;

    function execute() external {
        // Set the global debt ceiling to 1,456,000,000
        // 1,416 (current DC) + 40 (PAXUSD-A)
        VatAbstract(MCD_VAT).file("Line", 1456 * MILLION * RAD);

        // Set the PAXUSD-A debt ceiling
        //
        // Existing debt ceiling: 60 million
        // New debt ceiling: 100 million
        VatAbstract(MCD_VAT).file("PAXUSD-A", "line", 100 * MILLION * RAD);

        // Set the ETH-A stability fee
        //
        // Previous: 2.25%
        // New: 2%
        JugAbstract(MCD_JUG).drip("ETH-A"); // drip right before
        JugAbstract(MCD_JUG).file("ETH-A", "duty", TWO);

        // Set the BAT-A stability fee
        //
        // Previous: 4.25%
        // New: 4%
        JugAbstract(MCD_JUG).drip("BAT-A"); // drip right before
        JugAbstract(MCD_JUG).file("BAT-A", "duty", FOUR);

        // Set the USDC-A stability fee
        //
        // Previous: 4.25%
        // New: 4%
        JugAbstract(MCD_JUG).drip("USDC-A"); // drip right before
        JugAbstract(MCD_JUG).file("USDC-A", "duty", FOUR);

        // Set the USDC-B stability fee
        //
        // Previous: 50.25%
        // New: 50%
        JugAbstract(MCD_JUG).drip("USDC-B"); // drip right before
        JugAbstract(MCD_JUG).file("USDC-B", "duty", FIFTY);

        // Set the WBTC-A stability fee
        //
        // Previous: 4.25%
        // New: 4%
        JugAbstract(MCD_JUG).drip("WBTC-A"); // drip right before
        JugAbstract(MCD_JUG).file("WBTC-A", "duty", FOUR);

        // Set the TUSD-A stability fee
        //
        // Previous: 4.25%
        // New: 4%
        JugAbstract(MCD_JUG).drip("TUSD-A"); // drip right before
        JugAbstract(MCD_JUG).file("TUSD-A", "duty", FOUR);

        // Set the KNC-A stability fee
        //
        // Previous: 4.25%
        // New: 4%
        JugAbstract(MCD_JUG).drip("KNC-A"); // drip right before
        JugAbstract(MCD_JUG).file("KNC-A", "duty", FOUR);

        // Set the ZRX-A stability fee
        //
        // Previous: 4.25%
        // New: 4%
        JugAbstract(MCD_JUG).drip("ZRX-A"); // drip right before
        JugAbstract(MCD_JUG).file("ZRX-A", "duty", FOUR);

        // Set the MANA-A stability fee
        //
        // Previous: 12.25%
        // New: 12%
        JugAbstract(MCD_JUG).drip("MANA-A"); // drip right before
        JugAbstract(MCD_JUG).file("MANA-A", "duty", TWELVE);

        // Set the USDT-A stability fee
        //
        // Previous: 8.25%
        // New: 8%
        JugAbstract(MCD_JUG).drip("USDT-A"); // drip right before
        JugAbstract(MCD_JUG).file("USDT-A", "duty", EIGHT);

        // Set the PAXUSD-A stability fee
        //
        // Previous: 4.25%
        // New: 4%
        JugAbstract(MCD_JUG).drip("PAXUSD-A"); // drip right before
        JugAbstract(MCD_JUG).file("PAXUSD-A", "duty", FOUR);

        // Set the LINK-A stability fee
        //
        // Previous: 2.25%
        // New: 2%
        JugAbstract(MCD_JUG).drip("LINK-A"); // drip right before
        JugAbstract(MCD_JUG).file("LINK-A", "duty", TWO);

        // Set the LRC-A stability fee
        //
        // Previous: 3.25%
        // New: 3%
        JugAbstract(MCD_JUG).drip("LRC-A"); // drip right before
        JugAbstract(MCD_JUG).file("LRC-A", "duty", THREE);  

        // Set the COMP-A stability fee
        //
        // Previous: 3.25%
        // New: 3%
        JugAbstract(MCD_JUG).drip("COMP-A"); // drip right before
        JugAbstract(MCD_JUG).file("COMP-A", "duty", THREE);    

        // Unblock TUSD
        GemJoinImplementationAbstract(MCD_JOIN_TUSD_A).setImplementation(TUSD_IMPL, 1);
    }
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
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/cbf3dd1eab77cb3c5fe3b8db22a08b55a8d4aeaf/governance/votes/Executive%20vote%20-%20October%202%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-10-02 MakerDAO Executive Spell | Hash: 0xbf384941515f3594205f47f8e4675883118fead22472792119cf051ed37f29a8";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    // modifier officeHours {
    //     uint day = (now / 1 days + 3) % 7;
    //     require(day < 5, "Can only be cast on a weekday");
    //     uint hour = now / 1 hours % 24;
    //     require(hour >= 14 && hour < 21, "Outside office hours");
    //     _;
    // }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
