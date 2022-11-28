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
// 3) the messages hash are stored in the storage(IMT/SMT);
// 4) external component (relay) delivers messages to bridged chain;
// 5) messages are processed disorderly;
//
// Once message is sent, its progress can be tracked by looking at lane contract events.
// The assigned nonce is reported using `MessageAccepted` event. When message is
// delivered to the the bridged chain, it is reported using `MessagesDelivered` event.

pragma solidity 0.7.6;
pragma abicoder v2;

import "../interfaces/ICrossChainFilter.sol";
import "./InboundLaneVerifier.sol";

/// @title Everything about incoming messages receival
/// @author echo
/// @notice The inbound lane is the message layer of the bridge
/// @dev See https://itering.notion.site/Basic-Message-Channel-c41f0c9e453c478abb68e93f6a067c52
contract InboundLaneUDP is InboundLaneVerifier {
    /// slot 1
    mapping(uint32 => bool) dones;

    /// @dev Notifies an observer that the message has dispatched
    /// @param nonce The message nonce
    /// @param result The message result
    event MessageDispatched(uint64 nonce, bool result);

    /// @dev Deploys the InboundLane contract
    /// @param _lightClientBridge The contract address of on-chain light client
    /// @param _thisChainPosition The thisChainPosition of inbound lane
    /// @param _thisLanePosition The lanePosition of this inbound lane
    /// @param _bridgedChainPosition The bridgedChainPosition of inbound lane
    /// @param _bridgedLanePosition The lanePosition of target outbound lane
    constructor(
        address _lightClientBridge,
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition,
    ) InboundLaneVerifier(
        _lightClientBridge,
        _thisChainPosition,
        _thisLanePosition,
        _bridgedChainPosition,
        _bridgedLanePosition
    ) {}

    /// Receive messages proof from bridged chain.
    ///
    /// The weight of the call assumes that the transaction always brings outbound lane
    /// state update. Because of that, the submitter (relayer) has no benefit of not including
    /// this data in the transaction, so reward confirmations lags should be minimal.
    function receive_messages_proof(
        OutboundLaneData memory outboundLaneData,
        bytes memory messagesProof,
    ) external nonReentrant {
        _verify_messages_proof(hash(outboundLaneData), messagesProof);
        _receive_message(outboundLaneData.messages);
    }

    /// Return the commitment of lane data.
    function commitment() external view returns (bytes32) {
        return bytes32(0);
    }

    /// Get lane data from the storage.
    function data() public view returns (InboundLaneData memory lane_data) {
        uint64 size = _relayers_size();
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

    function _relayers_size() private view returns (uint64 size) {
        if (inboundLaneNonce.relayer_range_back >= inboundLaneNonce.relayer_range_front) {
            size = inboundLaneNonce.relayer_range_back - inboundLaneNonce.relayer_range_front + 1;
        }
    }

    function _relayers_back() private view returns (address pre_relayer) {
        if (_relayers_size() > 0) {
            uint64 back = inboundLaneNonce.relayer_range_back;
            pre_relayer = relayers[back].relayer;
        }
    }

    /// Receive new message.
    function _receive_message(Message memory message) private {
        MessageKey memory key = decodeMessageKey(message.encoded_key);
        Slot0 memory _slot0 = slot0;
        // check message nonce is correct and increment nonce for replay protection
        require(key.nonce == next, "InvalidNonce");
        // check message is from the correct source chain position
        require(key.this_chain_pos == _slot0.bridged_chain_pos, "InvalidSourceChainId");
        // check message is from the correct source lane position
        require(key.this_lane_pos == _slot0.bridged_lane_pos, "InvalidSourceLaneId");
        // check message delivery to the correct target chain position
        require(key.bridged_chain_pos == _slot0.this_chain_pos, "InvalidTargetChainId");
        // check message delivery to the correct target lane position
        require(key.bridged_lane_pos == _slot0.this_lane_pos, "InvalidTargetLaneId");

        require(dones[key.nonce] == false, "done");
        dones[key.nonce] = true;

        MessagePayload memory message_payload = message.payload;
        // then, dispatch message
        bool dispatch_result = _dispatch(message_payload);
        emit MessageDispatched(key.nonce, dispatch_result);
    }

    /// @dev dispatch the cross chain message
    /// @param payload payload of the dispatch message
    /// @return dispatch_result the dispatch call result
    /// - Return True:
    ///   1. filter return True and dispatch call successfully
    /// - Return False:
    ///   1. filter return False
    ///   2. filter return True and dispatch call failed
    function _dispatch(MessagePayload memory payload) private returns (bool dispatch_result) {
        Slot0 memory _slot0 = slot0;
        bytes memory filterCallData = abi.encodeWithSelector(
            ICrossChainFilter.cross_chain_filter.selector,
            _slot0.bridged_chain_pos,
            _slot0.bridged_lane_pos,
            payload.source,
            payload.encoded
        );
        if (_filter(payload.target, filterCallData)) {
            // Deliver the message to the target
            (dispatch_result,) = payload.target.call{gas: MAX_GAS_PER_MESSAGE}(payload.encoded);
        }
    }

    /// @dev filter the cross chain message
    /// @dev The app layer must implement the interface `ICrossChainFilter`
    /// to verify the source sender and payload of source chain messages.
    /// @param target target of the dispatch message
    /// @param encoded encoded calldata of the dispatch message
    /// @return canCall the filter static call result, Return True only when target contract
    /// implement the `ICrossChainFilter` interface with return data is True.
    function _filter(address target, bytes memory encoded) private view returns (bool canCall) {
        (bool ok, bytes memory result) = target.staticcall{gas: GAS_BUFFER}(encoded);
        if (ok) {
            if (result.length == 32) {
                canCall = abi.decode(result, (bool));
            }
        }
    }
}
