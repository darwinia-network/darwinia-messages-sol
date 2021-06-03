// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@darwinia/contracts-utils/contracts/Input.sol";
import "@darwinia/contracts-utils/contracts/Bytes.sol";
import "@darwinia/contracts-utils/contracts/Hash.sol";
import "@darwinia/contracts-utils/contracts/Nibble.sol";
import "@darwinia/contracts-utils/contracts/Node.sol";

/**
 * @dev Simple Verification of compact proofs for Modified Merkle-Patricia tries.
 */
library SimpleMerkleProof {
    using Bytes for bytes;
    using Input for Input.Data;

    uint8 internal constant NODEKIND_NOEXT_EMPTY = 0;
    uint8 internal constant NODEKIND_NOEXT_LEAF = 1;
    uint8 internal constant NODEKIND_NOEXT_BRANCH_NOVALUE = 2;
    uint8 internal constant NODEKIND_NOEXT_BRANCH_WITHVALUE = 3;

    struct Item {
        bytes32 key;
        bytes value;
    }

    /**
     * @dev Returns `values` if `keys` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, is a sequence of the subset
     * of nodes in the trie traversed while performing lookups on all keys.
     */
    function verify(
        bytes32 root,
        bytes[] memory proof,
        bytes[] memory keys
    ) internal view returns (bytes[] memory) {
        require(proof.length > 0, "no proof");
        require(keys.length > 0, "no keys");
        Item[] memory db = new Item[](proof.length);
        for (uint256 i = 0; i < proof.length; i++) {
            bytes memory v = proof[i];
            Item memory item = Item({key: Hash.blake2bHash(v), value: v});
            db[i] = item;
        }
        return verify_proof(root, keys, db);
    }

    /**
     * @dev Returns `values` if `keys` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, is a sequence of the subset
     * of nodes in the trie traversed while performing lookups on all keys.
     */
    function getEvents(
        bytes32 root,
        bytes memory key,
        bytes[] memory proof
    ) internal view returns (bytes memory value) {
        bytes memory k = Nibble.keyToNibbles(key);

        Item[] memory db = new Item[](proof.length);
        for (uint256 i = 0; i < proof.length; i++) {
            bytes memory v = proof[i];
            Item memory item = Item({key: Hash.blake2bHash(v), value: v});
            db[i] = item;
        }

        value = lookUp(root, k, db);
    }

    function verify_proof(
        bytes32 root,
        bytes[] memory keys,
        Item[] memory db
    ) internal pure returns (bytes[] memory values) {
        values = new bytes[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            bytes memory k = Nibble.keyToNibbles(keys[i]);
            bytes memory v = lookUp(root, k, db);
            values[i] = v;
        }
        return values;
    }

    /// Look up the given key. the value returns if it is found
    function lookUp(
        bytes32 root,
        bytes memory key,
        Item[] memory db
    ) internal pure returns (bytes memory v) {
        bytes32 hash = root;
        bytes memory partialKey = key;
        while (true) {
            bytes memory nodeData = getNodeData(hash, db);
            if (nodeData.length == 0) {
                return hex"";
            }
            while (true) {
                Input.Data memory data = Input.from(nodeData);
                uint8 header = data.decodeU8();
                uint8 kind = header >> 6;
                if (kind == NODEKIND_NOEXT_LEAF) {
                    //Leaf
                    Node.Leaf memory leaf = Node.decodeLeaf(data, header);
                    if (leaf.key.equals(partialKey)) {
                        return leaf.value;
                    } else {
                        return hex"";
                    }
                } else if (
                    kind == NODEKIND_NOEXT_BRANCH_NOVALUE ||
                    kind == NODEKIND_NOEXT_BRANCH_WITHVALUE
                ) {
                    //BRANCH_WITHOUT_MASK_NO_EXT  BRANCH_WITH_MASK_NO_EXT
                    Node.Branch memory branch = Node.decodeBranch(data, header);
                    uint256 sliceLen = branch.key.length;
                    if (startsWith(partialKey, branch.key)) {
                        if (partialKey.length == sliceLen) {
                            return branch.value;
                        } else {
                            uint8 index = uint8(partialKey[sliceLen]);
                            Node.NodeHandle memory child = branch
                                .children[index];
                            if (child.exist) {
                                partialKey = partialKey.substr(sliceLen + 1);
                                if (child.isInline) {
                                    nodeData = child.data;
                                } else {
                                    hash = abi.decode(child.data, (bytes32));
                                    break;
                                }
                            } else {
                                return hex"";
                            }
                        }
                    } else {
                        return hex"";
                    }
                } else if (kind == NODEKIND_NOEXT_EMPTY) {
                    return hex"";
                } else {
                    revert("not support node type");
                }
            }
        }
    }

    function getNodeData(bytes32 hash, Item[] memory db)
        internal
        pure
        returns (bytes memory)
    {
        for (uint256 i = 0; i < db.length; i++) {
            Item memory item = db[i];
            if (hash == item.key) {
                return item.value;
            }
        }
        return hex"";
    }

    function startsWith(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        if (a.length < b.length) {
            return false;
        }
        for (uint256 i = 0; i < b.length; i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }
}
