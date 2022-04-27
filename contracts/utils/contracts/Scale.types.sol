// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./ScaleCodec.sol";

library Types {
    struct EnumItemWithAccountId {
        uint8 index;
        bytes32 accountId;
    }

    function encodeEnumItemWithAccountId(EnumItemWithAccountId memory item) internal pure returns (bytes memory) {
        return abi.encodePacked(item.index, item.accountId);
    }

    struct EnumItemWithNull {
        uint8 index;
    }

    function encodeEnumItemWithNull(EnumItemWithNull memory item) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(item.index));
    }

    struct Message {
        uint32 specVersion;
        uint64 weight;
        EnumItemWithAccountId origin;
        EnumItemWithNull dispatchFeePayment;
        bytes call;
    }

    function encodeMessage(Message memory msg1) internal pure returns (bytes memory) {
        return abi.encodePacked(
            ScaleCodec.encode32(msg1.specVersion), 
            ScaleCodec.encode64(msg1.weight),
            encodeEnumItemWithAccountId(msg1.origin),
            encodeEnumItemWithNull(msg1.dispatchFeePayment),
            ScaleCodec.encodeBytes(msg1.call)
        );
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
        return abi.encodePacked(
            call.callIndex, 
            call.tokenAddress, 
            amountEncoded,
            ScaleCodec.encodeBytes(call.recipient)
        );
    }
}

library System {
    struct RemarkCall {
        bytes2 callIndex;
        bytes remark;
    }

    function encodeRemarkCall(RemarkCall memory call) internal pure returns (bytes memory) {
        return abi.encodePacked(
            call.callIndex, 
            ScaleCodec.encodeBytes(call.remark)
        );
    }
}

library Balances {
    struct TransferCall {
        bytes2 callIndex;
        Types.EnumItemWithAccountId dest;
        uint128 value;
    }

    function encodeTransferCall(TransferCall memory call) internal pure returns (bytes memory) {
        bytes memory destEncoded = Types.encodeEnumItemWithAccountId(call.dest);
        bytes memory valueEncoded = ScaleCodec.encodeUintCompact(call.value);
        return abi.encodePacked(
            call.callIndex, 
            destEncoded, 
            valueEncoded
        );
    }
}

library BridgeMessages {
    struct SendMessageCall {
        bytes2 callIndex;
        bytes4 lineId;
        Types.Message payload;
        uint128 deliveryAndDispatchFee;
    }

    function encodeSendMessageCall(SendMessageCall memory call) internal pure returns (bytes memory) {
        return abi.encodePacked(
            call.callIndex, 
            call.lineId, 
            Types.encodeMessage(call.payload),
            ScaleCodec.encode128(call.deliveryAndDispatchFee)
        );
    }
}
