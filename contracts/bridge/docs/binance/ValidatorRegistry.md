# ValidatorRegistry



> Stores the validator set as a Merkle root

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [_update](#_update)
  - [checkValidatorInSet](#checkvalidatorinset)
- [Events](#events)
  - [ValidatorRegistryUpdated](#validatorregistryupdated)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| validatorSetId | uint256 |
| numOfValidators | uint256 |
| validatorSetRoot | bytes32 |



## Functions

### _update
Updates the validator set



#### Declaration
```solidity
  function _update(
    uint256 _validatorSetId,
    uint256 _numOfValidators,
    bytes32 _validatorSetRoot
  ) internal
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_validatorSetId` | uint256 | The new validator set id
|`_numOfValidators` | uint256 | The new number of validator set
|`_validatorSetRoot` | bytes32 | The new validator set root

### checkValidatorInSet
Checks if a validators address is a member of the merkle tree



#### Declaration
```solidity
  function checkValidatorInSet(
    address addr,
    uint256 pos,
    bytes32[] proof
  ) public returns (bool)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`addr` | address | The address of the validator to check
|`pos` | uint256 | The position of the validator to check, index starting at 0
|`proof` | bytes32[] | Merkle proof required for validation of the address

#### Returns:
| Type | Description |
| --- | --- |
|`Returns` | true if the validator is in the set


## Events

### ValidatorRegistryUpdated
No description

  


