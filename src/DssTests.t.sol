pragma solidity ^0.5.12;

import "ds-test/test.sol";

import "./DssTests.sol";

contract DssTestsTest is DSTest {
    DssTests tests;

    function setUp() public {
        tests = new DssTests();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
