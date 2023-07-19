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

import "../spec/LibMessage.sol";
import "../interfaces/IUserConfig.sol";
import "../interfaces/IHashOracle.sol";
import "../interfaces/IMessageVerifier.sol";
import "../utils/call/ExcessivelySafeCall.sol";

/// @title MulticastChannelIn
/// @notice Everything about incoming messages receival
/// @dev TODO
contract MulticastChannelIn is LibMessage {
    using ExcessivelySafeCall for address;

    address public config;

    /// nonce => is_message_dispathed
    mapping(uint32 => bool) public dones;
    /// nonce => failed message
    mapping(uint32 => bytes32) public fails;

    uint32 immutable public localChainId;

    /// @dev Notifies an observer that the message has dispatched
    event MessageDispatched(uint32 indexed nonce, bool dispatch_result);

    event RetryFailedMessage(uint32 indexed nonce , bool dispatch_result);

    /// @dev Deploys the ParallelInboundLane contract
    constructor(uint32 localChainId_, address config_) {
        localChainId = localChainId_;
        config = config_;
    }

    /// Receive messages proof from bridged chain.
    function recv_message(
        Message calldata message,
        bytes calldata proof
    ) external {
        Config memory uaConfig = IUserConfig(config).getAppConfig(message.fromChainId, message.to);
        bytes32 merkle_root = IHashOracle(uaConfig.oracle).merkle_root();
        // check message is from the correct source chain position
        IMessageVerifier(uaConfig.verifier).verify_message_proof(
            message.fromChainId,
            merkle_root,
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
            abi.encodePacked(message.encoded, uint256(message.nonce), uint256(message.fromChainId), message.from)
        );
    }
}
