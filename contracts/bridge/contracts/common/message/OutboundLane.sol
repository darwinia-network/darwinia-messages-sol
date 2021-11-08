// SPDX-License-Identifier: MIT
// Message module that allows sending and receiving messages using lane concept:
//
// 1) the message is sent using `send_message()` call;
// 2) every outbound message is assigned nonce;
// 3) the messages are stored in the storage;
// 4) external component (relay) delivers messages to bridged chain;
// 5) messages are processed in order (ordered by assigned nonce);
// 6) relay may send proof-of-delivery back to this chain.
//
// Once message is sent, its progress can be tracked by looking at lane contract events.
// The assigned nonce is reported using `MessageAccepted` event. When message is
// delivered to the the bridged chain, it is reported using `MessagesDelivered` event.

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../../interfaces/IOutboundLane.sol";
import "./MessageVerifier.sol";
import "./TargetChain.sol";
import "./SourceChain.sol";

// Everything about outgoing messages sending.
contract OutboundLane is IOutboundLane, AccessControl, MessageVerifier, TargetChain, SourceChain {
    event MessageAccepted(uint256 bridgedChainPosition, uint256 lanePosition, uint256 nonce);
    event MessagesDelivered(uint256 bridgedChainPosition, uint256 lanePosition, uint256 begin, uint256 end, uint256 results);
    event MessagePruned(uint256 bridgedChainPosition, uint256 lanePosition, uint256 oldest_unpruned_nonce);
    event MessageFeeIncreased(uint256 bridgedChainPosition, uint256 lanePosition, uint256 nonce, uint256 fee);

    bytes32 internal constant OUTBOUND_ROLE = keccak256("OUTBOUND_ROLE");
    uint256 internal constant MAX_PENDING_MESSAGES = 50;
    uint256 internal constant MAX_PRUNE_MESSAGES_ATONCE = 10;

    // Outbound lane nonce.
    struct OutboundLaneNonce {
        // Nonce of the oldest message that we haven't yet pruned. May point to not-yet-generated
        // message if all sent messages are already pruned.
        uint256 oldest_unpruned_nonce;
        // Nonce of the latest message, received by bridged chain.
        uint256 latest_received_nonce;
        // Nonce of the latest message, generated by us.
        uint256 latest_generated_nonce;
    }

    /* State */

    OutboundLaneNonce public outboundLaneNonce;

    uint256 public confirmationFee = 0.1 ether; // how to set confirmation_fee

    // MessageKey => MessageData
    mapping(uint256 => MessageData) public messages;

    /**
     * @notice Deploys the OutboundLane contract
     * @param _lightClientBridge The contract address of on-chain light client
     * @param _thisChainPosition The thisChainPosition of outbound lane
     * @param _bridgedChainPosition The bridgedChainPosition of outbound lane
     * @param _lanePosition The lanePosition of outbound lane
     * @param _oldest_unpruned_nonce The oldest_unpruned_nonce of outbound lane
     * @param _latest_received_nonce The latest_received_nonce of outbound lane
     * @param _latest_generated_nonce The latest_generated_nonce of outbound lane
     */
    constructor(
        address _lightClientBridge,
        uint256 _thisChainPosition,
        uint256 _bridgedChainPosition,
        uint256 _lanePosition,
        uint256 _oldest_unpruned_nonce,
        uint256 _latest_received_nonce,
        uint256 _latest_generated_nonce
    ) public MessageVerifier(_lightClientBridge, _thisChainPosition, _bridgedChainPosition, _lanePosition) {
        outboundLaneNonce = OutboundLaneNonce(_oldest_unpruned_nonce, _latest_received_nonce, _latest_generated_nonce);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Send message over lane.
    function send_message(address targetContract, bytes calldata encoded) external payable override returns (uint256) {
        require(hasRole(OUTBOUND_ROLE, msg.sender), "Lane: NotAuthorized");
        require(outboundLaneNonce.latest_generated_nonce - outboundLaneNonce.latest_received_nonce <= MAX_PENDING_MESSAGES, "Lane: TooManyPendingMessages");
        require(outboundLaneNonce.latest_generated_nonce <= uint128(-1), "Lane: Overflow");
        uint256 nonce = outboundLaneNonce.latest_generated_nonce + 1;
        uint256 fee = msg.value;
        outboundLaneNonce.latest_generated_nonce = nonce;
        MessagePayload memory messagePayload = MessagePayload({
            sourceAccount: msg.sender,
            targetContract: targetContract,
            laneContract: address(this),
            encoded: encoded
        });
        uint256 key = encodeMessageKey(nonce);
        // finally, save messageData in outbound storage and emit `MessageAccepted` event
        messages[key] = MessageData({
            payload: messagePayload,
            fee: fee  // a lowest fee may be required and how to set it
        });
        // TODO:: callback `on_messages_accepted`

        // message sender prune at most `MAX_PRUNE_MESSAGES_ATONCE` messages
        prune_messages(MAX_PRUNE_MESSAGES_ATONCE);
        emit MessageAccepted(bridgedChainPosition, lanePosition, nonce);
        commit();
        return nonce;
    }

    function encodeMessageKey(uint256 nonce) public view returns (uint256 key) {
        key = (bridgedChainPosition << 192) + (lanePosition << 128) + nonce;
    }

    // Pay additional fee for the message.
    function increase_message_fee(uint256 nonce) external payable {
        require(nonce > outboundLaneNonce.latest_received_nonce, "Lane: MessageIsAlreadyDelivered");
        require(nonce <= outboundLaneNonce.latest_generated_nonce, "Lane: MessageIsNotYetSent");
        uint256 key = encodeMessageKey(nonce);
        messages[key].fee += msg.value;
        commit();
        emit MessageFeeIncreased(bridgedChainPosition, lanePosition, nonce, messages[key].fee);
    }

    // Receive messages delivery proof from bridged chain.
    function receive_messages_delivery_proof(
        bytes32 outboundLaneDataHash,
        InboundLaneData memory inboundLaneData,
        bytes memory messagesProof
    ) public {
        verify_messages_proof(outboundLaneDataHash, hash(inboundLaneData), messagesProof);
        DeliveredMessages memory confirmed_messages = confirm_delivery(inboundLaneData);
        // TODO: callback `on_messages_delivered`
        pay_relayers_rewards(inboundLaneData.relayers, confirmed_messages.begin, confirmed_messages.end);
        commit();
    }

    function message_size() public view returns (uint256 size) {
        size = outboundLaneNonce.latest_generated_nonce - outboundLaneNonce.latest_received_nonce;
    }

	/// Returns saved outbound message payload.
    function message(uint256 nonce) public view returns (MessageData memory) {
        return messages[encodeMessageKey(nonce)];
    }

	// Get lane data from the storage.
    function data() public view returns (OutboundLaneData memory lane_data) {
        uint256 size = message_size();
        lane_data.messages = new Message[](size);
        uint256 begin = outboundLaneNonce.latest_received_nonce + 1;
        for (uint256 index = 0; index < size; index++) {
            uint256 nonce = index + begin;
            uint256 key = encodeMessageKey(nonce);
            lane_data.messages[index] = Message(MessageKey(bridgedChainPosition, lanePosition, nonce), messages[key]);
        }
        lane_data.latest_received_nonce = outboundLaneNonce.latest_received_nonce;
    }

	/// commit lane data to the `commitment` storage.
    function commit() public returns (bytes32) {
        commitment = hash(data());
        return commitment;
    }

    /* Private Functions */

    function extract_substrate_inbound_lane_info(InboundLaneData memory lane_data) internal pure returns (uint256 total_unrewarded_messages, uint256 last_delivered_nonce) {
        uint256 len = lane_data.relayers.length;
        if(len > 0) {
            UnrewardedRelayer memory front = lane_data.relayers[0];
            UnrewardedRelayer memory back = lane_data.relayers[len-1];
            total_unrewarded_messages = back.messages.end - front.messages.begin + 1;
            last_delivered_nonce = back.messages.end;
        } else {
            total_unrewarded_messages = 0;
            last_delivered_nonce = lane_data.last_confirmed_nonce;
        }
    }

	// Confirm messages delivery.
    function confirm_delivery(InboundLaneData memory subInboundLaneData) internal returns (DeliveredMessages memory confirmed_messages) {
        (uint256 total_messages, uint256 latest_delivered_nonce) = extract_substrate_inbound_lane_info(subInboundLaneData);
        require(total_messages < 256, "Lane: InvalidNumberOfMessages");

        UnrewardedRelayer[] memory relayers = subInboundLaneData.relayers;
        OutboundLaneNonce memory nonce = outboundLaneNonce;
        require(latest_delivered_nonce > nonce.latest_received_nonce, "Lane: NoNewConfirmations");
        require(latest_delivered_nonce <= nonce.latest_generated_nonce, "Lane: FailedToConfirmFutureMessages");
        // that the relayer has declared correct number of messages that the proof contains (it
        // is checked outside of the function). But it may happen (but only if this/bridged
        // chain storage is corrupted, though) that the actual number of confirmed messages if
        // larger than declared.
        require(latest_delivered_nonce - nonce.latest_received_nonce <= total_messages, "Lane: TryingToConfirmMoreMessagesThanExpected");
        uint256 dispatch_results = extract_dispatch_results(nonce.latest_received_nonce, latest_delivered_nonce, relayers);
        uint256 prev_latest_received_nonce = nonce.latest_received_nonce;
        outboundLaneNonce.latest_received_nonce = latest_delivered_nonce;
        confirmed_messages = DeliveredMessages({
            begin: prev_latest_received_nonce + 1,
            end: latest_delivered_nonce,
            dispatch_results: dispatch_results
        });
        // emit 'MessagesDelivered' event
        emit MessagesDelivered(bridgedChainPosition, lanePosition, confirmed_messages.begin, confirmed_messages.end, confirmed_messages.dispatch_results);
    }

    // Extract new dispatch results from the unrewarded relayers vec.
    //
    // Revert if unrewarded relayers vec contains invalid data, meaning that the bridged
    // chain has invalid runtime storage.
    function extract_dispatch_results(uint256 prev_latest_received_nonce, uint256 latest_received_nonce, UnrewardedRelayer[] memory relayers) internal pure returns(uint256 received_dispatch_result) {
        // the only caller of this functions checks that the
        // prev_latest_received_nonce..=latest_received_nonce is valid, so we're ready to accept
        // messages in this range => with_capacity call must succeed here or we'll be unable to receive
        // confirmations at all
        uint256 last_entry_end = 0;
        uint256 padding = 0;
        for (uint256 i = 0; i < relayers.length; i++) {
            UnrewardedRelayer memory entry = relayers[i];
            // unrewarded relayer entry must have at least 1 unconfirmed message
            // (guaranteed by the `InboundLane::receive_message()`)
            require(entry.messages.end >= entry.messages.begin, "Lane: EmptyUnrewardedRelayerEntry");
            if (last_entry_end > 0) {
                uint256 expected_entry_begin = last_entry_end + 1;
                // every entry must confirm range of messages that follows previous entry range
                // (guaranteed by the `InboundLane::receive_message()`)
                require(entry.messages.begin == expected_entry_begin, "Lane: NonConsecutiveUnrewardedRelayerEntries");
            }
            last_entry_end = entry.messages.end;
            // entry can't confirm messages larger than `inbound_lane_data.latest_received_nonce()`
            // (guaranteed by the `InboundLane::receive_message()`)
			// technically this will be detected in the next loop iteration as
			// `InvalidNumberOfDispatchResults` but to guarantee safety of loop operations below
			// this is detected now
            require(entry.messages.end <= latest_received_nonce, "Lane: FailedToConfirmFutureMessages");
            // now we know that the entry is valid
            // => let's check if it brings new confirmations
            uint256 new_messages_begin = max(entry.messages.begin, prev_latest_received_nonce + 1);
            uint256 new_messages_end = min(entry.messages.end, latest_received_nonce);
            if (new_messages_end < new_messages_begin) {
                continue;
            }
            uint256 extend_begin = new_messages_begin - entry.messages.begin;
            uint256 messages_count_opp = 255 - (entry.messages.end - entry.messages.begin);
            // entry must have single dispatch result for every message
            // (guaranteed by the `InboundLane::receive_message()`)
            uint256 dispatch_results = entry.messages.dispatch_results << messages_count_opp >> messages_count_opp;
            // now we know that entry brings new confirmations
            // => let's extract dispatch results
            received_dispatch_result |= ((dispatch_results >> extend_begin) << padding);
            padding += (messages_count_opp - extend_begin);
        }
    }

	/// Prune at most `max_messages_to_prune` already received messages.
	///
	/// Returns number of pruned messages.
    function prune_messages(uint256 max_messages_to_prune) internal returns (uint256) {
        uint256 pruned_messages = 0;
        bool anything_changed = false;
        OutboundLaneNonce memory nonce = outboundLaneNonce;
        while (pruned_messages < max_messages_to_prune &&
            nonce.oldest_unpruned_nonce <= nonce.latest_received_nonce)
        {
            uint256 key = encodeMessageKey(nonce.oldest_unpruned_nonce);
            delete messages[key];
            anything_changed = true;
            pruned_messages += 1;
            nonce.oldest_unpruned_nonce += 1;
        }
        if (anything_changed) {
            outboundLaneNonce = nonce;
        }
        emit MessagePruned(bridgedChainPosition, lanePosition, outboundLaneNonce.oldest_unpruned_nonce);
        return pruned_messages;
    }

    /// Pay rewards to given relayers, optionally rewarding confirmation relayer.
    function pay_relayers_rewards(UnrewardedRelayer[] memory relayers, uint256 received_start, uint256 received_end) internal {
        address payable confirmation_relayer = msg.sender;
        uint256 confirmation_relayer_reward = 0;
        uint256 confirmation_fee = confirmationFee;
        // reward every relayer except `confirmation_relayer`
        for (uint256 i = 0; i < relayers.length; i++) {
            UnrewardedRelayer memory entry = relayers[i];
            address payable delivery_relayer = entry.relayer;
            uint256 nonce_begin = max(entry.messages.begin, received_start);
            uint256 nonce_end = min(entry.messages.end, received_end);
            uint256 delivery_reward = 0;
            uint256 confirmation_reward = 0;
            for (uint256 nonce = nonce_begin; nonce <= nonce_end; nonce++) {
                uint256 key = encodeMessageKey(nonce);
                delivery_reward += messages[key].fee;
                confirmation_reward += confirmation_fee;
            }
            if (confirmation_relayer != delivery_relayer) {
                // If delivery confirmation is submitted by other relayer, let's deduct confirmation fee
                // from relayer reward.
                //
                // If confirmation fee has been increased (or if it was the only component of message
                // fee), then messages relayer may receive zero reward.
                if (confirmation_reward > delivery_reward) {
                    confirmation_reward = delivery_reward;
                }
                delivery_reward = delivery_reward - confirmation_reward;
                confirmation_relayer_reward = confirmation_relayer_reward + confirmation_reward;
            } else {
                // If delivery confirmation is submitted by this relayer, let's add confirmation fee
                // from other relayers to this relayer reward.
                confirmation_relayer_reward = confirmation_relayer_reward + delivery_reward;
                continue;
            }
            pay_relayer_reward(delivery_relayer, delivery_reward);
        }
        // finally - pay reward to confirmation relayer
        pay_relayer_reward(confirmation_relayer, confirmation_relayer_reward);
    }

    function pay_relayer_reward(address payable to, uint256 value) internal {
        if (value > 0) {
            to.transfer(value);
        }
    }

    // --- Math ---
    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }

    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
}
