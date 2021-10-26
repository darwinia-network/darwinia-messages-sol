// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./BasicLane.sol";
import "../interfaces/ICrossChainFilter.sol";

/**
 * @title A entry contract for syncing message from Darwinia to Ethereum-like chain
 * @author echo
 * @notice The basic inbound lane is the message layer of the bridge
 * @dev See https://itering.notion.site/Basic-Message-Channel-c41f0c9e453c478abb68e93f6a067c52
 */
contract BasicInboundLane is BasicLane {
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
     * Hash of the OutboundLaneData Schema
     * keccak256(abi.encodePacked(
     *     "OutboundLaneData(uint256 latestReceivedNonce,bytes32 messagesHash)"
     *     ")"
     * )
     */
    bytes32 public constant OUTBOUNDLANEDATA_TYPETASH = 0x54fe6a2dce20f4c0c068b32ba323865c047ce85a18de6aa3a48bbe4fba4c5284;
    /**
     * @dev Gas used per message needs to be less than 100000 wei
     */
    uint256 public constant MAX_GAS_PER_MESSAGE = 100000;

    uint256 public constant MaxUnconfirmedMessagesAtInboundLane = 50;
    /**
     * @dev Gas buffer for executing `submit` tx
     */
    uint256 public constant GAS_BUFFER = 60000;

    struct Message {
        MessagePayload data;
        uint256 fee;
    }

    struct OutboundLaneData {
        uint256 latest_received_nonce;
        Message[] messages;
    }

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
    mapping(uint256 => DeliveredMessage) deliveredMessages;

    /**
     * @notice Deploys the BasicInboundLane contract
     * @param _chainPosition The position of the leaf in the `chain_messages_merkle_tree`, index starting with 0
     * @param _lanePosition The position of the leaf in the `lane_messages_merkle_tree`, index starting with 0
     * @param _lightClientBridge The contract address of on-chain light client
     */
    constructor(address _lightClientBridge, uint256 _chainPosition, uint256 _lanePosition, uint256 _last_confirmed_nonce, uint256 _last_delivered_nonce) public {
        lightClientBridge = ILightClientBridge(_lightClientBridge);
        chainPosition = _chainPosition;
        lanePosition = _lanePosition;
        data = InboundLaneData(_last_confirmed_nonce, _last_delivered_nonce);
    }

    /* Public Functions */

    /**
     * @notice Deliver and dispatch the messages
     * @param chainCount Number of all chain
     * @param chainMessagesProof The merkle proof required for validation of the messages in the `chain_messages_merkle_tree`
     * @param laneMessagesRoot The merkle root of the lanes, each lane is a leaf constructed by the hash of the messages in the lane
     * @param laneCount Number of all lanes
     * @param laneMessagesProof The merkle proof required for validation of the messages in the `lane_messages_merkle_tree`
     * @param beefyMMRLeaf Beefy MMR leaf which the messages root is located
     * @param beefyMMRLeafIndex Beefy MMR index which the beefy leaf is located
     * @param beefyMMRLeafCount Beefy MMR width of the MMR tree
     * @param peaks The proof required for validation the leaf
     * @param siblings The proof required for validation the leaf
     */
    function receive_messages_proof(
        OutboundLaneData memory outboundLaneData,
        bytes32 inboundLaneDataHash,
        uint256 chainCount,
        bytes32[] memory chainMessagesProof,
        bytes32 laneMessagesRoot,
        uint256 laneCount,
        bytes32[] memory laneMessagesProof,
        BeefyMMRLeaf memory beefyMMRLeaf,
        uint256 beefyMMRLeafIndex,
        uint256 beefyMMRLeafCount,
        bytes32[] memory peaks,
        bytes32[] memory siblings
    ) public {
        verifyMMRLeaf(beefyMMRLeaf, beefyMMRLeafIndex, beefyMMRLeafCount, peaks, siblings);
        verifyMessages(
            hash(outboundLaneData),
            inboundLaneDataHash,
            beefyMMRLeaf,
            chainCount,
            chainMessagesProof,
            laneMessagesRoot,
            laneCount,
            laneMessagesProof
        );
        // Require there is enough gas to play all messages
        require(
            gasleft() >= outboundLaneData.msgs.length * (MAX_GAS_PER_MESSAGE + GAS_BUFFER),
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
            MessagePayload message_data = message.data;
            uint256 nonce = data.last_delivered_nonce + 1;
            if (message_data.nonce < nonce) {
                continue;
            }
            // Check message nonce is correct and increment nonce for replay protection
            require(message_data.nonce == nonce, "Lane: InvalidNonce");
            uint256 unconfirmed_messages_count = nonce - (data.last_confirmed_nonce);
            require(nonce - data.last_confirmed_nonce <= MaxUnconfirmedMessagesAtInboundLane, "Lane: TooManyUnconfirmedMessages")
            require(message_data.laneContract == address(this), "Lane: InvalidLaneContract");

            data.last_delivered_nonce = nonce;

            bool dispatch_result = false;
            bytes memory returndata;

            /**
             * @notice The app layer must implement the interface `ICrossChainFilter`
             */
            try ICrossChainFilter(message_data.targetContract).crossChainFilter(message_data.sourceAccount, message_data.payload)
                returns (bool ok)
            {
                if (ok) {
                    // Deliver the message to the target
                    (dispatch_result, returndata) = message_data.targetContract.call{value: 0, gas: MAX_GAS_PER_MESSAGE}(message_data.payload);
                } else {
                    dispatch_result = false;
                    returndata = "Lane: filter failed";
                }
            } catch (bytes memory reason) {
                dispatch_result = false;
                returndata = reason;
            }
            deliveredMessages[nonce] = DeliveredMessage(relayer, dispatch_result);
            emit MessageDispatched(lanePosition, nonce, dispatch_result, returndata);
            // TODO: callback `pay_inbound_dispatch_fee_overhead`
        }
    }

    function hash(OutboundLaneData memory outboundLaneData)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
                    abi.encode(
                        OUTBOUNDLANEDATA_TYPETASH,
                        outboundLaneData.latestReceivedNonce,
                        hash(outboundLaneData.msgs)
                    )
                );
    }
}
