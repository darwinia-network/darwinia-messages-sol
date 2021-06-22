pragma solidity >=0.6.0 <0.7.0;

import "@darwinia/contracts-utils/contracts/ds-test/test.sol";
import "./MerkleProof.sol";
pragma experimental ABIEncoderV2;

contract MerkleProofTest is DSTest {
    function setUp() public {}

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }

    function verifyMerkleLeafAtPosition(
        bytes32 root,
        bytes32 leaf,
        uint256 pos,
        uint256 width,
        bytes32[] memory proof
    ) public logs_gas returns (bool) {
        bool res = MerkleProof.verifyMerkleLeafAtPosition(root, leaf, pos, width, proof);
        assertTrue(res);
        return res;
    }
}
