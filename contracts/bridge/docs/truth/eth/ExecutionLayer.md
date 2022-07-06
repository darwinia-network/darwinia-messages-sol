# ExecutionLayer





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [constructor](#constructor)
  - [state_root](#state_root)
  - [import_latest_execution_payload_state_root](#import_latest_execution_payload_state_root)
  - [verify_latest_execution_payload_state_root](#verify_latest_execution_payload_state_root)
- [Events](#events)
  - [LatestExecutionPayloadStateRootImported](#latestexecutionpayloadstaterootimported)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| CONSENSUS_LAYER | address |



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



### import_latest_execution_payload_state_root
No description


#### Declaration
```solidity
  function import_latest_execution_payload_state_root(
  ) external
```

#### Modifiers:
No modifiers



### verify_latest_execution_payload_state_root
No description


#### Declaration
```solidity
  function verify_latest_execution_payload_state_root(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers





## Events

### LatestExecutionPayloadStateRootImported
No description

  


