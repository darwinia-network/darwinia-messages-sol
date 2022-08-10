# EcdsaAuthority



> Stores the relayers and a threshold

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [constructor](#constructor)
  - [add_relayer](#add_relayer)
  - [remove_relayer](#remove_relayer)
  - [swap_relayer](#swap_relayer)
  - [change_threshold](#change_threshold)
  - [get_threshold](#get_threshold)
  - [is_relayer](#is_relayer)
  - [get_relayers](#get_relayers)
  - [domain_separator](#domain_separator)
- [Events](#events)
  - [AddedRelayer](#addedrelayer)
  - [RemovedRelayer](#removedrelayer)
  - [ChangedThreshold](#changedthreshold)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| nonce | uint256 |
| count | uint256 |
| threshold | uint256 |
| relayers | mapping(address => address) |



## Functions

### constructor
No description
> Sets initial storage of contract.


#### Declaration
```solidity
  function constructor(
    bytes32 _domain_separator,
    address[] _relayers,
    uint256 _threshold
  ) public
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_domain_separator` | bytes32 | source chain domain_separator
|`_relayers` | address[] | List of relayers.
|`_threshold` | uint256 | Number of required confirmations for check commitment or change relayers.

### add_relayer
Adds the `relayer` to the registry and updates the threshold to `_threshold`.

> Allows to add a new relayer to the registry and update the threshold at the same time.
     This can only be done via multi-sig.


#### Declaration
```solidity
  function add_relayer(
    address _relayer,
    uint256 _threshold,
    bytes[] _signatures
  ) external
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_relayer` | address | New relayer address.
|`_threshold` | uint256 | New threshold.
|`_signatures` | bytes[] | The signatures of the relayers which to add new relayer and update the `threshold` .

### remove_relayer
Removes the `relayer` from the registry and updates the threshold to `_threshold`.

> Allows to remove a relayer from the registry and update the threshold at the same time.
     This can only be done via multi-sig.


#### Declaration
```solidity
  function remove_relayer(
    address _prevRelayer,
    address _relayer,
    uint256 _threshold,
    bytes[] _signatures
  ) external
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_prevRelayer` | address | Relayer that pointed to the relayer to be removed in the linked list
|`_relayer` | address | Relayer address to be removed.
|`_threshold` | uint256 | New threshold.
|`_signatures` | bytes[] | The signatures of the relayers which to remove a relayer and update the `threshold` .

### swap_relayer
Replaces the `oldRelayer` in the registry with `newRelayer`.

> Allows to swap/replace a relayer from the registry with another address.
     This can only be done via multi-sig.


#### Declaration
```solidity
  function swap_relayer(
    address _prevRelayer,
    address _oldRelayer,
    address _newRelayer,
    bytes[] _signatures
  ) external
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_prevRelayer` | address | Relayer that pointed to the relayer to be replaced in the linked list
|`_oldRelayer` | address | Relayer address to be replaced.
|`_newRelayer` | address | New relayer address.
|`_signatures` | bytes[] | The signatures of the guards which to swap/replace a relayer and update the `threshold` .

### change_threshold
Changes the threshold of the registry to `_threshold`.

> Allows to update the number of required confirmations by relayers.
     This can only be done via multi-sig.


#### Declaration
```solidity
  function change_threshold(
    uint256 _threshold,
    bytes[] _signatures
  ) external
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_threshold` | uint256 | New threshold.
|`_signatures` | bytes[] | The signatures of the guards which to update the `threshold` .

### get_threshold
No description


#### Declaration
```solidity
  function get_threshold(
  ) public returns (uint256)
```

#### Modifiers:
No modifiers



### is_relayer
No description


#### Declaration
```solidity
  function is_relayer(
  ) public returns (bool)
```

#### Modifiers:
No modifiers



### get_relayers
No description
> Returns array of relayers.


#### Declaration
```solidity
  function get_relayers(
  ) public returns (address[])
```

#### Modifiers:
No modifiers


#### Returns:
| Type | Description |
| --- | --- |
|`Array` | of relayers.
### _check_relayer_signatures
No description
> Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.


#### Declaration
```solidity
  function _check_relayer_signatures(
    bytes32 structHash,
    bytes[] signatures
  ) internal
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`structHash` | bytes32 | The struct Hash of the data (could be either a message/commitment hash).
|`signatures` | bytes[] | Signature data that should be verified. only ECDSA signature.
 Signers need to be sorted in ascending order

### domain_separator
No description


#### Declaration
```solidity
  function domain_separator(
  ) public returns (bytes32)
```

#### Modifiers:
No modifiers





## Events

### AddedRelayer
No description

  


### RemovedRelayer
No description

  


### ChangedThreshold
No description

  


