// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./interfaces/IMessageGateway.sol";
import "./interfaces/IMessageReceiver.sol";
import "./interfaces/AbstractMessageAdapter.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract MessageGateway is IMessageGateway, Ownable2Step {
    address public adapterAddress;

    function setAdapter(address _adapterAddress) external onlyOwner {
        adapterAddress = _adapterAddress;
    }

    function estimateFee() external view returns (uint256) {
        AbstractMessageAdapter endpoint = AbstractMessageAdapter(
            adapterAddress
        );
        return endpoint.estimateFee();
    }

    // called by Dapp.
    function send(
        address _toDappAddress,
        bytes memory _message
    ) external payable returns (uint256) {
        AbstractMessageAdapter endpoint = AbstractMessageAdapter(
            adapterAddress
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
            endpoint.epSend{value: fee}(msg.sender, _toDappAddress, _message);
    }

    event ReceivedMessage(address, address, bytes);

    // called by endpoint.
    function recv(
        address _fromDappAddress,
        address _toDappAddress,
        bytes memory _message
    ) external {
        try IMessageReceiver(_toDappAddress).recv(_fromDappAddress, _message) {
            // call user's receive function successfully.
        } catch Error(string memory reason) {
            // call user's receive function failed by uncaught error.
            // store the message and error for the user to do something like retry.
            emit FailedMessage(
                _fromDappAddress,
                _toDappAddress,
                _message,
                reason
            );
        } catch (bytes memory lowLevelData) {
            emit FailedMessage(
                _fromDappAddress,
                _toDappAddress,
                _message,
                string(lowLevelData)
            );
        }
    }
}
