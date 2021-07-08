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

    function verifySparseMerkleLeaf(
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

    function verifyMerkleLeafAtPosition(
        bytes32 root,
        bytes32 leaf,
        uint256 pos,
        uint256 width,
        bytes32[] memory proof
    ) public pure returns (bool) {
        return MerkleProof.verifyMerkleLeafAtPosition(root, leaf, pos, width, proof);
    }

    /**
     * @notice Verify a flat array of data elements
     *
     * @param _data the array of data elements to be verified
     * @param _commitment the commitment hash to check
     * @return a boolean value representing the success or failure of the operation
     */
    function verifyMessageArray(bytes32[] calldata _data, bytes32 _commitment) external pure returns (bool) {
        bytes32 commitment = _data[0];
        for (uint256 i = 1; i < _data.length; i++) {
            commitment = keccak256(abi.encodePacked(commitment, _data[i]));
        }

        return commitment == _commitment;
    }

    function verifyMessageArrayUnpacked(bytes32[] calldata messages, bytes32 _commitment) external pure returns (bool) {
        return keccak256(abi.encode(messages)) == _commitment;
    }

    /**
     * @notice Verify all elements in a Merkle Tree data structure
     * @dev Performs an in-place merkle tree root calculation
     * @dev Note there is currently an assumption here that if the number
     *      of leaves is odd, the final leaf will be duplicated prior to
     *      calling this function
     *
     * @param _data the array of data elements to be verified
     * @param _commitment the expected merkle root of the structure
     * @return a boolean value representing the success or failure of the operation
     */
    function verifyMerkleAll(bytes32[] memory _data, bytes32 _commitment) public pure returns (bool) {
        uint256 hashLength = _data.length;

        for (uint256 j = 0; hashLength > 1; j = 0) {
            for (uint256 i = 0; i < hashLength; i = i + 2) {
                _data[j] = keccak256(abi.encodePacked(_data[i], _data[i + 1]));
                j = j + 1;
            }
            // This effectively halves the list length every time,
            // but a subtraction op-code costs less
            hashLength = hashLength - j;
        }

        return _data[0] == _commitment;
    }

    /**
     * @notice Verify a single leaf element in a Merkle Tree
     * @dev For sake of simplifying the verification algorithm,
     *      we make an assumption that the proof elements are sorted
     *
     * @param root the root of the merkle tree
     * @param leaf the leaf which needs to be proved
     * @param proof the array of proofs to help verify the leafs membership
     * @return a boolean value representing the success or failure of the operation
     */
    function verifyMerkleLeaf(
        bytes32 root,
        bytes32 leaf,
        bytes32[] calldata proof
    ) external pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash < proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == root;
    }

}
