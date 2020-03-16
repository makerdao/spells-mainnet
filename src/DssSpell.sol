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
    address constant public MCD_VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public MCD_CAT = 0x78F2c2AF65126834c51822F56Be0d7469D7A523E;
    address constant public MCD_JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public MCD_SPOT = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant public MCD_END = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;
    address constant public FLIPPER_MOM = 0x9BdDB99625A711bf9bda237044924E34E8570f75;
    address constant public FLIP_FAB = 0xBAB4FbeA257ABBfe84F4588d4Eedc43656E46Fc5;

    address constant public MCD_JOIN_USDC_A = 0xA191e578a6736167326d05c119CE0c90849E84B7;
    address constant public PIP_USDC = 0x77b68899b99b686F415d074278a9a16b336085A0;

    uint256 constant public THOUSAND = 10**3;
    uint256 constant public MILLION = 10**6;
    uint256 constant public WAD = 10**18;
    uint256 constant public RAY = 10**27;
    uint256 constant public RAD = 10**45;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 0.5%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.005)/(60 * 60 * 24 * 365) )'
    //
    uint256 constant public ZERO_FIVE_PCT_RATE = 1000000000158153903837946257;

    function execute() public {
        bytes32 ilk = "USDC-A";

        address MCD_FLIP_USDC_A = FlipFabAbstract(FLIP_FAB).newFlip(MCD_VAT, ilk);

        SpotAbstract(MCD_SPOT).file(ilk, "pip", PIP_USDC);

        CatAbstract(MCD_CAT).file(ilk, "flip", MCD_FLIP_USDC_A);
        VatAbstract(MCD_VAT).init(ilk);
        JugAbstract(MCD_JUG).init(ilk);

        VatAbstract(MCD_VAT).rely(MCD_JOIN_USDC_A);
        FlipAbstract(MCD_FLIP_USDC_A).rely(MCD_CAT);
        FlipAbstract(MCD_FLIP_USDC_A).rely(MCD_END);
        FlipAbstract(MCD_FLIP_USDC_A).rely(FLIPPER_MOM);

        // Set the global debt ceiling
        VatAbstract(MCD_VAT).file("Line", 163 * MILLION * RAD);
        // Set the USDC-A debt ceiling
        VatAbstract(MCD_VAT).file(ilk, "line", 50 * MILLION * RAD);
        // Set the Lot size to 50K USDC-A
        CatAbstract(MCD_CAT).file(ilk, "lump", 50 * THOUSAND * WAD);
        // Set the USDC-A liquidation penalty to 13%
        CatAbstract(MCD_CAT).file(ilk, "chop", 113 * RAY / 100);
        // Set the USDC-A stability fee to 0.5%
        JugAbstract(MCD_JUG).file(ilk, "duty", ZERO_FIVE_PCT_RATE);
        // Set the USDC-A min collateralization ratio to 110%
        SpotAbstract(MCD_SPOT).file(ilk, "mat", 110 * RAY / 100);
        // Update USDC-A spot value in Vat
        SpotAbstract(MCD_SPOT).poke(ilk);
    }
}

contract DssSpell {
    // MAINNET ADDRESS
    DSPauseAbstract public pause = DSPauseAbstract(
        0xbE286431454714F511008713973d3B053A2d38f3
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
        require(pause.delay() == 4 hours, "spell-not-4-hours-delay");

        eta = now + pause.delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
