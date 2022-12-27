// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

import "../Memory.sol";

/**
 * @custom:attribution https://github.com/hamdiallam/Solidity-RLP
 * @title RLPReader
 * @notice RLPReader is a library for parsing RLP-encoded byte arrays into Solidity types. Adapted
 *         from Solidity-RLP (https://github.com/hamdiallam/Solidity-RLP) by Hamdi Allam with
 *         various tweaks to improve readability.
 */
library RLPDecode {
    /**
     * Custom pointer type to avoid confusion between pointers and uint256s.
     */
    type MemoryPointer is uint256;

    /**
     * @notice RLP item types.
     *
     * @custom:value DATA_ITEM Represents an RLP data item (NOT a list).
     * @custom:value LIST_ITEM Represents an RLP list item.
     */
    enum RLPItemType {
        DATA_ITEM,
        LIST_ITEM
    }

    /**
     * @notice Struct representing an RLP item.
     *
     * @custom:field length Length of the RLP item.
     * @custom:field ptr    Pointer to the RLP item in memory.
     */
    struct RLPItem {
        uint256 length;
        MemoryPointer ptr;
    }

    /**
     * @notice Max list length that this library will accept.
     */
    uint256 internal constant MAX_LIST_LENGTH = 32;

    /**
     * @notice Converts bytes to a reference to memory position and length.
     *
     * @param _in Input bytes to convert.
     *
     * @return Output memory reference.
     */
    function toRLPItem(bytes memory _in) internal pure returns (RLPItem memory) {
        // Empty arrays are not RLP items.
        require(
            _in.length > 0,
            "RLPReader: length of an RLP item must be greater than zero to be decodable"
        );

        MemoryPointer ptr;
        assembly ("memory-safe") {
            ptr := add(_in, 32)
        }

        return RLPItem({ length: _in.length, ptr: ptr });
    }

    /**
     * @notice Reads an RLP list value into a list of RLP items.
     *
     * @param _in RLP list value.
     *
     * @return Decoded RLP list items.
     */
    function readList(RLPItem memory _in) internal pure returns (RLPItem[] memory) {
        (uint256 listOffset, uint256 listLength, RLPItemType itemType) = _decodeLength(_in);

        require(
            itemType == RLPItemType.LIST_ITEM,
            "RLPReader: decoded item type for list is not a list item"
        );

        require(
            listOffset + listLength == _in.length,
            "RLPReader: list item has an invalid data remainder"
        );

        // Solidity in-memory arrays can't be increased in size, but *can* be decreased in size by
        // writing to the length. Since we can't know the number of RLP items without looping over
        // the entire input, we'd have to loop twice to accurately size this array. It's easier to
        // simply set a reasonable maximum list length and decrease the size before we finish.
        RLPItem[] memory out = new RLPItem[](MAX_LIST_LENGTH);

        uint256 itemCount = 0;
        uint256 offset = listOffset;
        while (offset < _in.length) {
            (uint256 itemOffset, uint256 itemLength, ) = _decodeLength(
                RLPItem({
                    length: _in.length - offset,
                    ptr: MemoryPointer.wrap(MemoryPointer.unwrap(_in.ptr) + offset)
                })
            );

            // We don't need to check itemCount < out.length explicitly because Solidity already
            // handles this check on our behalf, we'd just be wasting gas.
            out[itemCount] = RLPItem({
                length: itemLength + itemOffset,
                ptr: MemoryPointer.wrap(MemoryPointer.unwrap(_in.ptr) + offset)
            });

            itemCount += 1;
            offset += itemOffset + itemLength;
        }

        // Decrease the array size to match the actual item count.
        assembly ("memory-safe") {
            mstore(out, itemCount)
        }

        return out;
    }

    /**
     * @notice Reads an RLP list value into a list of RLP items.
     *
     * @param _in RLP list value.
     *
     * @return Decoded RLP list items.
     */
    function readList(bytes memory _in) internal pure returns (RLPItem[] memory) {
        return readList(toRLPItem(_in));
    }

    /**
     * @notice Reads an RLP bytes value into bytes.
     *
     * @param _in RLP bytes value.
     *
     * @return Decoded bytes.
     */
    function readBytes(RLPItem memory _in) internal pure returns (bytes memory) {
        (uint256 itemOffset, uint256 itemLength, RLPItemType itemType) = _decodeLength(_in);

        require(
            itemType == RLPItemType.DATA_ITEM,
            "RLPReader: decoded item type for bytes is not a data item"
        );

        require(
            _in.length == itemOffset + itemLength,
            "RLPReader: bytes value contains an invalid remainder"
        );

        return _copy(_in.ptr, itemOffset, itemLength);
    }

    /**
     * @notice Reads an RLP bytes value into bytes.
     *
     * @param _in RLP bytes value.
     *
     * @return Decoded bytes.
     */
    function readBytes(bytes memory _in) internal pure returns (bytes memory) {
        return readBytes(toRLPItem(_in));
    }

    /**
     * @notice Reads the raw bytes of an RLP item.
     *
     * @param _in RLP item to read.
     *
     * @return Raw RLP bytes.
     */
    function readRawBytes(RLPItem memory _in) internal pure returns (bytes memory) {
        return _copy(_in.ptr, 0, _in.length);
    }

    /**
     * Reads an RLP string value into a string.
     * @param _in RLP string value.
     * @return Decoded string.
     */
    function readString(RLPItem memory _in) internal pure returns (string memory) {
        return string(readBytes(_in));
    }

    /**
     * Reads an RLP string value into a string.
     * @param _in RLP string value.
     * @return Decoded string.
     */
    function readString(bytes memory _in) internal pure returns (string memory) {
        return readString(toRLPItem(_in));
    }

    /**
     * Reads an RLP bytes32 value into a bytes32.
     * @param _in RLP bytes32 value.
     * @return Decoded bytes32.
     */
    function readBytes32(RLPItem memory _in) internal pure returns (bytes32) {
        require(_in.length <= 33, "Invalid RLP bytes32 value.");

        (uint256 itemOffset, uint256 itemLength, RLPItemType itemType) = _decodeLength(_in);

        require(itemType == RLPItemType.DATA_ITEM, "Invalid RLP bytes32 value.");

        uint256 ptr = MemoryPointer.unwrap(_in.ptr) + itemOffset;
        bytes32 out;
        assembly ("memory-safe") {
            out := mload(ptr)

            // Shift the bytes over to match the item size.
            if lt(itemLength, 32) {
                out := div(out, exp(256, sub(32, itemLength)))
            }
        }

        return out;
    }

    /**
     * Reads an RLP bytes32 value into a bytes32.
     * @param _in RLP bytes32 value.
     * @return Decoded bytes32.
     */
    function readBytes32(bytes memory _in) internal pure returns (bytes32) {
        return readBytes32(toRLPItem(_in));
    }

    /**
     * Reads an RLP uint256 value into a uint256.
     * @param _in RLP uint256 value.
     * @return Decoded uint256.
     */
    function readUint256(RLPItem memory _in) internal pure returns (uint256) {
        return uint256(readBytes32(_in));
    }

    /**
     * Reads an RLP uint256 value into a uint256.
     * @param _in RLP uint256 value.
     * @return Decoded uint256.
     */
    function readUint256(bytes memory _in) internal pure returns (uint256) {
        return readUint256(toRLPItem(_in));
    }

    /**
     * @notice Decodes the length of an RLP item.
     *
     * @param _in RLP item to decode.
     *
     * @return Offset of the encoded data.
     * @return Length of the encoded data.
     * @return RLP item type (LIST_ITEM or DATA_ITEM).
     */
    function _decodeLength(RLPItem memory _in)
        private
        pure
        returns (
            uint256,
            uint256,
            RLPItemType
        )
    {
        // Short-circuit if there's nothing to decode, note that we perform this check when
        // the user creates an RLP item via toRLPItem, but it's always possible for them to bypass
        // that function and create an RLP item directly. So we need to check this anyway.
        require(
            _in.length > 0,
            "RLPReader: length of an RLP item must be greater than zero to be decodable"
        );

        MemoryPointer ptr = _in.ptr;
        uint256 prefix;
        assembly ("memory-safe") {
            prefix := byte(0, mload(ptr))
        }

        if (prefix <= 0x7f) {
            // Single byte.
            return (0, 1, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xb7) {
            // Short string.

            // slither-disable-next-line variable-scope
            uint256 strLen = prefix - 0x80;

            require(
                _in.length > strLen,
                "RLPReader: length of content must be greater than string length (short string)"
            );

            bytes1 firstByteOfContent;
            assembly ("memory-safe") {
                firstByteOfContent := and(mload(add(ptr, 1)), shl(248, 0xff))
            }

            require(
                strLen != 1 || firstByteOfContent >= 0x80,
                "RLPReader: invalid prefix, single byte < 0x80 are not prefixed (short string)"
            );

            return (1, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xbf) {
            // Long string.
            uint256 lenOfStrLen = prefix - 0xb7;

            require(
                _in.length > lenOfStrLen,
                "RLPReader: length of content must be > than length of string length (long string)"
            );

            bytes1 firstByteOfContent;
            assembly ("memory-safe") {
                firstByteOfContent := and(mload(add(ptr, 1)), shl(248, 0xff))
            }

            require(
                firstByteOfContent != 0x00,
                "RLPReader: length of content must not have any leading zeros (long string)"
            );

            uint256 strLen;
            assembly ("memory-safe") {
                strLen := shr(sub(256, mul(8, lenOfStrLen)), mload(add(ptr, 1)))
            }

            require(
                strLen > 55,
                "RLPReader: length of content must be greater than 55 bytes (long string)"
            );

            require(
                _in.length > lenOfStrLen + strLen,
                "RLPReader: length of content must be greater than total length (long string)"
            );

            return (1 + lenOfStrLen, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xf7) {
            // Short list.
            // slither-disable-next-line variable-scope
            uint256 listLen = prefix - 0xc0;

            require(
                _in.length > listLen,
                "RLPReader: length of content must be greater than list length (short list)"
            );

            return (1, listLen, RLPItemType.LIST_ITEM);
        } else {
            // Long list.
            uint256 lenOfListLen = prefix - 0xf7;

            require(
                _in.length > lenOfListLen,
                "RLPReader: length of content must be > than length of list length (long list)"
            );

            bytes1 firstByteOfContent;
            assembly ("memory-safe") {
                firstByteOfContent := and(mload(add(ptr, 1)), shl(248, 0xff))
            }

            require(
                firstByteOfContent != 0x00,
                "RLPReader: length of content must not have any leading zeros (long list)"
            );

            uint256 listLen;
            assembly ("memory-safe") {
                listLen := shr(sub(256, mul(8, lenOfListLen)), mload(add(ptr, 1)))
            }

            require(
                listLen > 55,
                "RLPReader: length of content must be greater than 55 bytes (long list)"
            );

            require(
                _in.length > lenOfListLen + listLen,
                "RLPReader: length of content must be greater than total length (long list)"
            );

            return (1 + lenOfListLen, listLen, RLPItemType.LIST_ITEM);
        }
    }

    /**
     * @notice Copies the bytes from a memory location.
     *
     * @param _src    Pointer to the location to read from.
     * @param _offset Offset to start reading from.
     * @param _length Number of bytes to read.
     *
     * @return Copied bytes.
     */
    function _copy(
        MemoryPointer _src,
        uint256 _offset,
        uint256 _length
    ) private pure returns (bytes memory) {
        bytes memory out = new bytes(_length);
        if (_length == 0) {
            return out;
        }

        uint256 src = MemoryPointer.unwrap(_src) + _offset;
        uint256 desc;
        (desc,) = Memory.fromBytes(out);
        Memory.copy(src, desc, _length);

        return out;
    }
}
