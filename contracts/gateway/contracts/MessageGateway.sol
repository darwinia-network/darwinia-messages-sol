// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./interfaces/IMessageGateway.sol";
import "./interfaces/IMessageReceiver.sol";
import "./interfaces/AbstractMessageEndpoint.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract MessageGateway is IMessageGateway, Ownable2Step {
    // TODO: multiple endpoints for a chain.
    // TODO: default endpoint for a chain.
    // TODO: dapp registry. dapp config
    // chainid => endpoint
    mapping(uint16 => address) public endpoints;
    uint16 public immutable chainId;

    event FailedMessage(address, uint16, address, bytes, string);

    constructor(uint16 _chainId) {
        chainId = _chainId;
    }

    function updateEndpoint(
        uint16 _chainId,
        address _endpointAddress
    ) external onlyOwner {
        endpoints[_chainId] = _endpointAddress;
    }

    function estimateFee(uint16 _toChainId) external view returns (uint256) {
        address endpointAddress = endpoints[_toChainId];
        require(endpointAddress != address(0), "endpoint not set");

        AbstractMessageEndpoint endpoint = AbstractMessageEndpoint(
            endpointAddress
        );
        return endpoint.estimateFee();
    }

    // called by Dapp.
    function mgSend(
        uint16 _toChainId,
        address _toDappAddress,
        bytes memory _message
    ) external payable returns (uint256) {
        address endpointAddress = endpoints[_toChainId];
        require(endpointAddress != address(0), "endpoint not set");

        AbstractMessageEndpoint endpoint = AbstractMessageEndpoint(
            endpointAddress
        );
        uint256 fee = endpoint.estimateFee();

        // TODO: add dapp registry.

        uint256 paid = msg.value;
        require(paid >= fee, "!fee");

        // refund fee to caller if paid too much.
        if (paid > fee) {
            payable(msg.sender).transfer(paid - fee);
        }

        return
            endpoint.epSend{value: fee}(
                msg.sender,
                _toChainId,
                _toDappAddress,
                _message
            );
    }

    // called by endpoint.
    function mgRecv(
        address _fromDappAddress,
        uint16 _toChainId,
        address _toDappAddress,
        bytes memory _message
    ) external {
        if (_toChainId == chainId) {
            // message arrived the destination
            try
                IMessageReceiver(_toDappAddress).recv(
                    _fromDappAddress,
                    _message
                )
            {
                // call user's receive function successfully.
            } catch Error(string memory reason) {
                // call user's receive function failed by uncaught error.
                // store the message and error for the user to do something like retry.
                emit FailedMessage(
                    _fromDappAddress,
                    _toChainId,
                    _toDappAddress,
                    _message,
                    reason
                );
            } catch (bytes memory lowLevelData) {
                emit FailedMessage(
                    _fromDappAddress,
                    _toChainId,
                    _toDappAddress,
                    _message,
                    string(lowLevelData)
                );
            }
        } else {
            // direct message to another chain, (routing)
            address endpointAddress = endpoints[_toChainId];
            require(endpointAddress != address(0), "endpoint not set");

            AbstractMessageEndpoint endpoint = AbstractMessageEndpoint(
                endpointAddress
            );
            uint256 fee = endpoint.estimateFee();

            // TODO: add dapp setting
            endpoint.epSend{value: fee}(
                _fromDappAddress,
                _toChainId,
                _toDappAddress,
                _message
            );
        }
    }
}
