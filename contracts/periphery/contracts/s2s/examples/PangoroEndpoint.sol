// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../MessageEndpoint.sol";

// On Pangoro, to Pangolin
contract PangoroEndpoint is MessageEndpoint(0, 0x726f6c69, 0x726f6c69) {
    constructor() {
        storageKeyForMarketFee = 0x30d35416864cf657db51d3bc8505602f2edb70953213f33a6ef6b8a5e3ffcab2;
        storageKeyForLatestNonce = 0xd86d7f611f4d004e041fda08f633f10196c246acb9b55077390e3ca723a0ca1f;
        storageKeyForLastDeliveredNonce = 0xd86d7f611f4d004e041fda08f633f101e5f83cf83f2127eb47afdc35d6e43fab;
        sendMessageCallIndex = 0x2903;
        remoteMessageTransactCallIndex = 0x2600;
        remoteSmartChainId = 43;
    }

    function _canBeExecuted(
        address,
        bytes calldata
    ) internal pure override returns (bool) {
        return true;
    }

    function setRemoteEndpoint(
        bytes4 _remoteChainId,
        address _remoteEndpoint
    ) external {
        _setRemoteEndpoint(_remoteChainId, _remoteEndpoint);
    }

    function setRemoteMessageTransactCallIndex(
        bytes2 _remoteMessageTransactCallIndex
    ) external {
        _setRemoteMessageTransactCallIndex(_remoteMessageTransactCallIndex);
    }

    function setSendMessageCallIndex(bytes2 _sendMessageCallIndex) external {
        _setSendMessageCallIndex(_sendMessageCallIndex);
    }

    function setStorageKeyForMarketFee(
        bytes32 _storageKeyForMarketFee
    ) external {
        _setStorageKeyForMarketFee(_storageKeyForMarketFee);
    }

    function setStorageKeyForLatestNonce(
        bytes32 _storageKeyForLatestNonce
    ) external {
        _setStorageKeyForLatestNonce(_storageKeyForLatestNonce);
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
