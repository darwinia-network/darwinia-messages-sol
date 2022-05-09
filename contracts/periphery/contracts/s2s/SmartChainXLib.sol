// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";

library SmartChainXLib {
    address public constant DISPATCH =
        0x0000000000000000000000000000000000000019;

    // `LaneIndex` is call index + lane id
    struct LaneIndex {
        // send message call index at source chain 
        bytes2 sendMessageCallIndexAtSourceChain;
        
        // lane id in source chain
        bytes4 laneId;
    }

    event DispatchResult(bool success, bytes result);

    function sendMessage(
        LaneIndex memory laneIndex,
        uint256 deliveryAndDispatchFee,
        bytes memory message
    ) internal {
        // the pricision in contract is 18, and in pallet is 9, transform the fee value
        uint256 feeInPalletPricision = deliveryAndDispatchFee / (10**9);

        // encode send_message call
        BridgeMessages.SendMessageCall memory sendMessageCall = BridgeMessages
            .SendMessageCall(
                laneIndex.sendMessageCallIndexAtSourceChain,
                laneIndex.laneId,
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
        uint32 specVersionOfTargetChain,
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
                    specVersionOfTargetChain,
                    callWeight,
                    origin,
                    dispatchFeePayment,
                    callEncoded
                )
            );
    }
}
