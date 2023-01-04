# BeaconLCMandatoryReward





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Modifiers](#modifiers)
  - [onlySetter](#onlysetter)
- [Functions](#functions)
  - [constructor](#constructor)
  - [receive](#receive)
  - [is_imported](#is_imported)
  - [import_mandatory_next_sync_committee_for_reward](#import_mandatory_next_sync_committee_for_reward)
  - [changeReward](#changereward)
  - [changeConsensusLayer](#changeconsensuslayer)
  - [withdraw](#withdraw)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| reward | uint256 |
| setter | address |
| consensusLayer | address |


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



### receive
No description


#### Declaration
```solidity
  function receive(
  ) external
```

#### Modifiers:
No modifiers



### is_imported
No description


#### Declaration
```solidity
  function is_imported(
  ) external returns (bool)
```

#### Modifiers:
No modifiers



### import_mandatory_next_sync_committee_for_reward
No description


#### Declaration
```solidity
  function import_mandatory_next_sync_committee_for_reward(
  ) external
```

#### Modifiers:
No modifiers



### changeReward
No description


#### Declaration
```solidity
  function changeReward(
  ) external onlySetter
```

#### Modifiers:
| Modifier |
| --- |
| onlySetter |



### changeConsensusLayer
No description


#### Declaration
```solidity
  function changeConsensusLayer(
  ) external onlySetter
```

#### Modifiers:
| Modifier |
| --- |
| onlySetter |



### withdraw
No description


#### Declaration
```solidity
  function withdraw(
  ) public onlySetter
```

#### Modifiers:
| Modifier |
| --- |
| onlySetter |





