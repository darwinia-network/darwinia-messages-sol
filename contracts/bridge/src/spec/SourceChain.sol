// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

contract SourceChain {
    /**
     * The MessagePayload is the structure of RPC which should be delivery to target chain
     * @param sourceAccount The source contract address which send the message
     * @param targetContract The targe contract address which receive the message
     * @param encoded The calldata hash which encoded by ABI Encoding
     */
    struct MessagePayload {
        address sourceAccount;
        address targetContract;
        bytes32 encodedHash; /*keccak256(abi.encodePacked(SELECTOR, PARAMS))*/
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

    // Message as it is stored in the storage.
    struct Message {
        // Encoded message key.
        uint256 encoded_key;
        // Message data.
        MessagePayload data;
    }

    // Outbound lane data.
    struct OutboundLaneData {
        // Nonce of the latest message, received by bridged chain.
        uint64 latest_received_nonce;
        // Messages sent through this lane.
        Message[] messages;
    }

    //
    // Hash of the OutboundLaneData Schema
    // keccak256(abi.encodePacked(
    //     "OutboundLaneData(uint256 latest_received_nonce,bytes32 messages)"
    //     ")"
    // )
    //
    bytes32 internal constant OUTBOUNDLANEDATA_TYPEHASH = 0x82446a31771d975201a71d0d87c46edcb4996361ca06e16208c5a001081dee55;


    //
    // Hash of the Message Schema
    // keccak256(abi.encodePacked(
    //     "Message(uint256 encoded_key,MessagePayload data)",
    //     "MessagePayload(address sourceAccount,address targetContract,bytes32 encodedHash)"
    //     ")"
    // )
    //
    bytes32 internal constant MESSAGE_TYPEHASH = 0xca848e08f0288bb043640602cbacf8a9ac0a76c6dfe33cb660daa49c55f1d537;

    //
    // Hash of the MessageKey Schema
    // keccak256(abi.encodePacked(
    //     "MessageKey(uint32 this_chain_id,uint32 this_lane_id,uint32 bridged_chain_id,uint32 bridged_lane_id,uint64 nonce)"
    //     ")"
    // )
    //
    bytes32 internal constant MESSAGEKEY_TYPEHASH = 0x585f05d88bd03c64597258f8336daadecf668cb7b708cb320742d432114d13ac;

    //
    // Hash of the MessagePayload Schema
    // keccak256(abi.encodePacked(
    //     "MessagePayload(address sourceAccount,address targetContract,bytes32 encodedHash)"
    //     ")"
    // )
    //
    bytes32 internal constant MESSAGEPAYLOAD_TYPEHASH = 0x870c0499a698e69972afc2f00023f601b894f5731a45364e4d3ed7fd7304d9c7;

    function hash(OutboundLaneData memory landData)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                OUTBOUNDLANEDATA_TYPEHASH,
                landData.latest_received_nonce,
                hash(landData.messages)
            )
        );
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
                payload.encodedHash
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
