# BEEFYAuthorityRegistry



> Stores the authority set as a Merkle root
 0  |   1   |    2   |  .. x   3 |     4
    [       )
 (current, next) = (0, 0) -> (0, 1) -> (1, 2) -> (2, 3)

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [_updateCurrentAuthoritySet](#_updatecurrentauthorityset)
  - [_updateNextAuthoritySet](#_updatenextauthorityset)
- [Events](#events)
  - [BEEFYCurrentAuthoritySetUpdated](#beefycurrentauthoritysetupdated)
  - [BEEFYNextAuthoritySetUpdated](#beefynextauthoritysetupdated)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| current | struct BEEFYAuthorityRegistry.AuthoritySet |
| next | struct BEEFYAuthorityRegistry.AuthoritySet |



## Functions

### _updateCurrentAuthoritySet
No description


#### Declaration
```solidity
  function _updateCurrentAuthoritySet(
  ) internal
```

#### Modifiers:
No modifiers



### _updateNextAuthoritySet
No description


#### Declaration
```solidity
  function _updateNextAuthoritySet(
  ) internal
```

#### Modifiers:
No modifiers





## Events

### BEEFYCurrentAuthoritySetUpdated
No description

  


### BEEFYNextAuthoritySetUpdated
No description

  


