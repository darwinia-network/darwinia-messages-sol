// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../SmartChainXLib.sol";

abstract contract RemoteDispatchEndpoint {
    address public dispatchAddress;
    bytes2 public sendMessageCallIndex;
    address public storageAddress;
    bytes32 public storageKeyForLatestNonce;
    bytes32 public storageKeyForLastDeliveredNonce;
    bytes32 public storageKeyForMarketFee;
    bytes4 public outboundLaneId;
    bytes4 public inboundLaneId;
    // The chain on which this endpoint deployed
    bytes4 public chainId;

    ///////////////////////////////
    // Outbound
    ///////////////////////////////
    function fee() public view returns (uint256) {
        return SmartChainXLib.marketFee(storageAddress, storageKeyForMarketFee);
    }

    function _remoteDispatch(
        uint32 tgtSpecVersion,
        bytes memory tgtDispatchCallEncoded,
        uint64 tgtDispatchCallWeight
    ) internal returns (uint256) {
        uint64 messageNonce = SmartChainXLib.remoteDispatch(
            tgtSpecVersion,
            tgtDispatchCallEncoded,
            tgtDispatchCallWeight,
            dispatchAddress,
            sendMessageCallIndex,
            outboundLaneId,
            storageAddress,
            storageKeyForLatestNonce
        );

        return encodeMessageId(outboundLaneId, messageNonce);
    }

    // Dapp use this function to get the derived origin(used on remote chain)
    function getDerivedAccountId() external view returns (bytes32) {
        bytes32 derivedSubstrateAddress = AccountId.deriveSubstrateAddress(
            address(this)
        );

        bytes32 derivedAccountId = SmartChainXLib.deriveAccountId(
            chainId,
            derivedSubstrateAddress
        );

        return derivedAccountId;
    }

    ///////////////////////////////
    // Inbound
    ///////////////////////////////
    // Get the last delivered inbound message id
    function lastDeliveredMessageId() public view returns (uint256) {
        uint64 nonce = SmartChainXLib.lastDeliveredNonce(
            storageAddress,
            storageKeyForLastDeliveredNonce,
            inboundLaneId
        );
        return encodeMessageId(inboundLaneId, nonce);
    }

    // Check if an inbound message has been delivered
    function isMessageDelivered(uint256 messageId) public view returns (bool) {
        (bytes4 laneId, uint64 nonce) = decodeMessageId(messageId);
        uint64 lastNonce = SmartChainXLib.lastDeliveredNonce(
            storageAddress,
            storageKeyForLastDeliveredNonce,
            laneId
        );
        return nonce <= lastNonce;
    }

    ///////////////////////////////
    // Common functions
    ///////////////////////////////
    function decodeMessageId(uint256 messageId)
        public
        pure
        returns (bytes4, uint64)
    {
        return (
            bytes4(uint32(messageId >> 64)),
            uint64(messageId & 0xffffffffffffffff)
        );
    }

    function encodeMessageId(bytes4 laneId, uint64 nonce)
        public
        pure
        returns (uint256)
    {
        return (uint256(uint32(laneId)) << 64) + uint256(nonce);
    }

    ///////////////////////////////
    // Setters
    ///////////////////////////////
    function _setOutboundLaneId(bytes4 _outboundLaneId) internal {
        outboundLaneId = _outboundLaneId;
    }

    function _setStorageAddress(address _storageAddress) internal {
        storageAddress = _storageAddress;
    }

    function _setDispatchAddress(address _dispatchAddress) internal {
        dispatchAddress = _dispatchAddress;
    }

    function _setSendMessageCallIndex(bytes2 _sendMessageCallIndex) internal {
        sendMessageCallIndex = _sendMessageCallIndex;
    }

    function _setStorageKeyForMarketFee(bytes32 _storageKeyForMarketFee)
        internal
    {
        storageKeyForMarketFee = _storageKeyForMarketFee;
    }

    function _setStorageKeyForLatestNonce(bytes32 _storageKeyForLatestNonce)
        internal
    {
        storageKeyForLatestNonce = _storageKeyForLatestNonce;
    }

    function _setInboundLaneId(bytes4 _inboundLaneId) internal {
        inboundLaneId = _inboundLaneId;
    }

    function _setStorageKeyForLastDeliveredNonce(
        bytes32 _storageKeyForLastDeliveredNonce
    ) internal {
        storageKeyForLastDeliveredNonce = _storageKeyForLastDeliveredNonce;
    }
}
