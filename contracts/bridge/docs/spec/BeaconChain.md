# BeaconChain


Beacon chain specification


## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [compute_signing_root](#compute_signing_root)
  - [compute_fork_data_root](#compute_fork_data_root)
  - [compute_domain](#compute_domain)
  - [hash_tree_root](#hash_tree_root)
  - [hash_tree_root](#hash_tree_root-1)
  - [hash_tree_root](#hash_tree_root-2)
  - [hash_tree_root](#hash_tree_root-3)
  - [hash_tree_root](#hash_tree_root-4)
  - [hash_tree_root](#hash_tree_root-5)
  - [to_little_endian_64](#to_little_endian_64)
  - [to_little_endian_256](#to_little_endian_256)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| BLSPUBLICKEY_LENGTH | uint64 |
| BLSSIGNATURE_LENGTH | uint64 |
| SYNC_COMMITTEE_SIZE | uint64 |



## Functions

### compute_signing_root
Return the signing root for the corresponding signing data.


#### Declaration
```solidity
  function compute_signing_root(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### compute_fork_data_root
Return the 32-byte fork data root for the ``current_version`` and ``genesis_validators_root``.
This is used primarily in signature domains to avoid collisions across forks/chains.


#### Declaration
```solidity
  function compute_fork_data_root(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### compute_domain
Return the domain for the ``domain_type`` and ``fork_version``.


#### Declaration
```solidity
  function compute_domain(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### hash_tree_root
Return hash tree root of fork data


#### Declaration
```solidity
  function hash_tree_root(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### hash_tree_root
Return hash tree root of signing data


#### Declaration
```solidity
  function hash_tree_root(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### hash_tree_root
Return hash tree root of sync committee


#### Declaration
```solidity
  function hash_tree_root(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### hash_tree_root
Return hash tree root of beacon block header


#### Declaration
```solidity
  function hash_tree_root(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### hash_tree_root
Return hash tree root of beacon block body


#### Declaration
```solidity
  function hash_tree_root(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### hash_tree_root
Return hash tree root of execution payload


#### Declaration
```solidity
  function hash_tree_root(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### to_little_endian_64
Return little endian of uint64


#### Declaration
```solidity
  function to_little_endian_64(
  ) internal returns (bytes8)
```

#### Modifiers:
No modifiers



### to_little_endian_256
Return little endian of uint256


#### Declaration
```solidity
  function to_little_endian_256(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers





