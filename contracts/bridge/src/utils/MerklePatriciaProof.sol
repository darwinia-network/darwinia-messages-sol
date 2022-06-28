// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./RLPDecode.sol";

library MerklePatriciaProof {
    using RLPDecode for RLPDecode.RLPItem;
    using RLPDecode for RLPDecode.Iterator;

    /// @dev Validates a Merkle-Patricia-Trie proof.
    ///      If the proof proves the inclusion of value in the trie, the value is returned.
    ///      It only prove the value is included in the tree, the format and sanity of the value should be checked by caller.
    ///      It will revert if the proof is invalid.
    /// @param rootHash is the Keccak-256 hash of the root node of the MPT.
    /// @param paths select indexes array encoding to uint256.
    /// @param proof is decoded to stack of MPT nodes (starting with the root) that
    ///        need to be traversed during verification.
    /// @return value whose inclusion is proved or an empty byte array for
    ///         a proof of exclusion
    function validateProof(
        bytes32 rootHash,
        uint256 paths,
        bytes memory proof
    ) internal pure returns (bytes memory) {
        RLPDecode.RLPItem memory item = RLPDecode.toRlpItem(proof);
        RLPDecode.Iterator memory iterator = item.iterator();
        uint256 numItems = item.numItems();
        for (uint256 i = 0; i < numItems; i++) {
            item = iterator.next();
            uint256 index = uint8(paths);
            paths >>= 8;
            require(
                rootHash == item.toRlpBytesHash(),
                "ProofLib: invalid hashlink"
            );
            item = item.safeGetItemByIndex(index);
            if (i < numItems - 1) rootHash = bytes32(item.toUint());
        }
        require(paths == 0, "invalid path");
        return item.toBytes();
    }
}
