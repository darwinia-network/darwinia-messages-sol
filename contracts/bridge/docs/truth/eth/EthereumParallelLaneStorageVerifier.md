# EthereumParallelLaneStorageVerifier





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [constructor](#constructor)
  - [state_root](#state_root)
  - [verify_lindex](#verify_lindex)
  - [verify_messages_proof](#verify_messages_proof)
  - [toUint](#touint)
  - [toBytes32](#tobytes32)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| LINDEX | uint256 |
| LANE_ROOT_SLOT | uint256 |
| LIGHT_CLIENT | address |
| PARALLEL_OUTLANE | address |



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



### state_root
No description


#### Declaration
```solidity
  function state_root(
  ) public returns (bytes32)
```

#### Modifiers:
No modifiers



### verify_lindex
No description


#### Declaration
```solidity
  function verify_lindex(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### verify_messages_proof
No description


#### Declaration
```solidity
  function verify_messages_proof(
  ) external returns (bool)
```

#### Modifiers:
No modifiers



### toUint
No description


#### Declaration
```solidity
  function toUint(
  ) internal returns (uint256 data)
```

#### Modifiers:
No modifiers



### toBytes32
No description


#### Declaration
```solidity
  function toBytes32(
  ) internal returns (bytes32 data)
```

#### Modifiers:
No modifiers





