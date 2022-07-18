// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./SmartChainXLib.sol";
import "./types/PalletEthereum.sol";

contract MessageHandle {
    address public tgtHandle;
    bytes4 public srcOutboundLaneId;
    // target chain's `message_transact` call index
    bytes2 public tgtMessageTransactCallIndex;
    // precompile addresses
    address public srcStorageAddress;
    address public srcDispatchAddress;
    // bridge info
    bytes2 public srcSendMessageCallIndex;
    // readonly storage keys
    bytes32 public srcStorageKeyForMarketFee;
    bytes32 public srcStorageKeyForLatestNonce;
    // 1 gas ~= 40_000 weight.
    uint64 public tgtWeightPerGas = 40_000;

    address public srcHandle;
    bytes4 public tgtInboundLaneId;
    // source chain id
    bytes4 public srcChainId;
    // target smart chain id
    uint64 public tgtSmartChainId;
    // source chain message sender, derived from srcHandle
    address public derivedMessageSender;
    // precompile addresses
    address public tgtStorageAddress;
    // readonly storage keys
    bytes32 public tgtStorageKeyForLastDeliveredNonce;

    ///////////////////////////////
    // Source
    ///////////////////////////////
    // External & public functions
    function fee() public view returns (uint256) {
        return
            SmartChainXLib.marketFee(
                srcStorageAddress,
                srcStorageKeyForMarketFee
            );
    }

    function encodeMessageId(bytes4 laneId, uint64 nonce)
        public
        pure
        returns (uint256)
    {
        return (uint256(uint32(laneId)) << 64) + uint256(nonce);
    }

    // Internal functions
    function _remoteExecute(
        uint32 tgtSpecVersion,
        address callReceiver,
        bytes calldata callPayload,
        uint256 gasLimit
    ) internal returns (uint256) {
        bytes memory input = abi.encodeWithSelector(
            this.execute.selector,
            callReceiver,
            callPayload
        );

        return _remoteTransact(tgtSpecVersion, input, gasLimit);
    }

    function _remoteTransact(
        uint32 tgtSpecVersion,
        bytes memory input,
        uint256 gasLimit
    ) internal returns (uint256) {
        PalletEthereum.MessageTransactCall memory call = PalletEthereum
            .MessageTransactCall(
                // the call index of message_transact
                tgtMessageTransactCallIndex,
                // the evm transaction to transact
                PalletEthereum.buildTransactionV2ForMessageTransact(
                    gasLimit,
                    tgtHandle,
                    tgtSmartChainId,
                    input
                )
            );
        bytes memory callEncoded = PalletEthereum.encodeMessageTransactCall(
            call
        );
        uint64 weight = uint64(gasLimit * tgtWeightPerGas);

        return _sendMessage(tgtSpecVersion, callEncoded, weight);
    }

    function _sendMessage(
        uint32 tgtSpecVersion,
        bytes memory tgtCallEncoded,
        uint64 tgtCallWeight
    ) internal returns (uint256) {
        // Get the current market fee
        uint256 marketFee = SmartChainXLib.marketFee(
            srcStorageAddress,
            srcStorageKeyForMarketFee
        );
        require(msg.value >= marketFee, "Insufficient balance");

        // Build the encoded message to be sent
        bytes memory message = SmartChainXLib.buildMessage(
            tgtSpecVersion,
            tgtCallWeight,
            tgtCallEncoded
        );

        // Send the message
        SmartChainXLib.sendMessage(
            srcDispatchAddress,
            srcSendMessageCallIndex,
            srcOutboundLaneId,
            msg.value,
            message
        );

        // Get nonce from storage
        uint64 nonce = SmartChainXLib.latestNonce(
            srcStorageAddress,
            srcStorageKeyForLatestNonce,
            srcOutboundLaneId
        );

        return encodeMessageId(srcOutboundLaneId, nonce);
    }

    function _setTgtHandle(address _tgtHandle) internal {
        tgtHandle = _tgtHandle;
    }

    function _setSrcOutboundLaneId(bytes4 _srcOutboundLaneId) internal {
        srcOutboundLaneId = _srcOutboundLaneId;
    }

    function _setTgtMessageTransactCallIndex(
        bytes2 _tgtMessageTransactCallIndex
    ) internal {
        tgtMessageTransactCallIndex = _tgtMessageTransactCallIndex;
    }

    function _setSrcStorageAddress(address _srcStorageAddress) internal {
        srcStorageAddress = _srcStorageAddress;
    }

    function _setSrcDispatchAddress(address _srcDispatchAddress) internal {
        srcDispatchAddress = _srcDispatchAddress;
    }

    function _setSrcSendMessageCallIndex(bytes2 _srcSendMessageCallIndex)
        internal
    {
        srcSendMessageCallIndex = _srcSendMessageCallIndex;
    }

    function _setSrcStorageKeyForMarketFee(bytes32 _srcStorageKeyForMarketFee)
        internal
    {
        srcStorageKeyForMarketFee = _srcStorageKeyForMarketFee;
    }

    function _setSrcStorageKeyForLatestNonce(
        bytes32 _srcStorageKeyForLatestNonce
    ) internal {
        srcStorageKeyForLatestNonce = _srcStorageKeyForLatestNonce;
    }

    function _setSrcStorageKeyForLatestNonce(uint64 _tgtWeightPerGas) internal {
        tgtWeightPerGas = _tgtWeightPerGas;
    }

    ///////////////////////////////
    // Target
    ///////////////////////////////
    modifier onlyMessageSender() {
        require(
            derivedMessageSender == msg.sender,
            "MessageHandle: Invalid sender"
        );
        _;
    }

    // External & public functions
    function execute(address callReceiver, bytes calldata callPayload)
        external
        onlyMessageSender
    {
        (bool success, ) = callReceiver.call(callPayload);
        require(success, "MessageHandle: Call execution failed");
    }

    function latestMessageNonce() public view returns (uint256) {
        return
            SmartChainXLib.lastDeliveredNonce(
                tgtStorageAddress,
                tgtStorageKeyForLastDeliveredNonce,
                tgtInboundLaneId
            );
    }

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

    function isMessageDelivered(uint256 messageId) public view returns (bool) {
        (bytes4 laneId, uint64 nonce) = decodeMessageId(messageId);
        uint64 latestNonce = SmartChainXLib.lastDeliveredNonce(
            tgtStorageAddress,
            tgtStorageKeyForLastDeliveredNonce,
            laneId
        );
        return nonce <= latestNonce;
    }

    // Internal functions
    function _setSrcHandle(address _srcHandle) internal {
        srcHandle = _srcHandle;
        derivedMessageSender = SmartChainXLib.deriveSenderFromRemote(
            srcChainId,
            srcHandle
        );
    }

    function _setTgtInboundLaneId(bytes4 _tgtInboundLaneId) internal {
        tgtInboundLaneId = _tgtInboundLaneId;
    }

    function _setSrcChainId(bytes4 _srcChainId) internal {
        srcChainId = _srcChainId;
    }

    function _setTgtSmartChainId(uint64 _tgtSmartChainId) internal {
        tgtSmartChainId = _tgtSmartChainId;
    }

    function _setTgtStorageAddress(address _tgtStorageAddress) internal {
        tgtStorageAddress = _tgtStorageAddress;
    }

    function _setTgtStorageKeyForLastDeliveredNonce(
        bytes32 _tgtStorageKeyForLastDeliveredNonce
    ) internal {
        tgtStorageKeyForLastDeliveredNonce = _tgtStorageKeyForLastDeliveredNonce;
    }
}
