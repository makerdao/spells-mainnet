pragma solidity 0.5.12;

import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/PotAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/sai/SaiMomAbstract.sol";


contract SpellAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    string  constant public description =
        "2020-02-28 Weekly Executive: DSR, Sai Ceiling, Dai Ceiling";

    uint256 constant RAD = 10 ** 45;
    address constant public PAUSE = 0xbE286431454714F511008713973d3B053A2d38f3;
    address constant public JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public POT = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address constant public VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    uint256 constant public SEVEN_PCT_RATE = 1000000002145441671308778766;

    function execute() external {

        // Drip Pot and Jugs prior to all modifications.
        PotAbstract(POT).drip();
        JugAbstract(JUG).drip("ETH-A");
        JugAbstract(JUG).drip("BAT-A");


        // MCD Modifications

        // Set the global debt ceiling
        //
        // GLOBAL_AMOUNT is the total number of Dai that can be created by all collateral types
        //  as a whole number
        //  ex. a 100 million Dai global ceiling will be GLOBAL_AMOUNT = 100000000
        //
        // https://vote.makerdao.com/polling-proposal/qmfy3resrmo97rqyfffpndujszvbv59zuacfl3rxpcu2wx
        //
        // Existing Ceiling: 183 million Dai
        // New Ceiling: 158 million Dai
        uint256 GLOBAL_AMOUNT = 158000000;
        VatAbstract(VAT).file("Line", GLOBAL_AMOUNT * RAD);


        // Set the Dai Savings Rate
        // DSR_RATE is a value determined by the rate accumulator calculation (see above)
        //  ex. an 8% annual rate will be 1000000002440418608258400030
        //
        // https://vote.makerdao.com/polling-proposal/qmewwftkvpcnqzmfrskryenlpqj4qqxqtzi9djxa8k9wn3
        //
        // Existing Rate: 8%
        // New Rate: 7%
        uint256 DSR_RATE = SEVEN_PCT_RATE;
        PotAbstract(POT).file("dsr", DSR_RATE);


        // Set the ETH-A debt ceiling
        // ETH_LINE is the number of Dai that can be created with WETH token collateral
        //  ex. a 100 million Dai ETH ceiling will be ETH_LINE = 100000000
        //
        // https://vote.makerdao.com/polling-proposal/qmfy3resrmo97rqyfffpndujszvbv59zuacfl3rxpcu2wx
        //
        // Existing Line: 150 million Dai
        // New Line: 130 million Dai
        uint256 ETH_LINE = 130000000;
        VatAbstract(VAT).file("ETH-A", "line", ETH_LINE * RAD);


        // Set the Sai MCD debt ceiling
        // SAI_LINE is the number of Dai that can be created with Sai via the migration contract
        //  ex. a 20 million Dai from Sai ceiling will be SAI_LINE = 20000000
        //
        // https://vote.makerdao.com/polling-proposal/qmfy3resrmo97rqyfffpndujszvbv59zuacfl3rxpcu2wx
        //
        // Existing Line: 30 million Dai
        // New Line: 25 million Dai
        uint256 SAI_LINE = 25000000;
        VatAbstract(VAT).file("SAI", "line", SAI_LINE * RAD);
    }
}

contract DssSpell {

    uint256 constant public WAD = 10**18;
    DSPauseAbstract  public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address constant public SAI_MOM = 0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C;
    address          public action;
    bytes32          public tag;
    uint256          public eta;
    bytes            public sig;
    bool             public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function description() public view returns (string memory) {
        return SpellAction(action).description();
    }

    function schedule() public {
        require(eta == 0, "spell-already-scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);

        // NOTE: 'eta' check should mimic the old behavior of 'done', thus
        // preventing these SCD changes from being executed again.


        // Set the Sai debt ceiling
        //
        // SAI_AMOUNT is the total number of Sai that can be created in SCD
        //  as a whole number
        //  ex. a 15 million Sai global ceiling will be GLOBAL_AMOUNT = 15000000
        //
        // https://vote.makerdao.com/polling-proposal/qmfy3resrmo97rqyfffpndujszvbv59zuacfl3rxpcu2wx
        //
        // Existing ceiling: 30 million Sai
        // New ceiling: 25 million Sai
        uint256 SAI_AMOUNT = 25000000;
        SaiMomAbstract(SAI_MOM).setCap(SAI_AMOUNT * WAD);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
