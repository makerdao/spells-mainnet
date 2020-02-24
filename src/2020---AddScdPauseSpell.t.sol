pragma solidity ^0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import {DssSpell} from "./2020---AddScdPauseSpell.sol";

contract Hevm {
    function warp(uint) public;
}

contract DssSpellTest is DSTest, DSMath {
    Hevm hevm;

    DSPauseAbstract public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    MKRAbstract gov = MKRAbstract(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    DSChiefAbstract chief = DSChiefAbstract(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    address pause_proxy = 0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;
    address constant public SAIMOM = 0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C;
    address constant public SAITUB = 0x448a5065aeBB8E423F0896E6c5D525C040f59af3;
    address constant public SAITOP = 0x9b0ccf7C8994E19F39b2B4CF708e0A7DF65fA8a3;
    address constant public VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    DssSpell spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        // Using the Flopper test address, mint enough MKR to overcome the current hat.
        gov.mint(address(this), 1000001 ether);
    }

    function vote(address spell) private {
        if (chief.hat() != address(spell)) {
            gov.approve(address(chief), uint256(-1));
            chief.lock(sub(gov.balanceOf(address(this)), 1 ether));

            address[] memory yays = new address[](1);
            yays[0] = address(spell);

            chief.vote(yays);
            chief.lift(spell);
        }
        assertEq(chief.hat(), spell);
    }

    function scheduleWaitAndCast(address spell) private {
        DssSpell(spell).schedule();
        hevm.warp(add(now, pause.delay()));
        DssSpell(spell).cast();
    }

    function _testSetPause() internal {
        spell = new DssSpell();
        // spell = DssSpell(0xDD4Aa99077C5e976AFc22060EEafBBd1ba34eae9);

        assertTrue(SaiMomAbstract(SAIMOM).owner() == address(0x0));
        assertTrue(SaiMomAbstract(SAIMOM).authority() == address(chief));
        assertTrue(SaiTopAbstract(SAITOP).owner() == address(0x0));
        assertTrue(SaiTopAbstract(SAITOP).authority() == address(chief));

        vote(address(spell));
        scheduleWaitAndCast(address(spell));

        assertTrue(SaiMomAbstract(SAIMOM).owner() == address(pause_proxy));
        assertTrue(SaiMomAbstract(SAIMOM).authority() == address(0x0));
        assertTrue(SaiTopAbstract(SAITOP).owner() == address(pause_proxy));
        assertTrue(SaiTopAbstract(SAITOP).authority() == address(0x0));

        // assert that the pause is set for SCD
        assertEq(
            DSPauseAbstract(
                DSPauseProxyAbstract(
                    SaiMomAbstract(SAIMOM).owner() // is pause_proxy
                ).owner() // is pause
            ).delay()
            , 60 * 60 * 24
        );
    }

    // after passing, new spells can affect SCD after delay
    function testDATEHEREScdControlledByPauseMom() public {
        _testSetPause();

        TestDelaySpellMom testSpell = new TestDelaySpellMom();

        assertTrue(VatAbstract(VAT).Line() != 0);
        assertTrue(SaiTubAbstract(SAITUB).cap() != 0);

        vote(address(testSpell));
        scheduleWaitAndCast(address(testSpell));

        assertTrue(VatAbstract(VAT).Line() == 0);
        assertTrue(SaiTubAbstract(SAITUB).cap() == 0);
    }

    function testDATEHEREScdControlledByPauseTop() public {
        _testSetPause();

        TestDelaySpellTop testSpell = new TestDelaySpellTop();

        assertTrue(!SaiTubAbstract(SAITUB).off());
        assertTrue(SaiTubAbstract(SAITUB).cap() != 0);

        vote(address(testSpell));
        scheduleWaitAndCast(address(testSpell));

        assertTrue(VatAbstract(VAT).Line() == 0);
        assertTrue(SaiTubAbstract(SAITUB).off());
    }

    function testDATEHEREScdNoDelayMom() public {
        TestNoDelaySpellMom testSpell = new TestNoDelaySpellMom();

        assertTrue(SaiTubAbstract(SAITUB).cap() != 0);
        vote(address(testSpell));
        testSpell.cast();
        assertTrue(SaiTubAbstract(SAITUB).cap() == 0);
    }

    function testFailDATEHEREScdNoDelayMom() public {
        _testSetPause();

        TestNoDelaySpellMom testSpell = new TestNoDelaySpellMom();

        vote(address(testSpell));
        testSpell.cast();
    }

    function testDATEHEREScdNoDelayTop() public {
        TestNoDelaySpellTop testSpell = new TestNoDelaySpellTop();

        assertTrue(!SaiTubAbstract(SAITUB).off());
        vote(address(testSpell));
        testSpell.cast();
        assertTrue(SaiTubAbstract(SAITUB).off());
    }

    function testFailDATEHEREScdNoDelayTop() public {
        _testSetPause();

        TestNoDelaySpellTop testSpell = new TestNoDelaySpellTop();

        vote(address(testSpell));
        testSpell.cast();
    }
}

// Delay Spell setting on SaiMom
contract TestDelaySpellMomAction {
    address constant public SAIMOM = 0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C;
    address constant public VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    function execute() external {
        VatAbstract(VAT).file("Line", 0);
        SaiMomAbstract(SAIMOM).setCap(0);
    }
}
contract TestDelaySpellMom is DSMath {
    DSPauseAbstract  public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address          public action;
    bytes32          public tag;
    uint256          public eta;
    bytes            public sig;
    bool             public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new TestDelaySpellMomAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
        require(eta == 0, "spell-already-scheduled");
        eta = add(now, DSPauseAbstract(pause).delay());
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}

// Delay Spell setting on SaiTop
contract TestDelaySpellTopAction {
    address constant public SAITOP = 0x9b0ccf7C8994E19F39b2B4CF708e0A7DF65fA8a3;
    address constant public VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    function execute() external {
        VatAbstract(VAT).file("Line", 0);
        SaiTopAbstract(SAITOP).cage();
    }
}
contract TestDelaySpellTop is DSMath {
    DSPauseAbstract  public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address          public action;
    bytes32          public tag;
    uint256          public eta;
    bytes            public sig;
    bool             public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new TestDelaySpellTopAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
        require(eta == 0, "spell-already-scheduled");
        eta = add(now, DSPauseAbstract(pause).delay());
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}

// No delay Spell setting on SaiMom
contract TestNoDelaySpellMom {
    address constant public SAIMOM = 0xF2C5369cFFb8Ea6284452b0326e326DbFdCb867C;
    bool             public done;

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        SaiMomAbstract(SAIMOM).setCap(0);
    }
}

// No delay Spell setting on SaiTop
contract TestNoDelaySpellTop {
    address constant public SAITOP = 0x9b0ccf7C8994E19F39b2B4CF708e0A7DF65fA8a3;
    bool             public done;

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        SaiTopAbstract(SAITOP).cage();
    }
}
