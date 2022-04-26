// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./interfaces/ISubToSubBridge.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";

abstract contract SmartChainApp {
	address public constant DISPATCH_ENCODER = 0x0000000000000000000000000000000000000018;
    address public constant DISPATCH = 0x0000000000000000000000000000000000000019;

    receive() external payable {}

    fallback() external {}

    // move to solidity encode?
    // TODO: 
    //   define channel constant from palletIndex and laneId
    function sendMessage(uint32 palletIndex, bytes4 laneId, bytes calldata message) public payable returns (bool) {
    	// the pricision in contract is 18, and in pallet is 9, transform the fee value
        uint256 fee = msg.value/(10**9); 
        bytes memory sendMessageCall = ISubToSubBridge(DISPATCH_ENCODER).encode_send_message_dispatch_call(
            palletIndex,
            laneId,
            message,
            fee
        );
        
        (bool success, ) = DISPATCH.call(sendMessageCall);
        return success;
    }
    
    // origin?
    function buildMessage(uint32 specVersion, uint64 weight, bytes calldata callEncoded) public pure returns (bytes memory) {
        Types.EnumItemWithAccountId memory origin = Types.EnumItemWithAccountId(
            2, // index in enum
            AccountId.fromAddress(address(this)) // UserApp contract address
        );
        Types.EnumItemWithNull memory dispatchFeePayment = Types.EnumItemWithNull(0);
        Types.Message memory message = Types.Message(
            specVersion,
            weight,
            origin,
            dispatchFeePayment,
            callEncoded
        );
        return abi.encode(Types.encodeMessage(message));
    }
}
