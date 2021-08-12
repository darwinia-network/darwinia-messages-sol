# BasicInboundChannel





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [constructor](#constructor)
  - [submit](#submit)
  - [verifyMessages](#verifymessages)
  - [processMessages](#processmessages)
  - [validateMessagesMatchRoot](#validatemessagesmatchroot)
  - [hashMMRLeaf](#hashmmrleaf)
- [Events](#events)
  - [MessageDispatched](#messagedispatched)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| MAX_GAS_PER_MESSAGE | uint256 |
| nonce | uint64 |
| lightClientBridge | contract ILightClientBridge |



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



### submit
No description


#### Declaration
```solidity
  function submit(
  ) public
```

#### Modifiers:
No modifiers



### verifyMessages
No description


#### Declaration
```solidity
  function verifyMessages(
  ) internal
```

#### Modifiers:
No modifiers



### processMessages
No description


#### Declaration
```solidity
  function processMessages(
  ) internal
```

#### Modifiers:
No modifiers



### validateMessagesMatchRoot
No description


#### Declaration
```solidity
  function validateMessagesMatchRoot(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### hashMMRLeaf
No description


#### Declaration
```solidity
  function hashMMRLeaf(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers





## Events

### MessageDispatched
No description

  


