pragma solidity 0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssDeployFlipperMom} from "./DssDeployFlipperMom.sol";

contract Hevm {
    function warp(uint256) public;
}

contract FlipMomLike {
    function setOwner(address) external;
    function setAuthority(address) external;
    function rely(address) external;
    function deny(address) external;
    function authority() public returns (address);
    function owner() public returns (address);
}

contract DssSpellTest is DSTest, DSMath {
    // populate with mainnet spell if needed
    address constant MAINNET_SPELL = 0x3778e388A5CF2778E0fE5fC6205738BeCe9Cb99d;

    address constant MCD_PAUSE_PROXY = 0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
    address constant MCD_ADM = 0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5;
    address constant MCD_CAT = 0x78F2c2AF65126834c51822F56Be0d7469D7A523E;
    address constant MCD_FLIP_ETH_A = 0xd8a04F5412223F513DC55F839574430f5EC15531;
    address constant MCD_FLIP_BAT_A = 0xaA745404d55f88C108A28c86abE7b5A1E7817c07;

    address constant FLIPPER_MOM = 0xFF7bb16C5767694C767422912b516d9c8E94E392;

    // MAINNET ADDRESSES
    DSPauseAbstract pause = DSPauseAbstract(
        0xbE286431454714F511008713973d3B053A2d38f3
    );
    DSChiefAbstract chief = DSChiefAbstract(
        MCD_ADM
    );
    MKRAbstract gov = MKRAbstract(
        0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2
    );
    
    DssDeployFlipperMom spell;

    Hevm hevm;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        gov.mint(address(this), 300000 ether);
    }

    function vote() private {
        if (chief.hat() != address(spell)) {
            gov.approve(address(chief), uint256(-1));
            chief.lock(sub(gov.balanceOf(address(this)), 1 ether));

            assertTrue(!spell.done());

            address[] memory yays = new address[](1);
            yays[0] = address(spell);

            chief.vote(yays);
            chief.lift(address(spell));
        }
        assertEq(chief.hat(), address(spell));
    }

    function scheduleWaitAndCast() public {
        spell.schedule();
        hevm.warp(add(now, pause.delay()));
        spell.cast();
    }

    function testSpellIsCast() public {
        spell = MAINNET_SPELL != 
            address(0) ? DssDeployFlipperMom(MAINNET_SPELL) :
            new DssDeployFlipperMom();

        vote();
        scheduleWaitAndCast();
        assertTrue(spell.done());
    }

    function testWards() public {
        spell = MAINNET_SPELL != 
            address(0) ? DssDeployFlipperMom(MAINNET_SPELL) :
            new DssDeployFlipperMom();

        vote();
        scheduleWaitAndCast();

        assertEq(FlipMomLike(FLIPPER_MOM).authority(), MCD_ADM);
        assertEq(FlipMomLike(FLIPPER_MOM).owner(), MCD_PAUSE_PROXY);
        assertEq(FlipAbstract(MCD_FLIP_ETH_A).wards(FLIPPER_MOM), 1);
        assertEq(FlipAbstract(MCD_FLIP_BAT_A).wards(FLIPPER_MOM), 1);
    }

    function testFailOnSetOwner() public {
        spell = MAINNET_SPELL != address(0) ? 
            DssDeployFlipperMom(MAINNET_SPELL) :
            new DssDeployFlipperMom();

        vote();
        scheduleWaitAndCast();

        FlipMomLike(FLIPPER_MOM).setOwner(address(this));
    }

    function testFailOnSetAuthority() public {
        spell = MAINNET_SPELL != address(0) ? 
            DssDeployFlipperMom(MAINNET_SPELL) :
            new DssDeployFlipperMom();

        vote();
        scheduleWaitAndCast();

        FlipMomLike(FLIPPER_MOM).setAuthority(address(this));
    }

    function testFailOnUnAuthRely_ETH_A() public {
        spell = MAINNET_SPELL != address(0) ? 
            DssDeployFlipperMom(MAINNET_SPELL) :
            new DssDeployFlipperMom();

        vote();
        scheduleWaitAndCast();

        FlipMomLike(FLIPPER_MOM).rely(MCD_FLIP_ETH_A);
    }

    function testFailOnUnAuthRely_BAT_A() public {
        spell = MAINNET_SPELL != address(0) ? 
            DssDeployFlipperMom(MAINNET_SPELL) :
            new DssDeployFlipperMom();

        vote();
        scheduleWaitAndCast();

        FlipMomLike(FLIPPER_MOM).rely(MCD_FLIP_BAT_A);
    }

    function testFailOnUnAuthDeny_ETH_A() public {
        spell = MAINNET_SPELL != address(0) ? 
            DssDeployFlipperMom(MAINNET_SPELL) :
            new DssDeployFlipperMom();

        vote();
        scheduleWaitAndCast();

        FlipMomLike(FLIPPER_MOM).deny(MCD_FLIP_ETH_A);
    }

    function testFailOnUnAuthDeny_BAT_A() public {
        spell = MAINNET_SPELL != address(0) ? 
            DssDeployFlipperMom(MAINNET_SPELL) :
            new DssDeployFlipperMom();

        vote();
        scheduleWaitAndCast();

        FlipMomLike(FLIPPER_MOM).deny(MCD_FLIP_BAT_A);
    }
}
