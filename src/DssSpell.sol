pragma solidity 0.5.12;

import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dss/CatAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipAbstract.sol";
import "lib/dss-interfaces/src/dss/SpotAbstract.sol";

contract FlipFabAbstract {
    function newFlip(address, bytes32) public returns (address);
}

contract SpellAction {
    address constant public MCD_VAT = 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9;
    address constant public MCD_CAT = 0x0511674A67192FE51e86fE55Ed660eB4f995BDd6;
    address constant public MCD_JUG = 0xcbB7718c9F39d05aEEDE1c472ca8Bf804b2f1EaD;
    address constant public MCD_SPOT = 0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D;
    address constant public MCD_END = 0x24728AcF2E2C403F5d2db4Df6834B8998e56aA5F;
    //address constant public FLIPPER_MOM = 0x9BdDB99625A711bf9bda237044924E34E8570f75;
    address constant public FLIP_FAB = 0xFfB0382CA7Cfdc4Fc4d5Cc8913af1393d7eE1EF1;

    address constant public MCD_JOIN_USDC_A = 0xA191e578a6736167326d05c119CE0c90849E84B7;
    address constant public PIP_USDC = 0x4c51c2584309b7BF328F89609FDd03B3b95fC677;

    uint256 constant public THOUSAND = 10**3;
    uint256 constant public MILLION = 10**6;
    uint256 constant public WAD = 10**18;
    uint256 constant public RAY = 10**27;
    uint256 constant public RAD = 10**45;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 0.5%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.2)/(60 * 60 * 24 * 365) )'
    //
    uint256 constant public TWENTY_PCT_RATE = 1000000005781378656804591712;

    function execute() public {
        bytes32 ilk = "USDC-A";

        // Create the USDC-A Flipper via the original FlipFab
        address MCD_FLIP_USDC_A = FlipFabAbstract(FLIP_FAB).newFlip(MCD_VAT, ilk);

        // Set the USDC PIP in the Spotter
        SpotAbstract(MCD_SPOT).file(ilk, "pip", PIP_USDC);

        // Set the USDC-A Flipper in the Cat
        CatAbstract(MCD_CAT).file(ilk, "flip", MCD_FLIP_USDC_A);

        // Init USDC-A ilk in Vat
        VatAbstract(MCD_VAT).init(ilk);
        // Init USDC-A ilk in Jug
        JugAbstract(MCD_JUG).init(ilk);

        // Allow USDC-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_USDC_A);
        // Allow Cat to kick auctions in USDC-A Flipper
        FlipAbstract(MCD_FLIP_USDC_A).rely(MCD_CAT);
        // Allow End to yank auctions in USDC-A Flipper
        FlipAbstract(MCD_FLIP_USDC_A).rely(MCD_END);
        // Allow FlipperMom to access to the USDC-A Flipper
        //FlipAbstract(MCD_FLIP_USDC_A).rely(FLIPPER_MOM);

        // Set the global debt ceiling
        VatAbstract(MCD_VAT).file("Line", 138 * MILLION * RAD);
        // Set the USDC-A debt ceiling
        VatAbstract(MCD_VAT).file(ilk, "line", 25 * MILLION * RAD);
        // Set the USDC-A dust
        VatAbstract(MCD_VAT).file(ilk, "dust", 20 * RAD);
        // Set the Lot size to 50K USDC-A
        CatAbstract(MCD_CAT).file(ilk, "lump", 50 * THOUSAND * WAD);
        // Set the USDC-A liquidation penalty to 13%
        CatAbstract(MCD_CAT).file(ilk, "chop", 113 * RAY / 100);
        // Set the USDC-A stability fee to 20%
        JugAbstract(MCD_JUG).file(ilk, "duty", TWENTY_PCT_RATE);
        // Set the USDC-A percentage between bids to 2%
        FlipAbstract(MCD_FLIP_USDC_A).file("beg", 102 * WAD / 100);
        // Set the USDC-A time max time between bids to 6 hours
        FlipAbstract(MCD_FLIP_USDC_A).file("ttl", 6 hours);
        // Set the USDC-A max auction duration to 6 hours
        FlipAbstract(MCD_FLIP_USDC_A).file("tau", 6 hours);
        // Set the USDC-A min collateralization ratio to 125%
        SpotAbstract(MCD_SPOT).file(ilk, "mat", 125 * RAY / 100);

        // Update USDC-A spot value in Vat
        SpotAbstract(MCD_SPOT).poke(ilk);
    }
}

contract DssSpell {
    // MAINNET ADDRESS
    DSPauseAbstract public pause = DSPauseAbstract(
        0x8754E6ecb4fe68DaA5132c2886aB39297a5c7189
    );

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
        // Only plot it when the time delay is set to 4 hours
        //require(pause.delay() == 4 hours, "spell-not-4-hours-delay");

        eta = now + pause.delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
