// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../MessageEndpoint.sol";

// On Pangolin, to Pangolin Parachain
contract PangolinToPangolinParachainEndpoint is MessageEndpoint {
    constructor() {
        outboundLaneId = 0x70616c69;
        inboundLaneId = 0x70616c69;
        storageAddress = address(1024);
        dispatchAddress = address(1025);
        storageKeyForMarketFee = 0x39bf2363dd0720bd6e11a4c86f4949322edb70953213f33a6ef6b8a5e3ffcab2;
        storageKeyForLatestNonce = 0xdcdffe6202217f0ecb0ec75d8a09b32c96c246acb9b55077390e3ca723a0ca1f;
        storageKeyForLastDeliveredNonce = 0xdcdffe6202217f0ecb0ec75d8a09b32ce5f83cf83f2127eb47afdc35d6e43fab;
        sendMessageCallIndex = 0x3f03;
    }

    function _canBeExecuted(address, bytes calldata)
        internal
        pure
        override
        returns (bool)
    {
        return true;
    }

    function remoteExecuteOnMoonbeam(
        uint32 routerSpecVersion,
        address callReceiver,
        bytes calldata callPayload,
        uint256 gasLimit
    ) external returns (uint256) {
        return
            _remoteExecuteOnMoonbeam(
                routerSpecVersion,
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
