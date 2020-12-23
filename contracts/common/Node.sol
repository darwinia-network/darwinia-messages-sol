// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Input.sol";
import "./Nibble.sol";
import "./Bytes.sol";
import "./Hash.sol";
import "./Scale.sol";

library Node {
    using Input for Input.Data;
    using Bytes for bytes;

    uint8 internal constant NODEKIND_NOEXT_LEAF = 1;
    uint8 internal constant NODEKIND_NOEXT_BRANCH_NOVALUE = 2;
    uint8 internal constant NODEKIND_NOEXT_BRANCH_WITHVALUE = 3;

    struct NodeHandle {
        bytes data;
        bool exist;
        bool isInline;
    }

    struct Branch {
        bytes key; //partialkey
        NodeHandle[16] children;
        bytes value;
    }

    struct Leaf {
        bytes key; //partialkey
        bytes value;
    }

    // decodeBranch decodes a byte array into a branch node
    function decodeBranch(Input.Data memory data, uint8 header)
        internal
        pure
        returns (Branch memory)
    {
        Branch memory b;
        b.key = decodeNodeKey(data, header);
        uint8[2] memory bitmap;
        bitmap[0] = data.decodeU8();
        bitmap[1] = data.decodeU8();
        uint8 nodeType = header >> 6;
        if (nodeType == NODEKIND_NOEXT_BRANCH_WITHVALUE) {
            //BRANCH_WITH_MASK_NO_EXT
            b.value = Scale.decodeByteArray(data);
        }
        for (uint8 i = 0; i < 16; i++) {
            if (((bitmap[i / 8] >> (i % 8)) & 1) == 1) {
                bytes memory childData = Scale.decodeByteArray(data);
                bool isInline = true;
                if (childData.length == 32) {
                    isInline = false;
                }
                b.children[i] = NodeHandle({
                    data: childData,
                    isInline: isInline,
                    exist: true
                });
            }
        }
        return b;
    }

    // decodeLeaf decodes a byte array into a leaf node
    function decodeLeaf(Input.Data memory data, uint8 header)
        internal
        pure
        returns (Leaf memory)
    {
        Leaf memory l;
        l.key = decodeNodeKey(data, header);
        l.value = Scale.decodeByteArray(data);
        return l;
    }

    function decodeNodeKey(Input.Data memory data, uint8 header)
        internal
        pure
        returns (bytes memory key)
    {
        uint256 keyLen = header & 0x3F;
        if (keyLen == 0x3f) {
            while (keyLen < 65536) {
                uint8 nextKeyLen = data.decodeU8();
                keyLen += uint256(nextKeyLen);
                if (nextKeyLen < 0xFF) {
                    break;
                }
                require(
                    keyLen < 65536,
                    "Size limit reached for a nibble slice"
                );
            }
        }
        if (keyLen != 0) {
            key = data.decodeBytesN(keyLen / 2 + (keyLen % 2));
            key = Nibble.keyToNibbles(key);
            if (keyLen % 2 == 1) {
                key = key.substr(1);
            }
        }
        return key;
    }
}
