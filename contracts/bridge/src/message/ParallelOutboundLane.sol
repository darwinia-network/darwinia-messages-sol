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

pragma solidity 0.8.17;
pragma abicoder v2;

import "../interfaces/IOutboundLane.sol";
import "./LaneIdentity.sol";
import "../spec/SourceChain.sol";
import "../utils/imt/IncrementalMerkleTree.sol";

// Everything about outgoing messages sending.
contract ParallelOutboundLane is IOutboundLane, LaneIdentity, SourceChain {
    using IncrementalMerkleTree for IncrementalMerkleTree.Tree;
    // slot 1
    bytes32 private root;
    // slot [2, 34]
    IncrementalMerkleTree.Tree private imt;

    event MessageAccepted(uint64 indexed nonce, address source, address target, bytes encoded);

    /// @dev Deploys the OutboundLane contract
    /// @param _thisChainPosition The thisChainPosition of outbound lane
    /// @param _thisLanePosition The lanePosition of this outbound lane
    /// @param _bridgedChainPosition The bridgedChainPosition of outbound lane
    /// @param _bridgedLanePosition The lanePosition of target inbound lane
    constructor(
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition
    ) LaneIdentity (
        _thisChainPosition,
        _thisLanePosition,
        _bridgedChainPosition,
        _bridgedLanePosition
    ) {
        // init with empty tree
        root = 0x27ae5ba08d7291c96c8cbddcc148bf48a6d68c7974b94356f53754ef6171d757;
    }

    /// @dev Send message over lane.
    /// Submitter could be a contract or just an EOA address.
    /// At the beginning of the launch, submmiter is permission, after the system is stable it will be permissionless.
    /// @param target The target contract address which you would send cross chain message to
    /// @param encoded The calldata which encoded by ABI Encoding
    /// @return nonce Latest nonce
    function send_message(address target, bytes calldata encoded) external payable override returns (uint64) {
        require(msg.value == 0, "nonpayable");
        uint64 nonce = uint64(imt.count);
        Message memory message = Message(encodeMessageKey(nonce), MessagePayload({
            source: msg.sender,
            target: target,
            encoded: encoded
        }));
        bytes32 msg_hash = hash(message);
        imt.insert(msg_hash);
        root = imt.root();
        emit MessageAccepted(nonce, msg.sender, target, encoded);
        return nonce;
    }

    /// Return the commitment of lane data.
    function commitment() external view returns (bytes32) {
        return root;
    }

    function message_size() public view returns (uint64) {
        return uint64(imt.count);
    }

    function imt_branch() public view returns (bytes32[32] memory) {
        return imt.branch;
    }

    // 32 bytes to identify an unique message from source chain
    // MessageKey encoding:
    // ThisChainPosition | ThisLanePosition | BridgedChainPosition | BridgedLanePosition | Nonce
    // [0..8)   bytes ---- Reserved
    // [8..12)  bytes ---- ThisChainPosition
    // [16..20) bytes ---- ThisLanePosition
    // [12..16) bytes ---- BridgedChainPosition
    // [20..24) bytes ---- BridgedLanePosition
    // [24..32) bytes ---- Nonce, max of nonce is `uint64(-1)`
    function encodeMessageKey(uint64 nonce) public view override returns (uint256) {
        Slot0 memory _slot0 = slot0;
        return (uint256(_slot0.this_chain_pos) << 160) +
                (uint256(_slot0.this_lane_pos) << 128) +
                (uint256(_slot0.bridged_chain_pos) << 96) +
                (uint256(_slot0.bridged_lane_pos) << 64) +
                uint256(nonce);
    }
}
