pragma solidity ^0.5.12;

import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/VowAbstract.sol";
import "lib/dss-interfaces/src/dss/FlopAbstract.sol";

contract MkrAuthorityAbstract {
    function rely(address) public;
    function deny(address) public;
}

contract SpellAction {
    address constant public MCD_VOW = 0xA950524441892A31ebddF91d3cEEFa04Bf454466;
    address constant public MCD_FLOP = 0x4D95A049d5B0b7d32058cd3F2163015747522e99;
    address constant public GOV_GUARD = 0x6eEB68B2C7A918f36B78E2DB80dcF279236DDFb8;

    uint256 constant public THOUSAND = 10**3;
    uint256 constant public MILLION = 10**6;
    uint256 constant public WAD = 10**18;
    uint256 constant public RAY = 10**27;
    uint256 constant public RAD = 10**45;

    function execute() public {

        // set sump to a new value
        uint256 sump = (50 * THOUSAND) * RAD;
        VowAbstract(MCD_VOW).file("sump", sump);

        // set dump to a new value
        uint256 dump = 250 * WAD;
        VowAbstract(MCD_VOW).file("dump", dump);

        // set pad to a new value
        uint256 pad = 12 * (WAD / 10);
        FlopAbstract(MCD_FLOP).file("pad", pad);

        // set beg to a new value
        uint256 beg = 103 * (WAD / 100);
        FlopAbstract(MCD_FLOP).file("beg", beg);

        // set ttl to a new value
        uint256 ttl = 6 hours;
        FlopAbstract(MCD_FLOP).file("ttl", ttl);

        // set tau to a new value
        uint256 tau = 3 days;
        FlopAbstract(MCD_FLOP).file("tau", tau);

        // revoke Vow's authorization to start flop auctions
        FlopAbstract(MCD_FLOP).deny(MCD_VOW);

        // revoke Flopper's authorization to mint MKR
        MkrAuthorityAbstract(GOV_GUARD).deny(MCD_FLOP);
    }
}

contract DssSpell {
    // MAINNET ADDRESS
    DSPauseAbstract public pause = DSPauseAbstract(
        0xbE286431454714F511008713973d3B053A2d38f3
    );

    address public action;
    bytes32 public tag;
    uint256 public eta;
    bytes   public sig;
    uint256 public expiration;
    bool    public done;

    constructor() public {
        action = address(new SpellAction());
        sig = abi.encodeWithSignature("execute()");
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "spell-already-scheduled");

        eta = now + pause.delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
