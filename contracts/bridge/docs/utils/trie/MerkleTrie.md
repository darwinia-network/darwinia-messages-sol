# MerkleTrie


MerkleTrie is a small library for verifying standard Ethereum Merkle-Patricia trie
        inclusion proofs. By default, this library assumes a hexary trie. One can change the
        trie radix constant to support other trie radixes.


## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [verifyInclusionProof](#verifyinclusionproof)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| TREE_RADIX | uint256 |
| BRANCH_NODE_LENGTH | uint256 |
| LEAF_OR_EXTENSION_NODE_LENGTH | uint256 |
| PREFIX_EXTENSION_EVEN | uint8 |
| PREFIX_EXTENSION_ODD | uint8 |
| PREFIX_LEAF_EVEN | uint8 |
| PREFIX_LEAF_ODD | uint8 |



## Functions

### verifyInclusionProof
Verifies a proof that a given key/value pair is present in the trie.




#### Declaration
```solidity
  function verifyInclusionProof(
    bytes _key,
    bytes _value,
    bytes[] _proof,
    bytes32 _root
  ) internal returns (bool)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_key` | bytes |   Key of the node to search for, as a hex string.
|`_value` | bytes | Value of the node to search for, as a hex string.
|`_proof` | bytes[] | Merkle trie inclusion proof for the desired node. Unlike traditional Merkle
              trees, this proof is executed top-down and consists of a list of RLP-encoded
              nodes that make a path down to the target node.
|`_root` | bytes32 |  Known root of the Merkle trie. Used to verify that the included proof is
              correctly constructed.


#### Returns:
| Type | Description |
| --- | --- |
|`Whether` | or not the proof is valid.
### get
Retrieves the value associated with a given key.




#### Declaration
```solidity
  function get(
    bytes _key,
    bytes[] _proof,
    bytes32 _root
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_key` | bytes |   Key to search for, as hex bytes.
|`_proof` | bytes[] | Merkle trie inclusion proof for the key.
|`_root` | bytes32 |  Known root of the Merkle trie.


#### Returns:
| Type | Description |
| --- | --- |
|`Value` | of the key if it exists.


