pragma solidity ^0.4.23;

import "ds-test/test.sol";

import "./RING.sol";

contract RINGTest is DSTest {
    RING ring;

    function setUp() {
        ring = new RING();
    }

    function testFail_basic_sanity() {
        assertTrue(false);
    }

    function test_basic_sanity() {
        assertTrue(true);
    }

    function test_transfer_to_contract_with_fallback() {
        assertTrue(true);
    }

    function test_transfer_to_contract_without_fallback() {
        assertTrue(true);
    }
}
