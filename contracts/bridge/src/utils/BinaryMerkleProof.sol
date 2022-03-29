// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/// @title A verifier for binary merkle tree.
/// @author echo
/// @notice Binary Merkle Tree is constructed from arbitrary-length leaves,
///  that are initially hashed using the `keccak256` hash function as the inner nodes.
///  Inner nodes are created by concatenating child hashes and hashing again.
/// @dev If the number of leaves is not even, last leave (hash of) is promoted to the upper layer.
library BinaryMerkleProof {

    function hash_node(bytes32 left, bytes32 right)
        internal
        pure
        returns (bytes32 hash)
    {
        assembly {
            mstore(0x00, left)
            mstore(0x20, right)
            hash := keccak256(0x00, 0x40)
        }
        return hash;
    }

    /// @notice Verify that a specific leaf element is part of the Merkle Tree at a specific position in the tree.
    //
    /// @param root The root of the merkle tree
    /// @param leaf The leaf which needs to be proven
    /// @param pos The position of the leaf, index starting with 0
    /// @param proof The array of proofs to help verify the leaf's membership, ordered from leaf to root
    /// @return A boolean value representing the success or failure of the verification
    function verifyMerkleLeafAtPosition(
        bytes32 root,
        bytes32 leaf,
        uint256 pos,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        uint256 depth = proof.length;
        uint256 index = 2**depth + pos;
        bytes32 value = leaf;
        for (uint256 i = 0; i < depth; i++) {
            if (index & 1 == 0) {
                value = hash_node(value, proof[i]);
            } else {
                value = hash_node(proof[i], value);
            }
            index /= 2;
        }
        return value == root;
    }
}
