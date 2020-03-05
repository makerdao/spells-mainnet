pragma solidity ^0.5.12;

import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/PotAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/sai/SaiTubAbstract.sol";


contract SpellAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    string  constant public description = "2020-03-06 Weekly Executive: DSR spread adjustment";

    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.0.3/contracts.json
    //
    // Contract addresses pertaining to the SCD ecosystem can be found at:
    //     https://github.com/makerdao/sai#dai-v1-current-deployments
    address constant public MCD_PAUSE = 0xbE286431454714F511008713973d3B053A2d38f3;
    address constant public MCD_JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public MCD_POT = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    uint256 constant public SEVEN_PCT_RATE = 1000000002145441671308778766;
    uint256 constant public EIGHT_PCT_RATE = 1000000002440418608258400030;

    uint256 constant public RAD = 10**45;
    uint256 constant public MILLION = 10**6;

    function execute() external {

        // Drip Pot and Jugs prior to all modifications.
        PotAbstract(MCD_POT).drip();
        JugAbstract(MCD_JUG).drip("ETH-A");
        JugAbstract(MCD_JUG).drip("BAT-A");


        // MCD Modifications


        // Set the Dai Savings Rate
        // DSR_RATE is a value determined by the rate accumulator calculation (see above)
        //  ex. an 8% annual rate will be 1000000002440418608258400030
        //
        // Poll: Dai Savings Rate Spread Adjustment - March 2, 2020
        // https://vote.makerdao.com/polling-proposal/qmccrai2s7twl6y6yyhrznysnkbengrqg4ibhpw8cnhunp
        //
        // Existing Rate: 8%
        // New Rate: 7%
        uint256 DSR_RATE = SEVEN_PCT_RATE;
        PotAbstract(MCD_POT).file("dsr", DSR_RATE);


        // Set the ETH-A stability fee
        // ETH_FEE is a value determined by the rate accumulator calculation (see above)
        //  ex. an 8% annual rate will be 1000000002440418608258400030
        //
        // Poll: Dai Stability Fee Adjustment - March 2, 2020
        // https://vote.makerdao.com/polling-proposal/qmacgdz8euruq4lsqyzgjhumhexu5jnhihbmgbh54law7s
        //
        // Existing Rate: 8%
        // New Rate: 8%
        // Since the rate is not changing this week, we want to ensure that no other
        //  spell has changed the state preemptively.
        (uint256 dutyETH,) = JugAbstract(MCD_JUG).ilks("ETH-A");
        require(dutyETH == EIGHT_PCT_RATE, "Unexpected ETH-A Stability Fee");

    }
}

contract DssSpell {

    DSPauseAbstract  public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    SaiTubAbstract   public saiTub =
        SaiTubAbstract(0x448a5065aeBB8E423F0896E6c5D525C040f59af3);
    address          public action;
    bytes32          public tag;
    uint256          public eta;
    bytes            public sig;
    uint256          public expiration;
    bool             public done;

    uint256 constant internal MILLION = 10**6;
    uint256 constant internal WAD = 10**18;
    uint256 constant internal NINE_PT_FIVE_RATE = 1000000002877801985002875644;

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
        require(eta == 0, "This spell has already been sceduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);

        // NOTE: 'eta' check should mimic the old behavior of 'done', thus
        // preventing these SCD changes from being executed again.


        // Set the Sai stability fee
        // SAI_FEE is a value determined by the rate accumulator calculation (see above)
        //  ex. an 10% annual rate will be 1000000003022265980097387650
        //
        // Poll: Sai Stability Fee Adjustment - March 2, 2020
        // https://vote.makerdao.com/polling-proposal/qme4mhhlcuvcg7pwyfh1pdgqwp45abrdtvrdwvcbfggunj
        //
        // Existing Rate: 9.5%
        // New Rate: 9.5%
        require(saiTub.fee() == NINE_PT_FIVE_RATE, "Unexpected Sai Rate");
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
