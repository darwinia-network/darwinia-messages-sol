// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@darwinia/contracts-utils/contracts/AccountId.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "@darwinia/contracts-utils/contracts/Hash.sol";

import "./interfaces/IStateStorage.sol";
import "./types/CommonTypes.sol";
import "./types/PalletBridgeMessages.sol";

library MessageLib {
    bytes public constant ACCOUNT_DERIVATION_PREFIX =
        "pallet-bridge/account-derivation/account";

    // Send message over lane by calling the `send_message` dispatch call on
    // the source chain which is identified by the `callIndex` param.
    function sendMessage(
        address _srcDispatchPrecompileAddress,
        bytes2 _callIndex,
        bytes4 _laneId,
        uint256 _deliveryAndDispatchFee,
        bytes memory _message
    ) internal {
        // encode send_message call
        PalletBridgeMessages.SendMessageCall
            memory sendMessageCall = PalletBridgeMessages.SendMessageCall(
                _callIndex,
                _laneId,
                _message,
                uint128(_deliveryAndDispatchFee)
            );

        bytes memory sendMessageCallEncoded = PalletBridgeMessages
            .encodeSendMessageCall(sendMessageCall);

        // dispatch the send_message call
        dispatch(
            _srcDispatchPrecompileAddress,
            sendMessageCallEncoded,
            "Dispatch send_message failed"
        );
    }

    // Build the scale encoded message for the target chain.
    function buildMessage(
        uint32 _specVersion,
        uint64 _weight,
        bytes memory _call
    ) internal view returns (bytes memory) {
        // enum CallOrigin
        //   0: SourceRoot
        //   1: TargetAccount
        //   2: SourceAccount
        CommonTypes.EnumItemWithAccountId memory origin = CommonTypes
            .EnumItemWithAccountId(
                2, // CallOrigin::SourceAccount
                address(this) // UserApp contract address
            );

        // enum DispatchFeePayment
        //   0: AtSourceChain
        //   1: AtTargetChain
        CommonTypes.EnumItemWithNull memory dispatchFeePayment = CommonTypes
            .EnumItemWithNull(0); // DispatchFeePayment::AtSourceChain

        return
            CommonTypes.encodeMessage(
                CommonTypes.Message(
                    _specVersion,
                    0,
                    0,
                    origin,
                    dispatchFeePayment,
                    _call
                )
            );
    }

    // Get market fee from state storage of the substrate chain
    function marketFee(
        address _srcStoragePrecompileAddress,
        bytes32 _storageKey
    ) internal view returns (uint128) {
        bytes memory data = getStateStorage(
            _srcStoragePrecompileAddress,
            abi.encodePacked(_storageKey),
            "Get market fee failed"
        );

        CommonTypes.Relayer memory relayer = CommonTypes.getLastRelayerFromVec(
            data
        );
        return relayer.fee;
    }

    // Get the latest nonce from state storage
    function latestNonce(
        address _srcStoragePrecompileAddress,
        bytes32 _storageKey,
        bytes4 _laneId
    ) internal view returns (uint64) {
        // 1. Get `OutboundLaneData` from storage
        // Full storage key == storageKey + Blake2_128Concat(laneId)
        bytes memory hashedLaneId = Hash.blake2b128Concat(
            abi.encodePacked(_laneId)
        );
        bytes memory fullStorageKey = abi.encodePacked(
            _storageKey,
            hashedLaneId
        );

        // Do get data by calling state storage precompile
        bytes memory data = getStateStorage(
            _srcStoragePrecompileAddress,
            fullStorageKey,
            "Get OutboundLaneData failed"
        );

        // 2. Decode `OutboundLaneData` and return the latest nonce
        CommonTypes.OutboundLaneData memory outboundLaneData = CommonTypes
            .decodeOutboundLaneData(data);
        return outboundLaneData.latestGeneratedNonce;
    }

    function deriveAccountId(
        bytes4 _srcChainId,
        bytes32 _accountId
    ) internal view returns (bytes32) {
        bytes memory data = abi.encodePacked(
            bytes1(0xa0), // compact length of ACCOUNT_DERIVATION_PREFIX
            ACCOUNT_DERIVATION_PREFIX,
            _srcChainId,
            _accountId
        );
        return Hash.blake2bHash(data);
    }

    function revertIfFailed(
        bool _success,
        bytes memory _resultData,
        string memory _revertMsg
    ) internal pure {
        if (!_success) {
            if (_resultData.length > 0) {
                assembly {
                    let resultDataSize := mload(_resultData)
                    revert(add(32, _resultData), resultDataSize)
                }
            } else {
                revert(_revertMsg);
            }
        }
    }

    event DispatchCall(bytes);

    // dispatch pallet dispatch-call
    function dispatch(
        address _srcDispatchPrecompileAddress,
        bytes memory _callEncoded,
        string memory _errMsg
    ) internal {
        emit DispatchCall(_callEncoded);
        // Dispatch the call
        (bool success, bytes memory data) = _srcDispatchPrecompileAddress.call(
            _callEncoded
        );
        revertIfFailed(success, data, _errMsg);
    }

    function deriveSender(
        bytes4 _srcChainId,
        address _srcMessageSender
    ) internal view returns (address) {
        // H160(sender on the sourc chain) > AccountId32
        bytes32 derivedSubstrateAddress = AccountId.deriveSubstrateAddress(
            _srcMessageSender
        );

        // AccountId32 > derived AccountId32
        bytes32 derivedAccountId = deriveAccountId(
            _srcChainId,
            derivedSubstrateAddress
        );

        // derived AccountId32 > H160
        address result = AccountId.deriveEthereumAddress(derivedAccountId);

        return result;
    }

    // Get the last delivered nonce from the state storage of the target chain's inbound lane
    function lastDeliveredNonce(
        address _tgtStoragePrecompileAddress,
        bytes32 _storageKey,
        bytes4 _inboundLaneId
    ) internal view returns (uint64) {
        // 1. Get `inboundLaneData` from storage
        // Full storage key == storageKey + Blake2_128Concat(laneId)
        bytes memory hashedLaneId = Hash.blake2b128Concat(
            abi.encodePacked(_inboundLaneId)
        );
        bytes memory fullStorageKey = abi.encodePacked(
            _storageKey,
            hashedLaneId
        );

        // Do get data by calling state storage precompile
        bytes memory data = getStateStorage(
            _tgtStoragePrecompileAddress,
            fullStorageKey,
            "Get InboundLaneData failed"
        );

        // 2. Decode `InboundLaneData` and return the last delivered nonce
        return CommonTypes.getLastDeliveredNonceFromInboundLaneData(data);
    }

    function getStateStorage(
        address _storagePrecompileAddress,
        bytes memory _storageKey,
        string memory _failedMsg
    ) internal view returns (bytes memory) {
        (bool success, bytes memory data) = _storagePrecompileAddress
            .staticcall(
                abi.encodeWithSelector(
                    IStateStorage.state_storage.selector,
                    _storageKey
                )
            );

        // TODO: Use try/catch instead for error
        revertIfFailed(success, data, _failedMsg);

        return abi.decode(data, (bytes));
    }
}
