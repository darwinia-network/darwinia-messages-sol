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

/// @title SourceChain
/// @notice Source chain specification
contract SourceChain {
    /// @notice The MessagePayload is the structure of RPC which should be delivery to target chain
    /// @param source The source contract address which send the message
    /// @param target The targe contract address which receive the message
    /// @param encoded The calldata which encoded by ABI Encoding
    struct MessagePayload {
        address source;
        address target;
        bytes encoded; /*(abi.encodePacked(SELECTOR, PARAMS))*/
    }

    /// @notice Message key (unique message identifier) as it is stored in the storage.
    /// @param this_chain_pos This chain position
    /// @param this_lane_pos Position of the message this lane.
    /// @param bridged_chain_pos Bridged chain position
    /// @param bridged_lane_pos Position of the message bridged lane.
    /// @param nonce Nonce of the message.
    struct MessageKey {
        uint32 this_chain_pos;
        uint32 this_lane_pos;
        uint32 bridged_chain_pos;
        uint32 bridged_lane_pos;
        uint64 nonce;
    }

    /// @notice Message storage representation
    /// @param encoded_key Encoded message key
    /// @param payload_hash Hash of payload
    struct MessageStorage {
        uint256 encoded_key;
        bytes32 payload_hash;
    }

    /// @notice Message as it is stored in the storage.
    /// @param encoded_key Encoded message key.
    /// @param payload Message payload.
    struct Message {
        uint256 encoded_key;
        MessagePayload payload;
    }

    /// @notice Outbound lane data.
    /// @param latest_received_nonce Nonce of the latest message, received by bridged chain.
    /// @param messages Messages sent through this lane.
    struct OutboundLaneData {
        uint64 latest_received_nonce;
        Message[] messages;
    }

    /// @notice Outbound lane data storage representation
    /// @param latest_received_nonce Nonce of the latest message, received by bridged chain.
    /// @param messages Messages storage representation
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

    /// @notice Hash of OutboundLaneData
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

    /// @notice Hash of OutboundLaneDataStorage
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

    /// @notice Hash of MessageStorage
    function hash(MessageStorage[] memory msgs)
        internal
        pure
        returns (bytes32)
    {
        uint msgsLength = msgs.length;
        bytes memory encoded = abi.encode(msgsLength);
        for (uint256 i = 0; i < msgsLength; ) {
            MessageStorage memory message = msgs[i];
            encoded = abi.encodePacked(
                encoded,
                abi.encode(
                    MESSAGE_TYPEHASH,
                    message.encoded_key,
                    message.payload_hash
                )
            );
            unchecked { ++i; }
        }
        return keccak256(encoded);
    }

    /// @notice Hash of Message[]
    function hash(Message[] memory msgs)
        internal
        pure
        returns (bytes32)
    {
        uint msgsLength = msgs.length;
        bytes memory encoded = abi.encode(msgsLength);
        for (uint256 i = 0; i < msgsLength; ) {
            Message memory message = msgs[i];
            encoded = abi.encodePacked(
                encoded,
                abi.encode(
                    MESSAGE_TYPEHASH,
                    message.encoded_key,
                    hash(message.payload)
                )
            );
            unchecked { ++i; }
        }
        return keccak256(encoded);
    }

    /// @notice Hash of Message
    function hash(Message memory message)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                MESSAGE_TYPEHASH,
                message.encoded_key,
                hash(message.payload)
            )
        );
    }

    /// @notice Hash of MessagePayload
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

    /// @notice Decode message key
    /// @param encoded Encoded message key
    /// @return key Decoded message key
    function decodeMessageKey(uint256 encoded) internal pure returns (MessageKey memory key) {
        key.this_chain_pos = uint32(encoded >> 160);
        key.this_lane_pos = uint32(encoded >> 128);
        key.bridged_chain_pos = uint32(encoded >> 96);
        key.bridged_lane_pos = uint32(encoded >> 64);
        key.nonce = uint64(encoded);
    }
}
