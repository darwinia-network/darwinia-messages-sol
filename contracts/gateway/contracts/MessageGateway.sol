// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./interfaces/IMessageGateway.sol";
import "./interfaces/IMessageReceiver.sol";
import "./interfaces/AbstractMessageEndpoint.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract MessageGateway is IMessageGateway, Ownable2Step {
    mapping(uint16 => address) public endpoints;
    mapping(address => uint16) public endpointIds;
    uint16 public endpointCount;
    address public defaultEndpoint;
    uint16 public immutable chainId;

    event FailedMessage(address, uint16, address, bytes, string);

    constructor(uint16 _chainId) {
        chainId = _chainId;
    }

    function addEndpoint(address _endpointAddress) external onlyOwner {
        uint16 endpointId = endpointCount == 0 ? 1 : endpointCount + 1;
        endpoints[endpointId] = _endpointAddress;
        endpointIds[_endpointAddress] = endpointId;

        // set default endpoint immediately.
        setDefaultEndpoint(_endpointAddress);

        endpointCount++;
    }

    function setDefaultEndpoint(address _endpointAddress) public onlyOwner {
        // check endpoint id exists.
        require(endpointIds[_endpointAddress] != 0, "endpoint not exists");

        defaultEndpoint = _endpointAddress;
    }

    function estimateFee() external view returns (uint256) {
        AbstractMessageEndpoint endpoint = AbstractMessageEndpoint(
            defaultEndpoint
        );
        return endpoint.estimateFee();
    }

    // called by Dapp.
    function mgSend(
        uint16 _toChainId,
        address _toDappAddress,
        bytes memory _message
    ) external payable returns (uint256) {
        AbstractMessageEndpoint endpoint = AbstractMessageEndpoint(
            defaultEndpoint
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
            AbstractMessageEndpoint endpoint = AbstractMessageEndpoint(
                defaultEndpoint
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
