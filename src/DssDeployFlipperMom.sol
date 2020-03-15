pragma solidity ^0.5.12;

import "ds-math/math.sol";
import {Flipper} from "dss/flip.sol";
import {FlipperMom} from "flipper-mom/FlipperMom.sol";

import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipAbstract.sol";

contract MkrAuthLike {
    function rely(address) public;
    function deny(address) public;
}

contract FlipMomLike {
    function setOwner(address) external;
    function setAuthority(address) external;
    function rely(address, address) external;
    function deny(address, address) external;
}

contract SpellAction {
    // -------------------------------------------
    // ------------ MAINNET ADDRESSES ------------
    // -------------------------------------------
    // address constant public pauseProxy = 0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
    // address constant public flipper = 0xd8a04F5412223F513DC55F839574430f5EC15531;
    // address constant public auth = 0x6eEB68B2C7A918f36B78E2DB80dcF279236DDFb8;
    // address constant public chief = 0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5;

    // -------------------------------------------
    // ------------- KOVAN ADDRESSES -------------
    // -------------------------------------------
    address constant public pauseProxy = 0x0e4725db88Bb038bBa4C4723e91Ba183BE11eDf3;
    address constant public flipper = 0xB40139Ea36D35d0C9F6a2e62601B616F1FfbBD1b;
    address constant public auth = 0xE50303C6B67a2d869684EFb09a62F6aaDD06387B;
    address constant public chief = 0xbBFFC76e94B34F72D96D054b31f6424249c1337d;

    function execute() public {
        // deploy the flipper mom
        FlipperMom flipMom = new FlipperMom();

        // set flipper mom auth to MCD_ADM
        flipMom.setAuthority(chief);
        // set flipper mom owner to MCD_PAUSE_PROXY
        flipMom.setOwner(pauseProxy);

        // rely the flipper mom on the flipper
        FlipAbstract(flipper).rely(address(flipMom));
    }
}

contract DssDeployFlipperMom is DSMath {
    // MAINNET ADDRESS
    // DSPauseAbstract public pause = DSPauseAbstract(
    //     0xbE286431454714F511008713973d3B053A2d38f3
    // );

    // KOVAN ADDRESS
    DSPauseAbstract public pause = DSPauseAbstract(
        0x8754E6ecb4fe68DaA5132c2886aB39297a5c7189
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
        eta = add(now, pause.delay());
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
