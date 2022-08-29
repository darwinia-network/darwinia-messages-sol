// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../MessageEndpoint.sol";

// On Pangoro, to Pangolin
contract ToPangolinEndpoint is MessageEndpoint {
    constructor() {
        outboundLaneId = 0x726f6c69;
        inboundLaneId = 0x726f6c69;
        storageAddress = address(1024);
        dispatchAddress = address(1025);
        storageKeyForMarketFee = 0x30d35416864cf657db51d3bc8505602f2edb70953213f33a6ef6b8a5e3ffcab2;
        storageKeyForLatestNonce = 0xd86d7f611f4d004e041fda08f633f10196c246acb9b55077390e3ca723a0ca1f;
        storageKeyForLastDeliveredNonce = 0xd86d7f611f4d004e041fda08f633f101e5f83cf83f2127eb47afdc35d6e43fab;
        sendMessageCallIndex = 0x1103;
        remoteMessageTransactCallIndex = 0x2901;
        remoteSmartChainId = 43;
    }

    function _canBeExecuted(address, bytes calldata)
        internal
        pure
        override
        returns (bool)
    {
        return true;
    }

    function remoteExecute(
        uint32 pangolinSpecVersion,
        address callReceiver,
        bytes calldata callPayload,
        uint256 gasLimit
    ) external payable returns (uint256) {
        return
            _remoteExecute(
                pangolinSpecVersion,
                callReceiver,
                callPayload,
                gasLimit
            );
    }

    function setRemoteEndpoint(bytes4 _remoteChainId, address _remoteEndpoint)
        external
    {
        _setRemoteEndpoint(_remoteChainId, _remoteEndpoint);
    }

    function setOutboundLaneId(bytes4 _outboundLaneId) external {
        _setOutboundLaneId(_outboundLaneId);
    }

    function setRemoteMessageTransactCallIndex(
        bytes2 _remoteMessageTransactCallIndex
    ) external {
        _setRemoteMessageTransactCallIndex(_remoteMessageTransactCallIndex);
    }

    function setStorageAddress(address _storageAddress) external {
        _setStorageAddress(_storageAddress);
    }

    function setDispatchAddress(address _dispatchAddress) external {
        _setDispatchAddress(_dispatchAddress);
    }

    function setSendMessageCallIndex(bytes2 _sendMessageCallIndex) external {
        _setSendMessageCallIndex(_sendMessageCallIndex);
    }

    function setStorageKeyForMarketFee(bytes32 _storageKeyForMarketFee)
        external
    {
        _setStorageKeyForMarketFee(_storageKeyForMarketFee);
    }

    function setStorageKeyForLatestNonce(bytes32 _storageKeyForLatestNonce)
        external
    {
        _setStorageKeyForLatestNonce(_storageKeyForLatestNonce);
    }

    function setRemoteWeightPerGas(uint64 _remoteWeightPerGas) external {
        _setRemoteWeightPerGas(_remoteWeightPerGas);
    }

    function setInboundLaneId(bytes4 _inboundLaneId) external {
        _setInboundLaneId(_inboundLaneId);
    }

    function setRemoteSmartChainId(uint64 _remoteSmartChainId) external {
        _setRemoteSmartChainId(_remoteSmartChainId);
    }

    function setStorageKeyForLastDeliveredNonce(
        bytes32 _storageKeyForLastDeliveredNonce
    ) external {
        _setStorageKeyForLastDeliveredNonce(_storageKeyForLastDeliveredNonce);
    }
}
