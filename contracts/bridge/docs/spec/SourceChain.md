# SourceChain


Source chain specification


## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [hash](#hash)
  - [hash](#hash-1)
  - [hash](#hash-2)
  - [hash](#hash-3)
  - [hash](#hash-4)
  - [hash](#hash-5)
  - [decodeMessageKey](#decodemessagekey)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| OUTBOUNDLANEDATA_TYPEHASH | bytes32 |
| MESSAGE_TYPEHASH | bytes32 |
| MESSAGEPAYLOAD_TYPEHASH | bytes32 |



## Functions

### hash
Hash of OutboundLaneData


#### Declaration
```solidity
  function hash(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### hash
Hash of OutboundLaneDataStorage


#### Declaration
```solidity
  function hash(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### hash
Hash of MessageStorage


#### Declaration
```solidity
  function hash(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### hash
Hash of Message[]


#### Declaration
```solidity
  function hash(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### hash
Hash of Message


#### Declaration
```solidity
  function hash(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### hash
Hash of MessagePayload


#### Declaration
```solidity
  function hash(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### decodeMessageKey
Decode message key



#### Declaration
```solidity
  function decodeMessageKey(
    uint256 encoded
  ) internal returns (struct SourceChain.MessageKey key)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`encoded` | uint256 | Encoded message key

#### Returns:
| Type | Description |
| --- | --- |
|`key` | Decoded message key


