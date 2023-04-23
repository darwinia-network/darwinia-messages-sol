// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/ICrossChainFilter.sol";
import "./interfaces/IMessageGateway.sol";

contract DarwiniaReceivingService is
    ICrossChainFilter,
    IMessageReceivingService
{
    address public gateway;

    function cross_chain_filter(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address sourceAccount,
        bytes calldata payload
    ) external view returns (bool) {
        return true;
    }

    function recv(
        address fromDapp,
        address toDapp,
        bytes memory message
    ) external {
        IMessageGateway(gateway).recv(fromDapp, toDapp, message);
    }
}
