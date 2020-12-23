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
}
