// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IMessageReceiver.sol";

abstract contract AbstractMessageAdapter {
    address public remoteAdapterAddress;

    function estimateFee() external view virtual returns (uint256);

    function remoteExecute(
        address remoteAddress,
        bytes memory callData
    ) internal virtual;

    function send(
        address _localDappAddress,
        address _remoteDappAddress,
        bytes calldata _message
    ) external payable {
        // remote call `recv(from,to,message)`
        bytes memory recvCall = abi.encodeWithSignature(
            "recv(address,address,bytes)",
            _localDappAddress,
            _remoteDappAddress,
            _message
        );

        remoteExecute(remoteAdapterAddress, recvCall);
    }

    event FailedMessage(address from, address to, bytes message, string reason);

    function recv(
        address fromDappAddress,
        address toDappAddress,
        bytes memory message
    ) external {
        // this will catch all errors from user's receive function.
        try IMessageReceiver(toDappAddress).recv(fromDappAddress, message) {
            // call user's receive function successfully.
        } catch Error(string memory reason) {
            // call user's receive function failed by uncaught error.
            // store the message and error for the user to do something like retry.
            emit FailedMessage(fromDappAddress, toDappAddress, message, reason);
        } catch (bytes memory lowLevelData) {
            emit FailedMessage(
                fromDappAddress,
                toDappAddress,
                message,
                string(lowLevelData)
            );
        }
    }
}
