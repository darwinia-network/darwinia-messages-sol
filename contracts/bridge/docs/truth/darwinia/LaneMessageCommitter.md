# LaneMessageCommitter


Lane message committer commit all messages from this chain to bridged chain

> Lane message use sparse merkle tree to commit all messages

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
  - [changeLane](#changelane)
  - [registry](#registry)
- [Events](#events)
  - [Registry](#registry)
  - [ChangeLane](#changelane)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| setter | address |
| laneCount | uint256 |
| laneOf | mapping(uint256 => address) |
| THIS_CHAIN_POSITION | uint256 |
| BRIDGED_CHAIN_POSITION | uint256 |


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
    uint256 _thisChainPosition,
    uint256 _bridgedChainPosition
  ) public
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_thisChainPosition` | uint256 | This chain positon
|`_bridgedChainPosition` | uint256 | Bridged chain positon

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

### changeLane
Only could be called by setter

> Change lane address of the given positon


#### Declaration
```solidity
  function changeLane(
    uint256 pos,
    address lane
  ) external onlySetter
```

#### Modifiers:
| Modifier |
| --- |
| onlySetter |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`pos` | uint256 | The given positon
|`lane` | address | New lane address of the given positon

### registry
Only could be called by setter

> Registry a pair of out lane and in lane


#### Declaration
```solidity
  function registry(
    address outboundLane,
    address inboundLane
  ) external onlySetter
```

#### Modifiers:
| Modifier |
| --- |
| onlySetter |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`outboundLane` | address | Address of outbound lane
|`inboundLane` | address | Address of inbound lane



## Events

### Registry
No description

  


### ChangeLane
No description

  


