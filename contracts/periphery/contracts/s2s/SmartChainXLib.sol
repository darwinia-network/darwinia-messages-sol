// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "@darwinia/contracts-utils/contracts/Bytes.sol";
import "@darwinia/contracts-utils/contracts/Hash.sol";

import "./interfaces/IStateStorage.sol";
import "./types/CommonTypes.sol";

library SmartChainXLib {
    bytes public constant account_derivation_prefix =
        "pallet-bridge/account-derivation/account";

    event DispatchResult(bool success, bytes result);

    // Send message over lane by calling the `send_message` dispatch call on
    // the source chain which is identified by the `callIndex` param.
    function sendMessage(
        address dispatchAddress,
        bytes2 callIndex,
        bytes4 laneId,
        uint256 deliveryAndDispatchFee,
        bytes memory message
    ) internal {
        // the pricision in contract is 18, and in pallet is 9, transform the fee value
        uint256 feeOfPalletPrecision = deliveryAndDispatchFee / (10**9);

        // encode send_message call
        BridgeMessages.SendMessageCall memory sendMessageCall = BridgeMessages
            .SendMessageCall(
                callIndex,
                laneId,
                message,
                uint128(feeOfPalletPrecision)
            );

        bytes memory sendMessageCallEncoded = BridgeMessages
            .encodeSendMessageCall(sendMessageCall);

        // dispatch the send_message call
        dispatch(
            dispatchAddress,
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
        Types.EnumItemWithAccountId memory origin = Types.EnumItemWithAccountId(
                2, // index in enum
                AccountId.fromAddress(address(this)) // UserApp contract address
            );

        Types.EnumItemWithNull memory dispatchFeePayment = Types
            .EnumItemWithNull(0);

        return
            Types.encodeMessage(
                Types.Message(
                    specVersion,
                    weight,
                    origin,
                    dispatchFeePayment,
                    call
                )
            );
    }

    // Get market fee from state storage of the substrate chain
    function marketFee(address storageAddress, bytes32 storageKey)
        internal
        view
        returns (uint128)
    {
        (bool success, bytes memory data) = address(storageAddress).staticcall(
            abi.encodeWithSelector(
                IStateStorage.state_storage.selector,
                storageKey
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
        address storageAddress,
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
        (bool success, bytes memory data) = address(storageAddress).staticcall(
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
        address dispatchAddress,
        bytes memory callEncoded,
        string memory errMsg
    ) internal {
        // Dispatch the call
        (bool success, bytes memory data) = dispatchAddress.call(callEncoded);
        revertIfFailed(success, data, errMsg);
    }
}
