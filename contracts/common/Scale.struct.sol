// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

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
        uint8 assetType;
        address backing;
        address payable recipient;
        address token;
        address target;
        uint128 value;
    }
}
