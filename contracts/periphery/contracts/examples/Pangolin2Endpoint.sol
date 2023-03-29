// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../darwinia/AbstractDarwiniaEndpoint.sol";
import "../interfaces/ICrossChainFilter.sol";

contract Pangolin2Endpoint is
    AbstractDarwiniaEndpoint(
        0x2100, // _sendCallIndex
        0xe520, // _darwiniaParaId
        0x721F10bdE716FF44F596Afa2E8726aF197e6218E, // _toEthereumOutboundLane
        0x9FbA8f0a0Bd6CbcB6283c042edc6b20894Be09c8 // _toEthereumFeeMarket
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
}
