// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

/// @title A verifier for binary merkle tree.
/// @author echo
/// @notice Binary Merkle Tree is constructed from arbitrary-length leaves,
///  that are initially hashed using the `keccak256` hash function as the inner nodes.
///  Inner nodes are created by concatenating child hashes and hashing again.
/// @dev If the number of leaves is not even, last leave (hash of) is promoted to the upper layer.
library BinaryMerkleProof {

    /// @notice Verify that a specific leaf element is part of the Merkle Tree at a specific position in the tree.
    //
    /// @param root The root of the merkle tree
    /// @param leaf The leaf which needs to be proven
    /// @param pos The position of the leaf, index starting with 0
    /// @param width The width or number of leaves in the tree
    /// @param proof The array of proofs to help verify the leaf's membership, ordered from leaf to root
    /// @return A boolean value representing the success or failure of the verification
    function verifyMerkleLeafAtPosition(
        bytes32 root,
        bytes32 leaf,
        uint256 pos,
        uint256 width,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        if (pos + 1 > width) {
            return false;
        }

        uint256 i = 0;
        for (uint256 height = 0; width > 1; height++) {
            bool computedHashLeft = pos % 2 == 0;

            // check if at rightmost branch and whether the computedHash is left
            if (pos + 1 == width && computedHashLeft) {
                // there is no sibling and also no element in proofs, so we just go up one layer in the tree
                pos /= 2;
                width = ((width - 1) / 2) + 1;
                continue;
            }

            if (i >= proof.length) {
                // need another element from the proof we don't have
                return false;
            }

            bytes32 proofElement = proof[i];

            if (computedHashLeft) {
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }

            pos /= 2;
            width = ((width - 1) / 2) + 1;
            i++;
        }

        return computedHash == root;
    }
}
