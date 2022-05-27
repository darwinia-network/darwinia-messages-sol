// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "@darwinia/contracts-utils/contracts/Bytes.sol";

import "./interfaces/IStateStorage.sol";
import "./types/CommonTypes.sol";

library SmartChainXLib {
    bytes public constant account_derivation_prefix = "pallet-bridge/account-derivation/account";

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
        (bool success, bytes memory data) = dispatchAddress.call(
            sendMessageCallEncoded
        );
        revertIfFailed(success, data, "Send message failed");
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
    function latestNonce(address storageAddress, bytes memory storageKey)
        internal
        view
        returns (uint64)
    {
        (bool success, bytes memory data) = address(storageAddress).staticcall(
            abi.encodeWithSelector(
                IStateStorage.state_storage.selector,
                abi.encodePacked(storageKey)
            )
        );
        revertIfFailed(success, data, "Get latest nonce failed");

        CommonTypes.OutboundLaneData memory outboundLaneData = CommonTypes.decodeOutboundLaneData(
            data
        );
        return outboundLaneData.latestGeneratedNonce;
    }

    function blake2_256(address blake2bAddress, bytes memory data) internal returns (bytes32) {
        (bool success, bytes memory result) = blake2bAddress.call(
            abi.encodePacked(
                bytes4(keccak256("blake2_256(bytes)")),
                abi.encode(data)
            )
        );
        revertIfFailed(success, result, "Blake2_256 failed");

        return Bytes.toBytes32(result);
    }

    function deriveAccountId(address blake2bAddress, bytes4 srcChainId, bytes32 accountId) internal returns (bytes32) {
        bytes memory prefixLength = ScaleCodec.encodeUintCompact(account_derivation_prefix.length);
        bytes memory data = abi.encodePacked(prefixLength, account_derivation_prefix, srcChainId, accountId);
        return blake2_256(blake2bAddress, data);
    }

    function revertIfFailed(bool success, bytes memory resultData, string memory revertMsg) private pure {
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
}
