// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IOutboundLane.sol";
import "./interfaces/IFeeMarket.sol";
import "./interfaces/ICrossChainFilter.sol";
import "./interfaces/AbstractMessageAdapter.sol";

contract DarwiniaAdapter is AbstractMessageAdapter, ICrossChainFilter {
    address public outboundLane;
    address public feeMarket;
    address public remoteDarwiniaAdapterAddress;

    constructor(
        address _outboundLane,
        address _feeMarket,
        address _remoteDarwiniaAdapterAddress
    ) {
        outboundLane = _outboundLane;
        feeMarket = _feeMarket;
        remoteDarwiniaAdapterAddress = _remoteDarwiniaAdapterAddress;
    }

    function remoteExecuteRecvCall(
        bytes memory recvCallData
    ) internal override {
        IOutboundLane(outboundLane).send_message{value: msg.value}(
            remoteDarwiniaAdapterAddress,
            recvCallData
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
