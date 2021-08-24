# GuardRegistry



> Stores the guard set as a Merkle root

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [_updateGuardSet](#_updateguardset)
- [Events](#events)
  - [GuardRegistryUpdated](#guardregistryupdated)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| guardSetId | uint256 |
| numOfGuards | uint256 |
| guardSetRoot | bytes32 |
| guardThreshold | uint256 |



## Functions

### _updateGuardSet
Updates the guard set



#### Declaration
```solidity
  function _updateGuardSet(
    uint256 _guardSetId,
    uint256 _numOfGuards,
    bytes32 _guardSetRoot,
    uint256 _guardThreshold
  ) internal
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_guardSetId` | uint256 | The new guard set id
|`_numOfGuards` | uint256 | The new number of guard set
|`_guardSetRoot` | bytes32 | The new guard set root
|`_guardThreshold` | uint256 | The new guard threshold



## Events

### GuardRegistryUpdated
No description

  


