// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@darwinia/contracts-utils/contracts/Bits.sol"
import "./BasicLane.sol";
import "../interfaces/IOutboundLane.sol";

// BasicOutboundLand is a basic lane that just sends messages with a nonce.
contract BasicOutboundLane is IOutboundLane, AccessControl, BasicLane {
    using Bits for uint256;

    /**
     * Notifies an observer that the message has accepted
     * @param sourceAccount The source contract address which send the message
     * @param targetContract The targe derived DVM address of pallet ID which receive the message
     * @param laneContract The outbound lane contract address which the message commuting to
     * @param nonce The ID used to uniquely identify the message
     * @param payload The calldata which encoded by ABI Encoding, abi.encodePacked(SELECTOR, PARAMS)
     */
    event MessageAccepted(uint256 indexed lanePosition, uint256 indexed nonce, address sourceAccount, address targetContract, address laneContract, bytes payload, uint256 fee);
    event MessagesDelivered(uint256 indexed lanePosition, uint256 begin, uint256 end, uint256 results);
    event MessagePruned(uint256 indexed lanePosition, uint256 indexed oldest_unpruned_nonce);

    bytes32 public constant OUTBOUND_ROLE = keccak256("OUTBOUND_ROLE");

    /**
     * Hash of the InboundLaneData Schema
     * keccak256(abi.encodePacked(
     *     "InboundLaneData(uint256 lastDeliveredNonce,bytes32 messagesHash)"
     *     ")"
     * )
     */
    bytes32 public constant INBOUNDLANEDATA_TYPETASH = 0x54fe6a2dce20f4c0c068b32ba323865c047ce85a18de6aa3a48bbe4fba4c5284;

    uint256 public constant MAX_PENDING_MESSAGES = 50;
    uint256 public constant MaxMessagesToPruneAtOnce = 10;

    /* State */

    struct DeliveredMessages {
        uint256 begin;
        uint256 end;
        uint256 dispatch_results;
    }

    struct UnrewardedRelayer {
        address relayer;
        DeliveredMessages messages;
    }

    struct InboundLaneData {
        UnrewardedRelayer[] relayers;
        uint256 last_confirmed_nonce;
    }
    struct OutboundLaneData {
        uint256 oldest_unpruned_nonce;
        uint256 latest_received_nonce;
        uint256 latest_generated_nonce;
    }

    OutboundLaneData public data;

    // nonce => message
    mapping(uint256 => MessageData) messages;

    constructor(
        address _lightClientBridge,
        uint256 _chainPosition,
        uint256 _lanePosition,
        uint256 _oldestUnprunedNonce,
        uint256 _latestReceivedNonce,
        uint256 _latestGeneratedNonce
    ) public {
        lightClientBridge = ILightClientBridge(_lightClientBridge);
        chainPosition = _chainPosition;
        lanePosition = _lanePosition;
        data = OutboundLaneData(_oldestUnprunedNonce, _latestReceivedNonce, _latestGeneratedNonce);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Sends a message across the lane
     */
    function send_message(address targetContract, bytes calldata payload) external payable override returns (uint256) {
        require(hasRole(OUTBOUND_ROLE, msg.sender), "Lane: NotAuthorized");
        require(data.latest_generated_nonce - data.last_confirmed_nonce <= MAX_PENDING_MESSAGES, "Lane: TooManyPendingMessages");
		uint256 nonce = data.latest_generated_nonce + 1;
        uint256 fee = msg.value;
		data.latest_generated_nonce = nonce;
        MessagePayload memory messagePayload = MessagePayload({
            nonce: nonce,
            sourceAccount: msg.sender,
            targetContract: targetContract,
            laneContract: address(this),
            payload: payload
        });
        messages[nonce] = MessageData({
            payloadHash: hash(messagePayload),
            fee: fee  // a lowest fee may be required and how to set it
        });
        // TODO:: callback `on_messages_accepted`
        prune_messages(MaxMessagesToPruneAtOnce);
        emit MessageAccepted(lanePosition, messagePayload.nonce, messagePayload.sourceAccount, messagePayload.targetContract, messagePayload.laneContract, messagePayload.payload, fee);
        return nonce;
    }

    function receiveMessagesDeliveryProof(
        bytes32 outboundLaneDataHash,
        InboundLaneData memory inboundLaneData,
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
            outboundLaneDataHash,
            hash(inboundLaneData),
            beefyMMRLeaf,
            chainCount,
            chainMessagesProof,
            laneMessagesRoot,
            laneCount,
            laneMessagesProof
        );
        (uint256 total_messages, uint256 last_delivered_nonce) = source_chain_inbound_lane_info(inboundLaneData);
        require(total_messages < 256, "Lane: InvalidNumberOfMessages");
        confirm_delivery(total_messages, last_delivered_nonce, inboundLaneData.relayers);
        // TODO: callback `on_messages_delivered`
        // TODO: hook `pay_relayers_rewards`
    }

    /* Private Functions */

    function source_chain_inbound_lane_info(InboundLaneData memory land_data) internal returns (uint256 total_unrewarded_messages, uint256 last_delivered_nonce) {
        uint256 len = relayers.length;
        if(len > 0) {
            UnrewardedRelayer memory front = relayers[0];
            UnrewardedRelayer memory back = relayers[len-1];
            total_messages = back.messages.end - fron.messages.begin + 1;
            last_delivered_nonce = back.messages.end;
        } else {
            total_messages = 0;
            last_delivered_nonce = land_data.last_confirmed_nonce;
        }
    }

    function confirmDelivery(uint256 max_allowed_messages, uint256 latest_delivered_nonce, UnrewardedRelayer[] relayers) internal returns (DeliveredMessages confirmed_messages) {
        OutboundLaneData memory dataMem = data;
        require(latest_delivered_nonce > dataMem.latest_received_nonce, "Lane: NoNewConfirmations");
        require(latest_delivered_nonce <= dataMem.latest_generated_nonce, "Lane: FailedToConfirmFutureMessages");
        require(latest_delivered_nonce - dataMem.latest_received_nonce <= max_allowed_messages, "Lane: TryingToConfirmMoreMessagesThanExpected");
        uint256 dispatch_results = extract_dispatch_results(dataMem.latest_received_nonce, latest_delivered_nonce, relayers);

		uint256 prev_latest_received_nonce = dataMem.latest_received_nonce;
		data.latest_received_nonce = latest_delivered_nonce;

        confirmed_messages = DeliveredMessages({
            begin: prev_latest_received_nonce + 1,
            end: latest_delivered_nonce,
            dispatch_results: dispatch_results
        });
        emit MessagesDelivered(lanePosition, confirmed_messages.begin, confirmed_messages.end, confirmed_messages.dispatch_results);
    }

    function extract_dispatch_results(uint256 prev_latest_received_nonce, uint256 latest_received_nonce, UnrewardedRelayer[] relayers) internal returns(uint256 received_dispatch_result) {
        uint256 last_entry_end = 0;
        uint256 padding = 0;
        for (uint256 i = 0; i < relayers.length; i++) {
            UnrewardedRelayer entry = relayers[i];
            require(entry.messages.end < entry.messages.begin, "Lane: EmptyUnrewardedRelayerEntry")
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
            received_dispatch_result |= ((entry.dispatch_results << extend_begin) >> padding);
            padding = padding + entry.messages.end - entry.messages.begin - extend_begin + 1;
        }
    }

	/// Prune at most `max_messages_to_prune` already received messages.
	///
	/// Returns number of pruned messages.
    function prune_messages(uint256 max_messages_to_prune) internal returns (uint256) {
		uint256 pruned_messages = 0;
		bool anything_changed = false;
		OutboundLaneData memory dataMem = data;
		while pruned_messages < max_messages_to_prune &&
			dataMem.oldest_unpruned_nonce <= dataMem.latest_received_nonce
		{
            delete messages[dataMem.oldest_unpruned_nonce];
			anything_changed = true;
			pruned_messages += 1;
			dataMem.oldest_unpruned_nonce += 1;
		}

		if anything_changed {
			data = dataMem;
		}
        emit MessagePruned(lanePosition, data.oldest_unpruned_nonce);
        return pruned_messages;
    }

    function hash(InboundLaneData memory inboundLaneData)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
                    abi.encode(
                        INBOUNDLANEDATA_TYPETASH,
                        inboundLaneData.lastDeliveredNonce,
                        hash(inboundLaneData.msgs)
                    )
                );
    }

    // --- Math ---
    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }

    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
}
