// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MessageLib.sol";
import "./types/PalletEthereum.sol";

// srcDapp > endpoint[outboundLaneId] > substrate.send_message
// ->
// substrate.message_transact > remoteEndpoint[inboundLaneId] > TgtDapp.function
abstract contract MessageEndpoint {
    // REMOTE
    address public remoteEndpoint;
    // message sender derived from remoteEndpoint
    address public derivedMessageSender;
    // call indices
    bytes2 public remoteMessageTransactCallIndex;
    // remote smart chain id
    uint64 public remoteSmartChainId;

    // 1 gas ~= 40_000 weight
    uint64 public constant REMOTE_WEIGHT_PER_GAS = 40_000;

    // LOCAL
    // storage keys
    bytes32 public storageKeyForMarketFee;
    bytes32 public storageKeyForLatestNonce;
    bytes32 public storageKeyForLastDeliveredNonce;
    // call indices
    bytes2 public sendMessageCallIndex;

    // lane ids
    bytes4 public immutable OUTBOUND_LANE_ID;
    bytes4 public immutable INBOUND_LANE_ID;
    // precompile addresses
    address public constant STORAGE_ADDRESS =
        0x0000000000000000000000000000000000000400;
    address public constant DISPATCH_ADDRESS =
        0x0000000000000000000000000000000000000401;

    constructor(bytes4 outboundLaneId, bytes4 inboundLaneId) {
        OUTBOUND_LANE_ID = outboundLaneId;
        INBOUND_LANE_ID = inboundLaneId;
    }

    ///////////////////////////////
    // Outbound
    ///////////////////////////////
    function fee() public view returns (uint256) {
        return MessageLib.marketFee(STORAGE_ADDRESS, storageKeyForMarketFee);
    }

    // srcDapp > endpoint[outboundLaneId] > substrate.send_message
    // ->
    // substrate.message_transact(input) > remoteEndpoint[inboundLaneId] > TgtDapp.function
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
                remoteMessageTransactCallIndex,
                // the evm transaction to transact
                PalletEthereum.buildTransactionV2ForMessageTransact(
                    gasLimit,
                    remoteEndpoint,
                    remoteSmartChainId,
                    input
                )
            );
        bytes memory callEncoded = PalletEthereum.encodeMessageTransactCall(
            call
        );
        uint64 weight = uint64(gasLimit * REMOTE_WEIGHT_PER_GAS);

        return _remoteDispatch(tgtSpecVersion, callEncoded, weight);
    }

    function _remoteDispatch(
        uint32 tgtSpecVersion,
        bytes memory tgtCallEncoded,
        uint64 tgtCallWeight
    ) internal returns (uint256) {
        // Build the encoded message to be sent
        bytes memory message = MessageLib.buildMessage(
            tgtSpecVersion,
            tgtCallWeight,
            tgtCallEncoded
        );

        // Send the message
        MessageLib.sendMessage(
            DISPATCH_ADDRESS,
            sendMessageCallIndex,
            OUTBOUND_LANE_ID,
            msg.value,
            message
        );

        // Get nonce from storage
        uint64 nonce = MessageLib.latestNonce(
            STORAGE_ADDRESS,
            storageKeyForLatestNonce,
            OUTBOUND_LANE_ID
        );

        return encodeMessageId(OUTBOUND_LANE_ID, nonce);
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

    function execute(
        address callReceiver,
        bytes calldata callPayload
    ) external onlyMessageSender {
        if (_canBeExecuted(callReceiver, callPayload)) {
            (bool success, ) = callReceiver.call(callPayload);
            require(success, "MessageEndpoint: Call execution failed");
        } else {
            revert("MessageEndpoint: Unapproved call");
        }
    }

    // Check if the call can be executed
    function _canBeExecuted(
        address callReceiver,
        bytes calldata callPayload
    ) internal view virtual returns (bool);

    // Get the last delivered inbound message id
    function lastDeliveredMessageId() public view returns (uint256) {
        uint64 nonce = MessageLib.lastDeliveredNonce(
            STORAGE_ADDRESS,
            storageKeyForLastDeliveredNonce,
            INBOUND_LANE_ID
        );
        return encodeMessageId(INBOUND_LANE_ID, nonce);
    }

    // Check if an inbound message has been delivered
    function isMessageDelivered(uint256 messageId) public view returns (bool) {
        (bytes4 laneId, uint64 nonce) = decodeMessageId(messageId);
        uint64 lastNonce = MessageLib.lastDeliveredNonce(
            STORAGE_ADDRESS,
            storageKeyForLastDeliveredNonce,
            laneId
        );
        return nonce <= lastNonce;
    }

    ///////////////////////////////
    // Common functions
    ///////////////////////////////
    function decodeMessageId(
        uint256 messageId
    ) public pure returns (bytes4, uint64) {
        return (
            bytes4(uint32(messageId >> 64)),
            uint64(messageId & 0xffffffffffffffff)
        );
    }

    function encodeMessageId(
        bytes4 laneId,
        uint64 nonce
    ) public pure returns (uint256) {
        return (uint256(uint32(laneId)) << 64) + uint256(nonce);
    }

    ///////////////////////////////
    // Setters
    ///////////////////////////////
    function _setRemoteEndpoint(
        bytes4 _remoteChainId,
        address _remoteEndpoint
    ) internal {
        remoteEndpoint = _remoteEndpoint;
        derivedMessageSender = MessageLib.deriveSenderFromRemote(
            _remoteChainId,
            _remoteEndpoint
        );
    }

    function _setRemoteMessageTransactCallIndex(
        bytes2 _remoteMessageTransactCallIndex
    ) internal {
        remoteMessageTransactCallIndex = _remoteMessageTransactCallIndex;
    }

    function _setSendMessageCallIndex(bytes2 _sendMessageCallIndex) internal {
        sendMessageCallIndex = _sendMessageCallIndex;
    }

    function _setStorageKeyForMarketFee(
        bytes32 _storageKeyForMarketFee
    ) internal {
        storageKeyForMarketFee = _storageKeyForMarketFee;
    }

    function _setStorageKeyForLatestNonce(
        bytes32 _storageKeyForLatestNonce
    ) internal {
        storageKeyForLatestNonce = _storageKeyForLatestNonce;
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
