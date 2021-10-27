// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IOutboundLane.sol";
import "./SubstrateMessageCommitment.sol";
import "./SubstrateInboundLane.sol";

// BasicOutboundLand is a basic lane that just sends messages with a nonce.
contract BasicOutboundLane is IOutboundLane, AccessControl, SubstrateMessageCommitment, SubstrateInboundLane {
    event MessageAccepted(uint256 indexed lanePosition, uint256 indexed nonce, address sourceAccount, address targetContract, address laneContract, bytes encoded, uint256 fee);
    event MessagesDelivered(uint256 indexed lanePosition, uint256 begin, uint256 end, uint256 results);
    event MessagePruned(uint256 indexed lanePosition, uint256 indexed oldest_unpruned_nonce);
    event MessageFeeIncreased(uint256 indexed lanePosition, uint256 indexed nonce, uint256 fee);

    bytes32 internal constant OUTBOUND_ROLE = keccak256("OUTBOUND_ROLE");
    uint256 internal constant MAX_PENDING_MESSAGES = 50;
    uint256 internal constant MAX_PRUNE_MESSAGES_ATONCE = 10;

    /**
     * Hash of the MessagePayload Schema
     * keccak256(abi.encodePacked(
     *     "MessagePayload(address sourceAccount,address targetContract,address laneContract,bytes encoded)"
     *     ")"
     * )
     */
    bytes32 internal constant MESSAGEPAYLOAD_TYPEHASH = 0xa2b843d52192ed322a0cda3ca8b407825100c01ffd3676529bc139bc847a12fb;


    /**
     * The MessagePayload is the structure of DarwiniaRPC which should be delivery to Ethereum-like chain
     * @param sourceAccount The derived DVM address of pallet ID which send the message
     * @param targetContract The targe contract address which receive the message
     * @param laneContract The inbound lane contract address which the message commuting to
     * @param nonce The ID used to uniquely identify the message
     * @param encoded The calldata which encoded by ABI Encoding
     */
    struct MessagePayload {
        address sourceAccount;
        address targetContract;
        address laneContract;
        bytes encoded; /*abi.encodePacked(SELECTOR, PARAMS)*/
    }

    struct MessageDataHashed {
        bytes32 payloadHash;
        uint256 fee;
    }

    struct OutboundLaneData {
        uint256 oldest_unpruned_nonce;
        uint256 latest_received_nonce;
        uint256 latest_generated_nonce;
    }

    /* State */

    OutboundLaneData public data;

    // nonce => message
    mapping(uint256 => MessageDataHashed) messages;

    constructor(
        address _lightClientBridge,
        uint256 _chainPosition,
        uint256 _lanePosition,
        uint256 _oldest_unpruned_nonce,
        uint256 _latest_received_nonce,
        uint256 _latest_generated_nonce
    ) public {
        lightClientBridge = ILightClientBridge(_lightClientBridge);
        chainPosition = _chainPosition;
        lanePosition = _lanePosition;
        data = OutboundLaneData(_oldest_unpruned_nonce, _latest_received_nonce, _latest_generated_nonce);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Send message over lane
     */
    function send_message(address targetContract, bytes calldata encoded) external payable override returns (uint256) {
        require(hasRole(OUTBOUND_ROLE, msg.sender), "Lane: NotAuthorized");
        require(data.latest_generated_nonce - data.latest_received_nonce <= MAX_PENDING_MESSAGES, "Lane: TooManyPendingMessages");
		uint256 nonce = data.latest_generated_nonce + 1;
        uint256 fee = msg.value;
		data.latest_generated_nonce = nonce;
        MessagePayload memory messagePayload = MessagePayload({
            sourceAccount: msg.sender,
            targetContract: targetContract,
            laneContract: address(this),
            encoded: encoded
        });
        messages[nonce] = MessageDataHashed({
            payloadHash: hash(messagePayload),
            fee: fee  // a lowest fee may be required and how to set it
        });
        // TODO:: callback `on_messages_accepted`
        prune_messages(MAX_PRUNE_MESSAGES_ATONCE);
        emit MessageAccepted(lanePosition, nonce, messagePayload.sourceAccount, messagePayload.targetContract, messagePayload.laneContract, messagePayload.encoded, fee);
        return nonce;
    }

    function increase_message_fee(uint256 nonce) external payable {
        require(nonce > data.latest_received_nonce, "Lane: MessageIsAlreadyDelivered");
        require(nonce <= data.latest_generated_nonce, "Lane: MessageIsNotYetSent");
        messages[nonce].fee += msg.value;
        emit MessageFeeIncreased(lanePosition, nonce, messages[nonce].fee);
    }

    function receiveMessagesDeliveryProof(
        bytes32 subOutboundLaneDataHash,
        InboundLaneData memory subInboundLaneData,
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
            subOutboundLaneDataHash,
            hash(subInboundLaneData),
            beefyMMRLeaf,
            chainCount,
            chainMessagesProof,
            laneMessagesRoot,
            laneCount,
            laneMessagesProof
        );
        (uint256 total_messages, uint256 last_delivered_nonce) = extract_substrate_inbound_lane_info(subInboundLaneData);
        require(total_messages < 256, "Lane: InvalidNumberOfMessages");
        confirm_delivery(total_messages, last_delivered_nonce, subInboundLaneData.relayers);
        // TODO: callback `on_messages_delivered`
        // TODO: hook `pay_relayers_rewards`
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

    function confirm_delivery(uint256 max_allowed_messages, uint256 latest_delivered_nonce, UnrewardedRelayer[] memory relayers) internal returns (DeliveredMessages memory confirmed_messages) {
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

    function extract_dispatch_results(uint256 prev_latest_received_nonce, uint256 latest_received_nonce, UnrewardedRelayer[] memory relayers) internal pure returns(uint256 received_dispatch_result) {
        uint256 last_entry_end = 0;
        uint256 padding = 0;
        for (uint256 i = 0; i < relayers.length; i++) {
            UnrewardedRelayer memory entry = relayers[i];
            require(entry.messages.end < entry.messages.begin, "Lane: EmptyUnrewardedRelayerEntry");
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
            received_dispatch_result |= ((entry.messages.dispatch_results << extend_begin) >> padding);
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
		while (pruned_messages < max_messages_to_prune &&
			dataMem.oldest_unpruned_nonce <= dataMem.latest_received_nonce)
		{
            delete messages[dataMem.oldest_unpruned_nonce];
			anything_changed = true;
			pruned_messages += 1;
			dataMem.oldest_unpruned_nonce += 1;
		}

		if (anything_changed) {
			data = dataMem;
		}
        emit MessagePruned(lanePosition, data.oldest_unpruned_nonce);
        return pruned_messages;
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
                payload.laneContract,
                payload.encoded
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
