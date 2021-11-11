pragma solidity 0.5.12;

contract FileLike {
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
}

contract JugLike {
    function drip(bytes32) external;
    function file(bytes32, bytes32, uint256) external;
}

contract PotLike {
    function drip() external;
    function file(bytes32, uint256) external;
}

contract PauseLike {
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external;
}

contract MomLike {
    function setCap(uint256) external;
    function setFee(uint256) external;
}

contract DssFlopReplaceSpellAction {
    uint256 constant RAD = 10 ** 45;
    address constant public VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public POT = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;

    function execute() external {
        // set the global debt ceiling to 178,000,000
        FileLike(VAT).file("Line", 178000000 * RAD);

        // set the ETH-A debt ceiling to 75,000,000
        FileLike(VAT).file("ETH-A", "line", 75000000 * RAD);

        // DSR
        PotLike(POT).drip();
        PotLike(POT).file("dsr", 1000000001243680656318820312);

        // drip
        // JugLike(JUG).drip("ETH-A");
        // JugLike(JUG).drip("BAT-A");

        // set ETH-A duty to X
        // JugLike(JUG).file("ETH-A", "duty", X);

        // set BAT-A duty to X
        // JugLike(JUG).file("BAT-A", "duty", X);
    }
}

contract DssDecember6Spell {
    PauseLike public pause =
        PauseLike(0xbE286431454714F511008713973d3B053A2d38f3);
    address constant public SAIMOM = 0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C;
    uint256 constant public SCDCAP = 95000000 * 10 ** 18;
    uint256 constant public NEWFEE = 1000000000937303470807876289;
    address   public action;
    bytes32   public tag;
    uint256   public eta;
    bytes     public sig;
    bool      public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new DssFlopReplaceSpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function cast() external {
        require(!done, "spell-already-cast");
        done = true;
        pause.plot(action, tag, sig, now);
        pause.exec(action, tag, sig, now);
        // Lower Debt Ceiling in SCD to 95,000,000
        MomLike(SAIMOM).setCap(SCDCAP);
        MomLike(SAIMOM).setFee(NEWFEE);
    }
}