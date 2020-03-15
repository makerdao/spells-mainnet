pragma solidity 0.5.15;

import "ds-math/math.sol";
import {Flipper} from "dss/flip.sol";
import {FlipperMom} from "flipper-mom/FlipperMom.sol";

import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol";
import "lib/dss-interfaces/src/dss/FlipAbstract.sol";

contract FlipMomLike {
    function setOwner(address) external;
    function setAuthority(address) external;
    function rely(address, address) external;
    function deny(address, address) external;
}

contract SpellAction {
    address constant public DS_PAUSE_PROXY = 0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
    address constant public MCD_FLIP_ETH_A = 0xd8a04F5412223F513DC55F839574430f5EC15531;
    address constant public MCD_FLIP_BAT_A = 0xaA745404d55f88C108A28c86abE7b5A1E7817c07;
    address constant public MCD_ADM = 0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5;
    // address constant public flipperMom = ;

    function execute() public {
        // set flipper mom auth to MCD_ADM
        FlipMomLike(flipperMom).setAuthority(MCD_ADM);
        // set flipper mom owner to MCD_PAUSE_PROXY
        FlipMomLike(flipperMom).setOwner(DS_PAUSE_PROXY);
        // rely the flipper mom on both ETH-A and BAT-A flippers
        FlipAbstract(MCD_FLIP_ETH_A).rely(address(flipperMom));
        FlipAbstract(MCD_FLIP_BAT_A).rely(address(flipperMom));
    }
}

contract DssDeployFlipperMom is DSMath {
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
        eta = add(now, pause.delay());
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}
