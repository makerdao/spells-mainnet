pragma solidity ^0.5.12;

import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/PotAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dss/VowAbstract.sol";

contract SpellAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    string  constant public description = "MakerDAO Weekly Executive Spell";

    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.0.3/contracts.json
    //
    // Contract addresses pertaining to the SCD ecosystem can be found at:
    //     https://github.com/makerdao/sai#dai-v1-current-deployments
    address constant public MCD_PAUSE = 0xbE286431454714F511008713973d3B053A2d38f3;
    address constant public MCD_JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public MCD_POT = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address constant public MCD_VOW = 0xA950524441892A31ebddF91d3cEEFa04Bf454466;
    address constant public MCD_VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    uint256 constant public ZERO_PCT_RATE = 1000000000000000000000000000;
    uint256 constant public FOUR_PCT_RATE = 1000000001243680656318820312;

    uint256 constant public RAD = 10**45;
    uint256 constant public MILLION = 10**6;
    uint256 constant public DAY = 86400; // in seconds

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
        // Existing Rate: 8%
        // New Rate: 0%
        uint256 DSR_RATE = ZERO_PCT_RATE;
        PotAbstract(MCD_POT).file("dsr", DSR_RATE);


        // Set the ETH-A debt ceiling
        // ETH_LINE is the number of Dai that can be created with WETH token collateral
        //  ex. a 100 million Dai ETH ceiling will be ETH_LINE = 100000000
        //
        // Existing Line: 150m
        // New Line: 110m
        uint256 ETH_LINE = 110 * MILLION;
        VatAbstract(MCD_VAT).file("ETH-A", "line", ETH_LINE * RAD);


        // Set the ETH-A stability fee
        // ETH_FEE is a value determined by the rate accumulator calculation (see above)
        //  ex. an 8% annual rate will be 1000000002440418608258400030
        //
        // Existing Rate: 8%
        // New Rate: 4%
        uint256 ETH_FEE = FOUR_PCT_RATE;
        JugAbstract(MCD_JUG).file("ETH-A", "duty", ETH_FEE);


        // Set the BAT-A stability fee
        // BAT_FEE is a value determined by the rate accumulator calculation (see above)
        //  ex. an 8% annual rate will be 1000000002440418608258400030
        //
        // Existing Rate: 8%
        // New Rate: 4%
        uint256 BAT_FEE = FOUR_PCT_RATE;
        JugAbstract(MCD_JUG).file("BAT-A", "duty", BAT_FEE);


        // Set the global debt ceiling
        //
        // GLOBAL_AMOUNT is the total number of Dai that can be created by all collateral types
        //  as a whole number
        //  ex. a 100 million Dai global ceiling will be GLOBAL_AMOUNT = 100000000
        //
        // Existing Ceiling: 183m
        // New Ceiling: 143m
        uint256 GLOBAL_AMOUNT = 143 * MILLION;
        VatAbstract(MCD_VAT).file("Line", GLOBAL_AMOUNT * RAD);


        // Increase the wait delay for flop auctions
        //
        // WAIT_DELAY is the number of seconds that pass before debt is auctioned for MKR tokens
        //
        // Existing wait: 2 days
        // New wait: 14 days
        uint256 WAIT_DELAY = 14 * DAY;
        VowAbstract(MCD_VOW).file("wait", WAIT_DELAY);
    }
}

contract DssSpell {

    DSPauseAbstract  public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address constant public SAI_MOM = 0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C;
    address          public action;
    bytes32          public tag;
    uint256          public eta;
    bytes            public sig;
    uint256          public expiration;
    bool             public done;

    uint256 constant internal WAD = 10**18;

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
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
