// Copyright (C) 2020, The Maker Foundation
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
import "lib/dss-interfaces/src/dss/PotAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";

contract SaiMomLike {
    function setCap(uint256) external;
    function setFee(uint256) external;
}

contract SpellAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    string  constant public description = "04/10/2020 MakerDAO Executive Spell";

    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.0.4/contracts.json
    //
    // Contract addresses pertaining to the SCD ecosystem can be found at:
    //     https://github.com/makerdao/sai#dai-v1-current-deployments
    address constant public MCD_VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public MCD_JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public MCD_POT = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    uint256 constant public ZERO_FIVE_PCT_RATE = 1000000000158153903837946257;
    uint256 constant public ONE_PCT_RATE =       1000000000315522921573372069;
    uint256 constant public SIXTEEN_PCT_RATE =   1000000004706367499604668374;

    uint256 constant public RAD = 10**45;
    uint256 constant public MILLION = 10**6;

    function execute() external {

        // Drip Pot and Jugs prior to all modifications.
        PotAbstract(MCD_POT).drip();
        JugAbstract(MCD_JUG).drip("ETH-A");
        JugAbstract(MCD_JUG).drip("BAT-A");
        JugAbstract(MCD_JUG).drip("USDC-A");

        // MCD Modifications

        // Set the ETH-A stability fee
        // https://vote.makerdao.com/polling-proposal/qmcdbetspgy9jkfrfdvgzbwtemrkfgfmeaysudlruz2j5r
        // Existing Rate: 0.5%
        // New Rate: 1%
        uint256 ETH_FEE = ONE_PCT_RATE;
        JugAbstract(MCD_JUG).file("ETH-A", "duty", ETH_FEE);

        // Set the BAT-A stability fee
        // https://vote.makerdao.com/polling-proposal/qmcdbetspgy9jkfrfdvgzbwtemrkfgfmeaysudlruz2j5r
        // Existing Rate: 0.5%
        // New Rate: 1%
        uint256 BAT_FEE = ONE_PCT_RATE;
        JugAbstract(MCD_JUG).file("BAT-A", "duty", BAT_FEE);

        // Set the Dai Savings Rate
        // Updating DSR to maintain DSR spread of 0.5% with updated ETH-A Stability Fee
        // Existing Rate: 0%
        // New Rate: 0.5%
        uint256 DSR_RATE = ZERO_FIVE_PCT_RATE;
        PotAbstract(MCD_POT).file("dsr", DSR_RATE);

        // Set the USDC stability fee
        // https://vote.makerdao.com/polling-proposal/qmwtwpa8fxd7r4x2dhdauo2gpb1kfrc3gt7mhdtzmv4e2o
        // Existing Rate: 12%
        // New Rate: 16%
        uint256 USDC_FEE = SIXTEEN_PCT_RATE;
        JugAbstract(MCD_JUG).file("USDC-A", "duty", USDC_FEE);

    }
}

contract DssSpell {

    DSPauseAbstract  public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address          public action;
    bytes32          public tag;
    uint256          public eta;
    bytes            public sig;
    uint256          public expiration;
    bool             public done;

    uint256 constant internal MILLION = 10**6;

    address constant public SAIMOM = 0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C;
    uint256 constant SCD_EIGHT_FIVE_PCT_FEE = 1000000002586884420913935572;

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

        // NOTE: 'eta' check should mimic the old behavior of 'done', thus
        // preventing these SCD changes from being executed again.

        // Raise Stability Fee in SCD to 8.5% (from 8%)
        // https://vote.makerdao.com/polling-proposal/qmej8jxjscw9wznah7rrccgkrmsy4bcyt3bfhpwr1qwwyv
        // Existing Rate: 8%
        // New Rate: 8.5%
        SaiMomLike(SAIMOM).setFee(SCD_EIGHT_FIVE_PCT_FEE);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
