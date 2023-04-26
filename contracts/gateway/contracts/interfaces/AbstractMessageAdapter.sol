// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IMessageGateway.sol";

// adapter knows hot to send message to remote adapter.
abstract contract AbstractMessageAdapter {
    IMessageGateway public immutable localGateway;

    constructor(address _localGatewayAddress) {
        localGateway = IMessageGateway(_localGatewayAddress);
    }

    function estimateFee() external view virtual returns (uint256);

    function getRemoteAdapterAddress() public virtual returns (address);

    function remoteExecute(
        address _remoteAddress,
        bytes memory _remoteCallData
    ) internal virtual returns (uint256);

    // called by local gateway
    function epSend(
        address _fromDappAddress,
        address _toDappAddress,
        bytes calldata _message
    ) external payable returns (uint256) {
        // check this is called by local gateway
        require(
            msg.sender == address(localGateway),
            "not allowed to be called by others except local gateway"
        );
        address remoteAdapterAddress = getRemoteAdapterAddress();
        require(remoteAdapterAddress != address(0), "remote adapter not set");

        return
            remoteExecute(
                // the remote adapter
                remoteAdapterAddress,
                // the call to be executed on remote adapter
                abi.encodeWithSignature(
                    "epRecv(address,address,bytes)",
                    _fromDappAddress,
                    _toDappAddress,
                    _message
                )
            );
    }

    // called by remote adapter through low level messaging contract
    function epRecv(
        address _fromDappAddress,
        address _toDappAddress,
        bytes memory _message
    ) external {
        // call local gateway to receive message
        localGateway.recv(_fromDappAddress, _toDappAddress, _message);
    }
}
