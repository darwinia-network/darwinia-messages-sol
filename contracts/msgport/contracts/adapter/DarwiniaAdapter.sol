// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../interfaces/AbstractMessageAdapter.sol";
import "@darwinia/contracts-bridge/src/interfaces/IOutboundLane.sol";
import "@darwinia/contracts-bridge/src/interfaces/IFeeMarket.sol";
import "@darwinia/contracts-bridge/src/interfaces/ICrossChainFilter.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract DarwiniaAdapter is
    AbstractMessageAdapter,
    ICrossChainFilter,
    Ownable2Step
{
    address public remoteAdapterAddress;
    address public immutable outboundLane;
    address public immutable inboundLane;
    address public immutable feeMarket;

    constructor(
        address gatewayAddress,
        address _outboundLane,
        address _inboundLane,
        address _feeMarket
    ) AbstractMessageAdapter(gatewayAddress) {
        outboundLane = _outboundLane;
        inboundLane = _inboundLane;
        feeMarket = _feeMarket;
    }

    function setRemoteAdapterAddress(
        address _remoteAdapterAddress
    ) external onlyOwner {
        remoteAdapterAddress = _remoteAdapterAddress;
    }

    //////////////////////////////////////////
    // override AbstractMessageAdapter
    //////////////////////////////////////////
    function getRemoteAdapterAddress() public view override returns (address) {
        return remoteAdapterAddress;
    }

    function getRelayFee(
        address _fromDappAddress,
        bytes memory _messagePayload
    ) external view override returns (uint256) {
        return IFeeMarket(feeMarket).market_fee();
    }

    function getDeliveryGas(
        address _fromDappAddress,
        bytes memory _messagePayload
    ) external view override returns (uint256) {
        return 0;
    }

    // For sending
    function remoteExecute(
        address _remoteAddress,
        bytes memory _remoteCallData
    ) internal override returns (uint256) {
        return
            IOutboundLane(outboundLane).send_message{value: msg.value}(
                _remoteAddress,
                _remoteCallData
            );
    }

    // For receiving
    function permitted(
        address _fromDappAddress,
        address _toDappAddress,
        bytes memory _message
    ) internal view override returns (bool) {
        require(msg.sender == inboundLane, "!inboundLane");
        return true;
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
        require(remoteAdapterAddress != address(0), "!remote adapter");

        return sourceAccount == remoteAdapterAddress;
    }
}
