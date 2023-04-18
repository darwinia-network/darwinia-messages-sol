// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../MessageEndpoint.sol";

// 0x64616362(dacb) is the lane id of Darwinia <> Crab Message channel
contract CrabEndpoint is MessageEndpoint(0, 0x64616362, 0x64616362) {
    constructor() {
        storageKeyForMarketFee = 0xe0c938a0fbc88db6078b53e160c7c3ed2edb70953213f33a6ef6b8a5e3ffcab2; // checked, darwiniaFeeMarket's assignedRelayers storage key
        storageKeyForLatestNonce = 0xf1501030816118b9129255f5096aa9b296c246acb9b55077390e3ca723a0ca1f; // checked, bridgeDarwiniaMessages's outboundLanes storage key
        storageKeyForLastDeliveredNonce = 0xf1501030816118b9129255f5096aa9b2e5f83cf83f2127eb47afdc35d6e43fab; // checked, bridgeDarwiniaMessages's inboundLanes storage key
        sendMessageCallIndex = 0x2903; // checked
        remoteMessageTransactCallIndex = 0x3001; // checked, the call index of darwinia's ethereum.messageTransact
        remoteSmartChainId = 46; // checked, darwinia ethereum chain id
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

    function remoteExecute(
        uint32 pangoroSpecVersion,
        address callReceiver,
        bytes calldata callPayload,
        uint256 gasLimit
    ) external payable returns (uint256) {
        return
            _remoteExecute(
                pangoroSpecVersion,
                callReceiver,
                callPayload,
                gasLimit
            );
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
