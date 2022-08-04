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
  - [changeSetter](#changesetter)
  - [registry](#registry)
  - [commitment](#commitment)
- [Events](#events)
  - [Registry](#registry)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| thisChainPosition | uint256 |
| maxChainPosition | uint256 |
| chainOf | mapping(uint256 => address) |
| setter | address |


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

### commitment
Return bytes(0) if the lane committer address is address(0)

> Get the commitment of a lane committer


#### Declaration
```solidity
  function commitment(
    uint256 chainPos
  ) public returns (bytes32)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`chainPos` | uint256 | Bridged chian positon of the lane committer

#### Returns:
| Type | Description |
| --- | --- |
|`Commitment` | of the lane committer
### commitment
Return bytes(0) if there is no lane committer

> Get the commitment of all lane committers


#### Declaration
```solidity
  function commitment(
  ) public returns (bytes32)
```

#### Modifiers:
No modifiers


#### Returns:
| Type | Description |
| --- | --- |
|`Commitment` | of this chian committer


## Events

### Registry
No description

  


