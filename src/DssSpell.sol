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
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dss/VowAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipperMomAbstract.sol";
import "lib/dss-interfaces/src/dss/IlkRegistryAbstract.sol";

contract SpellAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/c8e9f709f4bc5d0384b47e0109eb7555f08b84fc/governance/votes/Executive%20vote%20-%20August%2014%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-08-14 MakerDAO Weekly Executive Spell | Hash: 0x97294bc0de2100192a54a618351a84574e5d1998da234152e68b4065ac9bea0f";

    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.0.9/contracts.json

    address constant MCD_VAT         = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant MCD_JUG         = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant MCD_VOW         = 0xA950524441892A31ebddF91d3cEEFa04Bf454466;
    address constant MCD_FLIP_TUSD_A = 0x04C42fAC3e29Fd27118609a5c36fD0b3Cb8090b3;
    address constant FLIPPER_MOM     = 0x9BdDB99625A711bf9bda237044924E34E8570f75;
    address constant ILK_REGISTRY    = 0xbE4F921cdFEf2cF5080F9Cf00CC2c14F1F96Bd07;

    uint256 constant MILLION  = 10 ** 6;
    uint256 constant RAD      = 10 ** 45;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 0%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.06)/(60 * 60 * 24 * 365) )'
    //
    uint256 constant SIX_PCT_RATE       = 1000000001847694957439350562;
    uint256 constant FORTYFOUR_PCT_RATE = 1000000011562757347033522598;

    function execute() external {
        bytes32[] memory ilks = IlkRegistryAbstract(ILK_REGISTRY).list();

        for(uint i = 0; i < ilks.length; i++) {
            // Set all ilks dust value from 20 Dai to 100 Dai
            VatAbstract(MCD_VAT).file(ilks[i], "dust", 100 * RAD);
        }

        // Set the MANA-A stability fee
        // value is determined by the rate accumulator calculation (see above)
        //  ex. an 8% annual rate will be 1000000002440418608258400030
        //
        // Existing Rate: 8%
        // New Rate: 6%
        JugAbstract(MCD_JUG).drip("MANA-A");
        JugAbstract(MCD_JUG).file("MANA-A", "duty", SIX_PCT_RATE);

        // Set the USDC-B stability fee
        // value is determined by the rate accumulator calculation (see above)
        //  ex. an 8% annual rate will be 1000000002440418608258400030
        //
        // Existing Rate: 46%
        // New Rate: 44%
        JugAbstract(MCD_JUG).drip("USDC-B");
        JugAbstract(MCD_JUG).file("USDC-B", "duty", FORTYFOUR_PCT_RATE);

        // Sets the system surplus buffer from 500k Dai to 2mm Dai
        VowAbstract(MCD_VOW).file("hump", 2 * MILLION * RAD);

        // Easter Egg, if you see this first Mariano will send you DAI
        // Our improved testing caught that TUSD-A liquidations are set "on"
        // when they should be "off".  We are fixing this misconfiguration here.
        //
        // Disable TUSD-A liquidations
        FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_TUSD_A);
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

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    function description() public view returns (string memory) {
        return SpellAction(action).description();
    }

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
