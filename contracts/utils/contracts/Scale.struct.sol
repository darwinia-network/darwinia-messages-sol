// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./ScaleCodec.sol";

library ScaleStruct {
    struct LockEvent {
        bytes2 index;
        bytes32 sender;
        address recipient;
        address token;
        uint128 value;
    }

    struct IssuingEvent {
        bytes2 index;
        uint8 eventType;
        address backing;
        address sender;
        address payable recipient;
        address token;
        address target;
        uint256 value;
    }

}

library S2SBacking {
    struct UnlockFromRemoteCall {
        bytes2 callIndex;
        address tokenAddress;
        uint256 amount;
        bytes recipient;
    }

    function encodeUnlockFromRemoteCall(UnlockFromRemoteCall memory call) internal pure returns (bytes memory) {
        bytes32 amountEncoded = ScaleCodec.encode256(call.amount);
        bytes memory recipientLengthEncoded = ScaleCodec.encodeUintCompact(call.recipient.length);
        return abi.encodePacked(
            call.callIndex, 
            call.tokenAddress, 
            amountEncoded,
            recipientLengthEncoded, 
            call.recipient
        );
    }
}

library System {
    struct RemarkCall {
        bytes2 callIndex;
        bytes remark;
    }

    function encodeRemarkCall(RemarkCall memory call) internal pure returns (bytes memory) {
        bytes memory remarkLengthEncoded = ScaleCodec.encodeUintCompact(call.remark.length);
        return abi.encodePacked(
            call.callIndex, 
            remarkLengthEncoded, 
            call.remark
        );
    }
}

