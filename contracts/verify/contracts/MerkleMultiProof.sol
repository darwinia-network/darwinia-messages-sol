pragma solidity >=0.6.0 <0.7.0;

/**
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * @notice based on https://github.com/ethereum/eth2.0-specs/blob/dev/ssz/merkle-proofs.md#merkle-multiproofs but without generalized indexes
 */
library MerkleMultiProof {

   /**
     * @notice Check validity of multimerkle proof
     * @param leaves ordered sequence of leaves and it's siblings
     * @param proofs ordered sequence of parent proofs
     * @param proofFlag flags for using or not proofs while hashing against hashes.
     * @return merkleRoot merkle root of tree
     */
    function calculateMultiMerkleRoot(
        bytes32[] memory leaves,
        bytes32[] memory proofs,
        bool[] memory proofFlag
    )
        internal 
        pure
        returns (bytes32 merkleRoot)
    {
        uint256 leafsLen = leaves.length;
        uint256 totalHashes = proofFlag.length;
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint leafPos = 0;
        uint hashPos = 0;
        uint proofPos = 0;
        for(uint256 i = 0; i < totalHashes; i++){
            hashes[i] = hashPair(
                proofFlag[i] ? (leafPos < leafsLen ? leaves[leafPos++] : hashes[hashPos++]) : proofs[proofPos++],
                leafPos < leafsLen ? leaves[leafPos++] : hashes[hashPos++]
            );
        }

        return hashes[totalHashes-1];
    }

    function hashPair(bytes32 a, bytes32 b) private pure returns(bytes32){
        return a < b ? hash_node(a, b) : hash_node(b, a);
    }

    function hash_node(bytes32 left, bytes32 right)
        private pure
        returns (bytes32 hash)
    {
        assembly {
            mstore(0x00, left)
            mstore(0x20, right)
            hash := keccak256(0x00, 0x40)
        }
        return hash;
    }

    /**
     * @notice Check validity of multimerkle proof
     * @param root merkle root
     * @param leaves ordered sequence of leaves and it's siblings
     * @param proofs ordered sequence of parent proofs
     * @param proofFlag flags for using or not proofs while hashing against hashes.
     */
    function verifyMultiProof(
        bytes32 root,
        bytes32[] memory leaves,
        bytes32[] memory proofs,
        bool[] memory proofFlag
    )
        internal 
        pure
        returns (bool)
    {
        return calculateMultiMerkleRoot(leaves, proofs, proofFlag) == root;
    }

    // Indices are required to be sorted highest to lowest.
    function verify(
        bytes32 root,
        uint256 depth,
        uint256[] memory indices,
        bytes32[] memory leaves,
        bytes32[] memory decommitments
    )
        internal
        pure
        returns (bool)
    {
        require(indices.length == leaves.length, "LENGTH_MISMATCH");
        uint256 n = indices.length;

        // Dynamically allocate index and hash queue
        uint256[] memory tree_indices = new uint256[](n + 1);
        bytes32[] memory hashes = new bytes32[](n + 1);
        uint256 head = 0;
        uint256 tail = 0;
        uint256 di = 0;

        // Queue the leafs
        for(; tail < n; ++tail) {
            tree_indices[tail] = 2**depth + indices[tail];
            hashes[tail] = leaves[tail];
        }

        // Itterate the queue until we hit the root
        while (true) {
            uint256 index = tree_indices[head];
            bytes32 hash = hashes[head];
            head = (head + 1) % (n + 1);

            // Merkle root
            if (index == 1) {
                return hash == root;
            
            // Even node, take sibbling from decommitments
            } else if (index & 1 == 0) {
                hash = hash_node(hash, decommitments[di++]);
            
            // Odd node with sibbling in the queue
            } else if (head != tail && tree_indices[head] == index - 1) {
                hash = hash_node(hashes[head], hash);
                head = (head + 1) % n;
            
            // Odd node with sibbling from decommitments
            } else {
                hash = hash_node(decommitments[di++], hash);
            
            }
            tree_indices[tail] = index / 2;
            hashes[tail] = hash;
            tail = (tail + 1) % (n + 1);
        }
    }
}
