// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Input.sol";
import "./Nibble.sol";
import "./Bytes.sol";
import "./Keccak.sol";
import "./Scale.sol";

library Node {
    using Input for Input.Data;
    using Keccak for bytes;
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

    // encodeBranch encodes a branch
    function encodeBranch(Branch memory b)
        internal
        pure
        returns (bytes memory encoding)
    {
        encoding = encodeBranchHeader(b);
        encoding = abi.encodePacked(encoding, Nibble.nibblesToKeyLE(b.key));
        encoding = abi.encodePacked(encoding, u16ToBytes(childrenBitmap(b)));
        if (b.value.length != 0) {
            bytes memory encValue;
            (encValue, ) = Scale.encodeByteArray(b.value);
            encoding = abi.encodePacked(encoding, encValue);
        }
        for (uint8 i = 0; i < 16; i++) {
            if (b.children[i].exist) {
                //TODO::encode data
                bytes memory childData = b.children[i].data;
                require(childData.length > 0, "miss child data");
                bytes memory hash;
                if (childData.length <= 32) {
                    hash = childData;
                } else {
                    hash = Memory.toBytes(childData.hash());
                }
                bytes memory encChild;
                (encChild, ) = Scale.encodeByteArray(hash);
                encoding = abi.encodePacked(encoding, encChild);
            }
        }
        return encoding;
    }

    // encodeLeaf encodes a leaf
    function encodeLeaf(Leaf memory l)
        internal
        pure
        returns (bytes memory encoding)
    {
        encoding = encodeLeafHeader(l);
        encoding = abi.encodePacked(encoding, Nibble.nibblesToKeyLE(l.key));
        bytes memory encValue;
        (encValue, ) = Scale.encodeByteArray(l.value);
        encoding = abi.encodePacked(encoding, encValue);
        return encoding;
    }

    function encodeBranchHeader(Branch memory b)
        internal
        pure
        returns (bytes memory branchHeader)
    {
        uint8 header;
        uint256 valueLen = b.value.length;
        require(valueLen < 65536, "partial key too long");
        if (valueLen == 0) {
            header = 2 << 6; // w/o
        } else {
            header = 3 << 6; // w/
        }
        bytes memory encPkLen;
        uint256 pkLen = b.key.length;
        if (pkLen >= 63) {
            header = header | 0x3F;
            encPkLen = encodeExtraPartialKeyLength(uint16(pkLen));
        } else {
            header = header | uint8(pkLen);
        }
        branchHeader = abi.encodePacked(header, encPkLen);
        return branchHeader;
    }

    function encodeLeafHeader(Leaf memory l)
        internal
        pure
        returns (bytes memory leafHeader)
    {
        uint8 header = 1 << 6;
        uint256 pkLen = l.key.length;
        bytes memory encPkLen;
        if (pkLen >= 63) {
            header = header | 0x3F;
            encPkLen = encodeExtraPartialKeyLength(uint16(pkLen));
        } else {
            header = header | uint8(pkLen);
        }
        leafHeader = abi.encodePacked(header, encPkLen);
        return leafHeader;
    }

    function encodeExtraPartialKeyLength(uint16 pkLen)
        internal
        pure
        returns (bytes memory encPkLen)
    {
        pkLen -= 63;
        for (uint8 i = 0; i < 65536; i++) {
            if (pkLen < 255) {
                encPkLen = abi.encodePacked(encPkLen, uint8(pkLen));
                break;
            } else {
                encPkLen = abi.encodePacked(encPkLen, uint8(255));
            }
        }
        return encPkLen;
    }

    // u16ToBytes converts a uint16 into a 2-byte slice
    function u16ToBytes(uint16 src) internal pure returns (bytes memory des) {
        des = new bytes(2);
        des[0] = bytes1(uint8(src & 0x00FF));
        des[1] = bytes1(uint8((src >> 8) & 0x00FF));
    }

    function childrenBitmap(Branch memory b)
        internal
        pure
        returns (uint16 bitmap)
    {
        for (uint256 i = 0; i < 16; i++) {
            if (b.children[i].exist) {
                bitmap = bitmap | uint16(1 << i);
            }
        }
    }
}
