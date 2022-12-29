# IMessageCommitter


A interface for message committer


## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [count](#count)
  - [proof](#proof)
  - [BRIDGED_CHAIN_POSITION](#bridged_chain_position)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### count
Return leave count


#### Declaration
```solidity
  function count(
  ) external returns (uint256)
```

#### Modifiers:
No modifiers



### proof
Return pos leave proof



#### Declaration
```solidity
  function proof(
    uint256 pos
  ) external returns (struct MessageSingleProof)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`pos` | uint256 | Which position leave to be prove

#### Returns:
| Type | Description |
| --- | --- |
|`MessageSingleProof` | message single proof of the leave
### leaveOf
Return committer address of positon



#### Declaration
```solidity
  function leaveOf(
    uint256 pos
  ) external returns (address)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`pos` | uint256 | Which positon of all leaves

#### Returns:
| Type | Description |
| --- | --- |
|`committer` | address of the positon
### commitment
Return message commitment of the committer



#### Declaration
```solidity
  function commitment(
  ) external returns (bytes32)
```

#### Modifiers:
No modifiers


#### Returns:
| Type | Description |
| --- | --- |
|`commitment` | hash
### THIS_CHAIN_POSITION
this chain position


#### Declaration
```solidity
  function THIS_CHAIN_POSITION(
  ) external returns (uint32)
```

#### Modifiers:
No modifiers



### BRIDGED_CHAIN_POSITION
bridged chain position


#### Declaration
```solidity
  function BRIDGED_CHAIN_POSITION(
  ) external returns (uint32)
```

#### Modifiers:
No modifiers





