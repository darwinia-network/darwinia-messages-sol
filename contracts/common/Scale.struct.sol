// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library ScaleStruct {
    struct LockEvent {
        bytes2 index;
        bytes32 sender;
        address recipient;
        // 0 -> ring, 1 -> kton
        uint8 token;
        uint128 value;
    }
}
