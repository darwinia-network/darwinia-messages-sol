# BinaryMerkleProof


Binary Merkle Tree is constructed from arbitrary-length leaves,
 that are initially hashed using the `keccak256` hash function as the inner nodes.
 Inner nodes are created by concatenating child hashes and hashing again.

> If the number of leaves is not even, last leave (hash of) is promoted to the upper layer.

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [verifyMerkleLeafAtPosition](#verifymerkleleafatposition)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### verifyMerkleLeafAtPosition
No description


#### Declaration
```solidity
  function verifyMerkleLeafAtPosition(
    bytes32 root,
    bytes32 leaf,
    uint256 pos,
    uint256 width,
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
|`width` | uint256 | The width or number of leaves in the tree
|`proof` | bytes32[] | The array of proofs to help verify the leaf's membership, ordered from leaf to root

#### Returns:
| Type | Description |
| --- | --- |
|`A` | boolean value representing the success or failure of the verification


