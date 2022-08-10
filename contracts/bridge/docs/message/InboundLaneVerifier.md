# InboundLaneVerifier





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [constructor](#constructor)
  - [_verify_messages_proof](#_verify_messages_proof)
  - [getLaneInfo](#getlaneinfo)
  - [encodeMessageKey](#encodemessagekey)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| slot0 | struct InboundLaneVerifier.Slot0 |
| lightClient | contract ILightClient |



## Functions

### constructor
No description


#### Declaration
```solidity
  function constructor(
  ) public
```

#### Modifiers:
No modifiers



### _verify_messages_proof
No description


#### Declaration
```solidity
  function _verify_messages_proof(
  ) internal
```

#### Modifiers:
No modifiers



### getLaneInfo
No description


#### Declaration
```solidity
  function getLaneInfo(
  ) external returns (uint32, uint32, uint32, uint32)
```

#### Modifiers:
No modifiers



### encodeMessageKey
32 bytes to identify an unique message from source chain
MessageKey encoding:
BridgedChainPosition | BridgedLanePosition | ThisChainPosition | ThisLanePosition | Nonce
[0..8)   bytes ---- Reserved
[8..12)  bytes ---- BridgedChainPosition
[16..20) bytes ---- BridgedLanePosition
[12..16) bytes ---- ThisChainPosition
[20..24) bytes ---- ThisLanePosition
[24..32) bytes ---- Nonce, max of nonce is `uint64(-1)`


#### Declaration
```solidity
  function encodeMessageKey(
  ) public returns (uint256)
```

#### Modifiers:
No modifiers





