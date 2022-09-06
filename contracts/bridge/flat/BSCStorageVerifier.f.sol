// hevm: flattened sources of src/truth/bsc/BSCStorageVerifier.sol
// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

////// src/interfaces/ILightClient.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.7.6; */

interface ILightClient {
    function merkle_root() external view returns (bytes32);
}

////// src/interfaces/IVerifier.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.7.6; */

interface IVerifier {
    function verify_messages_proof(
        bytes32 outlane_data_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external view returns (bool);

    function verify_messages_delivery_proof(
        bytes32 inlane_data_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external view returns (bool);
}

////// src/spec/ChainMessagePosition.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.7.6; */
/* pragma abicoder v2; */

enum ChainMessagePosition {
    Darwinia,
    ETH,
    BSC
}

////// src/spec/SourceChain.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.7.6; */
/* pragma abicoder v2; */

contract SourceChain {
    /// The MessagePayload is the structure of RPC which should be delivery to target chain
    /// @param source The source contract address which send the message
    /// @param target The targe contract address which receive the message
    /// @param encoded The calldata which encoded by ABI Encoding
    struct MessagePayload {
        address source;
        address target;
        bytes encoded; /*(abi.encodePacked(SELECTOR, PARAMS))*/
    }

    /// Message key (unique message identifier) as it is stored in the storage.
    struct MessageKey {
        // This chain position
        uint32 this_chain_pos;
        // Position of the message this lane.
        uint32 this_lane_pos;
        // Bridged chain position
        uint32 bridged_chain_pos;
        // Position of the message bridged lane.
        uint32 bridged_lane_pos;
        // Nonce of the message.
        uint64 nonce;
    }

    struct MessageStorage {
        uint256 encoded_key;
        bytes32 payload_hash;
    }

    /// Message as it is stored in the storage.
    struct Message {
        // Encoded message key.
        uint256 encoded_key;
        // Message payload.
        MessagePayload payload;
    }

    /// Outbound lane data.
    struct OutboundLaneData {
        // Nonce of the latest message, received by bridged chain.
        uint64 latest_received_nonce;
        // Messages sent through this lane.
        Message[] messages;
    }

    struct OutboundLaneDataStorage {
        uint64 latest_received_nonce;
        MessageStorage[] messages;
    }

    /// @dev Hash of the OutboundLaneData Schema
    /// keccak256(abi.encodePacked(
    ///     "OutboundLaneData(uint256 latest_received_nonce,Message[] messages)",
    ///     "Message(uint256 encoded_key,MessagePayload payload)",
    ///     "MessagePayload(address source,address target,bytes32 encoded_hash)"
    ///     )
    /// )
    bytes32 internal constant OUTBOUNDLANEDATA_TYPEHASH = 0x823237038687bee0f021baf36aa1a00c49bd4d430512b28fed96643d7f4404c6;


    /// @dev Hash of the Message Schema
    /// keccak256(abi.encodePacked(
    ///     "Message(uint256 encoded_key,MessagePayload payload)",
    ///     "MessagePayload(address source,address target,bytes32 encoded_hash)"
    ///     )
    /// )
    bytes32 internal constant MESSAGE_TYPEHASH = 0xfc686c8227203ee2031e2c031380f840b8cea19f967c05fc398fdeb004e7bf8b;

    /// @dev Hash of the MessagePayload Schema
    /// keccak256(abi.encodePacked(
    ///     "MessagePayload(address source,address target,bytes32 encoded_hash)"
    ///     )
    /// )
    bytes32 internal constant MESSAGEPAYLOAD_TYPEHASH = 0x582ffe1da2ae6da425fa2c8a2c423012be36b65787f7994d78362f66e4f84101;

    function hash(OutboundLaneData memory data)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                OUTBOUNDLANEDATA_TYPEHASH,
                data.latest_received_nonce,
                hash(data.messages)
            )
        );
    }

    function hash(OutboundLaneDataStorage memory data)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                OUTBOUNDLANEDATA_TYPEHASH,
                data.latest_received_nonce,
                hash(data.messages)
            )
        );
    }

    function hash(MessageStorage[] memory msgs)
        internal
        pure
        returns (bytes32)
    {
        uint msgsLength = msgs.length;
        bytes memory encoded = abi.encode(msgsLength);
        for (uint256 i = 0; i < msgsLength; i ++) {
            MessageStorage memory message = msgs[i];
            encoded = abi.encodePacked(
                encoded,
                abi.encode(
                    MESSAGE_TYPEHASH,
                    message.encoded_key,
                    message.payload_hash
                )
            );
        }
        return keccak256(encoded);
    }

    function hash(Message[] memory msgs)
        internal
        pure
        returns (bytes32)
    {
        uint msgsLength = msgs.length;
        bytes memory encoded = abi.encode(msgsLength);
        for (uint256 i = 0; i < msgsLength; i ++) {
            Message memory message = msgs[i];
            encoded = abi.encodePacked(
                encoded,
                abi.encode(
                    MESSAGE_TYPEHASH,
                    message.encoded_key,
                    hash(message.payload)
                )
            );
        }
        return keccak256(encoded);
    }

    function hash(MessagePayload memory payload)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                MESSAGEPAYLOAD_TYPEHASH,
                payload.source,
                payload.target,
                keccak256(payload.encoded)
            )
        );
    }

    function decodeMessageKey(uint256 encoded) internal pure returns (MessageKey memory key) {
        key.this_chain_pos = uint32(encoded >> 160);
        key.this_lane_pos = uint32(encoded >> 128);
        key.bridged_chain_pos = uint32(encoded >> 96);
        key.bridged_lane_pos = uint32(encoded >> 64);
        key.nonce = uint64(encoded);
    }
}

////// src/utils/rlp/RLPDecode.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.7.6; */

/**
 * @title RLDecode
 * @dev Adapted from "RLPDecode" by Hamdi Allam (hamdi.allam97@gmail.com).
 */
library RLPDecode {
    /*************
     * Constants *
     *************/

    uint256 internal constant MAX_LIST_LENGTH = 32;

    /*********
     * Enums *
     *********/

    enum RLPItemType {
        DATA_ITEM,
        LIST_ITEM
    }

    /***********
     * Structs *
     ***********/

    struct RLPItem {
        uint256 length;
        uint256 ptr;
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Converts bytes to a reference to memory position and length.
     * @param _in Input bytes to convert.
     * @return Output memory reference.
     */
    function toRLPItem(bytes memory _in) internal pure returns (RLPItem memory) {
        uint256 ptr;
        assembly {
            ptr := add(_in, 32)
        }

        return RLPItem({ length: _in.length, ptr: ptr });
    }

    /**
     * Reads an RLP list value into a list of RLP items.
     * @param _in RLP list value.
     * @return Decoded RLP list items.
     */
    function readList(RLPItem memory _in) internal pure returns (RLPItem[] memory) {
        (uint256 listOffset, , RLPItemType itemType) = _decodeLength(_in);

        require(itemType == RLPItemType.LIST_ITEM, "Invalid RLP list value.");

        // Solidity in-memory arrays can't be increased in size, but *can* be decreased in size by
        // writing to the length. Since we can't know the number of RLP items without looping over
        // the entire input, we'd have to loop twice to accurately size this array. It's easier to
        // simply set a reasonable maximum list length and decrease the size before we finish.
        RLPItem[] memory out = new RLPItem[](MAX_LIST_LENGTH);

        uint256 itemCount = 0;
        uint256 offset = listOffset;
        while (offset < _in.length) {
            require(itemCount < MAX_LIST_LENGTH, "Provided RLP list exceeds max list length.");

            (uint256 itemOffset, uint256 itemLength, ) = _decodeLength(
                RLPItem({ length: _in.length - offset, ptr: _in.ptr + offset })
            );

            out[itemCount] = RLPItem({ length: itemLength + itemOffset, ptr: _in.ptr + offset });

            itemCount += 1;
            offset += itemOffset + itemLength;
        }

        // Decrease the array size to match the actual item count.
        assembly {
            mstore(out, itemCount)
        }

        return out;
    }

    /**
     * Reads an RLP list value into a list of RLP items.
     * @param _in RLP list value.
     * @return Decoded RLP list items.
     */
    function readList(bytes memory _in) internal pure returns (RLPItem[] memory) {
        return readList(toRLPItem(_in));
    }

    /**
     * Reads an RLP bytes value into bytes.
     * @param _in RLP bytes value.
     * @return Decoded bytes.
     */
    function readBytes(RLPItem memory _in) internal pure returns (bytes memory) {
        (uint256 itemOffset, uint256 itemLength, RLPItemType itemType) = _decodeLength(_in);

        require(itemType == RLPItemType.DATA_ITEM, "Invalid RLP bytes value.");

        return _copy(_in.ptr, itemOffset, itemLength);
    }

    /**
     * Reads an RLP bytes value into bytes.
     * @param _in RLP bytes value.
     * @return Decoded bytes.
     */
    function readBytes(bytes memory _in) internal pure returns (bytes memory) {
        return readBytes(toRLPItem(_in));
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

        uint256 ptr = _in.ptr + itemOffset;
        bytes32 out;
        assembly {
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
     * Reads an RLP bool value into a bool.
     * @param _in RLP bool value.
     * @return Decoded bool.
     */
    function readBool(RLPItem memory _in) internal pure returns (bool) {
        require(_in.length == 1, "Invalid RLP boolean value.");

        uint256 ptr = _in.ptr;
        uint256 out;
        assembly {
            out := byte(0, mload(ptr))
        }

        require(out == 0 || out == 1, "RLPDecode: Invalid RLP boolean value, must be 0 or 1");

        return out != 0;
    }

    /**
     * Reads an RLP bool value into a bool.
     * @param _in RLP bool value.
     * @return Decoded bool.
     */
    function readBool(bytes memory _in) internal pure returns (bool) {
        return readBool(toRLPItem(_in));
    }

    /**
     * Reads an RLP address value into a address.
     * @param _in RLP address value.
     * @return Decoded address.
     */
    function readAddress(RLPItem memory _in) internal pure returns (address) {
        if (_in.length == 1) {
            return address(0);
        }

        require(_in.length == 21, "Invalid RLP address value.");

        return address(uint160(readUint256(_in)));
    }

    /**
     * Reads an RLP address value into a address.
     * @param _in RLP address value.
     * @return Decoded address.
     */
    function readAddress(bytes memory _in) internal pure returns (address) {
        return readAddress(toRLPItem(_in));
    }

    /**
     * Reads the raw bytes of an RLP item.
     * @param _in RLP item to read.
     * @return Raw RLP bytes.
     */
    function readRawBytes(RLPItem memory _in) internal pure returns (bytes memory) {
        return _copy(_in);
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * Decodes the length of an RLP item.
     * @param _in RLP item to decode.
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
        require(_in.length > 0, "RLP item cannot be null.");

        uint256 ptr = _in.ptr;
        uint256 prefix;
        assembly {
            prefix := byte(0, mload(ptr))
        }

        if (prefix <= 0x7f) {
            // Single byte.

            return (0, 1, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xb7) {
            // Short string.

            // slither-disable-next-line variable-scope
            uint256 strLen = prefix - 0x80;

            require(_in.length > strLen, "Invalid RLP short string.");

            return (1, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xbf) {
            // Long string.
            uint256 lenOfStrLen = prefix - 0xb7;

            require(_in.length > lenOfStrLen, "Invalid RLP long string length.");

            uint256 strLen;
            assembly {
                // Pick out the string length.
                strLen := div(mload(add(ptr, 1)), exp(256, sub(32, lenOfStrLen)))
            }

            require(_in.length > lenOfStrLen + strLen, "Invalid RLP long string.");

            return (1 + lenOfStrLen, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xf7) {
            // Short list.
            // slither-disable-next-line variable-scope
            uint256 listLen = prefix - 0xc0;

            require(_in.length > listLen, "Invalid RLP short list.");

            return (1, listLen, RLPItemType.LIST_ITEM);
        } else {
            // Long list.
            uint256 lenOfListLen = prefix - 0xf7;

            require(_in.length > lenOfListLen, "Invalid RLP long list length.");

            uint256 listLen;
            assembly {
                // Pick out the list length.
                listLen := div(mload(add(ptr, 1)), exp(256, sub(32, lenOfListLen)))
            }

            require(_in.length > lenOfListLen + listLen, "Invalid RLP long list.");

            return (1 + lenOfListLen, listLen, RLPItemType.LIST_ITEM);
        }
    }

    /**
     * Copies the bytes from a memory location.
     * @param _src Pointer to the location to read from.
     * @param _offset Offset to start reading from.
     * @param _length Number of bytes to read.
     * @return Copied bytes.
     */
    function _copy(
        uint256 _src,
        uint256 _offset,
        uint256 _length
    ) private pure returns (bytes memory) {
        bytes memory out = new bytes(_length);
        if (out.length == 0) {
            return out;
        }

        uint256 src = _src + _offset;
        uint256 dest;
        assembly {
            dest := add(out, 32)
        }

        // Copy over as many complete words as we can.
        for (uint256 i = 0; i < _length / 32; i++) {
            assembly {
                mstore(dest, mload(src))
            }

            src += 32;
            dest += 32;
        }

        // Pick out the remaining bytes.
        uint256 mask = 256**(32 - (_length % 32)) - 1;

        assembly {
            mstore(dest, or(and(mload(src), not(mask)), and(mload(dest), mask)))
        }
        return out;
    }

    /**
     * Copies an RLP item into bytes.
     * @param _in RLP item to copy.
     * @return Copied bytes.
     */
    function _copy(RLPItem memory _in) private pure returns (bytes memory) {
        return _copy(_in.ptr, 0, _in.length);
    }
}

////// src/spec/State.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.7.6; */

/* import "../utils/rlp/RLPDecode.sol"; */

library State {
    using RLPDecode for RLPDecode.RLPItem;

    struct EVMAccount {
        uint256 nonce;
        uint256 balance;
        bytes32 storage_root;
        bytes32 code_hash;
    }

    function toEVMAccount(bytes memory data) internal pure returns (EVMAccount memory) {
        RLPDecode.RLPItem[] memory account = RLPDecode.readList(data);

        return
            EVMAccount({
                nonce: account[0].readUint256(),
                balance: account[1].readUint256(),
                storage_root: account[2].readBytes32(),
                code_hash: account[3].readBytes32()
            });
    }
}

////// src/utils/BytesUtils.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.7.6; */

/**
 * @title BytesUtils
 */
library BytesUtils {
    /**********************
     * Internal Functions *
     **********************/

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function slice(bytes memory _bytes, uint256 _start) internal pure returns (bytes memory) {
        if (_start >= _bytes.length) {
            return bytes("");
        }

        return slice(_bytes, _start, _bytes.length - _start);
    }

    function toBytes32(bytes memory _bytes) internal pure returns (bytes32) {
        if (_bytes.length < 32) {
            bytes32 ret;
            assembly {
                ret := mload(add(_bytes, 32))
            }
            return ret;
        }

        return abi.decode(_bytes, (bytes32)); // will truncate if input length > 32 bytes
    }

    function toUint256(bytes memory _bytes) internal pure returns (uint256) {
        return uint256(toBytes32(_bytes));
    }

    function toNibbles(bytes memory _bytes) internal pure returns (bytes memory) {
        bytes memory nibbles = new bytes(_bytes.length * 2);

        for (uint256 i = 0; i < _bytes.length; i++) {
            nibbles[i * 2] = _bytes[i] >> 4;
            nibbles[i * 2 + 1] = bytes1(uint8(_bytes[i]) % 16);
        }

        return nibbles;
    }

    function fromNibbles(bytes memory _bytes) internal pure returns (bytes memory) {
        bytes memory ret = new bytes(_bytes.length / 2);

        for (uint256 i = 0; i < ret.length; i++) {
            ret[i] = (_bytes[i * 2] << 4) | (_bytes[i * 2 + 1]);
        }

        return ret;
    }

    function equal(bytes memory _bytes, bytes memory _other) internal pure returns (bool) {
        return keccak256(_bytes) == keccak256(_other);
    }
}

////// src/utils/trie/MerkleTrie.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.7.6; */

/* Library Imports */
/* import "../BytesUtils.sol"; */
/* import "../rlp/RLPDecode.sol"; */

/**
 * @title MerkleTrie
 */
library MerkleTrie {
    /*******************
     * Data Structures *
     *******************/

    enum NodeType {
        BranchNode,
        ExtensionNode,
        LeafNode
    }

    struct TrieNode {
        bytes encoded;
        RLPDecode.RLPItem[] decoded;
    }

    /**********************
     * Contract Constants *
     **********************/

    // TREE_RADIX determines the number of elements per branch node.
    uint256 constant TREE_RADIX = 16;
    // Branch nodes have TREE_RADIX elements plus an additional `value` slot.
    uint256 constant BRANCH_NODE_LENGTH = TREE_RADIX + 1;
    // Leaf nodes and extension nodes always have two elements, a `path` and a `value`.
    uint256 constant LEAF_OR_EXTENSION_NODE_LENGTH = 2;

    // Prefixes are prepended to the `path` within a leaf or extension node and
    // allow us to differentiate between the two node types. `ODD` or `EVEN` is
    // determined by the number of nibbles within the unprefixed `path`. If the
    // number of nibbles if even, we need to insert an extra padding nibble so
    // the resulting prefixed `path` has an even number of nibbles.
    uint8 constant PREFIX_EXTENSION_EVEN = 0;
    uint8 constant PREFIX_EXTENSION_ODD = 1;
    uint8 constant PREFIX_LEAF_EVEN = 2;
    uint8 constant PREFIX_LEAF_ODD = 3;

    // Just a utility constant. RLP represents `NULL` as 0x80.
    bytes1 constant RLP_NULL = bytes1(0x80);

    /**********************
     * Internal Functions *
     **********************/

    /**
     * @notice Verifies a proof that a given key/value pair is present in the
     * Merkle trie.
     * @param _key Key of the node to search for, as a hex string.
     * @param _value Value of the node to search for, as a hex string.
     * @param _proof Merkle trie inclusion proof for the desired node. Unlike
     * traditional Merkle trees, this proof is executed top-down and consists
     * of a list of RLP-encoded nodes that make a path down to the target node.
     * @param _root Known root of the Merkle trie. Used to verify that the
     * included proof is correctly constructed.
     * @return _verified `true` if the k/v pair exists in the trie, `false` otherwise.
     */
    function verifyInclusionProof(
        bytes memory _key,
        bytes memory _value,
        bytes memory _proof,
        bytes32 _root
    ) internal pure returns (bool _verified) {
        (bool exists, bytes memory value) = get(_key, _proof, _root);

        return (exists && BytesUtils.equal(_value, value));
    }

    /**
     * @notice Retrieves the value associated with a given key.
     * @param _key Key to search for, as hex bytes.
     * @param _proof Merkle trie inclusion proof for the key.
     * @param _root Known root of the Merkle trie.
     * @return _exists Whether or not the key exists.
     * @return _value Value of the key if it exists.
     */
    function get(
        bytes memory _key,
        bytes memory _proof,
        bytes32 _root
    ) internal pure returns (bool _exists, bytes memory _value) {
        TrieNode[] memory proof = _parseProof(_proof);
        (uint256 pathLength, bytes memory keyRemainder, bool isFinalNode) = _walkNodePath(
            proof,
            _key,
            _root
        );

        bool exists = keyRemainder.length == 0;

        require(exists || isFinalNode, "Provided proof is invalid.");

        bytes memory value = exists ? _getNodeValue(proof[pathLength - 1]) : bytes("");

        return (exists, value);
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * @notice Walks through a proof using a provided key.
     * @param _proof Inclusion proof to walk through.
     * @param _key Key to use for the walk.
     * @param _root Known root of the trie.
     * @return _pathLength Length of the final path
     * @return _keyRemainder Portion of the key remaining after the walk.
     * @return _isFinalNode Whether or not we've hit a dead end.
     */
    function _walkNodePath(
        TrieNode[] memory _proof,
        bytes memory _key,
        bytes32 _root
    )
        private
        pure
        returns (
            uint256 _pathLength,
            bytes memory _keyRemainder,
            bool _isFinalNode
        )
    {
        uint256 pathLength = 0;
        bytes memory key = BytesUtils.toNibbles(_key);

        bytes32 currentNodeID = _root;
        uint256 currentKeyIndex = 0;
        uint256 currentKeyIncrement = 0;
        TrieNode memory currentNode;

        // Proof is top-down, so we start at the first element (root).
        for (uint256 i = 0; i < _proof.length; i++) {
            currentNode = _proof[i];
            currentKeyIndex += currentKeyIncrement;

            // Keep track of the proof elements we actually need.
            // It's expensive to resize arrays, so this simply reduces gas costs.
            pathLength += 1;

            if (currentKeyIndex == 0) {
                // First proof element is always the root node.
                require(keccak256(currentNode.encoded) == currentNodeID, "Invalid root hash");
            } else if (currentNode.encoded.length >= 32) {
                // Nodes 32 bytes or larger are hashed inside branch nodes.
                require(
                    keccak256(currentNode.encoded) == currentNodeID,
                    "Invalid large internal hash"
                );
            } else {
                // Nodes smaller than 31 bytes aren't hashed.
                require(
                    BytesUtils.toBytes32(currentNode.encoded) == currentNodeID,
                    "Invalid internal node hash"
                );
            }

            if (currentNode.decoded.length == BRANCH_NODE_LENGTH) {
                if (currentKeyIndex == key.length) {
                    // We've hit the end of the key
                    // meaning the value should be within this branch node.
                    break;
                } else {
                    // We're not at the end of the key yet.
                    // Figure out what the next node ID should be and continue.
                    uint8 branchKey = uint8(key[currentKeyIndex]);
                    RLPDecode.RLPItem memory nextNode = currentNode.decoded[branchKey];
                    currentNodeID = _getNodeID(nextNode);
                    currentKeyIncrement = 1;
                    continue;
                }
            } else if (currentNode.decoded.length == LEAF_OR_EXTENSION_NODE_LENGTH) {
                bytes memory path = _getNodePath(currentNode);
                uint8 prefix = uint8(path[0]);
                uint8 offset = 2 - (prefix % 2);
                bytes memory pathRemainder = BytesUtils.slice(path, offset);
                bytes memory keyRemainder = BytesUtils.slice(key, currentKeyIndex);
                uint256 sharedNibbleLength = _getSharedNibbleLength(pathRemainder, keyRemainder);

                if (prefix == PREFIX_LEAF_EVEN || prefix == PREFIX_LEAF_ODD) {
                    if (
                        pathRemainder.length == sharedNibbleLength &&
                        keyRemainder.length == sharedNibbleLength
                    ) {
                        // The key within this leaf matches our key exactly.
                        // Increment the key index to reflect that we have no remainder.
                        currentKeyIndex += sharedNibbleLength;
                    }

                    // We've hit a leaf node, so our next node should be NULL.
                    currentNodeID = bytes32(RLP_NULL);
                    break;
                } else if (prefix == PREFIX_EXTENSION_EVEN || prefix == PREFIX_EXTENSION_ODD) {
                    if (sharedNibbleLength != pathRemainder.length) {
                        // Our extension node is not identical to the remainder.
                        // We've hit the end of this path
                        // updates will need to modify this extension.
                        currentNodeID = bytes32(RLP_NULL);
                        break;
                    } else {
                        // Our extension shares some nibbles.
                        // Carry on to the next node.
                        currentNodeID = _getNodeID(currentNode.decoded[1]);
                        currentKeyIncrement = sharedNibbleLength;
                        continue;
                    }
                } else {
                    revert("Received a node with an unknown prefix");
                }
            } else {
                revert("Received an unparseable node.");
            }
        }

        // If our node ID is NULL, then we're at a dead end.
        bool isFinalNode = currentNodeID == bytes32(RLP_NULL);
        return (pathLength, BytesUtils.slice(key, currentKeyIndex), isFinalNode);
    }

    /**
     * @notice Parses an RLP-encoded proof into something more useful.
     * @param _proof RLP-encoded proof to parse.
     * @return _parsed Proof parsed into easily accessible structs.
     */
    function _parseProof(bytes memory _proof) private pure returns (TrieNode[] memory _parsed) {
        RLPDecode.RLPItem[] memory nodes = RLPDecode.readList(_proof);
        TrieNode[] memory proof = new TrieNode[](nodes.length);

        for (uint256 i = 0; i < nodes.length; i++) {
            bytes memory encoded = RLPDecode.readBytes(nodes[i]);
            proof[i] = TrieNode({ encoded: encoded, decoded: RLPDecode.readList(encoded) });
        }

        return proof;
    }

    /**
     * @notice Picks out the ID for a node. Node ID is referred to as the
     * "hash" within the specification, but nodes < 32 bytes are not actually
     * hashed.
     * @param _node Node to pull an ID for.
     * @return _nodeID ID for the node, depending on the size of its contents.
     */
    function _getNodeID(RLPDecode.RLPItem memory _node) private pure returns (bytes32 _nodeID) {
        bytes memory nodeID;

        if (_node.length < 32) {
            // Nodes smaller than 32 bytes are RLP encoded.
            nodeID = RLPDecode.readRawBytes(_node);
        } else {
            // Nodes 32 bytes or larger are hashed.
            nodeID = RLPDecode.readBytes(_node);
        }

        return BytesUtils.toBytes32(nodeID);
    }

    /**
     * @notice Gets the path for a leaf or extension node.
     * @param _node Node to get a path for.
     * @return _path Node path, converted to an array of nibbles.
     */
    function _getNodePath(TrieNode memory _node) private pure returns (bytes memory _path) {
        return BytesUtils.toNibbles(RLPDecode.readBytes(_node.decoded[0]));
    }

    /**
     * @notice Gets the path for a node.
     * @param _node Node to get a value for.
     * @return _value Node value, as hex bytes.
     */
    function _getNodeValue(TrieNode memory _node) private pure returns (bytes memory _value) {
        return RLPDecode.readBytes(_node.decoded[_node.decoded.length - 1]);
    }

    /**
     * @notice Utility; determines the number of nibbles shared between two
     * nibble arrays.
     * @param _a First nibble array.
     * @param _b Second nibble array.
     * @return _shared Number of shared nibbles.
     */
    function _getSharedNibbleLength(bytes memory _a, bytes memory _b)
        private
        pure
        returns (uint256 _shared)
    {
        uint256 i = 0;
        while (_a.length > i && _b.length > i && _a[i] == _b[i]) {
            i++;
        }
        return i;
    }
}

////// src/utils/trie/SecureMerkleTrie.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.7.6; */

/* Library Imports */
/* import "./MerkleTrie.sol"; */

/**
 * @title SecureMerkleTrie
 */
library SecureMerkleTrie {
    /**********************
     * Internal Functions *
     **********************/

    /**
     * @notice Verifies a proof that a given key/value pair is present in the
     * Merkle trie.
     * @param _key Key of the node to search for, as a hex string.
     * @param _value Value of the node to search for, as a hex string.
     * @param _proof Merkle trie inclusion proof for the desired node. Unlike
     * traditional Merkle trees, this proof is executed top-down and consists
     * of a list of RLP-encoded nodes that make a path down to the target node.
     * @param _root Known root of the Merkle trie. Used to verify that the
     * included proof is correctly constructed.
     * @return _verified `true` if the k/v pair exists in the trie, `false` otherwise.
     */
    function verifyInclusionProof(
        bytes memory _key,
        bytes memory _value,
        bytes memory _proof,
        bytes32 _root
    ) internal pure returns (bool _verified) {
        bytes memory key = _getSecureKey(_key);
        return MerkleTrie.verifyInclusionProof(key, _value, _proof, _root);
    }

    /**
     * @notice Retrieves the value associated with a given key.
     * @param _key Key to search for, as hex bytes.
     * @param _proof Merkle trie inclusion proof for the key.
     * @param _root Known root of the Merkle trie.
     * @return _exists Whether or not the key exists.
     * @return _value Value of the key if it exists.
     */
    function get(
        bytes memory _key,
        bytes memory _proof,
        bytes32 _root
    ) internal pure returns (bool _exists, bytes memory _value) {
        bytes memory key = _getSecureKey(_key);
        return MerkleTrie.get(key, _proof, _root);
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * Computes the secure counterpart to a key.
     * @param _key Key to get a secure key from.
     * @return _secureKey Secure version of the key.
     */
    function _getSecureKey(bytes memory _key) private pure returns (bytes memory _secureKey) {
        return abi.encodePacked(keccak256(_key));
    }
}

////// src/spec/StorageProof.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.7.6; */

/* import "./State.sol"; */
/* import "../utils/rlp/RLPDecode.sol"; */
/* import "../utils/trie/SecureMerkleTrie.sol"; */

library StorageProof {
    using State for bytes;
    using RLPDecode for bytes;
    using RLPDecode for RLPDecode.RLPItem;

    function verify_single_storage_proof(
        bytes32 root,
        address account,
        bytes memory account_proof,
        bytes32 storage_key,
        bytes memory storage_proof
    ) internal pure returns (bytes memory value) {
        bytes memory account_hash = abi.encodePacked(account);
        (bool exists, bytes memory data) = SecureMerkleTrie.get(
            account_hash,
            account_proof,
            root
        );
        require(exists == true, "!account_proof");
        State.EVMAccount memory acc = data.toEVMAccount();
        bytes memory storage_key_hash = abi.encodePacked(storage_key);
        (exists, value) = SecureMerkleTrie.get(
            storage_key_hash,
            storage_proof,
            acc.storage_root
        );
        if (exists) {
            value = value.toRLPItem().readBytes();
        }
    }

    function verify_multi_storage_proof(
        bytes32 root,
        address account,
        bytes memory account_proof,
        bytes32[] memory storage_keys,
        bytes[] memory storage_proofs
    ) internal pure returns (bytes[] memory values) {
        uint key_size = storage_keys.length;
        require(key_size == storage_proofs.length, "!storage_proof_len");
        values = new bytes[](key_size);
        for (uint i = 0; i < key_size; i++) {
            values[i] = verify_single_storage_proof(
                root,
                account,
                account_proof,
                storage_keys[i],
                storage_proofs[i]
            );
        }
    }
}

////// src/spec/TargetChain.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.7.6; */
/* pragma abicoder v2; */

contract TargetChain {
    /// Delivered messages with their dispatch result.
    struct DeliveredMessages {
        // Nonce of the first message that has been delivered (inclusive).
        uint64 begin;
        // Nonce of the last message that has been delivered (inclusive).
        uint64 end;
    }

    /// Unrewarded relayer entry stored in the inbound lane data.
    ///
    /// This struct represents a continuous range of messages that have been delivered by the same
    /// relayer and whose confirmations are still pending.
    struct UnrewardedRelayer {
        // Address of the relayer.
        address relayer;
        // Messages range, delivered by this relayer.
        DeliveredMessages messages;
    }

    /// Inbound lane data
    struct InboundLaneData {
        // Identifiers of relayers and messages that they have delivered to this lane (ordered by
        // message nonce).
        //
        // This serves as a helper storage item, to allow the source chain to easily pay rewards
        // to the relayers who successfully delivered messages to the target chain (inbound lane).
        //
        // All nonces in this queue are in
        // range: `(self.last_confirmed_nonce; self.last_delivered_nonce()]`.
        //
        // When a relayer sends a single message, both of begin and end nonce are the same.
        // When relayer sends messages in a batch, the first arg is the lowest nonce, second arg the
        // highest nonce. Multiple dispatches from the same relayer are allowed.
        UnrewardedRelayer[] relayers;
        // Nonce of the last message that
        // a) has been delivered to the target (this) chain and
        // b) the delivery has been confirmed on the source chain
        //
        // that the target chain knows of.
        //
        // This value is updated indirectly when an `OutboundLane` state of the source
        // chain is received alongside with new messages delivery.
        uint64 last_confirmed_nonce;
        // Nonce of the latest received or has been delivered message to this inbound lane.
        uint64 last_delivered_nonce;
    }

    /// @dev Hash of the InboundLaneData Schema
    /// keccak256(abi.encodePacked(
    ///     "InboundLaneData(UnrewardedRelayer[] relayers,uint64 last_confirmed_nonce,uint64 last_delivered_nonce)",
    ///     "UnrewardedRelayer(address relayer,DeliveredMessages messages)",
    ///     "DeliveredMessages(uint64 begin,uint64 end)"
    ///     )
    /// )
    bytes32 internal constant INBOUNDLANEDATA_TYPEHASH = 0xcf4a39e72acc9d64da0fc507104c55de6ee7e6e1a477d8700014bcb981f85106;

    /// @dev Hash of the UnrewardedRelayer Schema
    /// keccak256(abi.encodePacked(
    ///     "UnrewardedRelayer(address relayer,DeliveredMessages messages)",
    ///     "DeliveredMessages(uint64 begin,uint64 end)"
    ///     )
    /// )
    bytes32 internal constant UNREWARDEDRELAYER_TYPETASH = 0x6d8ba9a028be62615788b0b9200c2e575678c124d2db04ca91582405eba190a1;

    /// @dev Hash of the DeliveredMessages Schema
    /// keccak256(abi.encodePacked(
    ///     "DeliveredMessages(uint64 begin,uint64 end)"
    ///     )
    /// )
    bytes32 internal constant DELIVEREDMESSAGES_TYPETASH = 0x1984c1907b379883ef1736e0351d28f5b4b82026a854e28971d89eb48f32fbe2;

    function hash(InboundLaneData memory inboundLaneData)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                INBOUNDLANEDATA_TYPEHASH,
                hash(inboundLaneData.relayers),
                inboundLaneData.last_confirmed_nonce,
                inboundLaneData.last_delivered_nonce
            )
        );
    }

    function hash(UnrewardedRelayer[] memory relayers)
        internal
        pure
        returns (bytes32)
    {
        uint relayersLength = relayers.length;
        bytes memory encoded = abi.encode(relayersLength);
        for (uint256 i = 0; i < relayersLength; i++) {
            UnrewardedRelayer memory r = relayers[i];
            encoded = abi.encodePacked(
                encoded,
                abi.encode(
                    UNREWARDEDRELAYER_TYPETASH,
                    r.relayer,
                    hash(r.messages)
                )
            );
        }
        return keccak256(encoded);
    }

    function hash(DeliveredMessages memory messages)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                DELIVEREDMESSAGES_TYPETASH,
                messages.begin,
                messages.end
            )
        );
    }
}

////// src/truth/common/StorageVerifier.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.7.6; */
/* pragma abicoder v2; */

/* import "../../interfaces/IVerifier.sol"; */
/* import "../../spec/SourceChain.sol"; */
/* import "../../spec/TargetChain.sol"; */
/* import "../../spec/StorageProof.sol"; */

abstract contract StorageVerifier is IVerifier, SourceChain, TargetChain {
    event Registry(uint256 bridgedChainPosition, uint256 lanePosition, address lane);

    struct ReceiveProof {
        bytes accountProof;
        bytes laneIDProof;
        bytes laneNonceProof;
        bytes[] laneMessagesProof;
    }

    struct DeliveryProof {
        bytes accountProof;
        bytes laneNonceProof;
        bytes[] laneRelayersProof;
    }

    uint256 public immutable THIS_CHAIN_POSITION;
    uint256 public immutable LANE_IDENTIFY_SLOT;
    uint256 public immutable LANE_NONCE_SLOT;
    uint256 public immutable LANE_MESSAGE_SLOT;

    // bridgedChainPosition => lanePosition => lanes
    mapping(uint32 => mapping(uint32 => address)) public lanes;
    address public setter;

    modifier onlySetter {
        require(msg.sender == setter, "forbidden");
        _;
    }

    function changeSetter(address _setter) external onlySetter {
        setter = _setter;
    }

    constructor(
        uint32 this_chain_position,
        uint256 lane_identify_slot,
        uint256 lane_nonce_slot,
        uint256 lane_message_slot
    ) {
        THIS_CHAIN_POSITION = this_chain_position;
        LANE_IDENTIFY_SLOT = lane_identify_slot;
        LANE_NONCE_SLOT = lane_nonce_slot;
        LANE_MESSAGE_SLOT = lane_message_slot;
        setter = msg.sender;
    }

    function registry(uint32 bridgedChainPosition, uint32 outboundPosition, address outbound, uint32 inboundPositon, address inbound) external onlySetter {
        require(bridgedChainPosition != THIS_CHAIN_POSITION, "invalid_chain_pos");
        lanes[bridgedChainPosition][outboundPosition] = outbound;
        lanes[bridgedChainPosition][inboundPositon] = inbound;
        emit Registry(bridgedChainPosition, outboundPosition, outbound);
        emit Registry(bridgedChainPosition, inboundPositon, inbound);
    }

    function state_root() public view virtual returns (bytes32);

    function verify_messages_proof(
        bytes32 outlane_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external view override returns (bool) {
        address lane = lanes[chain_pos][lane_pos];
        require(lane != address(0), "!outlane");
        ReceiveProof memory proof = abi.decode(encoded_proof, (ReceiveProof));

        // extract identify storage value from proof
        uint identify_storage = toUint(StorageProof.verify_single_storage_proof(
            state_root(),
            lane,
            proof.accountProof,
            bytes32(LANE_IDENTIFY_SLOT),
            proof.laneIDProof
        ));

        // extract nonce storage value from proof
        uint nonce_storage = toUint(StorageProof.verify_single_storage_proof(
            state_root(),
            lane,
            proof.accountProof,
            bytes32(LANE_NONCE_SLOT),
            proof.laneNonceProof
        ));

        OutboundLaneDataStorage memory lane_data = build_outlane(identify_storage, nonce_storage, lane, proof);
        // check the lane_data_hash
        return outlane_hash == hash(lane_data);
    }

    function build_outlane(uint identify_storage, uint nonce_storage, address lane, ReceiveProof memory proof) internal view returns (OutboundLaneDataStorage memory lane_data) {
        // restruct the outlane data
        uint64 latest_received_nonce = uint64(nonce_storage);
        uint64 size = uint64(nonce_storage >> 64) - latest_received_nonce;
        if (size > 0) {
            // find all messages storage keys
            bytes32[] memory storage_keys = build_message_keys(latest_received_nonce, size);

            // extract messages storage value from proof
            bytes[] memory values = StorageProof.verify_multi_storage_proof(
                state_root(),
                lane,
                proof.accountProof,
                storage_keys,
                proof.laneMessagesProof
            );

            require(size == values.length, "!values_len");
            MessageStorage[] memory messages = new MessageStorage[](size);
            for (uint64 i=0; i < size; i++) {
               bytes32 payload = toBytes32(values[i]);
               uint256 key = (identify_storage << 64) + latest_received_nonce + 1 + i;
               messages[i] = MessageStorage(key, payload);
            }
            lane_data.messages = messages;
        }
        lane_data.latest_received_nonce = latest_received_nonce;
    }

    function build_message_keys(uint64 latest_received_nonce, uint64 size) internal view returns (bytes32[] memory) {
        bytes32[] memory storage_keys = new bytes32[](size);
        uint64 begin = latest_received_nonce + 1;
        for (uint64 index=0; index < size;) {
            storage_keys[index++] = bytes32(mapLocation(LANE_MESSAGE_SLOT, begin + index));
        }
        return storage_keys;
    }

    function verify_messages_delivery_proof(
        bytes32 inlane_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external view override returns (bool) {
        address lane = lanes[chain_pos][lane_pos];
        require(lane != address(0), "!inlane");
        DeliveryProof memory proof = abi.decode(encoded_proof, (DeliveryProof));

        // extract nonce storage value from proof
        uint nonce_storage = toUint(StorageProof.verify_single_storage_proof(
            state_root(),
            lane,
            proof.accountProof,
            bytes32(LANE_NONCE_SLOT),
            proof.laneNonceProof
        ));

        uint64 last_confirmed_nonce = uint64(nonce_storage);
        uint64 last_delivered_nonce = uint64(nonce_storage >> 64);
        uint64 front = uint64(nonce_storage >> 128);
        uint64 back = uint64(nonce_storage >> 192);
        uint64 size = back >= front ? back - front + 1 : 0;
        // restruct the in lane data
        InboundLaneData memory lane_data = build_inlane(size, front, last_confirmed_nonce, last_delivered_nonce, lane, proof);
        // check the lane_data_hash
        return inlane_hash == hash(lane_data);
    }

    function build_inlane(
        uint64 size,
        uint64 front,
        uint64 last_confirmed_nonce,
        uint64 last_delivered_nonce,
        address lane,
        DeliveryProof memory proof
    ) internal view returns (InboundLaneData memory lane_data) {
        // restruct the in lane data
        if (size > 0) {
            uint64 len = 2 * size;
            // find all messages storage keys
            bytes32[] memory storage_keys = new bytes32[](len);
            for (uint64 index=0; index < len;) {
                uint256 relayersLocation = mapLocation(LANE_MESSAGE_SLOT, front + index/2);
                storage_keys[index++] = bytes32(relayersLocation);
                storage_keys[index++] = bytes32(relayersLocation + 1);
            }

            // extract messages storage value from proof
            bytes[] memory values = StorageProof.verify_multi_storage_proof(
                state_root(),
                lane,
                proof.accountProof,
                storage_keys,
                proof.laneRelayersProof
            );

            require(len == values.length, "!values_len");
            UnrewardedRelayer[] memory unrewarded_relayers = new UnrewardedRelayer[](size);
            for (uint64 i=0; i < size; i++) {
               uint slot2 = toUint(values[2*i+1]);
               unrewarded_relayers[i] = UnrewardedRelayer(
                   address(uint160(toUint(values[2*i]))),
                   DeliveredMessages(
                       uint64(slot2),
                       uint64(slot2 >> 64)
                   )
               );
            }
            lane_data.relayers = unrewarded_relayers;
        }
        lane_data.last_confirmed_nonce = last_confirmed_nonce;
        lane_data.last_delivered_nonce = last_delivered_nonce;
    }

    function toUint(bytes memory bts) internal pure returns (uint data) {
        uint len = bts.length;
        if (len == 0) {
            return 0;
        }
        require(len <= 32, "!len");
        assembly {
            data := div(mload(add(bts, 32)), exp(256, sub(32, len)))
        }
    }

    function toBytes32(bytes memory bts) internal pure returns (bytes32 data) {
        return bytes32(toUint(bts));
    }

    function mapLocation(uint256 slot, uint256 key) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(key, slot)));
    }
}

////// src/truth/bsc/BSCStorageVerifier.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.7.6; */
/* pragma abicoder v2; */

/* import "../common/StorageVerifier.sol"; */
/* import "../../spec/ChainMessagePosition.sol"; */
/* import "../../interfaces/ILightClient.sol"; */

contract BSCStorageVerifier is StorageVerifier {
    ILightClient public immutable LIGHT_CLIENT;

    constructor(address lightclient) StorageVerifier(uint32(ChainMessagePosition.BSC), 0, 1, 2) {
        LIGHT_CLIENT = ILightClient(lightclient);
    }

    function state_root() public view override returns (bytes32) {
        return LIGHT_CLIENT.merkle_root();
    }
}

