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
import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dss/PotAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/SpotAbstract.sol";
import "lib/dss-interfaces/src/dss/OsmAbstract.sol";
import "lib/dss-interfaces/src/sai/SaiMomAbstract.sol";
import "lib/dss-interfaces/src/sai/SaiTopAbstract.sol";

contract SaiSlayer {
    uint256 constant public T2020_05_12_1600UTC = 1589299200;
    SaiTopAbstract constant public SAITOP = SaiTopAbstract(0x9b0ccf7C8994E19F39b2B4CF708e0A7DF65fA8a3);

    function cage() public {
        require(now >= T2020_05_12_1600UTC);
        SAITOP.cage();
    }
}

contract NewMkrOracle {
    function read() external pure returns (bytes32) {
        revert();
    }
    function peek() external pure returns (bytes32, bool) {
        return (0, false);
    }
}

contract SpellAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    string constant public description = "2020-04-24 MakerDAO Executive Spell";

    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.0.5/contracts.json
    //
    // Contract addresses pertaining to the SCD ecosystem can be found at:
    //     https://github.com/makerdao/sai#dai-v1-current-deployments
    address constant public MCD_VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public MCD_JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public MCD_POT = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address constant public MCD_SPOT = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant public MCD_PAUSE = 0xbE286431454714F511008713973d3B053A2d38f3;
    address constant public ETHUSD = 0x64DE91F5A373Cd4c28de3600cB34C7C6cE410C85;
    address constant public BTCUSD = 0xe0F30cb149fAADC7247E953746Be9BbBB6B5751f;

    address constant public SET_ETHUSD = 0x97C3e595e8f80169266B5534e4d7A1bB58BB45ab;
    address constant public DYDX_BTCUSD = 0xbf63446ecF3341e04c6569b226a57860B188edBc;
    address constant public SET_BTCUSD = 0x538038E526517680735568f9C5342c6E68bbDA12;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    uint256 constant public ZERO_PCT_RATE =  1000000000000000000000000000;
    uint256 constant public SIX_PCT_RATE = 1000000001847694957439350562;

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
        // https://vote.makerdao.com/polling-proposal/qmefnpf1bbxac1o9clgedgbuvbtzrrji5yacopykftr4yb
        // Existing Rate: 0%
        // New Rate: 0%
        uint256 ETH_FEE = ZERO_PCT_RATE;
        JugAbstract(MCD_JUG).file("ETH-A", "duty", ETH_FEE);

        // Set the BAT-A stability fee
        // https://vote.makerdao.com/polling-proposal/qmefnpf1bbxac1o9clgedgbuvbtzrrji5yacopykftr4yb
        // Existing Rate: 0%
        // New Rate: 0%
        uint256 BAT_FEE = ZERO_PCT_RATE;
        JugAbstract(MCD_JUG).file("BAT-A", "duty", BAT_FEE);

        // Set the USDC stability fee
        // https://vote.makerdao.com/polling-proposal/qmqza5ad5pdlduzyd29akfoixcgcpkggaesc3bu75w95nr
        // Existing Rate: 8%
        // New Rate: 6%
        uint256 USDC_FEE = SIX_PCT_RATE;
        JugAbstract(MCD_JUG).file("USDC-A", "duty", USDC_FEE);

        // Set the Dai Savings Rate
        // Updating DSR to maintain DSR spread of 0% with updated ETH-A Stability Fee
        // Existing Rate: 0%
        // New Rate: 0%
        uint256 DSR_RATE = ZERO_PCT_RATE;
        PotAbstract(MCD_POT).file("dsr", DSR_RATE);

        // Set the ETH-A debt ceiling
        // ETH_LINE is the number of Dai that can be created with WETH token collateral
        //  ex. a 100 million Dai ETH ceiling will be ETH_LINE = 100000000
        // Existing Line: 90m
        // New Line: 100m
        uint256 ETH_LINE = 100 * MILLION;
        VatAbstract(MCD_VAT).file("ETH-A", "line", ETH_LINE * RAD);

        // set the global debt ceiling to 123,000,000
        VatAbstract(MCD_VAT).file("Line", 123000000 * RAD);

        // Set the USDC-A liquidation ratio
        // USDC_MAT is the percentage ratio at which a USDC-A Vault can be liquidated
        // https://vote.makerdao.com/polling-proposal/qmwdspr732kcrymg87csubobig9ms4avxzbbhwtrhwbp7v
        // Existing Mat: 125%
        // New Mat: 120%
        uint256 USDC_MAT = 1.2 * 10 ** 27;
        SpotAbstract(MCD_SPOT).file("USDC-A", "mat", USDC_MAT);

        OsmAbstract(ETHUSD).kiss(SET_ETHUSD);
        OsmAbstract(BTCUSD).kiss(DYDX_BTCUSD);
        OsmAbstract(BTCUSD).kiss(SET_BTCUSD);

        DSPauseAbstract(MCD_PAUSE).setDelay(60 * 60 * 12);
    }
}

contract DssSpell {

    DSPauseAbstract  public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    SaiMomAbstract   public saiMom =
        SaiMomAbstract(0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C);
    address          public action;
    bytes32          public tag;
    uint256          public eta;
    bytes            public sig;
    uint256          public expiration;
    bool             public done;
    SaiSlayer        public saiSlayer;
    NewMkrOracle     public newMkrOracle;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;

        saiSlayer = new SaiSlayer();
        newMkrOracle = new NewMkrOracle();
    }

    function description() public view returns (string memory) {
        return SpellAction(action).description();
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);

        // Set SaiSlayer to cage the system after May 12th, 2020 at 16:00 UTC
        saiSlayer.SAITOP().setOwner(address(saiSlayer));

        // Set PEP of SCD to the new MKR Oracle
        saiMom.setPep(address(newMkrOracle));
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
