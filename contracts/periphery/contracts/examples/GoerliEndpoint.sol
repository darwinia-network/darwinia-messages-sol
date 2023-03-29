// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ethereum/AbstractEthereumEndpoint.sol";
import "../interfaces/ICrossChainFilter.sol";

contract GoerliEndpoint is
    AbstractEthereumEndpoint(
        0x12225Fa4a20b13ccA0773E1D5f08BbC91f16f927, // outboundlane
        0x527560d6a509ddE7828D598BF31Fc67DA50c8093 // fee market
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
