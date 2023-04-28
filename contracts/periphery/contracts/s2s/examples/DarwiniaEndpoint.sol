// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../MessageEndpoint.sol";

// 0x64616362(dacb) is the lane id of Darwinia <> Crab Message channel
contract DarwiniaEndpoint is MessageEndpoint(0, 0x64616362, 0x64616362) {
    constructor() {
        storageKeyForMarketFee = 0x94594b5e37f74ce096905956485f9a7d2edb70953213f33a6ef6b8a5e3ffcab2;
        storageKeyForLatestNonce = 0xf4e61b17ce395203fe0f3c53a0d3986096c246acb9b55077390e3ca723a0ca1f;
        storageKeyForLastDeliveredNonce = 0xf4e61b17ce395203fe0f3c53a0d39860e5f83cf83f2127eb47afdc35d6e43fab;
        sendMessageCallIndex = 0x2903;
        remoteMessageTransactCallIndex = 0x2600; // the call index of crab's messageTransact.messageTransact
        remoteSmartChainId = 44;
    }

    function _canBeExecuted(
        address,
        bytes calldata
    ) internal pure override returns (bool) {
        return true;
    }

    function remoteExecute(
        uint32 pangolinSpecVersion,
        address callReceiver,
        bytes calldata callPayload,
        uint256 gasLimit
    ) external payable override returns (uint256) {
        return
            _remoteExecute(
                pangolinSpecVersion,
                callReceiver,
                callPayload,
                gasLimit
            );
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
