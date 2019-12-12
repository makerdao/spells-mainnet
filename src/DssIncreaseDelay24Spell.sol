pragma solidity 0.5.12;

contract PauseLike {
    function delay() external view returns (uint256);
    function setDelay(uint256) external;
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external;
    function owner() external returns(address);
}

contract DssIncreaseDelay24SpellAction {
    address constant public PAUSE = 0xbE286431454714F511008713973d3B053A2d38f3;
    address constant public ETH_OSM = 0x81fe72b5a8d1a857d176c3e7d5bd2679a9b85763;
    address constant public BAT_OSM = 0xb4eb54af9cc7882df0121d26c5b97e802915abe6;
    address constant public OSM_MOM = address(0);

    function execute() external {
        // deploy mom
        // relys
        OSMLike(ETH_OSM).rely(OSMMOM);
        OSMLike(BAT_OSM).rely(OSMMOM);
        OSMMomLike(OSM_MOM).setAuthority(PauseLike(PAUSE).owner());
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
