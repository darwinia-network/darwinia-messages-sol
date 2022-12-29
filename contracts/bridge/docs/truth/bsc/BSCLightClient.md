# BSCLightClient





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [constructor](#constructor)
  - [merkle_root](#merkle_root)
  - [block_number](#block_number)
  - [finalized_authorities_contains](#finalized_authorities_contains)
  - [length_of_finalized_authorities](#length_of_finalized_authorities)
  - [finalized_authorities_at](#finalized_authorities_at)
  - [finalized_authorities](#finalized_authorities)
  - [import_finalized_epoch_header](#import_finalized_epoch_header)
  - [_recover_creator](#_recover_creator)
  - [_extract_authorities](#_extract_authorities)
- [Layout of extra_data:](#layout-of-extra_data)
- [VANITY: 32 bytes
Signers: N * 32 bytes as hex encoded (20 characters)
Signature: 65 bytes](#vanity-32-bytes%0Asigners-n--32-bytes-as-hex-encoded-20-characters%0Asignature-65-bytes)
  - [bytesToAddress](#bytestoaddress)
- [Events](#events)
  - [FinalizedHeaderImported](#finalizedheaderimported)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| finalized_checkpoint | struct BSCLightClient.StoredBlockHeader |
| CHAIN_ID | uint64 |
| PERIOD | uint64 |



## Functions

### constructor
No description


#### Declaration
```solidity
  function constructor(
  ) public
```

#### Modifiers:
No modifiers



### merkle_root
No description


#### Declaration
```solidity
  function merkle_root(
  ) public returns (bytes32)
```

#### Modifiers:
No modifiers



### block_number
No description


#### Declaration
```solidity
  function block_number(
  ) public returns (uint256)
```

#### Modifiers:
No modifiers



### finalized_authorities_contains
No description


#### Declaration
```solidity
  function finalized_authorities_contains(
  ) external returns (bool)
```

#### Modifiers:
No modifiers



### length_of_finalized_authorities
No description


#### Declaration
```solidity
  function length_of_finalized_authorities(
  ) external returns (uint256)
```

#### Modifiers:
No modifiers



### finalized_authorities_at
No description


#### Declaration
```solidity
  function finalized_authorities_at(
  ) external returns (address)
```

#### Modifiers:
No modifiers



### finalized_authorities
No description


#### Declaration
```solidity
  function finalized_authorities(
  ) external returns (address[])
```

#### Modifiers:
No modifiers



### import_finalized_epoch_header
len(headers) == N/2 + 1, headers[0] == finalized_checkpoint
the first group headers that relayer submitted should exactly follow the initial
checkpoint eg. the initial header number is x, the first call of this extrinsic
should submit headers with numbers [x + epoch_length, x + epoch_length + 1, ... , x + epoch_length + N/2]
> Import finalized checkpoint


#### Declaration
```solidity
  function import_finalized_epoch_header(
  ) external
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





## Events

### FinalizedHeaderImported
No description

  


