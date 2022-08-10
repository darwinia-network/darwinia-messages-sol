# BeaconLightClient





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [constructor](#constructor)
  - [state_root](#state_root)
  - [import_next_sync_committee](#import_next_sync_committee)
  - [import_finalized_header](#import_finalized_header)
  - [verify_signed_header](#verify_signed_header)
  - [verify_finalized_header](#verify_finalized_header)
  - [verify_next_sync_committee](#verify_next_sync_committee)
  - [is_supermajority](#is_supermajority)
  - [fast_aggregate_verify](#fast_aggregate_verify)
  - [compute_sync_committee_period](#compute_sync_committee_period)
  - [sum](#sum)
- [Events](#events)
  - [FinalizedHeaderImported](#finalizedheaderimported)
  - [NextSyncCommitteeImported](#nextsynccommitteeimported)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| finalized_header | struct BeaconChain.BeaconBlockHeader |
| latest_execution_payload_state_root | bytes32 |
| sync_committee_roots | mapping(uint64 => bytes32) |
| GENESIS_VALIDATORS_ROOT | bytes32 |



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



### state_root
No description


#### Declaration
```solidity
  function state_root(
  ) public returns (bytes32)
```

#### Modifiers:
No modifiers



### import_next_sync_committee
No description


#### Declaration
```solidity
  function import_next_sync_committee(
  ) external
```

#### Modifiers:
No modifiers



### import_finalized_header
No description


#### Declaration
```solidity
  function import_finalized_header(
  ) external
```

#### Modifiers:
No modifiers



### verify_signed_header
No description


#### Declaration
```solidity
  function verify_signed_header(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### verify_finalized_header
No description


#### Declaration
```solidity
  function verify_finalized_header(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### verify_next_sync_committee
No description


#### Declaration
```solidity
  function verify_next_sync_committee(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### is_supermajority
No description


#### Declaration
```solidity
  function is_supermajority(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### fast_aggregate_verify
No description


#### Declaration
```solidity
  function fast_aggregate_verify(
  ) internal returns (bool valid)
```

#### Modifiers:
No modifiers



### compute_sync_committee_period
No description


#### Declaration
```solidity
  function compute_sync_committee_period(
  ) internal returns (uint64)
```

#### Modifiers:
No modifiers



### sum
No description


#### Declaration
```solidity
  function sum(
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers





## Events

### FinalizedHeaderImported
No description

  


### NextSyncCommitteeImported
No description

  


