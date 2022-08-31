// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./SmartChainXLib.sol";
import "./types/PalletEthereum.sol";
import "./types/PalletMessageRouter.sol";
import "./types/PalletEthereumXcm.sol";

abstract contract MoonbeamEndpoint {
    // Remote params
    address public remoteEndpoint;
    bytes2 public remoteMessageTransactCallIndex;

    // router params
    bytes2 public routerForwardToMoonbeamCallIndex;
    uint64 public routerForwardToMoonbeamCallWeight = 337_239_000;

    // Local params
    address public dispatchAddress;
    bytes2 public sendMessageCallIndex;
    address public storageAddress;
    bytes32 public storageKeyForLatestNonce;
    bytes32 public storageKeyForLastDeliveredNonce;
    bytes32 public storageKeyForMarketFee;
    bytes4 public outboundLaneId;
    bytes4 public inboundLaneId;

    // message sender derived from remoteEndpoint
    address public derivedMessageSender;

    ///////////////////////////////
    // Outbound
    ///////////////////////////////
    function fee() public view returns (uint256) {
        return SmartChainXLib.marketFee(storageAddress, storageKeyForMarketFee);
    }

    function _remoteExecute(
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

        // build the TransactCall
        bytes memory tgtTransactCallEncoded = PalletEthereumXcm
            .buildTransactCall(
                remoteMessageTransactCallIndex,
                gasLimit,
                remoteEndpoint,
                0,
                input
            );

        // build the ForwardToMoonbeamCall
        bytes memory routerForwardToMoonbeamCallEncoded = PalletMessageRouter
            .buildForwardToMoonbeamCall(
                routerForwardToMoonbeamCallIndex,
                tgtTransactCallEncoded
            );

        // dispatch the ForwardToMoonbeamCall
        uint64 messageNonce = SmartChainXLib.remoteDispatch(
            routerSpecVersion,
            routerForwardToMoonbeamCallEncoded,
            routerForwardToMoonbeamCallWeight,
            dispatchAddress,
            sendMessageCallIndex,
            outboundLaneId,
            storageAddress,
            storageKeyForLatestNonce
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
        if (_allowed(callReceiver, callPayload)) {
            (bool success, ) = callReceiver.call(callPayload);
            require(success, "MessageEndpoint: Call execution failed");
        } else {
            revert("MessageEndpoint: Unapproved call");
        }
    }

    // Check if the call can be executed
    function _allowed(address callReceiver, bytes calldata callPayload)
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
    function _setRemoteEndpointOnMoonbeam(
        bytes4 _remoteChainId,
        bytes memory _parachainId,
        address _remoteEndpoint
    ) internal {
        remoteEndpoint = _remoteEndpoint;
        derivedMessageSender = SmartChainXLib
            .deriveSenderFromSmartChainOnMoonbeam(
                _remoteChainId,
                _remoteEndpoint,
                _parachainId
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

    function _setInboundLaneId(bytes4 _inboundLaneId) internal {
        inboundLaneId = _inboundLaneId;
    }

    function _setStorageKeyForLastDeliveredNonce(
        bytes32 _storageKeyForLastDeliveredNonce
    ) internal {
        storageKeyForLastDeliveredNonce = _storageKeyForLastDeliveredNonce;
    }
}
