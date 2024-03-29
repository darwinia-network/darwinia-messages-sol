// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.
//
// Message module that allows sending and receiving messages using lane concept:
//
// 1) the message is sent using `send_message()` call;
// 2) every outbound message is assigned nonce;
// 3) the messages hash are stored in the storage;
// 4) external component (relay) delivers messages to bridged chain;
// 5) messages are processed in order (ordered by assigned nonce);
// 6) relay may send proof-of-delivery back to this chain.
//
// Once message is sent, its progress can be tracked by looking at lane contract events.
// The assigned nonce is reported using `MessageAccepted` event. When message is
// delivered to the the bridged chain, it is reported using `MessagesDelivered` event.

pragma solidity 0.8.17;

import "../interfaces/IOutboundLane.sol";
import "../interfaces/IFeeMarket.sol";
import "./OutboundLaneVerifier.sol";
import "../spec/SourceChain.sol";
import "../spec/TargetChain.sol";

/// @title SerialOutboundLane
/// @notice Everything about outgoing messages sending.
/// @dev See https://itering.notion.site/Basic-Message-Channel-c41f0c9e453c478abb68e93f6a067c52
contract SerialOutboundLane is IOutboundLane, OutboundLaneVerifier, TargetChain, SourceChain {
    /// @dev slot 1
    OutboundLaneNonce public outboundLaneNonce;
    /// @dev slot 2
    /// @notice nonce => hash(MessagePayload)
    mapping(uint64 => bytes32) public messages;

    address public immutable FEE_MARKET;

    uint64  private constant MAX_CALLDATA_LENGTH       = 2048;
    uint64  private constant MAX_PENDING_MESSAGES      = 20;
    uint64  private constant MAX_PRUNE_MESSAGES_ATONCE = 5;

    event MessageAccepted(uint64 indexed nonce, address source, address target, bytes encoded);
    event MessagesDelivered(uint64 indexed begin, uint64 indexed end);
    event MessagePruned(uint64 indexed oldest_unpruned_nonce);

    /// Outbound lane nonce.
    struct OutboundLaneNonce {
        // Nonce of the latest message, received by bridged chain.
        uint64 latest_received_nonce;
        // Nonce of the latest message, generated by this lane.
        uint64 latest_generated_nonce;
        // Nonce of the oldest message that we haven't yet pruned. May point to not-yet-generated
        // message if all sent messages are already pruned.
        uint64 oldest_unpruned_nonce;
    }

    /// @dev Deploys the SerialOutboundLane contract
    /// @param _verifier The contract address of on-chain verifier
    /// @param _feeMarket The fee market of the outbound lane
    /// @param _laneId The identify of the outbound lane
    /// @param _oldest_unpruned_nonce The oldest_unpruned_nonce of outbound lane
    /// @param _latest_received_nonce The latest_received_nonce of outbound lane
    /// @param _latest_generated_nonce The latest_generated_nonce of outbound lane
    constructor(
        address _verifier,
        address _feeMarket,
        uint256 _laneId,
        uint64 _oldest_unpruned_nonce,
        uint64 _latest_received_nonce,
        uint64 _latest_generated_nonce
    ) OutboundLaneVerifier(_verifier, _laneId) {
        outboundLaneNonce = OutboundLaneNonce(
            _latest_received_nonce,
            _latest_generated_nonce,
            _oldest_unpruned_nonce
        );
        FEE_MARKET = _feeMarket;
    }

    /// @dev Send message over lane.
    /// Submitter could be a contract or just an EOA address.
    /// At the beginning of the launch, submmiter is permission, after the system is stable it will be permissionless.
    /// @param target The target contract address which you would send cross chain message to
    /// @param encoded The calldata which encoded by ABI Encoding
    /// @return nonce Latest generated nonce
    function send_message(address target, bytes calldata encoded) external payable override returns (uint64) {
        require(outboundLaneNonce.latest_generated_nonce - outboundLaneNonce.latest_received_nonce < MAX_PENDING_MESSAGES, "TooManyPendingMessages");
        require(outboundLaneNonce.latest_generated_nonce < type(uint64).max, "Overflow");
        require(encoded.length <= MAX_CALLDATA_LENGTH, "TooLargeCalldata");

        uint64 nonce = outboundLaneNonce.latest_generated_nonce + 1;

        // assign the message to top relayers
        uint encoded_key = encodeMessageKey(nonce);
        require(IFeeMarket(FEE_MARKET).assign{value: msg.value}(encoded_key), "AssignRelayersFailed");

        outboundLaneNonce.latest_generated_nonce = nonce;
        MessagePayload memory payload = MessagePayload({
            source: msg.sender,
            target: target,
            encoded: encoded
        });
        messages[nonce] = hash(payload);
        // message sender prune at most `MAX_PRUNE_MESSAGES_ATONCE` messages
        _prune_messages(MAX_PRUNE_MESSAGES_ATONCE);
        emit MessageAccepted(
            nonce,
            msg.sender,
            target,
            encoded);
        return nonce;
    }

    /// Receive messages delivery proof from bridged chain.
    function receive_messages_delivery_proof(
        InboundLaneData calldata inboundLaneData,
        bytes memory messagesProof
    ) external {
        _verify_messages_delivery_proof(hash(inboundLaneData), messagesProof);
        DeliveredMessages memory confirmed_messages = _confirm_delivery(inboundLaneData);
        // settle the confirmed_messages at fee market
        settle_messages(inboundLaneData.relayers, confirmed_messages.begin, confirmed_messages.end);
    }

    /// Return the commitment of lane data.
    function commitment() external view returns (bytes32) {
        return hash(data());
    }

    function message_size() public view returns (uint64 size) {
        size = outboundLaneNonce.latest_generated_nonce - outboundLaneNonce.latest_received_nonce;
    }

    /// Get lane data from the storage.
    function data() public view returns (OutboundLaneDataStorage memory lane_data) {
        uint64 size = message_size();
        if (size > 0) {
            lane_data.messages = new MessageStorage[](size);
            unchecked {
                uint64 begin = outboundLaneNonce.latest_received_nonce + 1;
                for (uint64 index = 0; index < size; index++) {
                    uint64 nonce = index + begin;
                    lane_data.messages[index] = MessageStorage(encodeMessageKey(nonce), messages[nonce]);
                }
            }
        }
        lane_data.latest_received_nonce = outboundLaneNonce.latest_received_nonce;
    }

    function _extract_inbound_lane_info(
        InboundLaneData memory lane_data
    ) private pure returns (
        uint64 total_unrewarded_messages,
        uint64 last_delivered_nonce
    ) {
        total_unrewarded_messages = lane_data.last_delivered_nonce - lane_data.last_confirmed_nonce;
        last_delivered_nonce = lane_data.last_delivered_nonce;
    }

    /// Confirm messages delivery.
    function _confirm_delivery(
        InboundLaneData memory inboundLaneData
    ) private returns (
        DeliveredMessages memory confirmed_messages
    ) {
        (uint64 total_messages, uint64 latest_delivered_nonce) = _extract_inbound_lane_info(inboundLaneData);

        OutboundLaneNonce memory nonce = outboundLaneNonce;
        require(latest_delivered_nonce > nonce.latest_received_nonce, "NoNewConfirmations");
        require(latest_delivered_nonce <= nonce.latest_generated_nonce, "FailedToConfirmFutureMessages");
        // that the relayer has declared correct number of messages that the proof contains (it
        // is checked outside of the function). But it may happen (but only if this/bridged
        // chain storage is corrupted, though) that the actual number of confirmed messages if
        // larger than declared.
        require(latest_delivered_nonce - nonce.latest_received_nonce <= total_messages, "TryingToConfirmMoreMessagesThanExpected");
        _check_relayers(latest_delivered_nonce, inboundLaneData.relayers);
        uint64 prev_latest_received_nonce = nonce.latest_received_nonce;
        outboundLaneNonce.latest_received_nonce = latest_delivered_nonce;
        confirmed_messages = DeliveredMessages({
            begin: prev_latest_received_nonce + 1,
            end: latest_delivered_nonce
        });
        // emit 'MessagesDelivered' event
        emit MessagesDelivered(confirmed_messages.begin, confirmed_messages.end);
    }

    /// Extract new dispatch results from the unrewarded relayers vec.
    ///
    /// Revert if unrewarded relayers vec contains invalid data, meaning that the bridged
    /// chain has invalid runtime storage.
    function _check_relayers(uint64 latest_received_nonce, UnrewardedRelayer[] memory relayers) private pure {
        // the only caller of this functions checks that the
        // prev_latest_received_nonce..=latest_received_nonce is valid, so we're ready to accept
        // messages in this range => with_capacity call must succeed here or we'll be unable to receive
        // confirmations at all
        uint64 last_entry_end = 0;
        for (uint64 i = 0; i < relayers.length; ) {
            UnrewardedRelayer memory entry = relayers[i];
            unchecked { ++i; }
            // unrewarded relayer entry must have at least 1 unconfirmed message
            // (guaranteed by the `InboundLane::receive_message()`)
            require(entry.messages.end >= entry.messages.begin, "EmptyUnrewardedRelayerEntry");
            if (last_entry_end > 0) {
                uint64 expected_entry_begin = last_entry_end + 1;
                // every entry must confirm range of messages that follows previous entry range
                // (guaranteed by the `InboundLane::receive_message()`)
                require(entry.messages.begin == expected_entry_begin, "NonConsecutiveUnrewardedRelayerEntries");
            }
            last_entry_end = entry.messages.end;
            // entry can't confirm messages larger than `inbound_lane_data.latest_received_nonce()`
            // (guaranteed by the `InboundLane::receive_message()`)
			// technically this will be detected in the next loop iteration as
			// `InvalidNumberOfDispatchResults` but to guarantee safety of loop operations below
			// this is detected now
            require(entry.messages.end <= latest_received_nonce, "FailedToConfirmFutureMessages");
        }
    }

    /// Prune at most `max_messages_to_prune` already received messages.
    ///
    /// Returns number of pruned messages.
    function _prune_messages(uint64 max_messages_to_prune) private returns (uint64 pruned_messages) {
        OutboundLaneNonce memory nonce = outboundLaneNonce;
        while (pruned_messages < max_messages_to_prune &&
            nonce.oldest_unpruned_nonce <= nonce.latest_received_nonce)
        {
            delete messages[nonce.oldest_unpruned_nonce];
            unchecked {
                pruned_messages += 1;
                nonce.oldest_unpruned_nonce += 1;
            }
        }
        if (pruned_messages > 0) {
            outboundLaneNonce.oldest_unpruned_nonce = nonce.oldest_unpruned_nonce;
            emit MessagePruned(outboundLaneNonce.oldest_unpruned_nonce);
        }
        return pruned_messages;
    }

    function settle_messages(
        UnrewardedRelayer[] memory relayers,
        uint64 received_start,
        uint64 received_end
    ) private {
        IFeeMarket.DeliveredRelayer[] memory delivery_relayers = new IFeeMarket.DeliveredRelayer[](relayers.length);
        for (uint256 i = 0; i < relayers.length; ) {
            UnrewardedRelayer memory r = relayers[i];
            uint64 nonce_begin = _max(r.messages.begin, received_start);
            uint64 nonce_end = _min(r.messages.end, received_end);
            delivery_relayers[i] = IFeeMarket.DeliveredRelayer(r.relayer, encodeMessageKey(nonce_begin), encodeMessageKey(nonce_end));
            unchecked { ++i; }
        }
        require(IFeeMarket(FEE_MARKET).settle(delivery_relayers, msg.sender), "SettleFailed");
    }

    // --- Math ---
    function _min(uint64 x, uint64 y) private pure returns (uint64 z) {
        return x <= y ? x : y;
    }

    function _max(uint64 x, uint64 y) private pure returns (uint64 z) {
        return x >= y ? x : y;
    }
}
