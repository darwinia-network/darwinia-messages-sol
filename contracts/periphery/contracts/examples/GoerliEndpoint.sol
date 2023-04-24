// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ethereum/AbstractEthereumEndpoint.sol";
import "../interfaces/ICrossChainFilter.sol";

contract GoerliEndpoint is
    AbstractEthereumEndpoint(
        0x9B5010d562dDF969fbb85bC72222919B699b5F54, // outboundlane
        0x6c73B30a48Bb633DC353ed406384F73dcACcA5C3 // fee market
    )
{
    function cross_chain_filter(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address sourceAccount,
        bytes calldata payload
    ) external view returns (bool) {
        return true;
    }

    // Set darwinia endpoint as its remote endpoint.
    function setRemoteEndpoint(address _darwiniaEndpoint) external {
        _setRemoteEndpoint(_darwiniaEndpoint);
    }
}
