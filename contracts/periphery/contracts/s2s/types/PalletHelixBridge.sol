// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/Bytes.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "./TypeUtils.sol";
import "./XcmTypes.sol";

library PalletHelixBridge {
    ///////////////////////
    // Calls
    ///////////////////////
    // issue_from_remote
    struct IssueFromRemoteCall {
        bytes2 callIndex;
        uint128 value;
        bytes32 recipient;
        uint64[] burnPrunedMessages;
        uint64 maxLockPrunedNonce;
    }

    function encodeIssueFromRemoteCall(IssueFromRemoteCall memory _call)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory burnPrunedMessagesBytes = hex"";
        for (uint i = 0; i < _call.burnPrunedMessages.length; i++) {
            uint64 nonce = _call.burnPrunedMessages[i];
            burnPrunedMessagesBytes = abi.encodePacked(burnPrunedMessagesBytes, ScaleCodec.encode64(nonce));
        }
        burnPrunedMessagesBytes = abi.encodePacked(
            ScaleCodec.encodeUintCompact(_call.burnPrunedMessages.length),
            burnPrunedMessagesBytes
        );
        return
            abi.encodePacked(
                _call.callIndex,
                ScaleCodec.encode128(_call.value),
                _call.recipient,
                burnPrunedMessagesBytes,
                ScaleCodec.encode64(_call.maxLockPrunedNonce)
            );
    }

    // handle_issuing_failure_from_remote
    struct HandleIssuingFailureFromRemoteCall {
        bytes2 callIndex;
        uint64 failureNonce;
        uint64[] burnPrunedMessages;
        uint64 maxLockPrunedNonce;
    }

    function encodeHandleIssuingFailureFromRemoteCall(HandleIssuingFailureFromRemoteCall memory _call)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory burnPrunedMessagesBytes = hex"";
        for (uint i = 0; i < _call.burnPrunedMessages.length; i++) {
            uint64 nonce = _call.burnPrunedMessages[i];
            burnPrunedMessagesBytes = abi.encodePacked(burnPrunedMessagesBytes, ScaleCodec.encode64(nonce));
        }
        burnPrunedMessagesBytes = abi.encodePacked(
            ScaleCodec.encodeUintCompact(_call.burnPrunedMessages.length),
            burnPrunedMessagesBytes
        );
        return
            abi.encodePacked(
                _call.callIndex,
                ScaleCodec.encode64(_call.failureNonce),
                burnPrunedMessagesBytes,
                ScaleCodec.encode64(_call.maxLockPrunedNonce)
            );
    }
}
