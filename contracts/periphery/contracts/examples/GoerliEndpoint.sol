// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ethereum/AbstractEthereumEndpoint.sol";
import "../interfaces/ICrossChainFilter.sol";

contract GoerliEndpoint is
    AbstractEthereumEndpoint(
        0xB0322e02b9b7bD67cB071E408f73C34980D21A23,
        0xF72361096f11d7E4e45046d7a83726b1A9107D5E
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

    function setDarwiniaEndpoint(address _darwiniaEndpoint) external {
        _setDarwiniaEndpoint(_darwiniaEndpoint);
    }
}
