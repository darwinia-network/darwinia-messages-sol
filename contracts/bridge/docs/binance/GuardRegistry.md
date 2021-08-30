# GuardRegistry



> Stores the guards and a threshold


## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [constructor](#constructor)
  - [addGuardWithThreshold](#addguardwiththreshold)
  - [removeGuard](#removeguard)
  - [swapGuard](#swapguard)
  - [changeThreshold](#changethreshold)
  - [_changeThreshold](#_changethreshold)
  - [getThreshold](#getthreshold)
  - [isGuard](#isguard)
  - [getGuards](#getguards)
  - [verifyGuardSignatures](#verifyguardsignatures)
  - [checkGuardSignatures](#checkguardsignatures)
  - [checkNSignatures](#checknsignatures)
  - [getChainId](#getchainid)
  - [domainSeparator](#domainseparator)
  - [encodeDataHash](#encodedatahash)
- [Events](#events)
  - [AddedGuard](#addedguard)
  - [RemovedGuard](#removedguard)
  - [ChangedThreshold](#changedthreshold)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| DOMAIN_SEPARATOR_TYPEHASH | bytes32 |
| GUARD_TYPEHASH | bytes32 |
| SENTINEL_GUARDS | address |
| NETWORK | bytes32 |
| nonce | uint256 |
| guards | mapping(address => address) |
| guardCount | uint256 |
| threshold | uint256 |



## Functions

### constructor
No description
> Sets initial storage of contract.


#### Declaration
```solidity
  function constructor(
    bytes32 _network,
    address[] _guards,
    uint256 _threshold
  ) public
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_network` | bytes32 | source chain network name
|`_guards` | address[] | List of Safe guards.
|`_threshold` | uint256 | Number of required confirmations for check commitment or change guards.

### addGuardWithThreshold
Adds the guard `guard` to the registry and updates the threshold to `_threshold`.

> Allows to add a new guard to the registry and update the threshold at the same time.
     This can only be done via multi-sig.


#### Declaration
```solidity
  function addGuardWithThreshold(
    address guard,
    uint256 _threshold,
    bytes[] signatures
  ) public
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`guard` | address | New guard address.
|`_threshold` | uint256 | New threshold.
|`signatures` | bytes[] | The signatures of the guards which to add new guard and update the `threshold` .

### removeGuard
Removes the guard `guard` from the registry and updates the threshold to `_threshold`.

> Allows to remove an guard from the registry and update the threshold at the same time.
     This can only be done via multi-sig.


#### Declaration
```solidity
  function removeGuard(
    address prevGuard,
    address guard,
    uint256 _threshold,
    bytes[] signatures
  ) public
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`prevGuard` | address | Guard that pointed to the guard to be removed in the linked list
|`guard` | address | Guard address to be removed.
|`_threshold` | uint256 | New threshold.
|`signatures` | bytes[] | The signatures of the guards which to remove a guard and update the `threshold` .

### swapGuard
Replaces the guard `oldGuard` in the registry with `newGuard`.

> Allows to swap/replace a guard from the registry with another address.
     This can only be done via multi-sig.


#### Declaration
```solidity
  function swapGuard(
    address prevGuard,
    address oldGuard,
    address newGuard,
    bytes[] signatures
  ) public
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`prevGuard` | address | guard that pointed to the guard to be replaced in the linked list
|`oldGuard` | address | guard address to be replaced.
|`newGuard` | address | New guard address.
|`signatures` | bytes[] | The signatures of the guards which to swap/replace a guard and update the `threshold` .

### changeThreshold
Changes the threshold of the registry to `_threshold`.

> Allows to update the number of required confirmations by guards.
     This can only be done via multi-sig.


#### Declaration
```solidity
  function changeThreshold(
    uint256 _threshold,
    bytes[] signatures
  ) public
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_threshold` | uint256 | New threshold.
|`signatures` | bytes[] | The signatures of the guards which to update the `threshold` .

### _changeThreshold
No description


#### Declaration
```solidity
  function _changeThreshold(
  ) internal
```

#### Modifiers:
No modifiers



### getThreshold
No description


#### Declaration
```solidity
  function getThreshold(
  ) public returns (uint256)
```

#### Modifiers:
No modifiers



### isGuard
No description


#### Declaration
```solidity
  function isGuard(
  ) public returns (bool)
```

#### Modifiers:
No modifiers



### getGuards
No description
> Returns array of guards.


#### Declaration
```solidity
  function getGuards(
  ) public returns (address[])
```

#### Modifiers:
No modifiers


#### Returns:
| Type | Description |
| --- | --- |
|`Array` | of guards.
### verifyGuardSignatures
No description


#### Declaration
```solidity
  function verifyGuardSignatures(
  ) internal
```

#### Modifiers:
No modifiers



### checkGuardSignatures
No description
> Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.


#### Declaration
```solidity
  function checkGuardSignatures(
    bytes32 structHash,
    bytes[] signatures
  ) public
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`structHash` | bytes32 | The struct Hash of the data (could be either a message/commitment hash).
|`signatures` | bytes[] | Signature data that should be verified. only ECDSA signature.
Signers need to be sorted in ascending order

### checkNSignatures
No description
> Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.


#### Declaration
```solidity
  function checkNSignatures(
    bytes32 dataHash,
    bytes[] signatures,
    uint256 requiredSignatures
  ) public
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`dataHash` | bytes32 | Hash of the data (could be either a message hash or transaction hash).
|`signatures` | bytes[] | Signature data that should be verified. only ECDSA signature.
Signers need to be sorted in ascending order
|`requiredSignatures` | uint256 | Amount of required valid signatures.

### getChainId
No description
> Returns the chain id used by this contract.

#### Declaration
```solidity
  function getChainId(
  ) public returns (uint256)
```

#### Modifiers:
No modifiers



### domainSeparator
No description


#### Declaration
```solidity
  function domainSeparator(
  ) public returns (bytes32)
```

#### Modifiers:
No modifiers



### encodeDataHash
No description


#### Declaration
```solidity
  function encodeDataHash(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers





## Events

### AddedGuard
No description

  


### RemovedGuard
No description

  


### ChangedThreshold
No description

  


