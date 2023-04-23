// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IOutboundLane.sol";
import "./interfaces/IFeeMarket.sol";
import "./interfaces/ICrossChainFilter.sol";
import "./interfaces/AbstractMessageAdapter.sol";

contract DarwiniaAdapter is AbstractMessageAdapter, ICrossChainFilter {
    address public immutable outboundLane;
    address public immutable feeMarket;

    constructor(
        address _remoteAdapterAddress,
        address _outboundLane,
        address _feeMarket
    ) AbstractMessageAdapter(_remoteAdapterAddress) {
        outboundLane = _outboundLane;
        feeMarket = _feeMarket;
    }

    function remoteExecute(
        address remoteAddress,
        bytes memory callData
    ) internal override {
        IOutboundLane(outboundLane).send_message{value: msg.value}(
            remoteAddress,
            callData
        );
    }

    function estimateFee() external view override returns (uint256) {
        return IFeeMarket(feeMarket).market_fee();
    }

    function cross_chain_filter(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address sourceAccount,
        bytes calldata payload
    ) external view returns (bool) {
        return true;
    }
}
