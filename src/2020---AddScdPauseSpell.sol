pragma solidity 0.5.12;

import "ds-math/math.sol";
import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/sai/SaiMomAbstract.sol";
import "lib/dss-interfaces/src/sai/SaiTopAbstract.sol";

contract SaiConstants {
    address constant public SAIMOM = 0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C;
    address constant public SAITOP = 0x9b0ccf7C8994E19F39b2B4CF708e0A7DF65fA8a3;
}

contract SpellAction is SaiConstants, DSMath {
    address constant public PAUSE = 0xbE286431454714F511008713973d3B053A2d38f3;

    function execute() external {
        // this spell currently does nothing on exec
        // leaving this here in case there are SCD/MCD paused actions /
        // that need to be executed after the pause.
    }
}

contract DssSpell is SaiConstants, DSMath {
    DSPauseAbstract  public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
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

    function schedule() public {
        require(eta == 0, "spell-already-scheduled");
        eta = add(now, DSPauseAbstract(pause).delay());
        pause.plot(action, tag, sig, eta);

        // NOTE: 'eta' check should mimic the old behavior of 'done', thus
        // preventing these SCD changes from being executed again.

        // Use the Pause for SCD
        SaiMomAbstract(SAIMOM).setOwner(address(DSPauseAbstract(pause).proxy()));
        SaiTopAbstract(SAITOP).setOwner(address(DSPauseAbstract(pause).proxy()));
        // Remove Chief Direct Access
        SaiMomAbstract(SAIMOM).setAuthority(address(0));
        SaiTopAbstract(SAITOP).setAuthority(address(0));
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
