pragma solidity ^0.5.12;

import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/PotAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dss/VowAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipAbstract.sol";
import "lib/dss-interfaces/src/dss/FlopAbstract.sol";

contract SpellAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    string  constant public description = "03/12/2020 MakerDAO Executive Spell";

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
    address constant public MCD_FLIP_ETH_A = 0xd8a04F5412223F513DC55F839574430f5EC15531;
    address constant public MCD_FLIP_BAT_A = 0xaA745404d55f88C108A28c86abE7b5A1E7817c07;
    address constant public MCD_FLOP = 0x4D95A049d5B0b7d32058cd3F2163015747522e99;


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


        // Set the Sai debt ceiling for the migration contract
        // SAI_LINE is the number of Dai that can be created with Sai token collateral
        //  ex. a 10 million Dai ETH ceiling will be SAI_LINE = 10000000
        //
        // Existing Line: 30m
        // New Line: 10m
        uint256 SAI_LINE = 10 * MILLION;
        VatAbstract(MCD_VAT).file("SAI", "line", SAI_LINE * RAD);


        // Set the global debt ceiling
        //
        // GLOBAL_AMOUNT is the total number of Dai that can be created by all collateral types
        //  as a whole number
        //  ex. a 100 million Dai global ceiling will be GLOBAL_AMOUNT = 100000000
        //
        // Existing Ceiling: 183m
        // New Ceiling: 143m
        uint256 GLOBAL_AMOUNT = 123 * MILLION;
        VatAbstract(MCD_VAT).file("Line", GLOBAL_AMOUNT * RAD);


        // Increase the wait delay for flop auctions
        //
        // WAIT_DELAY is the number of seconds that pass before debt is auctioned for MKR tokens
        //
        // Existing wait: 2 days
        // New wait: 14 days
        uint256 WAIT_DELAY = 14 * DAY;
        VowAbstract(MCD_VOW).file("wait", WAIT_DELAY);


        // Increase the system surplus limit
        //
        // HUMP_AMOUNT is the amount of dai will can be held in surplus
        //
        // Existing hump: 500,000 Dai
        // New hump: 2 million Dai
        uint256 HUMP_AMOUNT = 2 * MILLION * RAD;
        VowAbstract(MCD_VOW).file("hump", HUMP_AMOUNT);


        // Set the ETH-A Flip ttl
        //
        // ETH_FLIP_TTL is the bid lifetime
        //
        // Existing ttl: 10 minutes
        // New ttl: 3 hours
        uint256 ETH_FLIP_TTL = 3 hours;
        FlipAbstract(MCD_FLIP_ETH_A).file("ttl", ETH_FLIP_TTL);

        // Set the BAT-A Flip ttl
        //
        // BAT_FLIP_TTL is the bid lifetime
        //
        // Existing ttl: 10 minutes
        // New ttl: 3 hours
        uint256 BAT_FLIP_TTL = 3 hours;
        FlipAbstract(MCD_FLIP_BAT_A).file("ttl", BAT_FLIP_TTL);


        // Set the Flop ttl
        //
        // FLOP_TTL is the bid lifetime
        //
        // Existing ttl: 10 minutes
        // New ttl: 3 hours
        uint256 FLOP_TTL = 3 hours;
        FlopAbstract(MCD_FLOP).file("ttl", FLOP_TTL);
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
