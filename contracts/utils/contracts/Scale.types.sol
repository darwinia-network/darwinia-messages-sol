// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./ScaleCodec.sol";

library Types {
    struct EnumItemAccountId32 {
        uint8 index;
        bytes32 accountId;
    }

    function encodeEnumItemAccountId32(EnumItemAccountId32 memory item) internal pure returns (bytes memory) {
        bytes memory prefix = abi.encodePacked(uint8(item.index));
        return abi.encodePacked(prefix, item.accountId);
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
        Types.EnumItemAccountId32 dest;
        uint128 value;
    }

    function encodeTransferCall(TransferCall memory call) internal pure returns (bytes memory) {
        bytes memory destEncoded = Types.encodeEnumItemAccountId32(call.dest);
        bytes memory valueEncoded = ScaleCodec.encodeUintCompact(call.value);
        return abi.encodePacked(
            call.callIndex, 
            destEncoded, 
            valueEncoded
        );
    }
}