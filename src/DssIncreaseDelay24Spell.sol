pragma solidity 0.5.12;

contract PauseLike {
    function delay() external view returns (uint256);
    function setDelay(uint256) external;
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external;
    function owner() external returns(address);
}

contract OSMMomLike {
    function setAuthority(address) external;
    function setOsm(bytes32, address) external;
}

contract DssIncreaseDelay24SpellAction {
    address constant public PAUSE = 0xbE286431454714F511008713973d3B053A2d38f3;
    address constant public CHIEF = 0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5;

    address constant public ETH_OSM = 0x81fe72b5a8d1a857d176c3e7d5bd2679a9b85763;
    address constant public BAT_OSM = 0xb4eb54af9cc7882df0121d26c5b97e802915abe6;

    address constant public OSM_MOM = address(0); // TODO add deployed address

    function execute() external {
        OSMLike(ETH_OSM).rely(OSM_MOM);
        OSMLike(BAT_OSM).rely(OSM_MOM);

        OSMMomLike(OSM_MOM).setAuthority(CHIEF);
        OSMMomLike(OSM_MOM).setOsm("ETH-A", ETH_OSM);
        OSMMomLike(OSM_MOM).setOsm("BAT-A", BAT_OSM);

        PauseLike(PAUSE).setDelay(60 * 60 * 24);
    }
}

contract DssIncreaseDelay24Spell {
    PauseLike public pause =
        PauseLike(0xbE286431454714F511008713973d3B053A2d38f3);
    address   public action;
    bytes32   public tag;
    uint256   public eta;
    bytes     public sig;
    bool      public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new DssIncreaseDelay24SpellAction());
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
    }
}
