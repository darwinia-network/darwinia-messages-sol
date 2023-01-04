# BEEFYCommitmentScheme


Beefy commitment scheme


## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [hash](#hash)
  - [hash](#hash-1)
  - [encode](#encode)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| PAYLOAD_SCALE_ENCOD_PREFIX | bytes4 |



## Functions

### hash
Return hash of commitment


#### Declaration
```solidity
  function hash(
  ) public returns (bytes32)
```

#### Modifiers:
No modifiers



### hash
Return hash of payload


#### Declaration
```solidity
  function hash(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### encode
No description


#### Declaration
```solidity
  function encode(
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers





