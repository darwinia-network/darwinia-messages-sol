// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

contract TargetChain {
    // Delivered messages with their dispatch result.
    struct DeliveredMessages {
        // Nonce of the first message that has been delivered (inclusive).
        uint256 begin;
        // Nonce of the last message that has been delivered (inclusive).
        uint256 end;
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
        address payable relayer;
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
        uint256 last_confirmed_nonce;
    }

    /**
     * Hash of the InboundLaneData Schema
     * keccak256(abi.encodePacked(
     *     "InboundLaneData(UnrewardedRelayer[] relayers,uint256 last_confirmed_nonce)",
     *     "UnrewardedRelayer(address relayer,DeliveredMessages messages)",
     *     "DeliveredMessages(uint256 begin,uint256 end,uint256 dispatch_results)"
     *     ")"
     * )
     */
    bytes32 internal constant INBOUNDLANEDATA_TYPETASH = 0xe0206b408dcea6820d150829d9cdbda81915a44d22dc7d582fbeaef4af0a7cc7;

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
     *     "DeliveredMessages(uint256 begin,uint256 end,uint256 dispatch_results)"
     *     ")"
     * )
     */
    bytes32 internal constant DELIVEREDMESSAGES_TYPETASH = 0x4fac2cc6d2c4efd6e36dc917cf7d5c24157fff4118169c91ea05772cfc06f24d;

    function hash(InboundLaneData memory inboundLaneData)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                INBOUNDLANEDATA_TYPETASH,
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
