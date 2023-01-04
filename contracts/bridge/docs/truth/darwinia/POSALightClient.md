# POSALightClient





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [constructor](#constructor)
  - [block_number](#block_number)
  - [merkle_root](#merkle_root)
  - [import_message_commitment](#import_message_commitment)
- [Events](#events)
  - [MessageRootImported](#messagerootimported)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| latest_block_number | uint256 |
| latest_message_root | bytes32 |



## Functions

### constructor
No description


#### Declaration
```solidity
  function constructor(
  ) public EcdsaAuthority
```

#### Modifiers:
| Modifier |
| --- |
| EcdsaAuthority |



### block_number
No description


#### Declaration
```solidity
  function block_number(
  ) public returns (uint256)
```

#### Modifiers:
No modifiers



### merkle_root
No description


#### Declaration
```solidity
  function merkle_root(
  ) public returns (bytes32)
```

#### Modifiers:
No modifiers



### import_message_commitment
No description
> Import message commitment which signed by RelayAuthorities


#### Declaration
```solidity
  function import_message_commitment(
    struct POSACommitmentScheme.Commitment commitment,
    bytes[] signatures
  ) external
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`commitment` | struct POSACommitmentScheme.Commitment | contains the message_root with block_number that is used for message verify
|`signatures` | bytes[] | The signatures of the relayers signed the commitment.



## Events

### MessageRootImported
No description

  


