# LaneMessageCommitter





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
  - [commitment](#commitment-1)
  - [roundUpToPow2](#rounduptopow2)
- [Events](#events)
  - [Registry](#registry)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| thisChainPosition | uint256 |
| bridgedChainPosition | uint256 |
| laneCount | uint256 |
| lanes | mapping(uint256 => address) |
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


#### Declaration
```solidity
  function constructor(
  ) public
```

#### Modifiers:
No modifiers



### changeSetter
No description


#### Declaration
```solidity
  function changeSetter(
  ) external onlySetter
```

#### Modifiers:
| Modifier |
| --- |
| onlySetter |



### registry
No description


#### Declaration
```solidity
  function registry(
  ) external onlySetter
```

#### Modifiers:
| Modifier |
| --- |
| onlySetter |



### commitment
No description


#### Declaration
```solidity
  function commitment(
  ) public returns (bytes32)
```

#### Modifiers:
No modifiers



### commitment
No description


#### Declaration
```solidity
  function commitment(
  ) public returns (bytes32)
```

#### Modifiers:
No modifiers



### roundUpToPow2
No description


#### Declaration
```solidity
  function roundUpToPow2(
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers





## Events

### Registry
No description

  


