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

import "../../interfaces/ICrossChainFilter.sol";
import "../../interfaces/IOutboundLane.sol";
import "../../spec/SourceChain.sol";

contract MessageGateway is SourceChain {
    address public dao;
    address public xMessageGateway;
    address public outboundLane;
    address public inboundLane;

    struct GatewayMessage {
        address caller;
        address callee;
        bytes appData;
    }

    event MessageDispatched(uint64 nonce, bool result);

    modifier onlyDao {
        require(dao == msg.sender, "!dao");
        _;
    }

    modifier onlyOutboundLane {
        require(outboundLane == msg.sender, "!outboundLane");
        _;
    }

    constructor(
        address _dao,
        address _xMessageGateway,
        address _outboundLane,
        address _inboundLane
    ) {
        dao = _dao;
        xMessageGateway = _xMessageGateway;
        outboundLane = _outboundLane;
        inboundLane = _inboundLane;
    }

    function setDao(address _dao) external onlyDao {
        dao = _dao;
    }

    function setXMessageGateway(address _xMessageGateway) external onlyDao {
        xMessageGateway = _xMessageGateway;
    }

    function setLanes(address _outboundLane, address _inboundLane) external onlyDao {
        outboundLane = _outboundLane;
        inboundLane = _inboundLane;
    }

    function send_message(address target, bytes calldata encoded) external payable returns (uint64) {
        GatewayMessage memory gateway_message = GatewayMessage({
            caller: msg.sender,
            callee: target,
            appData: encoded
        });
        return IOutboundLane(outboundLane).send_message(xMessageGateway, abi.encode(gateway_message));
    }

    function receive_message(Message calldata message) external onlyOutboundLane returns (bool) {
        _dispatch(message);
        return true;
    }

    /// @dev dispatch the cross chain message
    /// @param message the dispatch message
    /// @return dispatch_result the dispatch call result
    /// - Return True:
    ///   1. filter return True and dispatch call successfully
    /// - Return False:
    ///   1. filter return False
    ///   2. filter return True and dispatch call failed
    function _dispatch(Message memory message) private returns (bool dispatch_result) {
        MessageKey memory key = decodeMessageKey(message.encoded_key);
        MessagePayload memory payload = message.payload;
        require(xMessageGateway == payload.source, "!source");
        require(address(this) == payload.target, "!targe");
        GatewayMessage memory gateway_message = abi.decode(payload.encoded, (GatewayMessage));
        bool ok = ICrossChainFilter(gateway_message.callee).cross_chain_filter(
            key.bridged_chain_pos,
            key.bridged_lane_pos,
            gateway_message.caller,
            gateway_message.appData
        );

        if (ok) {
            // Deliver the message to the target
            // Custome gateway could store the message and retry
            (ok,) = gateway_message.callee.call(gateway_message.appData);
        }
        emit MessageDispatched(key.nonce, ok);
    }

    /// @dev filter the cross chain message
    /// @dev The app layer must implement the interface `ICrossChainFilter`
    /// to verify the source sender and payload of source chain messages.
    /// @param target target of the dispatch message
    /// @param encoded encoded calldata of the dispatch message
    /// @return canCall the filter static call result, Return True only when target contract
    /// implement the `ICrossChainFilter` interface with return data is True.
    function _filter(address target, bytes memory encoded) private view returns (bool canCall) {

        (bool ok, bytes memory result) = target.staticcall(encoded);
        if (ok) {
            if (result.length == 32) {
                canCall = abi.decode(result, (bool));
            }
        }
    }
}
