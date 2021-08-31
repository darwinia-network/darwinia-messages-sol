# BasicOutboundChannel





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [submit](#submit)
- [Events](#events)
  - [Message](#message)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| OUTBOUND_ROLE | bytes32 |
| nonce | uint256 |



## Functions

### submit
No description
> Sends a message across the channel

#### Declaration
```solidity
  function submit(
  ) external
```

#### Modifiers:
No modifiers





## Events

### Message
The Message is the structure of EthereRPC which should be delivery to Darwinia


  

#### Params:
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`source` | address |  | The source sender address which send the message
|`nonce` | uint256 |  | The ID used to uniquely identify the message
|`payload` | bytes |  | The calldata which encoded by ABI Encoding `abi.encodePacked(SELECTOR, PARAMS)`
