// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/AccountId.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "@darwinia/contracts-utils/contracts/Bytes.sol";
import "@darwinia/contracts-utils/contracts/Hash.sol";

import "./interfaces/IStateStorage.sol";
import "./types/CommonTypes.sol";
import "./types/PalletBridgeMessages.sol";

library SmartChainXLib {
    bytes public constant account_derivation_prefix =
        "pallet-bridge/account-derivation/account";

    event DispatchResult(bool success, bytes result);

    // Send message over lane by calling the `send_message` dispatch call on
    // the source chain which is identified by the `callIndex` param.
    function sendMessage(
        address srcDispatchPrecompileAddress,
        bytes2 callIndex,
        bytes4 laneId,
        uint256 deliveryAndDispatchFee,
        bytes memory message
    ) internal {
        // the pricision in contract is 18, and in pallet is 9, transform the fee value
        uint256 feeOfPalletPrecision = deliveryAndDispatchFee / (10**9);

        // encode send_message call
        PalletBridgeMessages.SendMessageCall
            memory sendMessageCall = PalletBridgeMessages.SendMessageCall(
                callIndex,
                laneId,
                message,
                uint128(feeOfPalletPrecision)
            );

        bytes memory sendMessageCallEncoded = PalletBridgeMessages
            .encodeSendMessageCall(sendMessageCall);

        // dispatch the send_message call
        dispatch(
            srcDispatchPrecompileAddress,
            sendMessageCallEncoded,
            "Dispatch send_message failed"
        );
    }

    // Build the scale encoded message for the target chain.
    function buildMessage(
        uint32 specVersion,
        uint64 weight,
        bytes memory call
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
                    specVersion,
                    weight,
                    origin,
                    dispatchFeePayment,
                    call
                )
            );
    }

    // Get market fee from state storage of the substrate chain
    function marketFee(address srcStoragePrecompileAddress, bytes32 storageKey)
        internal
        view
        returns (uint128)
    {
        (bool success, bytes memory data) = address(srcStoragePrecompileAddress).staticcall(
            abi.encodeWithSelector(
                IStateStorage.state_storage.selector,
                abi.encodePacked(storageKey)
            )
        );
        revertIfFailed(success, data, "Get market fee failed");

        CommonTypes.Relayer memory relayer = CommonTypes.getLastRelayerFromVec(
            data
        );
        return relayer.fee;
    }

    // Get the latest nonce from state storage
    function latestNonce(
        address srcStoragePrecompileAddress,
        bytes32 storageKey,
        bytes4 laneId
    ) internal view returns (uint64) {
        // 1. Get `OutboundLaneData` from storage
        // Full storage key == storageKey + Blake2_128Concat(laneId)
        bytes memory hashedLaneId = Hash.blake2b128Concat(
            abi.encodePacked(laneId)
        );
        bytes memory fullStorageKey = abi.encodePacked(
            storageKey,
            hashedLaneId
        );

        // Do get data by calling state storage precompile
        (bool success, bytes memory data) = address(srcStoragePrecompileAddress).staticcall(
            abi.encodeWithSelector(
                IStateStorage.state_storage.selector,
                fullStorageKey
            )
        );
        revertIfFailed(success, data, "Get latest nonce failed");

        // 2. Decode `OutboundLaneData` and return the latest nonce
        CommonTypes.OutboundLaneData memory outboundLaneData = CommonTypes
            .decodeOutboundLaneData(data);
        return outboundLaneData.latestGeneratedNonce;
    }

    function deriveAccountId(bytes4 srcChainId, bytes32 accountId)
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
            srcChainId,
            accountId
        );
        return Hash.blake2bHash(data);
    }

    function revertIfFailed(
        bool success,
        bytes memory resultData,
        string memory revertMsg
    ) internal pure {
        if (!success) {
            if (resultData.length > 0) {
                assembly {
                    let resultDataSize := mload(resultData)
                    revert(add(32, resultData), resultDataSize)
                }
            } else {
                revert(revertMsg);
            }
        }
    }

    // dispatch pallet dispatth-call
    function dispatch(
        address srcDispatchPrecompileAddress,
        bytes memory callEncoded,
        string memory errMsg
    ) internal {
        // Dispatch the call
        (bool success, bytes memory data) = srcDispatchPrecompileAddress.call(callEncoded);
        revertIfFailed(success, data, errMsg);
    }

    // derive an address from remote(source chain) sender address
    // H160(sender on the sourc chain) > AccountId32 > derived AccountId32 > H160
    function deriveSenderFromRemote(
        bytes4 srcChainId,
        address srcMessageSender
    ) internal view returns (address) {
        // H160(sender on the sourc chain) > AccountId32
        bytes32 derivedSubstrateAddress = AccountId.deriveSubstrateAddress(
            srcMessageSender
        );

        // AccountId32 > derived AccountId32
        bytes32 derivedAccountId = SmartChainXLib.deriveAccountId(
            srcChainId,
            derivedSubstrateAddress
        );
        
        // derived AccountId32 > H160
        address result = AccountId.deriveEthereumAddress(derivedAccountId);

        return result;
    }

    // Get the last delivered nonce from the state storage of the target chain's inbound lane
    function lastDeliveredNonce(
        address tgtStoragePrecompileAddress,
        bytes32 storageKey,
        bytes4 inboundLaneId
    ) internal view returns (uint64) {
        // 1. Get `inboundLaneData` from storage
        // Full storage key == storageKey + Blake2_128Concat(laneId)
        bytes memory hashedLaneId = Hash.blake2b128Concat(
            abi.encodePacked(inboundLaneId)
        );
        bytes memory fullStorageKey = abi.encodePacked(
            storageKey,
            hashedLaneId
        );

        // Do get data by calling state storage precompile
        (bool success, bytes memory data) = address(tgtStoragePrecompileAddress).staticcall(
            abi.encodeWithSelector(
                IStateStorage.state_storage.selector,
                fullStorageKey
            )
        );
        revertIfFailed(success, data, "get last delivered nonce failed");

        // 2. Decode `InboundLaneData` and return the last delivered nonce
        return CommonTypes.getLastDeliveredNonceFromInboundLaneData(data);
    }
}
