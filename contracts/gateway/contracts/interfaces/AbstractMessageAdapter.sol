// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IMsgport.sol";

// adapter knows hot to send message to remote adapter.
abstract contract AbstractMessageAdapter {
    IMsgport public immutable localMsgport;

    constructor(address _localMsgportAddress) {
        localMsgport = IMsgport(_localMsgportAddress);
    }

    ////////////////////////////////////////
    // Abstract functions
    ////////////////////////////////////////
    // For receiving
    function permitted(
        address _fromDappAddress,
        address _toDappAddress,
        bytes memory _message
    ) internal virtual returns (bool);

    // For sending
    function remoteExecute(
        address _remoteAddress,
        bytes memory _remoteCallData
    ) internal virtual returns (uint256);

    function getRemoteAdapterAddress() public virtual returns (address);

    function getRelayFee(
        address _fromDappAddress,
        bytes memory _messagePayload
    ) external view virtual returns (uint256);

    function getDeliveryGas(
        address _fromDappAddress,
        bytes memory _messagePayload
    ) external view virtual returns (uint256);

    ////////////////////////////////////////
    // Public functions
    ////////////////////////////////////////
    // called by local msgport
    function send(
        address _fromDappAddress,
        address _toDappAddress,
        bytes calldata _message
    ) external payable returns (uint256) {
        // check this is called by local msgport
        require(
            msg.sender == address(localMsgport),
            "not allowed to be called by others except local msgport"
        );
        address remoteAdapterAddress = getRemoteAdapterAddress();
        require(remoteAdapterAddress != address(0), "remote adapter not set");

        return
            remoteExecute(
                // the remote adapter
                remoteAdapterAddress,
                // the call to be executed on remote adapter
                abi.encodeWithSignature(
                    "recv(address,address,bytes)",
                    _fromDappAddress,
                    _toDappAddress,
                    _message
                )
            );
    }

    // called by remote adapter through low level messaging contract
    function recv(
        address _fromDappAddress,
        address _toDappAddress,
        bytes memory _message
    ) external {
        require(
            permitted(_fromDappAddress, _toDappAddress, _message),
            "!permitted"
        );

        // call local msgport to receive message
        localMsgport.recv(_fromDappAddress, _toDappAddress, _message);
    }
}
