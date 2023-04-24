// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IOutboundLane.sol";
import "../interfaces/IFeeMarket.sol";
import "../interfaces/ICrossChainFilter.sol";
import "../interfaces/AbstractMessageAdapter.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract DarwiniaAdapter is
    AbstractMessageAdapter,
    ICrossChainFilter,
    Ownable2Step
{
    address public immutable outboundLane;
    address public immutable feeMarket;

    constructor(address _outboundLane, address _feeMarket) {
        outboundLane = _outboundLane;
        feeMarket = _feeMarket;
    }

    function setRemoteAdapterAddress(
        address _remoteAdapterAddress
    ) external override onlyOwner {
        remoteAdapterAddress = _remoteAdapterAddress;
    }

    function remoteExecute(
        address remoteAddress,
        bytes memory callData
    ) internal override returns (uint256) {
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
        // check remote adapter address is set.
        // this check is not necessary, but it can provide an more understandable err.
        require(remoteAdapterAddress != address(0), "!remote adapter");

        return sourceAccount == remoteAdapterAddress;
    }
}
