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
import "lib/dss-interfaces/src/dss/CatAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/PotAbstract.sol";
import "lib/dss-interfaces/src/dss/SpotAbstract.sol";
import "lib/dss-interfaces/src/dss/GemJoinAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipAbstract.sol";

contract PsmAbstract {
    function daiJoin() external view returns (address);
    function gemJoin() external view returns (address);
    function vow() external view returns (address);
    function file(bytes32, uint256) external;
}

contract SpellAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    string constant public description = "2020-07-10 MakerDAO Executive Spell";

    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.0.8/contracts.json
    address constant MCD_VAT                = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant MCD_VOW                = 0xA950524441892A31ebddF91d3cEEFa04Bf454466;
    address constant MCD_CAT                = 0x78F2c2AF65126834c51822F56Be0d7469D7A523E;
    address constant MCD_JUG                = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant MCD_POT                = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address constant MCD_SPOT               = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant MCD_END                = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;
    address constant FLIPPER_MOM            = 0x9BdDB99625A711bf9bda237044924E34E8570f75;
    address constant MCD_JOIN_DAI           = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address constant MCD_JOIN_PSM_USDC_A    = address(0);
    address constant MCD_FLIP_PSM_USDC_A    = address(0);
    address constant PIP_USDC               = 0x77b68899b99b686F415d074278a9a16b336085A0;
    address constant PSM_USDC_A             = address(0);
    address constant USDC                   = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    uint256 constant THOUSAND = 10**3;
    uint256 constant MILLION  = 10**6;
    uint256 constant WAD      = 10**18;
    uint256 constant RAY      = 10**27;
    uint256 constant RAD      = 10**45;

    uint256 constant ZERO_PCT_RATE = 1000000000000000000000000000;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'

    function execute() external {
        // Perform drips
        PotAbstract(MCD_POT).drip();

        JugAbstract(MCD_JUG).drip("ETH-A");
        JugAbstract(MCD_JUG).drip("BAT-A");
        JugAbstract(MCD_JUG).drip("USDC-A");
        JugAbstract(MCD_JUG).drip("USDC-B");
        JugAbstract(MCD_JUG).drip("TUSD-A");
        JugAbstract(MCD_JUG).drip("WBTC-A");
        JugAbstract(MCD_JUG).drip("KNC-A");
        JugAbstract(MCD_JUG).drip("ZRX-A");

        // Set the global debt ceiling
        // Existing Line: 245m
        // New Line: 295m
        VatAbstract(MCD_VAT).file("Line", 295 * MILLION * RAD);


        /* ---- PSM-USDC-A Collateral Onboarding Spell ---- */
        bytes32 ilk = "PSM-USDC-A";

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_PSM_USDC_A).vat() == MCD_VAT,              "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_PSM_USDC_A).ilk() == ilk,                  "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_PSM_USDC_A).gem() == USDC,                 "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_PSM_USDC_A).dec() == 6,                    "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_PSM_USDC_A).vat()    == MCD_VAT,              "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_PSM_USDC_A).ilk()    == ilk,                  "flip-ilk-not-match");
        require(PsmAbstract(PSM_USDC_A).vow()              == MCD_VOW,              "psm-vow-not-match");
        require(PsmAbstract(PSM_USDC_A).daiJoin()          == MCD_JOIN_DAI,         "psm-dai-join-not-match");
        require(PsmAbstract(PSM_USDC_A).gemJoin()          == MCD_JOIN_PSM_USDC_A,  "psm-gem-join-not-match");

        // Set the USDC PIP in the Spotter
        SpotAbstract(MCD_SPOT).file(ilk, "pip", PIP_USDC);

        // Set the PSM-USDC-A Flipper in the Cat (WILL NOT BE USED IN NORMAL OPERATION)
        CatAbstract(MCD_CAT).file(ilk, "flip", MCD_FLIP_PSM_USDC_A);

        // Init PSM-USDC-A ilk in Vat
        VatAbstract(MCD_VAT).init(ilk);
        // Init PSM-USDC-A ilk in Jug
        JugAbstract(MCD_JUG).init(ilk);

        // Allow PSM-USDC-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_PSM_USDC_A);

        // Allow PSM-USDC-A to access the Join adapter
        GemJoinAbstract(MCD_JOIN_PSM_USDC_A).rely(PSM_USDC_A);

        // The following authorizations WILL NOT BE USED IN NORMAL OPERATION:
        // Allow Cat to kick auctions in PSM-USDC-A Flipper
        FlipAbstract(MCD_FLIP_PSM_USDC_A).rely(MCD_CAT);
        // Allow End to yank auctions in PSM-USDC-A Flipper
        FlipAbstract(MCD_FLIP_PSM_USDC_A).rely(MCD_END);
        // Allow FlipperMom to access to the PSM-USDC-A Flipper
        FlipAbstract(MCD_FLIP_PSM_USDC_A).rely(FLIPPER_MOM);
        //

        // Set the PSM-USDC-A feeIn to 0.1%
        PsmAbstract(PSM_USDC_A).file("feeIn", 0.1 * 10 * RAY / 100 / 10);
        // Set the PSM-USDC-A feeOut to 0.1%
        PsmAbstract(PSM_USDC_A).file("feeOut", 0.1 * 10 * RAY / 100 / 10);

        // Set the PSM-USDC-A debt ceiling to 50 MM
        VatAbstract(MCD_VAT).file(ilk, "line", 50 * MILLION * RAD);
        // Set the PSM-USDC-A dust
        VatAbstract(MCD_VAT).file(ilk, "dust", 0);
        // Set the PSM-USDC-A stability fee to 0%
        JugAbstract(MCD_JUG).file(ilk, "duty", ZERO_PCT_RATE);
        // Set the PSM-USDC-A min collateralization ratio to 100%
        SpotAbstract(MCD_SPOT).file(ilk, "mat", 100 * RAY / 100);
        // Update PSM-USDC-A spot value in Vat
        SpotAbstract(MCD_SPOT).poke(ilk);

        // The following values WILL NOT BE USED IN NORMAL OPERATION:
        // Set the Lot size to 50,000 USDC
        CatAbstract(MCD_CAT).file(ilk, "lump", 50 * THOUSAND * WAD);
        // Set the PSM-USDC-A liquidation penalty to 0%
        CatAbstract(MCD_CAT).file(ilk, "chop", 100 * RAY / 100);
        // Set the PSM-USDC-A percentage between bids to 3%
        FlipAbstract(MCD_FLIP_PSM_USDC_A).file("beg", 103 * WAD / 100);
        // Set the PSM-USDC-A time max time between bids to 6 hours
        FlipAbstract(MCD_FLIP_PSM_USDC_A).file("ttl", 6 hours);
        // Set the PSM-USDC-A max auction duration to 6 hours
        FlipAbstract(MCD_FLIP_PSM_USDC_A).file("tau", 6 hours);
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
