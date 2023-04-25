// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../interfaces/AbstractMessageEndpoint.sol";
import "@darwinia/contracts-bridge/src/interfaces/IOutboundLane.sol";
import "@darwinia/contracts-bridge/src/interfaces/IFeeMarket.sol";
import "@darwinia/contracts-bridge/src/interfaces/ICrossChainFilter.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract DarwiniaEndpoint is
    AbstractMessageEndpoint,
    ICrossChainFilter,
    Ownable2Step
{
    address public remoteEndpointAddress;
    address public immutable outboundLane;
    address public immutable feeMarket;

    constructor(
        address gatewayAddress,
        address _outboundLane,
        address _feeMarket
    ) AbstractMessageEndpoint(gatewayAddress) {
        outboundLane = _outboundLane;
        feeMarket = _feeMarket;
    }

    function setRemoteEndpointAddress(
        address _remoteEndpointAddress
    ) external onlyOwner {
        remoteEndpointAddress = _remoteEndpointAddress;
    }

    //////////////////////////////////////////
    // override AbstractMessageEndpoint
    //////////////////////////////////////////
    function getRemoteEndpointAddress() public override returns (address) {
        return remoteEndpointAddress;
    }

    function remoteExecute(
        address _remoteAddress,
        bytes memory _remoteCallData
    ) internal override returns (uint256) {
        IOutboundLane(outboundLane).send_message{value: msg.value}(
            _remoteAddress,
            _remoteCallData
        );
    }

    function estimateFee() external view override returns (uint256) {
        return IFeeMarket(feeMarket).market_fee();
    }

    //////////////////////////////////////////
    // implement ICrossChainFilter
    //////////////////////////////////////////
    function cross_chain_filter(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address sourceAccount,
        bytes calldata payload
    ) external view returns (bool) {
        // check remote adapter address is set.
        // this check is not necessary, but it can provide an more understandable err.
        require(remoteEndpointAddress != address(0), "!remote adapter");

        return sourceAccount == remoteEndpointAddress;
    }
}
