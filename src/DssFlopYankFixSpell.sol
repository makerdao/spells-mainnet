pragma solidity 0.5.12;

contract WardsLike {
    function rely(address) public;
    function deny(address) public;
}

contract FileLike {
    function file(bytes32, uint) public;
    function file(bytes32, address) public;
}

contract FlopLike {
    function beg() public returns(uint);
    function pad() public returns(uint);
    function ttl() public returns(uint);
    function tau() public returns(uint);
}

contract PauseLike {
    function delay() public view returns (uint256);
    function plot(address, bytes32, bytes memory, uint256) public;
    function exec(address, bytes32, bytes memory, uint256) public;
}

contract DssFlopYankFixSpellAction {
    uint constant RAD = 10 ** 45;
    address constant newFLOPPER = _____;
    address constant MKRAUTHORITY = _____;
    address constant VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant VOW = 0xA950524441892A31ebddF91d3cEEFa04Bf454466;
    address constant oldFLOPPER = 0xBE00FE8Dfd9C079f1E5F5ad7AE9a3Ad2c571FCAC;


    function execute() public {
        // # Setup new Flopper #
        // file same beg on new Flopper
        FileLike(newFLOPPER).file("beg", FlopLike(oldFLOPPER).beg());
        // file same pad on new Flopper
        FileLike(newFLOPPER).file("pad", FlopLike(oldFLOPPER).pad());
        // file same ttl on new Flopper
        FileLike(newFLOPPER).file("ttl", FlopLike(oldFLOPPER).ttl());
        // file same tau on new Flopper
        FileLike(newFLOPPER).file("tau", FlopLike(oldFLOPPER).tau());
        // rely on the vow
        WardsLike(newFlopper).rely(VOW);
        // Vat relies on new Flopper
        WardsLike(VAT).rely(newFlopper);
        // File new Flopper on Vow
        FileLike(VOW).file("flopper", newFlopper);
        FileLike(MKRAUTHORITY).rely(newFlopper);

        // # Close down Old Flopper #
        WardsLike(oldFlopper).deny(VOW);
        FlopLike(oldFlopper).cage();
        FileLike(MKRAUTHORITY).deny(oldFlopper);
    }
}

contract DssFlopYankFixSpell {
    PauseLike public pause =
        PauseLike(0xbE286431454714F511008713973d3B053A2d38f3);
    address   public action;
    bytes32   public tag;
    uint256   public eta;
    bytes     public sig;
    bool      public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new DssFlopYankFixSpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.plot(action, tag, sig, now);
        pause.exec(action, tag, sig, now);
    }
}
