pragma solidity ^0.5.12;

import "ds-test/test.sol";

import {Dai} from "dss/dai.sol";
import {Vat} from "dss/vat.sol";
import {Vow} from "dss/vow.sol";
import {Pot} from "dss/pot.sol";
import {ERC20} from "erc20/erc20.sol";

import {DssIncreaseDelay24Spell} from "./DssIncreaseDelay24Spell.sol";

contract ChiefLike {
    function hat() public view returns (address);
    function lock(uint) public;
    function vote(address[] memory) public;
    function lift(address) public;
}

contract ProxyLike {
    function execute(address, bytes memory) public payable;
}

contract TokenLike {
    function balanceOf(address) public view returns (uint);
    function approve(address, uint) public;
}

contract PauseLike {
    function delay() external view returns (uint256);
    function setDelay(uint256) external;
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external;
}

contract Hevm {
    function warp(uint) public;
}

contract OSMLike {
    function rely(address) external;
    function wards(address) external view returns (uint256);
}

contract OSMMomLike {
    function authority() external view returns (address);
    function osms(bytes32) external view returns (address);
    function setAuthority(address) external;
    function setOsm(bytes32, address) external;
}

contract DssIncreaseDelay24SpellTest is DSTest {
    Hevm hevm;

    PauseLike public pause =
        PauseLike(0xbE286431454714F511008713973d3B053A2d38f3);
    ERC20 gov = ERC20(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    ChiefLike chief = ChiefLike(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    OSMLike eth_osm = OSMLike(0x81fe72b5a8d1a857d176c3e7d5bd2679a9b85763);
    OSMLike bat_osm = OSMLike(0xb4eb54af9cc7882df0121d26c5b97e802915abe6);
    OSMMomLike osm_mom = OSMMomLike(address(0)); // TODO(cmooney) fix me

    DssIncreaseDelay24Spell spell;

    function vote() private {
        gov.approve(address(chief), uint256(-1));
        chief.lock(gov.balanceOf(address(this)));

        assertTrue(!spell.done());

        address[] memory vote = new address[](1);
        vote[0] = address(spell);

        chief.vote(vote);
        chief.lift(address(spell));
        assertEq(chief.hat(), address(spell));
    }

    function testIncreaseDelay24SpellIsCast() public {
        spell = DssIncreaseDelay24Spell(
            //TODO(cmooney) deployed script
        );

        assertEq(pause.delay(), 0);

        vote();
        spell.cast();

        // test ETH_OSM rely on OSM_MOM
        assertEq(eth_osm.wards(address(osm_mom)), 1);

        // test BAT_OSM rely on OSM_MOM
        assertEq(bat_osm.wards(address(osm_mom)), 1);

        // test OSM_MOM Authority is Chief
        // TODO(brian): make sure the interface is conformant
        assertEq(osm_mom.authority(), address(chief));

        // test OSM_MOM has OSM for ETH-A
        assertEq(osm_mom.osms('ETH-A'), address(eth_osm));

        // test OSM_MOM has OSM for BAT-A
        assertEq(osm_mom.osms('BAT-A'), address(bat_osm));

        // test that the new pause delay is 24 hours
        assertEq(pause.delay(), 60 * 60 * 24);

        fail();
    }

    // TODO(iamchrissmith): add test for checking canCall on OSM-MOM
}
