// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../darwinia/AbstractDarwiniaEndpoint.sol";
import "../interfaces/ICrossChainFilter.sol";

contract Pangolin2Endpoint is
    AbstractDarwiniaEndpoint(
        0x2100, // _sendCallIndex
        0xe520, // _darwiniaParaId
        0xAbd165DE531d26c229F9E43747a8d683eAD54C6c, // _toEthereumOutboundLane
        0x4DBdC9767F03dd078B5a1FC05053Dd0C071Cc005 // _toEthereumFeeMarket
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
