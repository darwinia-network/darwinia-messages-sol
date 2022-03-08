# BEEFYAuthorityRegistry



> Stores the authority set as a Merkle root
 0  |   1   |    2   |  .. x   3 |     4
    [       )

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [_updateAuthoritySet](#_updateauthorityset)
- [Events](#events)
  - [BEEFYAuthoritySetUpdated](#beefyauthoritysetupdated)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| authoritySetId | uint256 |
| authoritySetLen | uint256 |
| authoritySetRoot | bytes32 |



## Functions

### _updateAuthoritySet
Updates the current authority set



#### Declaration
```solidity
  function _updateAuthoritySet(
    uint256 _authoritySetId,
    uint256 _authoritySetLen,
    bytes32 _authoritySetRoot
  ) internal
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_authoritySetId` | uint256 | The new authority set id
|`_authoritySetLen` | uint256 | The new length of authority set
|`_authoritySetRoot` | bytes32 | The new authority set root



## Events

### BEEFYAuthoritySetUpdated
No description

  


