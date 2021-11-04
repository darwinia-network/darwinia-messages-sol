// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IOutboundLane.sol";
import "./MessageCommitment.sol";
import "./TargetChain.sol";
import "./SourceChain.sol";

// OutboundLand is a basic lane that just sends messages with a nonce.
contract OutboundLane is IOutboundLane, AccessControl, MessageCommitment, TargetChain, SourceChain {
    event MessageAccepted(uint256 indexed lanePosition, uint256 indexed nonce, address sourceAccount, address targetContract, address laneContract, bytes encoded, uint256 fee);
    event MessagesDelivered(uint256 indexed lanePosition, uint256 begin, uint256 end, uint256 results);
    event MessagePruned(uint256 indexed lanePosition, uint256 indexed oldest_unpruned_nonce);
    event MessageFeeIncreased(uint256 indexed lanePosition, uint256 indexed nonce, uint256 fee);

    bytes32 internal constant OUTBOUND_ROLE = keccak256("OUTBOUND_ROLE");
    uint256 internal constant MAX_PENDING_MESSAGES = 50;
    uint256 internal constant MAX_PRUNE_MESSAGES_ATONCE = 10;

    struct OutboundLaneNonce {
        uint256 oldest_unpruned_nonce;
        uint256 latest_received_nonce;
        uint256 latest_generated_nonce;
    }

    /* State */

    OutboundLaneNonce public outboundLaneNonce;

    uint256 public confirmationFee = 0.1 ether; // how to set confirmation_fee

    // nonce => message
    mapping(uint256 => MessageData) public messages;

    constructor(
        address _lightClientBridge,
        uint256 _chainPosition,
        uint256 _lanePosition,
        uint256 _oldest_unpruned_nonce,
        uint256 _latest_received_nonce,
        uint256 _latest_generated_nonce
    ) public MessageCommitment(_lightClientBridge, _chainPosition, _lanePosition) {
        outboundLaneNonce = OutboundLaneNonce(_oldest_unpruned_nonce, _latest_received_nonce, _latest_generated_nonce);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Send message over lane
     */
    function send_message(address targetContract, bytes calldata encoded) external payable override returns (uint256) {
        require(hasRole(OUTBOUND_ROLE, msg.sender), "Lane: NotAuthorized");
        require(outboundLaneNonce.latest_generated_nonce - outboundLaneNonce.latest_received_nonce <= MAX_PENDING_MESSAGES, "Lane: TooManyPendingMessages");
        uint256 nonce = outboundLaneNonce.latest_generated_nonce + 1;
        uint256 fee = msg.value;
        outboundLaneNonce.latest_generated_nonce = nonce;
        MessagePayload memory messagePayload = MessagePayload({
            sourceAccount: msg.sender,
            targetContract: targetContract,
            laneContract: address(this),
            encoded: encoded
        });
        messages[nonce] = MessageData({
            payload: messagePayload,
            fee: fee  // a lowest fee may be required and how to set it
        });
        // TODO:: callback `on_messages_accepted`
        prune_messages(MAX_PRUNE_MESSAGES_ATONCE);
        emit MessageAccepted(lanePosition, nonce, messagePayload.sourceAccount, messagePayload.targetContract, messagePayload.laneContract, messagePayload.encoded, fee);
        commit();
        return nonce;
    }

    function increase_message_fee(uint256 nonce) external payable {
        require(nonce > outboundLaneNonce.latest_received_nonce, "Lane: MessageIsAlreadyDelivered");
        require(nonce <= outboundLaneNonce.latest_generated_nonce, "Lane: MessageIsNotYetSent");
        messages[nonce].fee += msg.value;
        commit();
        emit MessageFeeIncreased(lanePosition, nonce, messages[nonce].fee);
    }

    function receive_messages_delivery_proof(
        bytes32 outboundLaneDataHash,
        InboundLaneData memory inboundLaneData,
        MessagesProof memory messagesProof
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

    function data() public view returns (OutboundLaneData memory lane_data) {
        uint256 size = message_size();
        lane_data.messages = new Message[](size);
        uint256 begin = outboundLaneNonce.latest_received_nonce + 1;
        for (uint256 index = 0; index < size; index++) {
            uint256 nonce = index + begin;
            lane_data.messages[index] = Message(MessageKey(lanePosition, nonce), messages[nonce]);
        }
        lane_data.latest_received_nonce = outboundLaneNonce.latest_received_nonce;
    }

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

    function confirm_delivery(InboundLaneData memory subInboundLaneData) internal returns (DeliveredMessages memory confirmed_messages) {
        (uint256 total_messages, uint256 latest_delivered_nonce) = extract_substrate_inbound_lane_info(subInboundLaneData);
        require(total_messages < 256, "Lane: InvalidNumberOfMessages");

        UnrewardedRelayer[] memory relayers = subInboundLaneData.relayers;
        OutboundLaneNonce memory nonce = outboundLaneNonce;
        require(latest_delivered_nonce > nonce.latest_received_nonce, "Lane: NoNewConfirmations");
        require(latest_delivered_nonce <= nonce.latest_generated_nonce, "Lane: FailedToConfirmFutureMessages");
        require(latest_delivered_nonce - nonce.latest_received_nonce <= total_messages, "Lane: TryingToConfirmMoreMessagesThanExpected");
        uint256 dispatch_results = extract_dispatch_results(nonce.latest_received_nonce, latest_delivered_nonce, relayers);
        uint256 prev_latest_received_nonce = nonce.latest_received_nonce;
        outboundLaneNonce.latest_received_nonce = latest_delivered_nonce;
        confirmed_messages = DeliveredMessages({
            begin: prev_latest_received_nonce + 1,
            end: latest_delivered_nonce,
            dispatch_results: dispatch_results
        });
        emit MessagesDelivered(lanePosition, confirmed_messages.begin, confirmed_messages.end, confirmed_messages.dispatch_results);
    }

    function extract_dispatch_results(uint256 prev_latest_received_nonce, uint256 latest_received_nonce, UnrewardedRelayer[] memory relayers) internal pure returns(uint256 received_dispatch_result) {
        uint256 last_entry_end = 0;
        uint256 padding = 0;
        for (uint256 i = 0; i < relayers.length; i++) {
            UnrewardedRelayer memory entry = relayers[i];
            require(entry.messages.end >= entry.messages.begin, "Lane: EmptyUnrewardedRelayerEntry");
            if (last_entry_end > 0) {
                uint256 expected_entry_begin = last_entry_end + 1;
                require(entry.messages.begin == expected_entry_begin, "Lane: NonConsecutiveUnrewardedRelayerEntries");
            }
            last_entry_end = entry.messages.end;
            require(entry.messages.end <= latest_received_nonce, "Lane: FailedToConfirmFutureMessages");
            uint256 new_messages_begin = max(entry.messages.begin, prev_latest_received_nonce + 1);
            uint256 new_messages_end = min(entry.messages.end, latest_received_nonce);
            if (new_messages_end < new_messages_begin) {
                continue;
            }
            uint256 extend_begin = new_messages_begin - entry.messages.begin;
            uint256 messages_count_opp = 255 - (entry.messages.end - entry.messages.begin);
            uint256 dispatch_results = entry.messages.dispatch_results << messages_count_opp >> messages_count_opp;
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
            delete messages[nonce.oldest_unpruned_nonce];
            anything_changed = true;
            pruned_messages += 1;
            nonce.oldest_unpruned_nonce += 1;
        }
        if (anything_changed) {
            outboundLaneNonce = nonce;
        }
        emit MessagePruned(lanePosition, outboundLaneNonce.oldest_unpruned_nonce);
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
                delivery_reward += messages[nonce].fee;
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
