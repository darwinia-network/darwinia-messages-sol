# OutboundLaneVerifier





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [constructor](#constructor)
  - [_verify_messages_delivery_proof](#_verify_messages_delivery_proof)
  - [getLaneInfo](#getlaneinfo)
  - [encodeMessageKey](#encodemessagekey)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| slot0 | struct OutboundLaneVerifier.Slot0 |
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



### _verify_messages_delivery_proof
No description


#### Declaration
```solidity
  function _verify_messages_delivery_proof(
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





