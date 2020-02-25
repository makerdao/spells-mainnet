pragma solidity ^0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

/**
 * Must be executed from the Multisig address.
 * Use ./src/template/test-example-hattopper.sh
 */

contract Hevm {
    function warp(uint) public;
}

contract MkrMinterLike {
    function doMint(address, address, uint) external;
}

contract SpellAction {
    address constant public POT = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;

    function execute() public {
        // drip
        PotAbstract(POT).drip();
        // set dsr to 0%
        PotAbstract(POT).file("dsr", 1000000000000000000000000000);
    }
}

contract Spell is DSMath {
    DSPauseAbstract public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address   public action;
    bytes32   public tag;
    uint256   public eta;
    bytes     public sig;
    bool      public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
        require(eta == 0, "spell-already-scheduled");
        eta = add(now, DSPauseAbstract(pause).delay());
        pause.plot(action, tag, sig, eta);

        // NOTE: 'eta' check should mimic the old behavior of 'done', thus
        // preventing these SCD changes from being executed again.
        //
        // insert SCD changes (pre-pause implementation)
        //
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}

contract HatTopperTest is DSTest, DSMath {
    Hevm hevm;

    DSPauseAbstract pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    FlopAbstract flop       = FlopAbstract(0x4D95A049d5B0b7d32058cd3F2163015747522e99);
    PotAbstract pot        = PotAbstract(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    DSTokenAbstract gov    = DSTokenAbstract(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);

    DSChiefAbstract chief  = DSChiefAbstract(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);

    address multisig     = 0x8EE7D9235e01e6B42345120b5d270bdB763624C7;

    Spell spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    uint256  constant RAD = 10 ** 45;

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));

        spell = new Spell();
    }

    function mintMkrFrom0() private {
        // The next two lines only need to be here since we are running from multisig.
        // Once the multisig is not the owner of MKR, we can run from any address
        // And remove these lines.
        gov.setOwner(address(0));
        assertEq(DSAuthAbstract(address(gov)).owner(), address(0));

        MkrMinterLike(address(0)).doMint(address(gov), address(this), uint(-1) - gov.totalSupply());
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

    function scheduleWaitAndCast() private {
        spell.schedule();
        hevm.warp(add(now, pause.delay()));
        spell.cast();
    }

    function test_ExampleTestFromMultisig() public {
        // Test pre-spell conditions
        assertTrue(pot.dsr() != 1000000000000000000000000000);

        // guarantee we have enough to overcome any hat
        MkrMinterLike(multisig).doMint(address(gov), address(this), uint(-1) - gov.totalSupply());

        vote();
        scheduleWaitAndCast();

        // Test effects of Spell
        assertTrue(pot.dsr() == 1000000000000000000000000000);
    }

    function test_ExampleTestFrom0() public {
        // Test pre-spell conditions
        assertTrue(pot.dsr() != 1000000000000000000000000000);

        mintMkrFrom0();
        vote();
        scheduleWaitAndCast();

        // Test effects of Spell
        assertTrue(pot.dsr() == 1000000000000000000000000000);
    }
}
