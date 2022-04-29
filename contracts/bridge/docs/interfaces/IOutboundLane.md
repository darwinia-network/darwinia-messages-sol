# IOutboundLane


The app layer could implement the interface `IOnMessageDelivered` to receive message dispatch result (optionally)


## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [send_message](#send_message)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### send_message
Send message over lane.
Submitter could be a contract or just an EOA address.
At the beginning of the launch, submmiter is permission, after the system is stable it will be permissionless.



#### Declaration
```solidity
  function send_message(
    address targetContract,
    bytes encoded
  ) external returns (uint256)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`targetContract` | address | The target contract address which you would send cross chain message to
|`encoded` | bytes | The calldata which encoded by ABI Encoding `abi.encodePacked(SELECTOR, PARAMS)`



