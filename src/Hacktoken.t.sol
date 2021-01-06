pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./Hacktoken.sol";

contract HacktokenTest is DSTest {
    Hacktoken hacktoken;

    function setUp() public {
        hacktoken = new Hacktoken("Hackathon Token", "HAKTOK");
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
