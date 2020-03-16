pragma solidity 0.5.12;

import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/PotAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipAbstract.sol";
import "lib/dss-interfaces/src/sai/SaiMomAbstract.sol";

contract FlipMomLike {
    function setOwner(address) external;
    function setAuthority(address) external;
    function rely(address, address) external;
    function deny(address, address) external;
}

contract SpellAction {
    address constant public MCD_PAUSE = 0xbE286431454714F511008713973d3B053A2d38f3;
    address constant public MCD_JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public MCD_POT = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address constant public MCD_FLIP_ETH_A = 0xd8a04F5412223F513DC55F839574430f5EC15531;
    address constant public MCD_FLIP_BAT_A = 0xaA745404d55f88C108A28c86abE7b5A1E7817c07;
    address constant public MCD_ADM = 0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5;
    address constant public FLIPPER_MOM = 0x9BdDB99625A711bf9bda237044924E34E8570f75;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 0%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.00)/(60 * 60 * 24 * 365) )'
    //
    uint256 constant public ZERO_PCT_RATE = 1000000000000000000000000000;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 0.5%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.005)/(60 * 60 * 24 * 365) )'
    //
    uint256 constant public ZERO_FIVE_PCT_RATE = 1000000000158153903837946257;

    function execute() public {
        // Drip Pot and Jugs prior to all modifications.
        PotAbstract(MCD_POT).drip();
        JugAbstract(MCD_JUG).drip("ETH-A");
        JugAbstract(MCD_JUG).drip("BAT-A");

        // Set the Dai Savings Rate
        // DSR_RATE is a value determined by the rate accumulator calculation (see above)
        //  ex. an 8% annual rate will be 1000000002440418608258400030
        //
        // Existing Rate: 4%
        // New Rate: 0%
        uint256 DSR_RATE = ZERO_PCT_RATE;
        PotAbstract(MCD_POT).file("dsr", DSR_RATE);

        // Set the ETH-A stability fee
        // ETH_FEE is a value determined by the rate accumulator calculation (see above)
        //  ex. an 8% annual rate will be 1000000002440418608258400030
        //
        // Existing Rate: 4%
        // New Rate: 0.5%
        uint256 ETH_FEE = ZERO_FIVE_PCT_RATE;
        JugAbstract(MCD_JUG).file("ETH-A", "duty", ETH_FEE);

        // Set the BAT-A stability fee
        // BAT_FEE is a value determined by the rate accumulator calculation (see above)
        //  ex. an 8% annual rate will be 1000000002440418608258400030
        //
        // Existing Rate: 4%
        // New Rate: 0.5%
        uint256 BAT_FEE = ZERO_FIVE_PCT_RATE;
        JugAbstract(MCD_JUG).file("BAT-A", "duty", BAT_FEE);

        // Set Pause Delay to 4 hours
        DSPauseAbstract(MCD_PAUSE).setDelay(4 hours);

        // Add FlipperMom
        // Set flipper mom auth to MCD_ADM
        FlipMomLike(FLIPPER_MOM).setAuthority(MCD_ADM);
        // Rely the flipper mom on both ETH-A and BAT-A flippers
        FlipAbstract(MCD_FLIP_ETH_A).rely(address(FLIPPER_MOM));
        FlipAbstract(MCD_FLIP_BAT_A).rely(address(FLIPPER_MOM));
    }
}

contract DssSpell {
    // MAINNET ADDRESS
    DSPauseAbstract public pause = DSPauseAbstract(
        0xbE286431454714F511008713973d3B053A2d38f3
    );
    address constant public SAI_MOM = 0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C;
    uint256 constant public MILLION = 10**6;
    uint256 constant public WAD = 10**18;

    address public action;
    bytes32 public tag;
    uint256 public eta;
    bytes   public sig;
    uint256 public expiration;
    bool    public done;

    constructor() public {
        action = address(new SpellAction());
        sig = abi.encodeWithSignature("execute()");
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "spell-already-scheduled");
        eta = now + pause.delay();
        pause.plot(action, tag, sig, eta);

        // Set the Sai debt ceiling
        //
        // SAI_AMOUNT is the total number of Sai that can be created in SCD
        //  as a whole number
        //  ex. a 15 million Sai global ceiling will be GLOBAL_AMOUNT = 15000000
        //
        // Existing ceiling: 25m
        // New ceiling: 20m
        uint256 SAI_AMOUNT = 20 * MILLION;
        SaiMomAbstract(SAI_MOM).setCap(SAI_AMOUNT * WAD);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
