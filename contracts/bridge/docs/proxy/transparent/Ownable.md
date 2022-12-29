# Ownable



> Contract module which provides a basic access control mechanism, where
there is an account (an owner) that can be granted exclusive access to
specific functions.

By default, the owner account will be the one that deploys the contract. This
can later be changed with {transferOwnership}.

This module is used through inheritance. It will make available the modifier
`onlyOwner`, which can be applied to your functions to restrict their use to
the owner.

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Modifiers](#modifiers)
  - [onlyOwner](#onlyowner)
- [Functions](#functions)
  - [constructor](#constructor)
  - [owner](#owner)
  - [_checkOwner](#_checkowner)
  - [renounceOwnership](#renounceownership)
  - [transferOwnership](#transferownership)
  - [_transferOwnership](#_transferownership)
- [Events](#events)
  - [OwnershipTransferred](#ownershiptransferred)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->



## Modifiers

### onlyOwner
No description
> Throws if called by any account other than the owner.

#### Declaration
```solidity
  modifier onlyOwner
```



## Functions

### constructor
No description
> Initializes the contract setting the deployer as the initial owner.

#### Declaration
```solidity
  function constructor(
  ) internal
```

#### Modifiers:
No modifiers



### owner
No description
> Returns the address of the current owner.

#### Declaration
```solidity
  function owner(
  ) public returns (address)
```

#### Modifiers:
No modifiers



### _checkOwner
No description
> Throws if the sender is not the owner.

#### Declaration
```solidity
  function _checkOwner(
  ) internal
```

#### Modifiers:
No modifiers



### renounceOwnership
No description
> Leaves the contract without owner. It will not be possible to call
`onlyOwner` functions anymore. Can only be called by the current owner.

NOTE: Renouncing ownership will leave the contract without an owner,
thereby removing any functionality that is only available to the owner.

#### Declaration
```solidity
  function renounceOwnership(
  ) public onlyOwner
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |



### transferOwnership
No description
> Transfers ownership of the contract to a new account (`newOwner`).
Can only be called by the current owner.

#### Declaration
```solidity
  function transferOwnership(
  ) public onlyOwner
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |



### _transferOwnership
No description
> Transfers ownership of the contract to a new account (`newOwner`).
Internal function without access restriction.

#### Declaration
```solidity
  function _transferOwnership(
  ) internal
```

#### Modifiers:
No modifiers





## Events

### OwnershipTransferred
No description

  


