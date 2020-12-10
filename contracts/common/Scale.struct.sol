pragma solidity >=0.5.0 <0.6.0;

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
