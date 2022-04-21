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
        address backing;
        address sender;
        address payable recipient;
        address token;
        address target;
        uint256 value;
    }

    // struct Arg {
    //     uint16 type;
    //     bytes value;
    // }

    // struct SystemRemarkCall {
    //     bytes2 callIndex;
    //     bytes remark;
    // }
}

// function encodeSystemRemarkCall(SystemRemarkCall call) {
//   call.callIndex + 
//   call.remark.length
  
// }
