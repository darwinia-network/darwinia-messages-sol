// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "../darwinia/MappingTokenAddress.sol";

interface IDispatchCall {
    function generated_nonce() view external returns(uint64);
    function send_message(uint32 pallet_id, bytes4 lane_id, bytes memory message, uint256 fee) external;
}

contract MockSubToSubBridge is MappingTokenAddress {
    function outbound_latest_generated_nonce(bytes4 laneid) external view returns (uint64) {
        return IDispatchCall(DISPATCH).generated_nonce();
    }

    function inbound_latest_received_nonce(bytes4 laneid) external view returns (uint64) {
        // suppose received nonce is generated nonce
        return IDispatchCall(DISPATCH).generated_nonce();
    }

    function encode_unlock_from_remote_dispatch_call(
        uint32 spec_version,
        uint64 weight,
        uint32 token_type,
        address original_token,
        bytes memory recipient,
        uint256 amount) external pure returns(bytes memory) {
            return abi.encode(
                spec_version,
                weight,
                token_type,
                original_token,
                recipient,
                amount);
    }

    function encode_send_message_dispatch_call(uint32 msg_pallet_id, bytes4 lane_id, bytes memory message, uint256 fee) external pure returns(bytes memory) {
        return abi.encodeWithSelector(
            IDispatchCall.send_message.selector,
            msg_pallet_id,
            lane_id,
            message,
            fee
        );
    }
}

