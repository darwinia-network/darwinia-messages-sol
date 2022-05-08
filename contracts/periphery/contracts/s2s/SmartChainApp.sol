// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";

abstract contract SmartChainApp {
    address public constant DISPATCH = 0x0000000000000000000000000000000000000019;

    event DispatchResult(bool success, bytes result);

    function sendMessage(bytes2 sendMessageCallIndexAtSourceChain, bytes4 laneId, uint256 fee, bytes memory message) internal {
    	// the pricision in contract is 18, and in pallet is 9, transform the fee value
        uint256 feeInPallet = fee/(10**9); 

        // encode send_message call
        BridgeMessages.SendMessageCall memory sendMessageCall = 
            BridgeMessages.SendMessageCall(
                callIndex,
                laneId,
                message,
                uint128(feeInPallet)
            );

        bytes memory sendMessageCallEncoded = 
            BridgeMessages.encodeSendMessageCall(sendMessageCall);

        // dispatch the send_message call
        (bool success, bytes memory returndata) = DISPATCH.call(sendMessageCallEncoded);
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

    
    function buildMessage(uint32 specVersionOfTargetChain, uint64 callWeight, bytes memory callEncoded) internal returns (bytes memory) {
        Types.EnumItemWithAccountId memory origin = Types.EnumItemWithAccountId(
            2, // index in enum
            AccountId.fromAddress(address(this)) // UserApp contract address
        );

        Types.EnumItemWithNull memory dispatchFeePayment = 
            Types.EnumItemWithNull(0);

        return Types.encodeMessage(
            Types.Message(
                specVersion,
                weight,
                origin,
                dispatchFeePayment,
                callEncoded
            )
        );
    }
}
