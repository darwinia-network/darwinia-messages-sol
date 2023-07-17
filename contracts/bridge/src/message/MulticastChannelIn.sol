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

pragma solidity 0.8.17;

import "../interfaces/ICrossChainFilter.sol";
import "../utils/imt/IncrementalMerkleTree.sol";
import "../utils/call/ExcessivelySafeCall.sol";

struct Message {
    uint32 fromChainId;
    address from;
    uint32 nonce;
    uint32 toChainId;
    address to;
    bytes encoded;
}

struct Proof {
    bytes[] accountProof;
    bytes[] imtRootProof;
    uint256 messageIndex;
    bytes32[32] messageProof;
}

interface IVerifier {
    function verify_message_proof(
        uint32 fromChainId,
        bytes32 msg_root,
        Proof calldata proof
    ) external view returns (bool);
}

/// @title MulticastChannelIn
/// @notice Everything about incoming messages receival
/// @dev TODO
contract MulticastChannelIn {
    using ExcessivelySafeCall for address;

    address public verifier;

    /// nonce => is_message_dispathed
    mapping(uint64 => bool) public dones;
    /// nonce => failed message
    mapping(uint64 => bytes32) public fails;

    uint32 immutable public localChainId;

    /// @dev Notifies an observer that the message has dispatched
    /// @param nonce The message nonce
    event MessageDispatched(uint64 indexed nonce, bool dispatch_result);

    event RetryFailedMessage(uint64 indexed nonce , bool dispatch_result);

    /// @dev Deploys the ParallelInboundLane contract
    constructor(uint32 localChainId_, address verifier_) {
        verifier = verifier_;
        localChainId = localChainId_;
    }

    /// Receive messages proof from bridged chain.
    function recv_message(
        uint32 fromChainId,
        Message memory message,
        Proof calldata proof
    ) external {
        // check message is from the correct source chain position
        require(fromChainId == message.fromChainId, "InvalidSourceChainId");
        IVerifier(verifier).verify_message_proof(
            fromChainId,
            hash(message),
            proof
        );
        _receive_message(message);
    }

    /// Retry failed message
    function retry_failed_message(Message calldata message) external returns (bool dispatch_result) {
        require(fails[message.nonce] == hash(message), "InvalidFailedMessage");
        dispatch_result = _dispatch(message);
        if (dispatch_result) {
            delete fails[message.nonce];
        }
        emit RetryFailedMessage(message.nonce, dispatch_result);
    }

    /// Receive new message.
    function _receive_message(Message memory message) private {
        // check message delivery to the correct target lane position
        require(localChainId == message.toChainId, "InvalidTargetLaneId");

        require(dones[message.nonce] == false, "done");
        dones[message.nonce] = true;

        // then, dispatch message
        bool dispatch_result = _dispatch(message);
        if (!dispatch_result) {
            fails[message.nonce] = hash(message);
        }
        emit MessageDispatched(message.nonce, dispatch_result);
    }

    /// @dev dispatch the cross chain message
    function _dispatch(Message memory message) private returns (bool dispatch_result) {
        // Deliver the message to the target
        (dispatch_result,) = message.to.excessivelySafeCall(
            gasleft(),
            0,
            abi.encodePacked(message.encoded, uint256(message.nonce), message.fromChainId, message.from)
        );
    }

    function hash(Message memory message) internal pure returns (bytes32) {
        return keccak256(abi.encode(message));
    }
}
