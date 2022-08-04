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
  - [changeSetter](#changesetter)
  - [changeLane](#changelane)
  - [registry](#registry)
  - [commitment](#commitment)
- [Events](#events)
  - [Registry](#registry)
  - [ChangeLane](#changelane)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| thisChainPosition | uint256 |
| bridgedChainPosition | uint256 |
| count | uint256 |
| laneOf | mapping(uint256 => address) |
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

### commitment
Return bytes(0) if the lane address is address(0)

> Get the commitment of a lane


#### Declaration
```solidity
  function commitment(
    uint256 lanePos
  ) public returns (bytes32)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`lanePos` | uint256 | Positon of the lane

#### Returns:
| Type | Description |
| --- | --- |
|`Commitment` | of the lane
### commitment
Return bytes(0) if there is no lane

> Get the commitment of all lanes in this committer


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
|`Commitment` | of this committer


## Events

### Registry
No description

  


### ChangeLane
No description

  


