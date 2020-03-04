pragma solidity ^0.5.12;

import "ds-math/math.sol";
import "ds-test/test.sol";
import "lib/dss-interfaces/src/Interfaces.sol";

import { DssSpell } from "./2020-02-28-DssSpell.sol";

contract Hevm {
    function warp(uint) public;
}

contract DssSpellTest is DSTest, DSMath {
    Hevm hevm;

    DSPauseAbstract pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    DSChiefAbstract chief =
        DSChiefAbstract(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    VatAbstract    vat = VatAbstract(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    VowAbstract    vow = VowAbstract(0xA950524441892A31ebddF91d3cEEFa04Bf454466);
    PotAbstract    pot = PotAbstract(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    JugAbstract    jug = JugAbstract(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    FlapAbstract  flap = FlapAbstract(0xdfE0fb1bE2a52CDBf8FB962D5701d7fd0902db9f);
    MKRAbstract    gov = MKRAbstract(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    SaiTubAbstract tub = SaiTubAbstract(0x448a5065aeBB8E423F0896E6c5D525C040f59af3);
    OsmAbstract eth_osm = OsmAbstract(0x81FE72B5A8d1A857d176C3E7d5Bd2679A9B85763);
    OsmAbstract bat_osm = OsmAbstract(0xB4eb54AF9Cc7882DF0121d26c5b97E802915ABe6);
    OsmMomAbstract osm_mom = OsmMomAbstract(0x76416A4d5190d071bfed309861527431304aA14f);
    address pause_proxy = 0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB;

    DssSpell spell;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    // not provided in DSMath
    uint constant RAD = 10 ** 45;

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        assembly {
        result := mload(add(source, 32))
        }
    }

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        // Using the Flopper test address, mint enough MKR to overcome the current hat.
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

    function testSpell_2020_02_28_IsCast() public {
        spell = DssSpell(0xCd989b68d99DDDA02c6A58b1B3985962F4D59e33);
        // spell = new DssSpell();

        // DS-Test can't handle strings directly, so cast to a bytes32.
        assertEq(stringToBytes32(spell.description()),
            stringToBytes32("2020-02-28 Weekly Executive: DSR, Sai Ceiling, Dai Ceiling"));

        // Preflight Check

        // (ETH-A, BAT-A, DSR) = (8%, 8%, 8%)
        (uint dutyETH,) = jug.ilks("ETH-A");
        (uint dutyBAT,) = jug.ilks("BAT-A");
        assertEq(dutyETH,   1000000002440418608258400030);
        assertEq(dutyBAT,   1000000002440418608258400030);
        assertEq(pot.dsr(), 1000000002440418608258400030);

        // ETH-A line = 150mm
        (,,, uint256 lineETH,) = vat.ilks("ETH-A");
        assertEq(lineETH, mul(150000000, RAD));

        // SAI line = 30mm
        (,,, uint256 lineSAI,) = vat.ilks("SAI");
        assertEq(lineSAI, mul(30000000, RAD));

        // Line = 158mm
        assertEq(vat.Line(), mul(183000000, RAD));

        // SCD DC = 30mm
        assertEq(tub.cap(), mul(30000000, WAD));
        // SCD Fee = 9.5%
        assertEq(tub.fee(), 1000000002877801985002875644);

        // Pause is 24 hours
        assertEq(pause.delay(), 86400);

        // This is where the magic happens
        vote();
        scheduleWaitAndCast();

        // spell done
        assertTrue(spell.done());

        // Post-state check

        // (ETH-A, BAT-A, DSR) = (8%, 8%, 7%)
        (dutyETH,) = jug.ilks("ETH-A");
        (dutyBAT,) = jug.ilks("BAT-A");
        assertEq(dutyETH, 1000000002440418608258400030);
        assertEq(dutyBAT, 1000000002440418608258400030);
        assertEq(pot.dsr(), 1000000002145441671308778766);

        // ETH-A line = 130mm
        (,,, lineETH,) = vat.ilks("ETH-A");
        assertEq(lineETH, mul(130000000, RAD));

        // SAI line = 25mm
        (,,, lineSAI,) = vat.ilks("SAI");
        assertEq(lineSAI, mul(25000000, RAD));

        // Line = 158mm
        assertEq(vat.Line(), mul(158000000, RAD));

        // SCD DC = 25mm
        assertEq(tub.cap(), mul(25000000, WAD));
        // SCD SF = 9.5%
        assertEq(tub.fee(), 1000000002877801985002875644);

        // Pause is 86400 (1 day)
        assertEq(pause.delay(), 86400);
    }
}
