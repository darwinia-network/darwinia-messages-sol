# BSCLightClient





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [constructor](#constructor)
  - [state_root](#state_root)
  - [finalized_authorities_contains](#finalized_authorities_contains)
  - [length_of_finalized_authorities](#length_of_finalized_authorities)
  - [finalized_authorities_at](#finalized_authorities_at)
  - [finalized_authorities](#finalized_authorities)
  - [import_finalized_epoch_header](#import_finalized_epoch_header)
  - [_clean_finalized_authority_set](#_clean_finalized_authority_set)
  - [_finalize_authority_set](#_finalize_authority_set)
  - [contextless_checks](#contextless_checks)
  - [contextual_checks](#contextual_checks)
  - [_recover_creator](#_recover_creator)
  - [extract_sign](#extract_sign)
  - [_extract_authorities](#_extract_authorities)
- [Layout of extra_data:](#layout-of-extra_data)
- [VANITY: 32 bytes
Signers: N * 32 bytes as hex encoded (20 characters)
Signature: 65 bytes](#vanity-32-bytes%0Asigners-n--32-bytes-as-hex-encoded-20-characters%0Asignature-65-bytes)
  - [bytesToAddress](#bytestoaddress)
  - [add](#add)
  - [sub](#sub)
- [Events](#events)
  - [FinalizedHeaderImported](#finalizedheaderimported)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| CHAIN_ID | uint64 |
| PERIOD | uint64 |
| finalized_checkpoint | struct BSCLightClient.StoredBlockHeader |



## Functions

### constructor
No description


#### Declaration
```solidity
  function constructor(
  ) public StorageVerifier
```

#### Modifiers:
| Modifier |
| --- |
| StorageVerifier |



### state_root
No description


#### Declaration
```solidity
  function state_root(
  ) public returns (bytes32)
```

#### Modifiers:
No modifiers



### finalized_authorities_contains
No description


#### Declaration
```solidity
  function finalized_authorities_contains(
  ) public returns (bool)
```

#### Modifiers:
No modifiers



### length_of_finalized_authorities
No description


#### Declaration
```solidity
  function length_of_finalized_authorities(
  ) public returns (uint256)
```

#### Modifiers:
No modifiers



### finalized_authorities_at
No description


#### Declaration
```solidity
  function finalized_authorities_at(
  ) public returns (address)
```

#### Modifiers:
No modifiers



### finalized_authorities
No description


#### Declaration
```solidity
  function finalized_authorities(
  ) public returns (address[])
```

#### Modifiers:
No modifiers



### import_finalized_epoch_header
Import finalized checkpoint
len(headers) == N/2 + 1, headers[0] == finalized_checkpoint
the first group headers that relayer submitted should exactly follow the initial
checkpoint eg. the initial header number is x, the first call of this extrinsic
should submit headers with numbers [x + epoch_length, x + epoch_length + 1, ... , x + epoch_length + N/2]


#### Declaration
```solidity
  function import_finalized_epoch_header(
  ) external
```

#### Modifiers:
No modifiers



### _clean_finalized_authority_set
No description


#### Declaration
```solidity
  function _clean_finalized_authority_set(
  ) internal
```

#### Modifiers:
No modifiers



### _finalize_authority_set
No description


#### Declaration
```solidity
  function _finalize_authority_set(
  ) internal
```

#### Modifiers:
No modifiers



### contextless_checks
No description


#### Declaration
```solidity
  function contextless_checks(
  ) internal
```

#### Modifiers:
No modifiers



### contextual_checks
No description


#### Declaration
```solidity
  function contextual_checks(
  ) internal
```

#### Modifiers:
No modifiers



### _recover_creator
No description


#### Declaration
```solidity
  function _recover_creator(
  ) internal returns (address)
```

#### Modifiers:
No modifiers



### extract_sign
No description


#### Declaration
```solidity
  function extract_sign(
  ) internal returns (bytes32, bytes32)
```

#### Modifiers:
No modifiers



### _extract_authorities
Extract authority set from extra_data.

Layout of extra_data:
----
VANITY: 32 bytes
Signers: N * 32 bytes as hex encoded (20 characters)
Signature: 65 bytes
--


#### Declaration
```solidity
  function _extract_authorities(
  ) internal returns (address[])
```

#### Modifiers:
No modifiers



### bytesToAddress
No description


#### Declaration
```solidity
  function bytesToAddress(
  ) internal returns (address addr)
```

#### Modifiers:
No modifiers



### add
No description


#### Declaration
```solidity
  function add(
  ) internal returns (uint256 z)
```

#### Modifiers:
No modifiers



### sub
No description


#### Declaration
```solidity
  function sub(
  ) internal returns (uint256 z)
```

#### Modifiers:
No modifiers





## Events

### FinalizedHeaderImported
No description

  


