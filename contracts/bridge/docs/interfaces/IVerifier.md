# IVerifier


A interface for message layer to verify the correctness of the lane hash


## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [verify_messages_proof](#verify_messages_proof)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### verify_messages_proof
Verify outlane data hash using message/storage proof



#### Declaration
```solidity
  function verify_messages_proof(
    bytes32 outlane_data_hash,
    uint32 chain_pos,
    uint32 lane_pos,
    bytes encoded_proof
  ) external returns (bool)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`outlane_data_hash` | bytes32 | The outlane data hash to be verify
|`chain_pos` | uint32 | Bridged chain position
|`lane_pos` | uint32 | Bridged outlane position
|`encoded_proof` | bytes | Message/storage abi-encoded proof

#### Returns:
| Type | Description |
| --- | --- |
|`the` | verify result
### verify_messages_delivery_proof
Verify inlane data hash using message/storage proof



#### Declaration
```solidity
  function verify_messages_delivery_proof(
    bytes32 inlane_data_hash,
    uint32 chain_pos,
    uint32 lane_pos,
    bytes encoded_proof
  ) external returns (bool)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`inlane_data_hash` | bytes32 | The inlane data hash to be verify
|`chain_pos` | uint32 | Bridged chain position
|`lane_pos` | uint32 | Bridged outlane position
|`encoded_proof` | bytes | Message/storage abi-encoded proof

#### Returns:
| Type | Description |
| --- | --- |
|`the` | verify result


