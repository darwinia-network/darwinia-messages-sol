// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ethereum/AbstractEthereumEndpoint.sol";
import "../interfaces/ICrossChainFilter.sol";

contract GoerliEndpoint is
    AbstractEthereumEndpoint(
        0x21D4A3c5390D098073598d30FD49d32F9d9E355E, // outboundlane
        0xecB07f26F2E7028A7090cF6419116A9D11c36054 // fee market
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
