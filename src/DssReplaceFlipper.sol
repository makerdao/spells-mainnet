pragma solidity ^0.5.12;

import "ds-math/math.sol";

import "lib/dss-interfaces/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/dss/FlipAbstract.sol";
import "lib/dss-interfaces/dss/CatAbstract.sol";
import "lib/dss-interfaces/dss/VatAbstract.sol";
import "lib/dss-interfaces/dss/EndAbstract.sol";

contract SpellAction {
    address constant public cat = 0x0511674A67192FE51e86fE55Ed660eB4f995BDd6;
    address constant public vow = 0x0F4Cbe6CBA918b7488C26E29d9ECd7368F38EA3b;
    address constant public vat = 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9;
    address constant public end = 0x24728AcF2E2C403F5d2db4Df6834B8998e56aA5F;
    address constant public oldFlipper = 0xB40139Ea36D35d0C9F6a2e62601B616F1FfbBD1b;
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
    }
}

contract DssReplaceFlipper is DSMath {
    DSPauseAbstract public pause = DSPauseAbstract(
        0xbE286431454714F511008713973d3B053A2d38f3
    );

    address public action;
    bytes32 public tag;
    uint256 public eta;
    bytes public sig;
    bool public done;

    constructor() public {
        action = address(new SpellAction());

        sig = abi.encodeWithSignature("execute()");

        bytes _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
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
