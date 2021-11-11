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
import "lib/dss-interfaces/src/dss/PotAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";

contract SpellAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    string constant public description = "2020-06-12 MakerDAO Executive Spell";

    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.0.7/contracts.json
    //
    // Contract addresses pertaining to the SCD ecosystem can be found at:
    //     https://github.com/makerdao/sai#dai-v1-current-deployments
    address constant public MCD_JUG             = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public MCD_POT             = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    uint256 constant public ONE_PCT_RATE = 1000000000315522921573372069;
    uint256 constant public ONE_SEVENTY_FIVE_PCT_RATE = 1000000000550121712943459312;
    uint256 constant public TWO_PCT_RATE = 1000000000627937192491029810;
    uint256 constant public FIFTY_ONE_PCT_RATE = 1000000013067911387605883890;

    // decimals & precision
    uint256 constant public MILLION             = 10 ** 6;
    uint256 constant public RAD                 = 10 ** 45;

    function execute() external {

        PotAbstract(MCD_POT).drip();
        JugAbstract(MCD_JUG).drip("ETH-A");
        JugAbstract(MCD_JUG).drip("BAT-A");
        JugAbstract(MCD_JUG).drip("USDC-A");
        JugAbstract(MCD_JUG).drip("USDC-B");
        JugAbstract(MCD_JUG).drip("WBTC-A");
        JugAbstract(MCD_JUG).drip("TUSD-A");

        // MCD Modifications
        // https://vote.makerdao.com/polling-proposal/qmyyuvc3fphgt9bqotkedijxt5mpnjfktz3je9c2cspfae
        // Increase all stability fees by 1%

        uint256 ETH_FEE = ONE_PCT_RATE;
        JugAbstract(MCD_JUG).file("ETH-A", "duty", ETH_FEE);

        uint256 BAT_FEE = ONE_PCT_RATE;
        JugAbstract(MCD_JUG).file("BAT-A", "duty", BAT_FEE);

        uint256 USDC_FEE_A = ONE_SEVENTY_FIVE_PCT_RATE;
        JugAbstract(MCD_JUG).file("USDC-A", "duty", USDC_FEE_A);

        uint256 USDC_FEE_B = FIFTY_ONE_PCT_RATE;
        JugAbstract(MCD_JUG).file("USDC-B", "duty", USDC_FEE_B);

        uint256 WBTC_FEE = TWO_PCT_RATE;
        JugAbstract(MCD_JUG).file("WBTC-A", "duty", WBTC_FEE);

        uint256 TUSD_FEE = ONE_PCT_RATE;
        JugAbstract(MCD_JUG).file("TUSD-A", "duty", TUSD_FEE);

        // Set the Dai Savings Rate
        // Updating DSR to maintain DSR spread of 0% with base rate
        // Existing Rate: 0%
        // New Rate: 1%
        uint256 DSR_RATE = ONE_PCT_RATE;
        PotAbstract(MCD_POT).file("dsr", DSR_RATE);
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
