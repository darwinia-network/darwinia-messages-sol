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

import "../interfaces/IOutboundLane.sol";
import "./OutboundLaneVerifier.sol";
import "../utils/IncrementalMerkleTree.sol";

// Everything about outgoing messages sending.
contract OutboundLaneUDP is IOutboundLane, OutboundLaneVerifier {
    using IncrementalMerkleTree for IncrementalMerkleTree.Tree
    /// slot 1
    bytes32 public root;
    /// slot [2, 34]
    IncrementalMerkleTree.Tree public imt;

    event MessageAccepted(uint64 indexed nonce, address source, address target, bytes encoded);

    /// @dev Deploys the OutboundLane contract
    /// @param _lightClientBridge The contract address of on-chain light client
    /// @param _thisChainPosition The thisChainPosition of outbound lane
    /// @param _thisLanePosition The lanePosition of this outbound lane
    /// @param _bridgedChainPosition The bridgedChainPosition of outbound lane
    /// @param _bridgedLanePosition The lanePosition of target inbound lane
    /// @param _latest_nonce The latest_nonce of outbound lane
    constructor(
        address _lightClientBridge,
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition
    ) OutboundLaneVerifier(
        _lightClientBridge,
        _thisChainPosition,
        _thisLanePosition,
        _bridgedChainPosition,
        _bridgedLanePosition
    ) {}

    /// @dev Send message over lane.
    /// Submitter could be a contract or just an EOA address.
    /// At the beginning of the launch, submmiter is permission, after the system is stable it will be permissionless.
    /// @param target The target contract address which you would send cross chain message to
    /// @param encoded The calldata which encoded by ABI Encoding
    /// @return nonce Latest nonce
    function send_message(address target, bytes calldata encoded) external override returns (uint64) {
        uint32 nonce = tree.count + 1;
        uint encoded_key = encodeMessageKey(nonce);
        MessagePayload memory payload = MessagePayload({
            key: encoded_key,
            source: msg.sender,
            target: target,
            encoded: encoded
        });
        bytes32 msg_hash = hash(payload);
        imt.insert(msg_hash);
        root = imt.root();
        emit MessageAccepted(
            nonce_,
            msg.sender,
            target,
            encoded);
        return nonce_;
    }

    /// Return the commitment of lane data.
    function commitment() external view returns (bytes32) {
        return root;
    }

    function message_size() public view returns (uint64 size) {
        size = imt.count();
    }
}
