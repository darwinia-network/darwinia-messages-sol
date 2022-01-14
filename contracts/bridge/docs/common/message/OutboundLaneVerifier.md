# OutboundLaneVerifier





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [constructor](#constructor)
  - [verify_messages_delivery_proof](#verify_messages_delivery_proof)
  - [getLaneInfo](#getlaneinfo)
  - [encodeMessageKey](#encodemessagekey)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| lightClient | contract ILightClient |
| bridgedLanePosition | uint32 |
| bridgedChainPosition | uint32 |
| thisLanePosition | uint32 |
| thisChainPosition | uint32 |



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



### verify_messages_delivery_proof
No description


#### Declaration
```solidity
  function verify_messages_delivery_proof(
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
No description


#### Declaration
```solidity
  function encodeMessageKey(
  ) public returns (uint256)
```

#### Modifiers:
No modifiers





