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

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../../interfaces/ICrossChainFilter.sol";
import "./MessageVerifier.sol";
import "./SourceChain.sol";
import "./TargetChain.sol";
import "hardhat/console.sol";

/**
 * @title Everything about incoming messages receival
 * @author echo
 * @notice The inbound lane is the message layer of the bridge
 * @dev See https://itering.notion.site/Basic-Message-Channel-c41f0c9e453c478abb68e93f6a067c52
 */
contract InboundLane is ReentrancyGuard, MessageVerifier, SourceChain, TargetChain {
    /**
     * @notice Notifies an observer that the message has dispatched
     * @param thisChainPosition The thisChainPosition of inbound lane
     * @param lanePosition The lanePosition of inbound lane
     * @param nonce The message nonce
     * @param result The message result
     * @param returndata The return data of message call, when return false, it's the reason of the error
     */
    event MessageDispatched(uint256 thisChainPosition, uint256 lanePosition, uint256 nonce, bool result, bytes returndata);

    /* Constants */

    /**
     * @dev Gas used per message needs to be less than 100000 wei
     */
    uint256 public constant MAX_GAS_PER_MESSAGE = 100000;
    /**
     * @dev Gas buffer for executing `send_message` tx
     */
    uint256 public constant GAS_BUFFER = 60000;
    /**
     * @notice This parameter must lesser than 256
     * Maximal number of unconfirmed messages at inbound lane. Unconfirmed means that the
     * message has been delivered, but either confirmations haven't been delivered back to the
     * source chain, or we haven't received reward confirmations for these messages yet.
     *
     * This constant limits difference between last message from last entry of the
     * `InboundLaneData::relayers` and first message at the first entry.
     *
     * This value also represents maximal number of messages in single delivery transaction.
     * Transaction that is declaring more messages than this value, will be rejected. Even if
     * these messages are from different lanes.
     */
    uint256 public constant MAX_UNCONFIRMED_MESSAGES = 50;

    /* State */

    /**
     * @dev ID of the next message, which is incremented in strict order
     * @notice When upgrading the lane, this value must be synchronized
     */
    struct InboundLaneNonce {
        // Nonce of the last message that
        // a) has been delivered to the target (this) chain and
        // b) the delivery has been confirmed on the source chain
        //
        // that the target chain knows of.
        //
        // This value is updated indirectly when an `OutboundLane` state of the source
        // chain is received alongside with new messages delivery.
        uint256 last_confirmed_nonce;
        // Nonce of the latest received or has been delivered message to this inbound lane.
        uint256 last_delivered_nonce;
    }

    InboundLaneNonce public inboundLaneNonce;

    // Range of UnrewardedRelayers
    struct RelayersRange {
        // Front index of the UnrewardedRelayers (inclusive).
        uint256 front;
        // Back index of the UnrewardedRelayers (inclusive).
        uint256 back;
    }

    RelayersRange public relayersRange;

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
    mapping(uint256 => UnrewardedRelayer) public relayers;

    /**
     * @notice Deploys the InboundLane contract
     * @param _lightClientBridge The contract address of on-chain light client
     * @param _thisChainPosition The thisChainPosition of inbound lane
     * @param _bridgedChainPosition The bridgedChainPosition of inbound lane
     * @param _lanePosition The lanePosition of inbound lane
     * @param _last_confirmed_nonce The last_confirmed_nonce of inbound lane
     * @param _last_delivered_nonce The last_delivered_nonce of inbound lane
     */
    constructor(
        address _lightClientBridge,
        uint256 _thisChainPosition,
        uint256 _bridgedChainPosition,
        uint256 _lanePosition,
        uint256 _last_confirmed_nonce,
        uint256 _last_delivered_nonce
    ) public MessageVerifier(_lightClientBridge, _thisChainPosition, _bridgedChainPosition, _lanePosition) {
        inboundLaneNonce = InboundLaneNonce(_last_confirmed_nonce, _last_delivered_nonce);
        relayersRange = RelayersRange(1, 0);
    }

    /* Public Functions */

    // Receive messages proof from bridged chain.
    //
    // The weight of the call assumes that the transaction always brings outbound lane
    // state update. Because of that, the submitter (relayer) has no benefit of not including
    // this data in the transaction, so reward confirmations lags should be minimal.
    function receive_messages_proof(
        OutboundLaneData memory outboundLaneData,
        bytes32 inboundLaneDataHash,
        bytes memory messagesProof
    ) public nonReentrant {
        verify_messages_proof(hash(outboundLaneData), inboundLaneDataHash, messagesProof);
        // Require there is enough gas to play all messages
        require(
            gasleft() >= outboundLaneData.messages.length * (MAX_GAS_PER_MESSAGE + GAS_BUFFER),
            "Lane: insufficient gas for delivery of all messages"
        );
        receive_state_update(outboundLaneData.latest_received_nonce);
        receive_message(outboundLaneData.messages);
        commit();
    }

    function relayers_size() public view returns (uint256 size) {
        if (relayersRange.back >= relayersRange.front) {
            size = relayersRange.back - relayersRange.front + 1;
        }
    }

    function relayers_back() public view returns (address pre_relayer) {
        if (relayers_size() > 0) {
            uint256 back = relayersRange.back;
            pre_relayer = relayers[back].relayer;
        }
    }

	// Get lane data from the storage.
    function data() public view returns (InboundLaneData memory lane_data) {
        uint256 size = relayers_size();
        if (size > 0) {
            lane_data.relayers = new UnrewardedRelayer[](size);
            uint256 front = relayersRange.front;
            for (uint256 index = 0; index < size; index++) {
                lane_data.relayers[index] = relayers[front + index];
            }
        }
        lane_data.last_confirmed_nonce = inboundLaneNonce.last_confirmed_nonce;
        lane_data.last_delivered_nonce = inboundLaneNonce.last_delivered_nonce;
    }

    /* Private Functions */

    // storage proof issue: must use latest commitment in lightclient, cause we rm mmr root
    function commit() internal returns (bytes32) {
        commitment = hash(data());
        return commitment;
    }

    // Receive state of the corresponding outbound lane.
    // Syncing state from SourceChain::OutboundLane, deal with nonce and relayers.
    function receive_state_update(uint256 latest_received_nonce) internal returns (uint256) {
        uint256 last_delivered_nonce = inboundLaneNonce.last_delivered_nonce;
        uint256 last_confirmed_nonce = inboundLaneNonce.last_confirmed_nonce;
        // SourceChain::OutboundLane::latest_received_nonce must less than or equal to TargetChain::InboundLane::last_delivered_nonce, otherwise it will receive the future nonce which has not delivery.
        // This should never happen if proofs are correct
        require(latest_received_nonce <= last_delivered_nonce, "Lane: InvalidReceivedNonce");
        if (latest_received_nonce > last_confirmed_nonce) {
            uint256 new_confirmed_nonce = latest_received_nonce;
            uint256 front = relayersRange.front;
            uint256 back = relayersRange.back;
            for (uint256 index = front; index <= back; index++) {
                UnrewardedRelayer storage entry = relayers[index];
                if (entry.messages.end <= new_confirmed_nonce) {
                    // Firstly, remove all of the records where higher nonce <= new confirmed nonce
                    delete relayers[index];
                    relayersRange.front = index + 1;
                } else if (entry.messages.begin < new_confirmed_nonce) {
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
        address payable relayer = msg.sender;
        uint256 begin = inboundLaneNonce.last_delivered_nonce + 1;
        uint256 next = begin;
        uint256 end;
        for (uint256 i = 0; i < messages.length; i++) {
            Message memory message = messages[i];
            MessageKey memory key = message.key;
            MessagePayload memory message_payload = message.data.payload;
            if (key.nonce < next) {
                continue;
            }
            // check message nonce is correct and increment nonce for replay protection
            require(key.nonce == next, "Lane: InvalidNonce");
            // check message delivery to the correct chain position
            require(key.chain_id == thisChainPosition, "Lane: InvalidChainId");
            // check message delivery to the correct lane position
            require(key.lane_id == lanePosition, "Lane: InvalidLaneID");
            // if there are more unconfirmed messages than we may accept, reject this message
            require(next - inboundLaneNonce.last_confirmed_nonce <= MAX_UNCONFIRMED_MESSAGES, "Lane: TooManyUnconfirmedMessages");

            // then, dispatch message
            (bool dispatch_result, bytes memory returndata) = dispatch(message_payload);

            emit MessageDispatched(thisChainPosition, lanePosition, next, dispatch_result, returndata);
            // TODO: callback `pay_inbound_dispatch_fee_overhead`
            dispatch_results |= (dispatch_result ? uint256(1) : uint256(0)) << i;
            end = next;
            next += 1;
        }
        if (end > inboundLaneNonce.last_delivered_nonce) {
            // update inbound lane nonce storage
            inboundLaneNonce.last_delivered_nonce = end;

            // now let's update inbound lane storage
            address pre_relayer = relayers_back();
            if (pre_relayer == relayer) {
                UnrewardedRelayer storage r = relayers[relayersRange.back];
                r.messages.dispatch_results |= dispatch_results << (r.messages.end - r.messages.begin + 1);
                r.messages.end = end;
            } else {
                relayersRange.back += 1;
                relayers[relayersRange.back] = UnrewardedRelayer(relayer, DeliveredMessages(begin, end, dispatch_results));
            }
        }
    }

    function dispatch(MessagePayload memory payload) internal returns (bool dispatch_result, bytes memory returndata) {
        bytes memory filterCallData = abi.encodeWithSelector(
            ICrossChainFilter.crossChainFilter.selector,
            payload.sourceAccount,
            payload.encoded
        );
        bool canCall = filter(payload.targetContract, filterCallData);
        if (canCall) {
            // Deliver the message to the target
            (dispatch_result, returndata) = payload.targetContract.call{value: 0, gas: MAX_GAS_PER_MESSAGE}(payload.encoded);
        } else {
            dispatch_result = false;
            returndata = "Lane: MessageCallRejected";
        }
    }

    function filter(address target, bytes memory callData) internal returns (bool canCall) {
        /**
         * @notice The app layer must implement the interface `ICrossChainFilter`
         */
        (bool ok, bytes memory result) = target.call{value: 0, gas: GAS_BUFFER}(callData);
        if (ok) {
            if (result.length == 32) {
                canCall = abi.decode(result, (bool));
            }
        }
    }
}
