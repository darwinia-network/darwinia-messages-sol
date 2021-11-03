// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "../interfaces/ICrossChainFilter.sol";
import "./MessageCommitment.sol";
import "./SourceChain.sol";

/**
 * @title A entry contract for syncing message from Darwinia to Ethereum-like chain
 * @author echo
 * @notice The inbound lane is the message layer of the bridge
 * @dev See https://itering.notion.site/Basic-Message-Channel-c41f0c9e453c478abb68e93f6a067c52
 */
contract InboundLane is MessageCommitment, SourceChain {
    /**
     * @notice Notifies an observer that the message has dispatched
     * @param nonce The message nonce
     * @param result The message result
     * @param returndata The return data of message call, when return false, it's the reason of the error
     */
    event MessageDispatched(uint256 indexed lanePosition, uint256 indexed nonce, bool indexed result, bytes returndata);
    event DeliveredMessagePruned(uint256 indexed lanePosition, uint256 indexed nonce);

    /* Constants */

    /**
     * @dev Gas used per message needs to be less than 100000 wei
     */
    uint256 public constant MAX_GAS_PER_MESSAGE = 100000;

    uint256 public constant MAX_UNCONFIRMED_MESSAGES = 50;
    /**
     * @dev Gas buffer for executing `submit` tx
     */
    uint256 public constant GAS_BUFFER = 60000;

    struct DeliveredMessage {
        address relayer;
        bool dispatch_result;
    }

    /* State */

    /**
     * @dev ID of the next message, which is incremented in strict order
     * @notice When upgrading the lane, this value must be synchronized
     */

    struct InboundLaneData {
        uint256 last_confirmed_nonce;
        uint256 last_delivered_nonce;
    }

    InboundLaneData public data;

    // nonce => DeliveredMessage
    mapping(uint256 => DeliveredMessage) public deliveredMessages;

    /**
     * @notice Deploys the BasicInboundLane contract
     * @param _chainPosition The position of the leaf in the `chain_messages_merkle_tree`, index starting with 0
     * @param _lanePosition The position of the leaf in the `lane_messages_merkle_tree`, index starting with 0
     * @param _lightClientBridge The contract address of on-chain light client
     */
    constructor(address _lightClientBridge, uint256 _chainPosition, uint256 _lanePosition, uint256 _last_confirmed_nonce, uint256 _last_delivered_nonce) public MessageCommitment(_lightClientBridge, _chainPosition, _lanePosition) {
        data = InboundLaneData(_last_confirmed_nonce, _last_delivered_nonce);
    }

    /* Public Functions */

    /**
     * @notice Receive messages proof from bridged chain
     */
    function receive_messages_proof(
        OutboundLaneData memory outboundLaneData,
        bytes32 inboundLaneDataHash,
        MessagesProof memory messagesProof
    ) public {
        verify_messages_proof(hash(outboundLaneData), inboundLaneDataHash, messagesProof);
        // Require there is enough gas to play all messages
        require(
            gasleft() >= outboundLaneData.messages.length * (MAX_GAS_PER_MESSAGE + GAS_BUFFER),
            "Lane: insufficient gas for delivery of all messages"
        );
        receive_state_update(outboundLaneData.latest_received_nonce);
        receive_message(outboundLaneData.messages);
    }

    /* Private Functions */

    function receive_state_update(uint256 latest_received_nonce) internal returns (uint256) {
        uint256 last_delivered_nonce = data.last_delivered_nonce;
        uint256 last_confirmed_nonce = data.last_confirmed_nonce;
        require(latest_received_nonce <= last_delivered_nonce, "Lane: InvalidReceivedNonce");
        if (latest_received_nonce > last_confirmed_nonce) {
            uint256 new_confirmed_nonce = latest_received_nonce;
            for (uint256 nonce = last_confirmed_nonce; nonce <= latest_received_nonce; nonce++) {
                delete deliveredMessages[nonce];
                emit DeliveredMessagePruned(lanePosition, nonce);
            }
            data.last_confirmed_nonce = new_confirmed_nonce;
        }
        return latest_received_nonce;
    }

    function receive_message(Message[] memory messages) internal {
        address relayer = msg.sender;
        for (uint256 i = 0; i < messages.length; i++) {
            Message memory message = messages[i];
            MessageKey memory key = message.key;
            MessagePayload memory message_payload = message.data.payload;
            uint256 nonce = data.last_delivered_nonce + 1;
            if (key.nonce < nonce) {
                continue;
            }
            // Check message nonce is correct and increment nonce for replay protection
            require(key.nonce == nonce, "Lane: InvalidNonce");
            require(key.lane_id == lanePosition, "Lane: InvalidLaneID");
            require(nonce - data.last_confirmed_nonce <= MAX_UNCONFIRMED_MESSAGES, "Lane: TooManyUnconfirmedMessages");
            require(message_payload.laneContract == address(this), "Lane: InvalidLaneContract");

            data.last_delivered_nonce = nonce;

            (bool dispatch_result, bytes memory returndata) = dispatch(message_payload);

            deliveredMessages[nonce] = DeliveredMessage(relayer, dispatch_result);
            emit MessageDispatched(lanePosition, nonce, dispatch_result, returndata);
            // TODO: callback `pay_inbound_dispatch_fee_overhead`
        }
    }

    function dispatch(MessagePayload memory payload) internal returns (bool dispatch_result, bytes memory returndata) {
        /**
         * @notice The app layer must implement the interface `ICrossChainFilter`
         */
        try ICrossChainFilter(payload.targetContract).crossChainFilter(payload.sourceAccount, payload.encoded)
            returns (bool ok)
        {
            if (ok) {
                // Deliver the message to the target
                (dispatch_result, returndata) = payload.targetContract.call{value: 0, gas: MAX_GAS_PER_MESSAGE}(payload.encoded);
            } else {
                dispatch_result = false;
                returndata = "Lane: filter failed";
            }
        } catch (bytes memory reason) {
            dispatch_result = false;
            returndata = reason;
        }
    }

}
