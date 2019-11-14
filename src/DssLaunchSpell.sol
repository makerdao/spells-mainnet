pragma solidity 0.5.12;

contract VatLike {
    function file(bytes32,uint) public;
    function file(bytes32,bytes32,uint) public;
}

contract PauseLike {
    function delay() public view returns (uint256);
    function plot(address, bytes32, bytes memory, uint256) public;
    function exec(address, bytes32, bytes memory, uint256) public;
}

contract LaunchSpellAction {
    uint constant RAD = 10 ** 45;
    address constant VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    function execute() public {
        // set the global debt ceiling to 153,000,000
        VatLike(VAT).file("Line", 153000000 * RAD);

        // set the ETH-A debt ceiling to 50,000,000
        VatLike(VAT).file("ETH-A", "line", 50000000 * RAD);

        // set the BAT-A debt ceiling to 3,000,000
        VatLike(VAT).file("BAT-A", "line", 3000000 * RAD);

        // set the SAI debt ceiling to 100,000,000
        VatLike(VAT).file("SAI", "line", 100000000 * RAD);
    }
}

contract DssLaunchSpell {
    PauseLike public pause =
        PauseLike(0xbE286431454714F511008713973d3B053A2d38f3);
    address   public action;
    bytes32   public tag;
    uint256   public eta;
    bytes     public sig;
    bool      public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new LaunchSpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
        // 1574092800 == Monday, November 18, 2019 16:00:00 GMT
        require(now >= 1574092800, "launch-time-error");
        require(eta == 0, "spell-already-scheduled");
        eta = now + PauseLike(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        pause.exec(action, tag, sig, eta);
        done = true;
    }
}
