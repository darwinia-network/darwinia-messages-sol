// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./SmartChainXLib.sol";
import "./types/PalletEthereum.sol";

abstract contract MessageEndpoint {
    address public remoteEndpoint;
    // lane ids
    bytes4 public outboundLaneId;
    bytes4 public inboundLaneId;
    // precompile addresses
    address public storageAddress;
    address public dispatchAddress;
    // storage keys
    bytes32 public storageKeyForMarketFee;
    bytes32 public storageKeyForLatestNonce;
    bytes32 public storageKeyForLastDeliveredNonce;
    // call indices
    bytes2 public sendMessageCallIndex;
    bytes2 public remoteMessageTransactCallIndex;
    // remote smart chain id
    uint64 public remoteSmartChainId;
    // message sender derived from remoteEndpoint
    address public derivedMessageSender;
    // 1 gas ~= 40_000 weight
    uint64 public remoteWeightPerGas = 40_000;
    // router params
    bytes2 public routerForwardToMoonbeamCallIndex;

    ///////////////////////////////
    // Outbound
    ///////////////////////////////
    function fee() public view returns (uint256) {
        return SmartChainXLib.marketFee(storageAddress, storageKeyForMarketFee);
    }

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

        uint64 messageNonce = SmartChainXLib.remoteTransact(
            tgtSpecVersion,
            SmartChainXLib.RemoteTransactParams(
                remoteMessageTransactCallIndex,
                remoteEndpoint,
                input,
                gasLimit
            ),
            remoteSmartChainId,
            remoteWeightPerGas,
            SmartChainXLib.LocalParams(
                dispatchAddress,
                sendMessageCallIndex,
                outboundLaneId,
                storageAddress,
                storageKeyForLatestNonce
            )
        );

        return encodeMessageId(outboundLaneId, messageNonce);
    }

    function _remoteExecuteOnMoonbeam(
        uint32 routerSpecVersion,
        address callReceiver,
        bytes calldata callPayload,
        uint256 gasLimit
    ) internal returns (uint256) {
        bytes memory input = abi.encodeWithSelector(
            this.execute.selector,
            callReceiver,
            callPayload
        );

        uint64 messageNonce = SmartChainXLib.remoteTransactOnMoonbeam(
            SmartChainXLib.RemoteTransactParams(
                remoteMessageTransactCallIndex,
                remoteEndpoint,
                input,
                gasLimit
            ),
            routerSpecVersion,
            routerForwardToMoonbeamCallIndex,
            SmartChainXLib.LocalParams(
                dispatchAddress,
                sendMessageCallIndex,
                outboundLaneId,
                storageAddress,
                storageKeyForLatestNonce
            )
        );

        return encodeMessageId(outboundLaneId, messageNonce);
    }

    ///////////////////////////////
    // Inbound
    ///////////////////////////////
    modifier onlyMessageSender() {
        require(
            derivedMessageSender == msg.sender,
            "MessageEndpoint: Invalid sender"
        );
        _;
    }

    function execute(address callReceiver, bytes calldata callPayload)
        external
        onlyMessageSender
    {
        if (_canBeExecuted(callReceiver, callPayload)) {
            (bool success, ) = callReceiver.call(callPayload);
            require(success, "MessageEndpoint: Call execution failed");
        } else {
            revert("MessageEndpoint: Unapproved call");
        }
    }

    // Check if the call can be executed
    function _canBeExecuted(address callReceiver, bytes calldata callPayload)
        internal
        view
        virtual
        returns (bool);

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
    function _setRemoteEndpoint(bytes4 _remoteChainId, address _remoteEndpoint)
        internal
    {
        remoteEndpoint = _remoteEndpoint;
        derivedMessageSender = SmartChainXLib.deriveSenderFromRemote(
            _remoteChainId,
            _remoteEndpoint
        );
    }

    function _setOutboundLaneId(bytes4 _outboundLaneId) internal {
        outboundLaneId = _outboundLaneId;
    }

    function _setRemoteMessageTransactCallIndex(
        bytes2 _remoteMessageTransactCallIndex
    ) internal {
        remoteMessageTransactCallIndex = _remoteMessageTransactCallIndex;
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

    function _setRemoteWeightPerGas(uint64 _remoteWeightPerGas) internal {
        remoteWeightPerGas = _remoteWeightPerGas;
    }

    function _setInboundLaneId(bytes4 _inboundLaneId) internal {
        inboundLaneId = _inboundLaneId;
    }

    function _setRemoteSmartChainId(uint64 _remoteSmartChainId) internal {
        remoteSmartChainId = _remoteSmartChainId;
    }

    function _setStorageKeyForLastDeliveredNonce(
        bytes32 _storageKeyForLastDeliveredNonce
    ) internal {
        storageKeyForLastDeliveredNonce = _storageKeyForLastDeliveredNonce;
    }
}
