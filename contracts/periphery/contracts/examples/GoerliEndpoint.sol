// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ethereum/AbstractEthereumEndpoint.sol";
import "../interfaces/ICrossChainFilter.sol";

contract GoerliEndpoint is
    AbstractEthereumEndpoint(
        0x5a10ca57e07133AA5132eF29BA1EBf0096a302B0,
        0xA10D0C6e04845A5e998d1936249A30563c553417
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
