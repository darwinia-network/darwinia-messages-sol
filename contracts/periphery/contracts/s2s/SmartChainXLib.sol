// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "@darwinia/contracts-utils/contracts/Bytes.sol";

import "./interfaces/IStateStorage.sol";
import "./types/CommonTypes.sol";

library SmartChainXLib {
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
        (bool success, bytes memory returndata) = dispatchAddress.call(
            sendMessageCallEncoded
        );
        if (!success) {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("Send message failed");
            }
        }
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

    function marketFee(address storageAddress, bytes memory storageKey)
        internal
        view
        returns (uint128)
    {
        bytes memory data = IStateStorage(storageAddress).state_storage(
            storageKey
        );
        CommonTypes.Relayer memory relayer = CommonTypes
            .getLastRelayerFromVec(data);
        return relayer.fee;
    }
}