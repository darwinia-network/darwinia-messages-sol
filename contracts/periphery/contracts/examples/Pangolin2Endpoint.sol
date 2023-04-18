// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../darwinia/AbstractDarwiniaEndpoint.sol";
import "../interfaces/ICrossChainFilter.sol";

contract Pangolin2Endpoint is
    AbstractDarwiniaEndpoint(
        0x2100, // _sendCallIndex
        0xe520, // _darwiniaParaId
        0xcF2A32c182A73D93fBa0C5e515e3C5ec7944a471, // _toEthereumOutboundLane
        0x43d6711EB86C852Ec1E04af55C52a0dd51b2C743 // _toEthereumFeeMarket
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
