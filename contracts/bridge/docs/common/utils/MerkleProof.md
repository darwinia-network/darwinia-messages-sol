# MerkleProof





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [verifyMerkleLeafAtPosition](#verifymerkleleafatposition)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### verifyMerkleLeafAtPosition
Verify that a specific leaf element is part of the Merkle Tree at a specific position in the tree




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
|`root` | bytes32 | the root of the merkle tree
|`leaf` | bytes32 | the leaf which needs to be proven
|`pos` | uint256 | the position of the leaf, index starting with 0
|`width` | uint256 | the width or number of leaves in the tree
|`proof` | bytes32[] | the array of proofs to help verify the leaf's membership, ordered from leaf to root

#### Returns:
| Type | Description |
| --- | --- |
|`a` | boolean value representing the success or failure of the operation


