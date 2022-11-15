// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "../munged/OutboundLane.f.sol";

contract OutboundLaneHarness is OutboundLane {

    constructor(
        address _lightClientBridge,
        address _feeMarket,
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition,
        uint64 _oldest_unpruned_nonce,
        uint64 _latest_received_nonce,
        uint64 _latest_generated_nonce
    ) OutboundLane (
        _lightClientBridge,
        _feeMarket,
        _thisChainPosition,
        _thisLanePosition,
        _bridgedChainPosition,
        _bridgedLanePosition,
        _oldest_unpruned_nonce,
        _latest_received_nonce,
        _latest_generated_nonce
    ) {}
}
