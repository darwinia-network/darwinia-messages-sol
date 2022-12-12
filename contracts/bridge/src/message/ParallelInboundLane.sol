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
import "../spec/SourceChain.sol";
import "../utils/imt/IncrementalMerkleTree.sol";
import "../utils/call/ExcessivelySafeCall.sol";

/// @title Everything about incoming messages receival
contract ParallelInboundLane is InboundLaneVerifier, SourceChain {
    using ExcessivelySafeCall for address;

    /// nonce => is_message_dispathed
    mapping(uint64 => bool) public dones;
    /// nonce => failed message
    mapping(uint64 => bytes32) public fails;

    /// @dev Notifies an observer that the message has dispatched
    /// @param nonce The message nonce
    event MessageDispatched(uint64 indexed nonce, bool dispatch_result);

    event RetryFailedMessage(uint64 indexed nonce , bool dispatch_result);

    /// @dev Deploys the InboundLane contract
    /// @param _verifier The contract address of on-chain verifier
    /// @param _thisChainPosition The thisChainPosition of inbound lane
    /// @param _thisLanePosition The lanePosition of this inbound lane
    /// @param _bridgedChainPosition The bridgedChainPosition of inbound lane
    /// @param _bridgedLanePosition The lanePosition of target outbound lane
    constructor(
        address _verifier,
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition
    ) InboundLaneVerifier(
        _verifier,
        _thisChainPosition,
        _thisLanePosition,
        _bridgedChainPosition,
        _bridgedLanePosition
    ) {}

    /// Receive messages proof from bridged chain.
    function receive_message(
        bytes32 outlane_data_hash,
        bytes memory lane_proof,
        Message memory message,
        bytes32[32] calldata message_proof
    ) external {
        _verify_messages_proof(outlane_data_hash, lane_proof);
        _receive_message(message, outlane_data_hash, message_proof);
    }

    /// Retry failed message
    function retry_failed_message(Message calldata message) external returns (bool dispatch_result) {
        MessageKey memory key = decodeMessageKey(message.encoded_key);
        require(fails[key.nonce] == hash(message), "InvalidFailedMessage");
        dispatch_result = _dispatch(message.payload);
        if (dispatch_result) {
            delete fails[key.nonce];
        }
        emit RetryFailedMessage(key.nonce, dispatch_result);
    }

    function _verify_message(
        bytes32 root,
        bytes32 leaf,
        uint256 index,
        bytes32[32] calldata proof
    ) internal pure returns (bool) {
        return root == IncrementalMerkleTree.branchRoot(leaf, proof, index);
    }

    /// Return the commitment of lane data.
    function commitment() external pure returns (bytes32) {
        return bytes32(0);
    }

    /// Receive new message.
    function _receive_message(Message memory message, bytes32 outlane_data_hash, bytes32[32] calldata message_proof) private {
        MessageKey memory key = decodeMessageKey(message.encoded_key);
        Slot0 memory _slot0 = slot0;
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

        _verify_message(outlane_data_hash, hash(message), key.nonce, message_proof);

        MessagePayload memory message_payload = message.payload;
        // then, dispatch message
        bool dispatch_result = _dispatch(message_payload);
        if (!dispatch_result) {
            fails[key.nonce] = hash(message);
        }
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
            (dispatch_result,) = payload.target.excessivelySafeCall(
                gasleft(),
                0,
                payload.encoded
            );
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
        (bool ok, bytes memory result) = target.excessivelySafeStaticCall(
            gasleft(),
            32,
            encoded
        );
        if (ok) {
            if (result.length == 32) {
                canCall = abi.decode(result, (bool));
            }
        }
    }
}
