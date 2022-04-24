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

pragma solidity 0.7.6;
pragma abicoder v2;

import "../interfaces/ICrossChainFilter.sol";
import "./InboundLaneVerifier.sol";
import "../spec/SourceChain.sol";
import "../spec/TargetChain.sol";

/// @title Everything about incoming messages receival
/// @author echo
/// @notice The inbound lane is the message layer of the bridge
/// @dev See https://itering.notion.site/Basic-Message-Channel-c41f0c9e453c478abb68e93f6a067c52
///
contract InboundLane is InboundLaneVerifier, SourceChain, TargetChain {
    /// @notice Notifies an observer that the message has dispatched
    /// @param nonce The message nonce
    /// @param result The message result
    event MessageDispatched(uint64 nonce, bool result);

    /* Constants */

    /// @dev Gas used per message needs to be less than 100000 wei
    uint256 public constant MAX_GAS_PER_MESSAGE = 100000;
    /// @dev Gas buffer for executing `send_message` tx
    uint256 public constant GAS_BUFFER = 6000;
    /// @notice This parameter must lesser than 256
    /// Maximal number of unconfirmed messages at inbound lane. Unconfirmed means that the
    /// message has been delivered, but either confirmations haven't been delivered back to the
    /// source chain, or we haven't received reward confirmations for these messages yet.
    //
    /// This constant limits difference between last message from last entry of the
    /// `InboundLaneData::relayers` and first message at the first entry.
    //
    /// This value also represents maximal number of messages in single delivery transaction.
    /// Transaction that is declaring more messages than this value, will be rejected. Even if
    /// these messages are from different lanes.
    uint256 public constant MAX_UNCONFIRMED_MESSAGES = 30;

    /* State */

    /// @dev ID of the next message, which is incremented in strict order
    /// @notice When upgrading the lane, this value must be synchronized
    struct InboundLaneNonce {
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

        // Range of UnrewardedRelayers
        // Front index of the UnrewardedRelayers (inclusive).
        uint64 relayer_range_front;
        // Back index of the UnrewardedRelayers (inclusive).
        uint64 relayer_range_back;
    }

    // slot 1
    InboundLaneNonce public inboundLaneNonce;

    // slot 2
    // index => UnrewardedRelayer
    // indexes to relayers and messages that they have delivered to this lane (ordered by
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
    mapping(uint64 => UnrewardedRelayer) public relayers;

    uint256 internal locked;
    // --- Synchronization ---
    modifier nonReentrant {
        require(locked == 0, "Lane: locked");
        locked = 1;
        _;
        locked = 0;
    }

    /**
     * @notice Deploys the InboundLane contract
     * @param _lightClientBridge The contract address of on-chain light client
     * @param _thisChainPosition The thisChainPosition of inbound lane
     * @param _thisLanePosition The lanePosition of this inbound lane
     * @param _bridgedChainPosition The bridgedChainPosition of inbound lane
     * @param _bridgedLanePosition The lanePosition of target outbound lane
     * @param _last_confirmed_nonce The last_confirmed_nonce of inbound lane
     * @param _last_delivered_nonce The last_delivered_nonce of inbound lane
     */
    constructor(
        address _lightClientBridge,
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition,
        uint64 _last_confirmed_nonce,
        uint64 _last_delivered_nonce
    ) InboundLaneVerifier(_lightClientBridge, _thisChainPosition, _thisLanePosition, _bridgedChainPosition, _bridgedLanePosition) {
        inboundLaneNonce = InboundLaneNonce(_last_confirmed_nonce, _last_delivered_nonce, 1, 0);
    }

    /* Public Functions */

    // Receive messages proof from bridged chain.
    //
    // The weight of the call assumes that the transaction always brings outbound lane
    // state update. Because of that, the submitter (relayer) has no benefit of not including
    // this data in the transaction, so reward confirmations lags should be minimal.
    function receive_messages_proof(
        OutboundLaneData memory outboundLaneData,
        bytes memory messagesProof
    ) public nonReentrant {
        verify_messages_proof(hash(outboundLaneData), messagesProof);
        // Require there is enough gas to play all messages
        require(
            gasleft() >= outboundLaneData.messages.length * (MAX_GAS_PER_MESSAGE + GAS_BUFFER),
            "Lane: InsufficientGas"
        );
        receive_state_update(outboundLaneData.latest_received_nonce);
        receive_message(outboundLaneData.messages);
    }

    function relayers_size() public view returns (uint64 size) {
        if (inboundLaneNonce.relayer_range_back >= inboundLaneNonce.relayer_range_front) {
            size = inboundLaneNonce.relayer_range_back - inboundLaneNonce.relayer_range_front + 1;
        }
    }

    function relayers_back() public view returns (address pre_relayer) {
        if (relayers_size() > 0) {
            uint64 back = inboundLaneNonce.relayer_range_back;
            pre_relayer = relayers[back].relayer;
        }
    }

	// Get lane data from the storage.
    function data() public view returns (InboundLaneData memory lane_data) {
        uint64 size = relayers_size();
        if (size > 0) {
            lane_data.relayers = new UnrewardedRelayer[](size);
            uint64 front = inboundLaneNonce.relayer_range_front;
            for (uint64 index = 0; index < size; index++) {
                lane_data.relayers[index] = relayers[front + index];
            }
        }
        lane_data.last_confirmed_nonce = inboundLaneNonce.last_confirmed_nonce;
        lane_data.last_delivered_nonce = inboundLaneNonce.last_delivered_nonce;
    }

    // commit lane data to the `commitment` storage.
    function commitment() external view returns (bytes32) {
        return hash(data());
    }

    /* Private Functions */

    // Receive state of the corresponding outbound lane.
    // Syncing state from SourceChain::OutboundLane, deal with nonce and relayers.
    function receive_state_update(uint64 latest_received_nonce) internal returns (uint64) {
        uint64 last_delivered_nonce = inboundLaneNonce.last_delivered_nonce;
        uint64 last_confirmed_nonce = inboundLaneNonce.last_confirmed_nonce;
        // SourceChain::OutboundLane::latest_received_nonce must less than or equal to TargetChain::InboundLane::last_delivered_nonce, otherwise it will receive the future nonce which has not delivery.
        // This should never happen if proofs are correct
        require(latest_received_nonce <= last_delivered_nonce, "Lane: InvalidReceivedNonce");
        if (latest_received_nonce > last_confirmed_nonce) {
            uint64 new_confirmed_nonce = latest_received_nonce;
            uint64 front = inboundLaneNonce.relayer_range_front;
            uint64 back = inboundLaneNonce.relayer_range_back;
            for (uint64 index = front; index <= back; index++) {
                UnrewardedRelayer storage entry = relayers[index];
                if (entry.messages.end <= new_confirmed_nonce) {
                    // Firstly, remove all of the records where higher nonce <= new confirmed nonce
                    delete relayers[index];
                    inboundLaneNonce.relayer_range_front = index + 1;
                } else if (entry.messages.begin <= new_confirmed_nonce) {
                    // Secondly, update the next record with lower nonce equal to new confirmed nonce if needed.
                    // Note: There will be max. 1 record to update as we don't allow messages from relayers to
                    // overlap.
                    entry.messages.dispatch_results >>= (new_confirmed_nonce + 1 - entry.messages.begin);
                    entry.messages.begin = new_confirmed_nonce + 1;
                }
            }
            inboundLaneNonce.last_confirmed_nonce = new_confirmed_nonce;
        }
        return latest_received_nonce;
    }

    // Receive new message.
    function receive_message(Message[] memory messages) internal returns (uint256 dispatch_results) {
        address relayer = msg.sender;
        uint64 begin = inboundLaneNonce.last_delivered_nonce + 1;
        uint64 next = begin;
        for (uint256 i = 0; i < messages.length; i++) {
            Message memory message = messages[i];
            MessageKey memory key = decodeMessageKey(message.encoded_key);
            MessagePayload memory message_payload = message.payload;
            if (key.nonce < next) {
                continue;
            }
            // check message nonce is correct and increment nonce for replay protection
            require(key.nonce == next, "Lane: InvalidNonce");
            // check message is from the correct source chain position
            require(key.this_chain_id == bridgedChainPosition, "Lane: InvalidSourceChainId");
            // check message is from the correct source lane position
            require(key.this_lane_id == bridgedLanePosition, "Lane: InvalidSourceLaneId");
            // check message delivery to the correct target chain position
            require(key.bridged_chain_id == thisChainPosition, "Lane: InvalidTargetChainId");
            // check message delivery to the correct target lane position
            require(key.bridged_lane_id == thisLanePosition, "Lane: InvalidTargetLaneId");
            // if there are more unconfirmed messages than we may accept, reject this message
            require(next - inboundLaneNonce.last_confirmed_nonce <= MAX_UNCONFIRMED_MESSAGES, "Lane: TooManyUnconfirmedMessages");

            // update inbound lane nonce storage
            inboundLaneNonce.last_delivered_nonce = next;

            // then, dispatch message
            bool dispatch_result = dispatch(message_payload);

            emit MessageDispatched(key.nonce, dispatch_result);
            dispatch_results |= (dispatch_result ? uint256(1) << (next - begin) : uint256(0));

            next += 1;
        }
        if (inboundLaneNonce.last_delivered_nonce >= begin) {
            uint64 end = inboundLaneNonce.last_delivered_nonce;
            // now let's update inbound lane storage
            address pre_relayer = relayers_back();
            if (pre_relayer == relayer) {
                UnrewardedRelayer storage r = relayers[inboundLaneNonce.relayer_range_back];
                r.messages.dispatch_results |= dispatch_results << (r.messages.end - r.messages.begin + 1);
                r.messages.end = end;
            } else {
                inboundLaneNonce.relayer_range_back += 1;
                relayers[inboundLaneNonce.relayer_range_back] = UnrewardedRelayer(relayer, DeliveredMessages(begin, end, dispatch_results));
            }
        }
    }

    /// @notice dispatch the cross chain message
    /// @param payload payload of the dispatch message
    /// @return dispatch_result the dispatch call result
    /// - Return True:
    ///   1. filter return True and dispatch call successfully with none 32-length return data
    ///   2. filter return True and dispatch call successfully with 32-length return data is True
    /// - Return False:
    ///   1. filter return False
    ///   2. filter return True and dispatch call failed
    ///   3. filter return True and dispatch call successfully with 32-length return data is False
    function dispatch(MessagePayload memory payload) internal returns (bool dispatch_result) {
        bytes memory filterCallData = abi.encodeWithSelector(
            ICrossChainFilter.cross_chain_filter.selector,
            bridgedChainPosition,
            bridgedLanePosition,
            payload.source,
            payload.encoded
        );
        bool canCall = filter(payload.target, filterCallData);
        if (canCall) {
            // Deliver the message to the target
            bytes memory result_data;
            (dispatch_result, result_data) = payload.target.call{value: 0, gas: MAX_GAS_PER_MESSAGE}(payload.encoded);
            if (dispatch_result && result_data.length == 32) {
                dispatch_result = abi.decode(result_data, (bool));
            }
        }
    }

    /// @notice filter the cross chain message
    /// @dev The app layer must implement the interface `ICrossChainFilter`
    /// to verify the source sender and payload of source chain messages.
    /// @param target target of the dispatch message
    /// @param encoded encoded calldata of the dispatch message
    /// @return canCall the filter static call result, Return True only when target contract
    /// implement the `ICrossChainFilter` interface with return data is True.
    function filter(address target, bytes memory encoded) internal view returns (bool canCall) {
        (bool ok, bytes memory result) = target.staticcall{gas: GAS_BUFFER}(encoded);
        if (ok) {
            if (result.length == 32) {
                canCall = abi.decode(result, (bool));
            }
        }
    }
}
