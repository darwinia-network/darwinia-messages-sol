// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

contract TargetChain {
    // Delivered messages with their dispatch result.
    struct DeliveredMessages {
        // Nonce of the first message that has been delivered (inclusive).
        uint64 begin;
        // Nonce of the last message that has been delivered (inclusive).
        uint64 end;
        // Dispatch result (`false`/`true`), returned by the message dispatcher for every
        // message in the `[end; begin]` range.
        // The `MAX_UNCONFIRMED_MESSAGES` parameter must lesser than 256 for gas saving
        uint256 dispatch_results;
    }

    // Unrewarded relayer entry stored in the inbound lane data.
    //
    // This struct represents a continuous range of messages that have been delivered by the same
    // relayer and whose confirmations are still pending.
    struct UnrewardedRelayer {
        // Address of the relayer.
        address relayer;
        // Messages range, delivered by this relayer.
        DeliveredMessages messages;
    }

    // Inbound lane data
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

    /**
     * Hash of the InboundLaneData Schema
     * keccak256(abi.encodePacked(
     *     "InboundLaneData(UnrewardedRelayer[] relayers,uint64 last_confirmed_nonce,uint64 last_delivered_nonce)",
     *     "UnrewardedRelayer(address relayer,DeliveredMessages messages)",
     *     "DeliveredMessages(uint64 begin,uint64 end,uint256 dispatch_results)"
     *     ")"
     * )
     */
    bytes32 internal constant INBOUNDLANEDATA_TYPEHASH = 0x921cbc4091014b23df7eb9bbd83d71accebac7afad7c1344d8b581e63b929a86;

    /**
     * Hash of the UnrewardedRelayer Schema
     * keccak256(abi.encodePacked(
     *     "UnrewardedRelayer(address relayer,DeliveredMessages messages)"
     *     ")"
     * )
     */
    bytes32 internal constant UNREWARDEDRELAYER_TYPETASH = 0x5a4aa0af73c7f5d93a664d3d678d10103a266e77779c6809ea90b94851216106;

    /**
     * Hash of the DeliveredMessages Schema
     * keccak256(abi.encodePacked(
     *     "DeliveredMessages(uint64 begin,uint64 end,uint256 dispatch_results)"
     *     ")"
     * )
     */
    bytes32 internal constant DELIVEREDMESSAGES_TYPETASH = 0xaa6637cd9a4d6b5008a62cb1bef3d0ade9f8d8284cc2d4bf4eb1e15260726513;

    function hash(InboundLaneData memory inboundLaneData)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                INBOUNDLANEDATA_TYPEHASH,
                hash(inboundLaneData.relayers),
                inboundLaneData.last_confirmed_nonce
            )
        );
    }

    function hash(UnrewardedRelayer[] memory relayers)
        internal
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(relayers.length);
        for (uint256 i = 0; i < relayers.length; i ++) {
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
                messages.end,
                messages.dispatch_results
            )
        );
    }

}
