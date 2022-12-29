# IncrementalMerkleTree


An incremental merkle tree modeled on the eth2 deposit contract.


## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [insert](#insert)
  - [rootWithCtx](#rootwithctx)
  - [zeroHashes](#zerohashes)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| TREE_DEPTH | uint256 |
| MAX_LEAVES | uint256 |
| Z_0 | bytes32 |
| Z_1 | bytes32 |
| Z_2 | bytes32 |
| Z_3 | bytes32 |
| Z_4 | bytes32 |
| Z_5 | bytes32 |
| Z_6 | bytes32 |
| Z_7 | bytes32 |
| Z_8 | bytes32 |
| Z_9 | bytes32 |
| Z_10 | bytes32 |
| Z_11 | bytes32 |
| Z_12 | bytes32 |
| Z_13 | bytes32 |
| Z_14 | bytes32 |
| Z_15 | bytes32 |
| Z_16 | bytes32 |
| Z_17 | bytes32 |
| Z_18 | bytes32 |
| Z_19 | bytes32 |
| Z_20 | bytes32 |
| Z_21 | bytes32 |
| Z_22 | bytes32 |
| Z_23 | bytes32 |
| Z_24 | bytes32 |
| Z_25 | bytes32 |
| Z_26 | bytes32 |
| Z_27 | bytes32 |
| Z_28 | bytes32 |
| Z_29 | bytes32 |
| Z_30 | bytes32 |
| Z_31 | bytes32 |



## Functions

### insert
Inserts `_node` into merkle tree

> Reverts if tree is full


#### Declaration
```solidity
  function insert(
    struct IncrementalMerkleTree.Tree _node
  ) internal
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_node` | struct IncrementalMerkleTree.Tree | Element to insert into tree

### rootWithCtx
Calculates and returns`_tree`'s current root given array of zero
hashes



#### Declaration
```solidity
  function rootWithCtx(
    struct IncrementalMerkleTree.Tree _zeroes
  ) internal returns (bytes32 _current)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_zeroes` | struct IncrementalMerkleTree.Tree | Array of zero hashes

#### Returns:
| Type | Description |
| --- | --- |
|`_current` | Calculated root of `_tree`
### root
Calculates and returns`_tree`'s current root


#### Declaration
```solidity
  function root(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### zeroHashes
Returns array of TREE_DEPTH zero hashes



#### Declaration
```solidity
  function zeroHashes(
  ) internal returns (bytes32[32] _zeroes)
```

#### Modifiers:
No modifiers


#### Returns:
| Type | Description |
| --- | --- |
|`_zeroes` | Array of TREE_DEPTH zero hashes
### branchRoot
Calculates and returns the merkle root for the given leaf
`_item`, a merkle branch, and the index of `_item` in the tree.



#### Declaration
```solidity
  function branchRoot(
    bytes32 _item,
    bytes32[32] _branch,
    uint256 _index
  ) internal returns (bytes32 _current)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_item` | bytes32 | Merkle leaf
|`_branch` | bytes32[32] | Merkle proof
|`_index` | uint256 | Index of `_item` in tree

#### Returns:
| Type | Description |
| --- | --- |
|`_current` | Calculated merkle root


