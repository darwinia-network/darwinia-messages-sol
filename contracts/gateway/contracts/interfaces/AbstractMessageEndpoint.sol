// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IMessageGateway.sol";

// endpoint knows hot to send message to remote adapter.
abstract contract AbstractMessageEndpoint {
    IMessageGateway public immutable localGateway;

    constructor(address _localGatewayAddress) {
        localGateway = IMessageGateway(_localGatewayAddress);
    }

    event FailedMessage(address from, address to, bytes message, string reason);

    function estimateFee() external view virtual returns (uint256);

    function getRemoteEndpointAddress() public virtual returns (address);

    function remoteExecute(
        address _remoteAddress,
        bytes memory _remoteCallData
    ) internal virtual returns (uint256);

    // called by local gateway
    function epSend(
        address _fromDappAddress,
        uint16 _toChainId,
        address _toDappAddress,
        bytes calldata _message
    ) external payable returns (uint256) {
        // check this is called by local gateway
        require(
            msg.sender == address(localGateway),
            "not allowed to be called by others except local gateway"
        );
        address remoteEndpointAddress = getRemoteEndpointAddress();
        require(remoteEndpointAddress != address(0), "remote endpoint not set");

        return
            remoteExecute(
                // the remote endpoint
                remoteEndpointAddress,
                // the call to be executed on remote endpoint
                abi.encodeWithSignature(
                    "epRecv(address,uint16,address,bytes)",
                    _fromDappAddress,
                    _toChainId,
                    _toDappAddress,
                    _message
                )
            );
    }

    // called by remote endpoint through low level messaging contract
    function epRecv(
        address _fromDappAddress,
        uint16 _toChainId,
        address _toDappAddress,
        bytes memory _message
    ) external {
        // call local gateway to receive message
        localGateway.mgRecv(
            _fromDappAddress,
            _toChainId,
            _toDappAddress,
            _message
        );
    }
}
