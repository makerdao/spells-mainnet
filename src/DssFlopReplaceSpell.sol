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
    function cage() public;
}

contract PauseLike {
    function delay() public view returns (uint256);
    function plot(address, bytes32, bytes memory, uint256) public;
    function exec(address, bytes32, bytes memory, uint256) public;
}

contract MomLike {
    function setPep(address) external;
}

contract DssFlopReplaceSpellAction {
    address constant public newFLOPPER = 0x4D95A049d5B0b7d32058cd3F2163015747522e99;
    // address constant public MKRAUTHORITY = 0xc725e52E55929366dFdF86ac4857Ae272e8BF13D;
    address constant public VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public VOW = 0xA950524441892A31ebddF91d3cEEFa04Bf454466;
    address constant public oldFLOPPER = 0xBE00FE8Dfd9C079f1E5F5ad7AE9a3Ad2c571FCAC;
    address constant public SAIMOM = 0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C;
    address constant public MKRPEP = 0x99041F808D598B782D5a3e498681C2452A31da08;


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
        WardsLike(newFLOPPER).rely(VOW);
        // Vat relies on new Flopper
        WardsLike(VAT).rely(newFLOPPER);
        // File new Flopper on Vow
        FileLike(VOW).file("flopper", newFLOPPER);
        // WardsLike(MKRAUTHORITY).rely(newFLOPPER);

        // # Close down Old Flopper #
        WardsLike(oldFLOPPER).deny(VOW);
        FlopLike(oldFLOPPER).cage();
        // WardsLike(MKRAUTHORITY).deny(oldFLOPPER);

        // change Pep in SCD to Medianizer
        MomLike(SAIMOM).setPep(MKRPEP);
    }
}

contract DssFlopReplaceSpell {
    PauseLike public pause =
        PauseLike(0xbE286431454714F511008713973d3B053A2d38f3);
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

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.plot(action, tag, sig, now);
        pause.exec(action, tag, sig, now);
    }
}
