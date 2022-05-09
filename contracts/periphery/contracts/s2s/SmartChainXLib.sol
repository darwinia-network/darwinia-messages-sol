// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";

library SmartChainXLib {
    address public constant DISPATCH =
        0x0000000000000000000000000000000000000019;

    // `Channel` is a helper term to define params to route message to target chain
    // 
    //  send message call index at source chain 
    //   -> 
    //  lane id in source chain
    //   -> 
    //  spec version of target chain
    struct Channel {
        bytes2 sendMessageCallIndexAtSourceChain;
        bytes4 laneId;
        uint32 specVersionOfTargetChain;
    }

    event DispatchResult(bool success, bytes result);

    function sendMessage(
        Channel memory channel,
        uint256 deliveryAndDispatchFee,
        bytes memory message
    ) internal {
        // the pricision in contract is 18, and in pallet is 9, transform the fee value
        uint256 feeInPalletPricision = deliveryAndDispatchFee / (10**9);

        // encode send_message call
        BridgeMessages.SendMessageCall memory sendMessageCall = BridgeMessages
            .SendMessageCall(
                channel.sendMessageCallIndexAtSourceChain,
                channel.laneId,
                message,
                uint128(feeInPalletPricision)
            );

        bytes memory sendMessageCallEncoded = BridgeMessages
            .encodeSendMessageCall(sendMessageCall);

        // dispatch the send_message call
        (bool success, bytes memory returndata) = DISPATCH.call(
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

    function buildMessage(
        Channel memory channel,
        uint64 callWeight,
        bytes memory callEncoded
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
                    channel.specVersionOfTargetChain,
                    callWeight,
                    origin,
                    dispatchFeePayment,
                    callEncoded
                )
            );
    }
}
