// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/AccountId.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "@darwinia/contracts-utils/contracts/Bytes.sol";
import "@darwinia/contracts-utils/contracts/Hash.sol";

import "./interfaces/IStateStorage.sol";
import "./types/CommonTypes.sol";
import "./types/PalletBridgeMessages.sol";
import "./types/PalletEthereum.sol";
import "./types/PalletMessageRouter.sol";
import "./types/PalletEthereumXcm.sol";

library SmartChainXLib {
    struct LocalParams {
        address dispatchPrecompileAddress;
        bytes2 sendMessageCallIndex;
        bytes4 outboundLaneId;
        address storagePrecompileAddress;
        bytes32 storageKeyForLatestNonce;
    }

    struct RemoteTransactParams {
        bytes2 transactCallIndex;
        address endpoint;
        bytes input;
        uint256 gasLimit;
    }

    bytes public constant account_derivation_prefix =
        "pallet-bridge/account-derivation/account";

    event DispatchResult(bool success, bytes result);

    function remoteTransactOnMoonbeam(
        // target params
        RemoteTransactParams memory _tgtTransactParams, 
        // router params
        uint32 _routerSpecVersion,
        bytes2 _routerForwardToMoonbeamCallIndex,
        // local params
        LocalParams memory _localParams
    ) external returns (uint64) {
        bytes memory routerCallEncoded = PalletMessageRouter.buildForwardToMoonbeamCall(
            _routerForwardToMoonbeamCallIndex,
            hex"43726162536d617274436861696e",
            msg.sender,
            PalletEthereumXcm.buildTransactCall(
                _tgtTransactParams.transactCallIndex,
                _tgtTransactParams.gasLimit,
                _tgtTransactParams.endpoint,
                0,
                _tgtTransactParams.input
            )
        );

        uint64 routerCallWeight = 0; // TODO: waiting for guantong

        return
            remoteDispatch(
                _routerSpecVersion,
                routerCallEncoded,
                routerCallWeight,
                _localParams.dispatchPrecompileAddress,
                _localParams.sendMessageCallIndex,
                _localParams.outboundLaneId,
                _localParams.storagePrecompileAddress,
                _localParams.storageKeyForLatestNonce
            );
    }

    function remoteTransact(
        // target params
        uint32 _tgtSpecVersion,
        RemoteTransactParams memory _tgtTransactParams,
        uint64 _tgtSmartChainId,
        uint64 _tgtWeightPerGas,
        // local params
        LocalParams memory _localParams
    ) internal returns (uint64) {
        PalletEthereum.MessageTransactCall memory tgtCall = PalletEthereum
            .MessageTransactCall(
                // the call index of message_transact
                _tgtTransactParams.transactCallIndex,
                // the evm transaction to transact
                PalletEthereum.buildTransactionV2ForMessageTransact(
                    _tgtTransactParams.gasLimit,
                    _tgtTransactParams.endpoint,
                    _tgtSmartChainId,
                    _tgtTransactParams.input
                )
            );
        bytes memory tgtCallEncoded = PalletEthereum.encodeMessageTransactCall(
            tgtCall
        );
        uint64 tgtCallWeight = uint64(_tgtTransactParams.gasLimit * _tgtWeightPerGas);

        return
            remoteDispatch(
                _tgtSpecVersion,
                tgtCallEncoded,
                tgtCallWeight,
                _localParams.dispatchPrecompileAddress,
                _localParams.sendMessageCallIndex,
                _localParams.outboundLaneId,
                _localParams.storagePrecompileAddress,
                _localParams.storageKeyForLatestNonce
            );
    }

    function remoteDispatch(
        uint32 _tgtSpecVersion,
        bytes memory _tgtCallEncoded,
        uint64 _tgtCallWeight,
        //
        address _dispatchPrecompileAddress,
        bytes2 _sendMessageCallIndex,
        bytes4 _outboundLaneId,
        address _storagePrecompileAddress,
        bytes32 _storageKeyForLatestNonce
    ) internal returns (uint64) {
        // Build the encoded message to be sent
        bytes memory message = buildMessage(
            _tgtSpecVersion,
            _tgtCallWeight,
            _tgtCallEncoded
        );

        // Send the message
        sendMessage(
            _dispatchPrecompileAddress,
            _sendMessageCallIndex,
            _outboundLaneId,
            msg.value,
            message
        );

        // Get nonce from storage
        uint64 nonce = latestNonce(
            _storagePrecompileAddress,
            _storageKeyForLatestNonce,
            _outboundLaneId
        );

        return nonce;
    }

    // Send message over lane by calling the `send_message` dispatch call on
    // the source chain which is identified by the `callIndex` param.
    function sendMessage(
        address _srcDispatchPrecompileAddress,
        bytes2 _callIndex,
        bytes4 _laneId,
        uint256 _deliveryAndDispatchFee,
        bytes memory _message
    ) internal {
        // the fee precision in the contracts is 18, but on chain is 9, transform the fee amount.
        uint256 feeOfPalletPrecision = _deliveryAndDispatchFee / (10**9);

        // encode send_message call
        PalletBridgeMessages.SendMessageCall
            memory sendMessageCall = PalletBridgeMessages.SendMessageCall(
                _callIndex,
                _laneId,
                _message,
                uint128(feeOfPalletPrecision)
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
        CommonTypes.EnumItemWithAccountId memory origin = CommonTypes
            .EnumItemWithAccountId(
                2, // index in enum
                AccountId.fromAddress(address(this)) // UserApp contract address
            );

        CommonTypes.EnumItemWithNull memory dispatchFeePayment = CommonTypes
            .EnumItemWithNull(0);

        return
            CommonTypes.encodeMessage(
                CommonTypes.Message(
                    _specVersion,
                    _weight,
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
    ) internal view returns (uint256) {
        bytes memory data = getStateStorage(
            _srcStoragePrecompileAddress,
            abi.encodePacked(_storageKey),
            "Get market fee failed"
        );

        CommonTypes.Relayer memory relayer = CommonTypes.getLastRelayerFromVec(
            data
        );
        return relayer.fee * 10**9;
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

    function deriveAccountId(bytes4 _srcChainId, bytes32 _accountId)
        internal
        view
        returns (bytes32)
    {
        bytes memory prefixLength = ScaleCodec.encodeUintCompact(
            account_derivation_prefix.length
        );
        bytes memory data = abi.encodePacked(
            prefixLength,
            account_derivation_prefix,
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

    // dispatch pallet dispatch-call
    function dispatch(
        address _srcDispatchPrecompileAddress,
        bytes memory _callEncoded,
        string memory _errMsg
    ) internal {
        // Dispatch the call
        (bool success, bytes memory data) = _srcDispatchPrecompileAddress.call(
            _callEncoded
        );
        revertIfFailed(success, data, _errMsg);
    }

    // derive an address from remote sender address (sender on the source chain).
    //   
    // H160          =>          AccountId32        =>        derived AccountId32       =>       H160
    //   |------ e2s addr mapping ----||---- crosschain derive -------||---- s2e addr mapping -----|
    //   |-------- on source ---------||------------------------ on target ------------------------|
    //
    // e2s addr mapping: `EVM H160 address` mapping to `Substrate AccountId32 address`.
    // s2e addr mapping: `Substrate AccountId32 address` mapping to `EVM H160 address`.
    // https://github.com/darwinia-network/darwinia/wiki/Darwinia-Address-Format-Overview
    //
    // crosschain derive: generate the address on the target chain based on the address of the source chain.
    // https://github.com/darwinia-network/darwinia-messages-substrate/blob/c3f10155a2650850ffa8998e5f98617e1aded55a/primitives/runtime/src/lib.rs#L107
    function deriveSenderFromRemote(
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
