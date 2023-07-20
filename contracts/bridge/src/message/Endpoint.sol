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
import "../utils/call/ExcessivelySafeCall.sol";

interface IChannel {
    function send_message(
        address from,
        uint32 toChainId,
        address to,
        bytes calldata encoded
    ) external;
}

contract Endpoint is LibMessage {
    using ExcessivelySafeCall for address;

    event ClearFailedMessage(bytes32 indexed msg_hash);
    event RetryFailedMessage(bytes32 indexed msg_hash, bool dispatch_result);

    address public immutable CONFIG;
    address public immutable CHANNEL;

    /// messageId => failed message
    mapping(bytes32 => bool) public fails;

    constructor(
        address config,
        address channel
    ) {
        CONFIG = config;
        CHANNEL = channel;
    }

    function send(uint32 toChainId, address to, bytes calldata encoded, bytes calldata params) external payable {
        Config memory uaConfig = IUserConfig(CONFIG).getAppConfig(toChainId, to);
        IChannel(CHANNEL).send_message(
            msg.sender,
            toChainId,
            to,
            encoded
        );

        // uint relayerFee = _handleRelayer(toChainId, );
        // uint oracleFee = _handleOracle(toChainId, );
        // uint protocolFee = _handleProtocol();
    }

    function recv(Message calldata message) external returns (bool dispatch_result) {
        require(msg.sender == CHANNEL, "!auth");
        dispatch_result = _dispatch(message);
        if (!dispatch_result) {
            bytes32 msg_hash = hash(message);
            fails[msg_hash] = true;
        }
    }

    function clear_failed_message(Message calldata message) external {
        bytes32 msg_hash = hash(message);
        require(fails[msg_hash] == true, "InvalidFailedMessage");
        require(message.to == msg.sender, "!auth");
        delete fails[msg_hash];
        emit ClearFailedMessage(msg_hash);
    }

    /// Retry failed message
    function retry_failed_message(Message calldata message) external returns (bool dispatch_result) {
        bytes32 msg_hash = hash(message);
        require(fails[msg_hash] == true, "InvalidFailedMessage");
        dispatch_result = _dispatch(message);
        if (dispatch_result) {
            delete fails[msg_hash];
        }
        emit RetryFailedMessage(msg_hash, dispatch_result);
    }

    /// @dev dispatch the cross chain message
    function _dispatch(Message memory message) private returns (bool dispatch_result) {
        // Deliver the message to the target
        (dispatch_result,) = message.to.excessivelySafeCall(
            gasleft(),
            0,
            abi.encodePacked(message.encoded, hash(message), uint256(message.fromChainId), message.from)
        );
    }
}
