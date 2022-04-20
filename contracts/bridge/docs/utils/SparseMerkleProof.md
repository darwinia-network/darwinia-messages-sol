# SparseMerkleProof


Sparse Merkle Tree is constructed from 2^n-length leaves, where n is the tree depth
 equal to log2(number of leafs) and it's initially hashed using the `keccak256` hash function as the inner nodes.
 Inner nodes are created by concatenating child hashes and hashing again.


## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [hash_node](#hash_node)
  - [singleVerify](#singleverify)
  - [multiVerify](#multiverify)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### hash_node
No description


#### Declaration
```solidity
  function hash_node(
  ) internal returns (bytes32 hash)
```

#### Modifiers:
No modifiers



### singleVerify
No description


#### Declaration
```solidity
  function singleVerify(
    bytes32 root,
    bytes32 leaf,
    uint256 pos,
    bytes32[] proof
  ) internal returns (bool)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`root` | bytes32 | The root of the merkle tree
|`leaf` | bytes32 | The leaf which needs to be proven
|`pos` | uint256 | The position of the leaf, index starting with 0
|`proof` | bytes32[] | The array of proofs to help verify the leaf's membership, ordered from leaf to root

#### Returns:
| Type | Description |
| --- | --- |
|`A` | boolean value representing the success or failure of the verification
### multiVerify
Verify that multi leafs in the Sparse Merkle Tree with generalized indices.

> Indices are required to be sorted highest to lowest.


#### Declaration
```solidity
  function multiVerify(
    bytes32 root,
    uint256 depth,
    bytes32 indices,
    bytes32[] leaves,
    bytes32[] decommitments
  ) internal returns (bool)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`root` | bytes32 | The root of the merkle tree
|`depth` | uint256 | Depth of the merkle tree. Equal to log2(number of leafs)
|`indices` | bytes32 | The indices of the leafs, index starting whith 0
|`leaves` | bytes32[] | The leaves which need to be proven
|`decommitments` | bytes32[] | A list of decommitments required to reconstruct the merkle root

#### Returns:
| Type | Description |
| --- | --- |
|`A` | boolean value representing the success or failure of the verification


