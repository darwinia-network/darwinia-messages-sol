# MockBSCLightClient





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [constructor](#constructor)
  - [setBound](#setbound)
  - [relayHeader](#relayheader)
  - [verify_messages_proof](#verify_messages_proof)
  - [verify_messages_delivery_proof](#verify_messages_delivery_proof)
  - [verify_storage_proof](#verify_storage_proof)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| LANE_COMMITMENT_POSITION | uint256 |
| lanes | mapping(uint32 => mapping(uint32 => address)) |
| stateRoot | bytes32 |



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



### setBound
No description


#### Declaration
```solidity
  function setBound(
  ) public
```

#### Modifiers:
No modifiers



### relayHeader
No description


#### Declaration
```solidity
  function relayHeader(
  ) public
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



### verify_messages_delivery_proof
No description


#### Declaration
```solidity
  function verify_messages_delivery_proof(
  ) external returns (bool)
```

#### Modifiers:
No modifiers



### verify_storage_proof
No description


#### Declaration
```solidity
  function verify_storage_proof(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers





