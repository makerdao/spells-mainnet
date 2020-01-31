pragma solidity 0.5.12;

import "ds-math/math.sol";
import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/JugAbstract.sol";
import "lib/dss-interfaces/src/dss/PotAbstract.sol";
import "lib/dss-interfaces/src/dss/VatAbstract.sol";

contract SaiMomLike {
    function setCap(uint256) external;
    function setFee(uint256) external;
}

contract SpellAction is DSMath {
    uint256 constant RAD = 10 ** 45;
    address constant public VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public POT = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;

    function execute() external {
        // drip
        PotAbstract(POT).drip();
        JugAbstract(JUG).drip("ETH-A");
        JugAbstract(JUG).drip("BAT-A");

        // set the global debt ceiling to 158,000,000 (125 + 30 + 3)
        VatAbstract(VAT).file("Line", mul(158000000, RAD));

        // // set the ETH-A debt ceiling to 125,000,000
        // VatAbstract(VAT).file("ETH-A", "line", mul(125000000, RAD));

        // set the SAI debt ceiling to 30,000,000
        VatAbstract(VAT).file("SAI", "line", mul(30000000, RAD));

        // set dsr to 8.75%
        PotAbstract(POT).file("dsr", 1000000002659864411854984565);

        // SF = 9%
        uint256 sf = 1000000002732676825177582095;

        // set ETH-A duty to 9%
        JugAbstract(JUG).file("ETH-A", "duty", sf);

        // set BAT-A duty to 9%
        JugAbstract(JUG).file("BAT-A", "duty", sf);
    }
}

contract DssJanuary31Spell is DSMath {
    DSPauseAbstract  public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address constant public SAIMOM = 0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C;
    uint256 constant public SCDCAP = 30000000 * 10 ** 18;
    uint256 constant public SCDFEE = 1000000003022265980097387650;
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

        // Lower Debt Ceiling in SCD to 30,000,000
        SaiMomLike(SAIMOM).setCap(SCDCAP);

        // Raise Stability Fee in SCD to 10%
        SaiMomLike(SAIMOM).setFee(SCDFEE);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
