pragma solidity ^0.5.12;

import "ds-math/math.sol";

import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipAbstract.sol";
import "lib/dss-interfaces/src/dss/CatAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";
import "lib/dss-interfaces/src/dss/EndAbstract.sol";

contract SpellAction {
    // mainnet variables
    address constant public cat = 0x78F2c2AF65126834c51822F56Be0d7469D7A523E;
    address constant public vow = 0xA950524441892A31ebddF91d3cEEFa04Bf454466;
    address constant public vat = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public end = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;
    address constant public oldFlipper = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;
    // address constant public newFlipper = _NEWFLIPPER_;

    function execute() public {
        // file the new flipper on the cat
        // this nopes the old flipper, sets ilks[ilk].flip to the new flip
        // and hopes the new flip
        CatAbstract(cat).file("ETH-A", "flip", newFlipper);

        // rely the new flipper on the cat
        FlipAbstract(newFlipper).rely(cat);
        FlipAbstract(newFlipper).rely(end);

        // rely the new flipper on the end
        EndAbstract(end).rely(newFlipper);

        // deny on the old flopper
        FlipAbstract(oldFlipper).deny(end);
        FlipAbstract(oldFlipper).deny(cat);
    }
}

contract DssReplaceFlipper is DSMath {
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

        bytes _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
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
