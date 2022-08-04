# SecureMerkleTrie





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [verifyInclusionProof](#verifyinclusionproof)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### verifyInclusionProof
Verifies a proof that a given key/value pair is present in the
Merkle trie.



#### Declaration
```solidity
  function verifyInclusionProof(
    bytes _key,
    bytes _value,
    bytes _proof,
    bytes32 _root
  ) internal returns (bool _verified)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_key` | bytes | Key of the node to search for, as a hex string.
|`_value` | bytes | Value of the node to search for, as a hex string.
|`_proof` | bytes | Merkle trie inclusion proof for the desired node. Unlike
traditional Merkle trees, this proof is executed top-down and consists
of a list of RLP-encoded nodes that make a path down to the target node.
|`_root` | bytes32 | Known root of the Merkle trie. Used to verify that the
included proof is correctly constructed.

#### Returns:
| Type | Description |
| --- | --- |
|`_verified` | `true` if the k/v pair exists in the trie, `false` otherwise.
### get
Retrieves the value associated with a given key.



#### Declaration
```solidity
  function get(
    bytes _key,
    bytes _proof,
    bytes32 _root
  ) internal returns (bool _exists, bytes _value)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_key` | bytes | Key to search for, as hex bytes.
|`_proof` | bytes | Merkle trie inclusion proof for the key.
|`_root` | bytes32 | Known root of the Merkle trie.

#### Returns:
| Type | Description |
| --- | --- |
|`_exists` | Whether or not the key exists.
|`_value` | Value of the key if it exists.


