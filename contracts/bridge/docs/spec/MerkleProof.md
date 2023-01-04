# MerkleProof


Merkle proof specification


## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [is_valid_merkle_branch](#is_valid_merkle_branch)
  - [merkle_root](#merkle_root)
  - [hash_node](#hash_node)
  - [hash](#hash)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### is_valid_merkle_branch
Check if ``leaf`` at ``index`` verifies against the Merkle ``root`` and ``branch``.


#### Declaration
```solidity
  function is_valid_merkle_branch(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### merkle_root
No description


#### Declaration
```solidity
  function merkle_root(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### hash_node
No description


#### Declaration
```solidity
  function hash_node(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### hash
No description


#### Declaration
```solidity
  function hash(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers





