# IOnMessageDelivered


The app layer could implement the interface `IOnMessageDelivered` to receive message dispatch result (optionally)


## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [on_messages_delivered](#on_messages_delivered)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### on_messages_delivered
Message delivered callback



#### Declaration
```solidity
  function on_messages_delivered(
    uint256 nonce,
    bool dispatch_result
  ) external
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`nonce` | uint256 | Nonce of the callback message
|`dispatch_result` | bool | Dispatch result of cross chain message



