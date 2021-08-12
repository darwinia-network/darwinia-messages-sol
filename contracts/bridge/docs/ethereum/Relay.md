# Relay





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [initialize](#initialize)
  - [getRelayerCount](#getrelayercount)
  - [getRelayerNonce](#getrelayernonce)
  - [getRelayer](#getrelayer)
  - [getNetworkPrefix](#getnetworkprefix)
  - [getRelayerThreshold](#getrelayerthreshold)
  - [getMMRRoot](#getmmrroot)
  - [getLockTokenReceipt](#getlocktokenreceipt)
  - [isRelayer](#isrelayer)
  - [checkNetworkPrefix](#checknetworkprefix)
  - [checkRelayerNonce](#checkrelayernonce)
  - [updateRelayer](#updaterelayer)
  - [appendRoot](#appendroot)
  - [verifyRootAndDecodeReceipt](#verifyrootanddecodereceipt)
  - [verifyBlockProof](#verifyblockproof)
  - [resetRoot](#resetroot)
  - [unpause](#unpause)
  - [pause](#pause)
  - [resetNetworkPrefix](#resetnetworkprefix)
  - [resetRelayerThreshold](#resetrelayerthreshold)
  - [resetRelayer](#resetrelayer)
  - [_updateRelayer](#_updaterelayer)
  - [_resetRelayer](#_resetrelayer)
  - [_appendRoot](#_appendroot)
  - [_setRoot](#_setroot)
  - [_setNetworkPrefix](#_setnetworkprefix)
  - [_setRelayThreshold](#_setrelaythreshold)
  - [_checkSignature](#_checksignature)
  - [hasDuplicate](#hasduplicate)
- [Events](#events)
  - [SetRootEvent](#setrootevent)
  - [SetAuthoritiesEvent](#setauthoritiesevent)
  - [ResetRootEvent](#resetrootevent)
  - [ResetAuthoritiesEvent](#resetauthoritiesevent)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| relayers | struct Relay.Relayers |
| mmrRootPool | mapping(uint32 => bytes32) |



## Functions

### initialize
No description


#### Declaration
```solidity
  function initialize(
  ) public initializer
```

#### Modifiers:
| Modifier |
| --- |
| initializer |



### getRelayerCount
==== Getters ====


#### Declaration
```solidity
  function getRelayerCount(
  ) public returns (uint256)
```

#### Modifiers:
No modifiers



### getRelayerNonce
No description


#### Declaration
```solidity
  function getRelayerNonce(
  ) public returns (uint32)
```

#### Modifiers:
No modifiers



### getRelayer
No description


#### Declaration
```solidity
  function getRelayer(
  ) public returns (address[])
```

#### Modifiers:
No modifiers



### getNetworkPrefix
No description


#### Declaration
```solidity
  function getNetworkPrefix(
  ) public returns (bytes)
```

#### Modifiers:
No modifiers



### getRelayerThreshold
No description


#### Declaration
```solidity
  function getRelayerThreshold(
  ) public returns (uint8)
```

#### Modifiers:
No modifiers



### getMMRRoot
No description


#### Declaration
```solidity
  function getMMRRoot(
  ) public returns (bytes32)
```

#### Modifiers:
No modifiers



### getLockTokenReceipt
No description


#### Declaration
```solidity
  function getLockTokenReceipt(
  ) public whenNotPaused returns (bytes)
```

#### Modifiers:
| Modifier |
| --- |
| whenNotPaused |



### isRelayer
No description


#### Declaration
```solidity
  function isRelayer(
  ) public returns (bool)
```

#### Modifiers:
No modifiers



### checkNetworkPrefix
No description


#### Declaration
```solidity
  function checkNetworkPrefix(
  ) public returns (bool)
```

#### Modifiers:
No modifiers



### checkRelayerNonce
No description


#### Declaration
```solidity
  function checkRelayerNonce(
  ) public returns (bool)
```

#### Modifiers:
No modifiers



### updateRelayer
==== Setters ====


#### Declaration
```solidity
  function updateRelayer(
  ) public whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| whenNotPaused |



### appendRoot
No description


#### Declaration
```solidity
  function appendRoot(
  ) public whenNotPaused
```

#### Modifiers:
| Modifier |
| --- |
| whenNotPaused |



### verifyRootAndDecodeReceipt
No description


#### Declaration
```solidity
  function verifyRootAndDecodeReceipt(
  ) public whenNotPaused returns (bytes)
```

#### Modifiers:
| Modifier |
| --- |
| whenNotPaused |



### verifyBlockProof
No description


#### Declaration
```solidity
  function verifyBlockProof(
  ) public whenNotPaused returns (bool)
```

#### Modifiers:
| Modifier |
| --- |
| whenNotPaused |



### resetRoot
==== onlyOwner ====


#### Declaration
```solidity
  function resetRoot(
  ) public onlyOwner
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |



### unpause
No description


#### Declaration
```solidity
  function unpause(
  ) public onlyOwner
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |



### pause
No description


#### Declaration
```solidity
  function pause(
  ) public onlyOwner
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |



### resetNetworkPrefix
No description


#### Declaration
```solidity
  function resetNetworkPrefix(
  ) public onlyOwner
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |



### resetRelayerThreshold
No description


#### Declaration
```solidity
  function resetRelayerThreshold(
  ) public onlyOwner
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |



### resetRelayer
No description


#### Declaration
```solidity
  function resetRelayer(
  ) public onlyOwner
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |



### _updateRelayer
==== Internal ====


#### Declaration
```solidity
  function _updateRelayer(
  ) internal
```

#### Modifiers:
No modifiers



### _resetRelayer
No description


#### Declaration
```solidity
  function _resetRelayer(
  ) internal
```

#### Modifiers:
No modifiers



### _appendRoot
No description


#### Declaration
```solidity
  function _appendRoot(
  ) internal
```

#### Modifiers:
No modifiers



### _setRoot
No description


#### Declaration
```solidity
  function _setRoot(
  ) internal
```

#### Modifiers:
No modifiers



### _setNetworkPrefix
No description


#### Declaration
```solidity
  function _setNetworkPrefix(
  ) internal
```

#### Modifiers:
No modifiers



### _setRelayThreshold
No description


#### Declaration
```solidity
  function _setRelayThreshold(
  ) internal
```

#### Modifiers:
No modifiers



### _checkSignature
No description


#### Declaration
```solidity
  function _checkSignature(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### hasDuplicate

Returns whether or not there's a duplicate. Runs in O(n^2).



#### Declaration
```solidity
  function hasDuplicate(
    address[] A
  ) internal returns (bool)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`A` | address[] | Array to search

#### Returns:
| Type | Description |
| --- | --- |
|`Returns` | true if duplicate, false otherwise
/


## Events

### SetRootEvent
No description

  


### SetAuthoritiesEvent
No description

  


### ResetRootEvent
No description

  


### ResetAuthoritiesEvent
No description

  


