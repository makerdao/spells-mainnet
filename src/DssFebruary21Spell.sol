pragma solidity 0.5.12;

import "ds-math/math.sol";
import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/PotAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";

contract SaiMomLike {
    function setOwner(address) external;
    function owner() external view returns(address);
}

contract SaiTopLike {
    function setOwner(address) external;
    function owner() external view returns(address);
}

contract SaiConstants {
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAD = 10 ** 45;
    address constant public SAIMOM = 0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C;
    address constant public SAITOP = 0x9b0ccf7C8994E19F39b2B4CF708e0A7DF65fA8a3;
    // uint256 constant public SCDCAP = 30000000;
    // uint256 constant public SCDFEE = 1000000002732676825177582095;
}

contract SpellAction is SaiConstants, DSMath {
    // address constant public VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    // address constant public JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    // address constant public POT = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address constant public PAUSE = 0xbE286431454714F511008713973d3B053A2d38f3;

    function execute() external {
        DSPauseAbstract(PAUSE).setDelay(60 * 60 * 24);
    }
}

contract DssFebruary21Spell is SaiConstants, DSMath {
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
        SaiMomLike(SAIMOM).setOwner(address(DSPauseAbstract(pause).proxy()));
        SaiTopLike(SAIMOM).setOwner(address(DSPauseAbstract(pause).proxy()));
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
