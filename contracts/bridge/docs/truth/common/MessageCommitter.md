# MessageCommitter





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [count](#count)
  - [leaveOf](#leaveof)
  - [commitment](#commitment)
  - [root](#root)
  - [merkle_tree](#merkle_tree)
  - [get_proof](#get_proof)
  - [hash_node](#hash_node)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

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



### commitment
Return bytes(0) if there is no leave

> Get the commitment of all leaves


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
### commitment
Return bytes(0) if the leaf address is address(0)

> Get the commitment of the leaf


#### Declaration
```solidity
  function commitment(
    uint256 pos
  ) public returns (bytes32)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`pos` | uint256 | Positon of the leaf

#### Returns:
| Type | Description |
| --- | --- |
|`Commitment` | of the leaf
### proof
No description
> Construct a Merkle Proof for leave given by position.

#### Declaration
```solidity
  function proof(
  ) public returns (struct MessageSingleProof)
```

#### Modifiers:
No modifiers



### root
No description


#### Declaration
```solidity
  function root(
  ) public returns (bytes32)
```

#### Modifiers:
No modifiers



### merkle_tree
No description


#### Declaration
```solidity
  function merkle_tree(
  ) public returns (bytes32[])
```

#### Modifiers:
No modifiers



### get_proof
No description


#### Declaration
```solidity
  function get_proof(
  ) internal returns (bytes32[])
```

#### Modifiers:
No modifiers



### hash_node
No description


#### Declaration
```solidity
  function hash_node(
  ) internal returns (bytes32 hash)
```

#### Modifiers:
No modifiers





