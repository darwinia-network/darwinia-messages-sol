# ValidatorRegistry



> Stores the validator set as a Merkle root

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [_updateValidatorSet](#_updatevalidatorset)
- [Events](#events)
  - [ValidatorRegistryUpdated](#validatorregistryupdated)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| validatorSetId | uint256 |
| validatorSetLen | uint256 |
| validatorSetRoot | bytes32 |



## Functions

### _updateValidatorSet
Updates the validator set



#### Declaration
```solidity
  function _updateValidatorSet(
    uint256 _validatorSetId,
    uint256 _validatorSetLen,
    bytes32 _validatorSetRoot
  ) internal
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_validatorSetId` | uint256 | The new validator set id
|`_validatorSetLen` | uint256 | The new length of validator set
|`_validatorSetRoot` | bytes32 | The new validator set root



## Events

### ValidatorRegistryUpdated
No description

  


