// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

contract SourceChain {
    /**
     * The MessagePayload is the structure of RPC which should be delivery to target chain
     * @param sourceAccount The source contract address which send the message
     * @param targetContract The targe contract address which receive the message
     * @param encoded The calldata which encoded by ABI Encoding
     */
    struct MessagePayload {
        address sourceAccount;
        address targetContract;
        bytes encoded; /*abi.encodePacked(SELECTOR, PARAMS)*/
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
        /// Nonce of the message.
        uint64 nonce;
    }

    // Message data as it is stored in the storage.
    struct MessageData {
        // Message payload.
        MessagePayload payload;
        // Message delivery and dispatch fee, paid by the submitter.
        uint256 fee;
    }

    // Message as it is stored in the storage.
    struct Message {
        // Encoded message key.
        uint256 encoded_key;
        // Message data.
        MessageData data;
    }

    // Outbound lane data.
    struct OutboundLaneData {
        // Nonce of the latest message, received by bridged chain.
        uint64 latest_received_nonce;
        // Messages sent through this lane.
        Message[] messages;
    }

    /**
     * Hash of the OutboundLaneData Schema
     * keccak256(abi.encodePacked(
     *     "OutboundLaneData(uint256 latest_received_nonce,bytes32 messages)"
     *     ")"
     * )
     */
    bytes32 internal constant OUTBOUNDLANEDATA_TYPEHASH = 0x82446a31771d975201a71d0d87c46edcb4996361ca06e16208c5a001081dee55;


    /**
     * Hash of the Message Schema
     * keccak256(abi.encodePacked(
     *     "Message(uint256 encoded_key,MessageData data)",
     *     "MessageData(MessagePayload payload,uint256 fee)",
     *     "MessagePayload(address sourceAccount,address targetContract,bytes encoded)"
     *     ")"
     * )
     */
    bytes32 internal constant MESSAGE_TYPEHASH = 0xd71e134eb63429389e340ef0242aedc243cd42c6b9f91f4c3fd39c9bab2a9beb;

    /**
     * Hash of the MessageKey Schema
     * keccak256(abi.encodePacked(
     *     "MessageKey(uint32 this_chain_id,uint32 this_lane_id,uint32 bridged_chain_id,uint32 bridged_lane_id,uint64 nonce)"
     *     ")"
     * )
     */
    bytes32 internal constant MESSAGEKEY_TYPEHASH = 0x585f05d88bd03c64597258f8336daadecf668cb7b708cb320742d432114d13ac;

    /**
     * Hash of the MessageData Schema
     * keccak256(abi.encodePacked(
     *     "MessageData(MessagePayload payload,uint256 fee)",
     *     "MessagePayload(address sourceAccount,address targetContract,bytes encoded)"
     *     ")"
     * )
     */
    bytes32 internal constant MESSAGEDATA_TYPEHASH = 0x6158c19ce509d2b577b8dc4529dc0519fdf45619f983f5a0e6e51136b0f1d363;

    /**
     * Hash of the MessagePayload Schema
     * keccak256(abi.encodePacked(
     *     "MessagePayload(address sourceAccount,address targetContract,bytes encoded)"
     *     ")"
     * )
     */
    bytes32 internal constant MESSAGEPAYLOAD_TYPEHASH = 0x42e909341e89300b2354a544bf88d3a550ead1215f32330f71c0fb0462933569;

    function hash(OutboundLaneData memory subLandData)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                OUTBOUNDLANEDATA_TYPEHASH,
                subLandData.latest_received_nonce,
                hash(subLandData.messages)
            )
        );
    }

    function hash(Message[] memory msgs)
        internal
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(msgs.length);
        for (uint256 i = 0; i < msgs.length; i ++) {
            Message memory message = msgs[i];
            encoded = abi.encodePacked(
                encoded,
                abi.encode(
                    MESSAGE_TYPEHASH,
                    message.encoded_key,
                    hash(message.data)
                )
            );
        }
        return keccak256(encoded);
    }

    function hash(MessageKey memory key)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                MESSAGEKEY_TYPEHASH,
                key.this_chain_id,
                key.this_lane_id,
                key.bridged_chain_id,
                key.bridged_lane_id,
                key.nonce
            )
        );
    }

    function hash(MessageData memory data)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                MESSAGEDATA_TYPEHASH,
                hash(data.payload),
                data.fee
            )
        );
    }

    function hash(MessagePayload memory payload)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                MESSAGEPAYLOAD_TYPEHASH,
                payload.sourceAccount,
                payload.targetContract,
                payload.encoded
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
