pragma solidity ^0.5.12;

import "ds-math/math.sol";
import {Flipper} from "dss/flip.sol";

import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipAbstract.sol";
import "lib/dss-interfaces/src/dss/CatAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dss/EndAbstract.sol";

contract SpellAction {
    // -------------------------------------------
    // ------------ MAINNET ADDRESSES ------------
    // -------------------------------------------
    // address constant public cat = 0x78F2c2AF65126834c51822F56Be0d7469D7A523E;
    // address constant public vow = 0xA950524441892A31ebddF91d3cEEFa04Bf454466;
    // address constant public vat = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    // address constant public end = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;
    // address constant public oldFlipper = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;

    // -------------------------------------------
    // ------------- KOVAN ADDRESSES -------------
    // -------------------------------------------
    address constant public cat = 0x0511674A67192FE51e86fE55Ed660eB4f995BDd6;
    address constant public vow = 0x0F4Cbe6CBA918b7488C26E29d9ECd7368F38EA3b;
    address constant public vat = 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9;
    address constant public end = 0x24728AcF2E2C403F5d2db4Df6834B8998e56aA5F;
    address constant public oldFlipper = 0xB40139Ea36D35d0C9F6a2e62601B616F1FfbBD1b;

    function execute() public {
        Flipper newFlipper = new Flipper(vat, "ETH-A");

        // file ETH-A ilk type to update cat to new flipper
        CatAbstract(cat).file("ETH-A", "flip", address(newFlipper));

        // rely the cat and end on the new flipper
        newFlipper.rely(cat);
        newFlipper.rely(end);

        // rely the new flipper on the end
        EndAbstract(end).rely(address(newFlipper));

        // deny the end and cat on the old flipper
        FlipAbstract(oldFlipper).deny(end);
        FlipAbstract(oldFlipper).deny(cat);
    }
}

contract DssReplaceFlipper is DSMath {
    // MAINNET ADDRESS
    // DSPauseAbstract public pause = DSPauseAbstract(
    //     0xbE286431454714F511008713973d3B053A2d38f3
    // );

    // KOVAN ADDRESS
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
        eta = add(now, pause.delay());
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
