# ChainMessageCommitter


Chain message committer commit messages from all lane committers

> Chain message use sparse merkle tree to commit all messages

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Modifiers](#modifiers)
  - [onlySetter](#onlysetter)
- [Functions](#functions)
  - [constructor](#constructor)
  - [count](#count)
  - [leaveOf](#leaveof)
  - [changeSetter](#changesetter)
  - [registry](#registry)
  - [prove](#prove)
- [Events](#events)
  - [Registry](#registry)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| maxChainPosition | uint256 |
| chainOf | mapping(uint256 => address) |
| setter | address |
| thisChainPosition | uint256 |


## Modifiers

### onlySetter
No description


#### Declaration
```solidity
  modifier onlySetter
```



## Functions

### constructor
No description
> Constructor params


#### Declaration
```solidity
  function constructor(
    uint256 _thisChainPosition
  ) public
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_thisChainPosition` | uint256 | This chain positon

### count
No description


#### Declaration
```solidity
  function count(
  ) public returns (uint256)
```

#### Modifiers:
No modifiers



### leaveOf
No description


#### Declaration
```solidity
  function leaveOf(
  ) public returns (address)
```

#### Modifiers:
No modifiers



### changeSetter
Only could be called by setter

> Change the setter


#### Declaration
```solidity
  function changeSetter(
    address _setter
  ) external onlySetter
```

#### Modifiers:
| Modifier |
| --- |
| onlySetter |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_setter` | address | The new setter

### registry
Only could be called by setter

> Registry a lane committer


#### Declaration
```solidity
  function registry(
    address committer
  ) external onlySetter
```

#### Modifiers:
| Modifier |
| --- |
| onlySetter |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`committer` | address | Address of lane committer

### prove
No description
> Get message proof for lane


#### Declaration
```solidity
  function prove(
    uint256 chainPos,
    uint256 lanePos
  ) external returns (struct MessageProof)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`chainPos` | uint256 | Bridged chain position of lane
|`lanePos` | uint256 | This lane positon of lane



## Events

### Registry
No description

  


