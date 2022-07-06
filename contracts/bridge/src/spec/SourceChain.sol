// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

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

    // Message key (unique message identifier) as it is stored in the storage.
    struct MessageKey {
        // This chain position
        uint32 this_chain_id;
        // Position of the message this lane.
        uint32 this_lane_id;
        // Bridged chain position
        uint32 bridged_chain_id;
        // Position of the message bridged lane.
        uint32 bridged_lane_id;
        // Nonce of the message.
        uint64 nonce;
    }

    struct MessageStorage {
        uint256 encoded_key;
        bytes32 payload_hash;
    }

    // Message as it is stored in the storage.
    struct Message {
        // Encoded message key.
        uint256 encoded_key;
        // Message payload.
        MessagePayload payload;
    }

    // Outbound lane data.
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

    // Hash of the OutboundLaneData Schema
    // keccak256(abi.encodePacked(
    //     "OutboundLaneData(uint256 latest_received_nonce,Message[] messages)",
    //     "Message(uint256 encoded_key,MessagePayload payload)",
    //     "MessagePayload(address source,address target,bytes32 encoded_hash)"
    //     )
    // )
    bytes32 internal constant OUTBOUNDLANEDATA_TYPEHASH = 0x823237038687bee0f021baf36aa1a00c49bd4d430512b28fed96643d7f4404c6;


    // Hash of the Message Schema
    // keccak256(abi.encodePacked(
    //     "Message(uint256 encoded_key,MessagePayload payload)",
    //     "MessagePayload(address source,address target,bytes32 encoded_hash)"
    //     )
    // )
    bytes32 internal constant MESSAGE_TYPEHASH = 0xfc686c8227203ee2031e2c031380f840b8cea19f967c05fc398fdeb004e7bf8b;

    // Hash of the MessagePayload Schema
    // keccak256(abi.encodePacked(
    //     "MessagePayload(address source,address target,bytes32 encoded_hash)"
    //     )
    // )
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

    function decodeMessageKey(uint256 encoded) public pure returns (MessageKey memory key) {
        key.this_chain_id = uint32(encoded >> 160);
        key.this_lane_id = uint32(encoded >> 128);
        key.bridged_chain_id = uint32(encoded >> 96);
        key.bridged_lane_id = uint32(encoded >> 64);
        key.nonce = uint64(encoded);
    }
}
