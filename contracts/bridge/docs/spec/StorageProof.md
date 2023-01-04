# StorageProof


Storage proof specification


## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [verify_single_storage_proof](#verify_single_storage_proof)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### verify_single_storage_proof
Verify single storage proof



#### Declaration
```solidity
  function verify_single_storage_proof(
    bytes32 root,
    address account,
    bytes[] account_proof,
    bytes32 storage_key,
    bytes[] storage_proof
  ) internal returns (bytes value)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`root` | bytes32 | State root
|`account` | address | Account address to be prove
|`account_proof` | bytes[] | Merkle trie inclusion proof for the account
|`storage_key` | bytes32 | Storage key to be prove
|`storage_proof` | bytes[] | Merkle trie inclusion proof for storage key

#### Returns:
| Type | Description |
| --- | --- |
|`value` | of the key if it exists
### verify_multi_storage_proof
Verify multi storage proof



#### Declaration
```solidity
  function verify_multi_storage_proof(
    bytes32 root,
    address account,
    bytes[] account_proof,
    bytes32[] storage_keys,
    bytes[][] storage_proofs
  ) internal returns (bytes[] values)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`root` | bytes32 | State root
|`account` | address | Account address to be prove
|`account_proof` | bytes[] | Merkle trie inclusion proof for the account
|`storage_keys` | bytes32[] | Multi storage key to be prove
|`storage_proofs` | bytes[][] | Merkle trie inclusion multi proof for storage keys

#### Returns:
| Type | Description |
| --- | --- |
|`values` | of the keys if it exists


