# UpgradeableProxy



> This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
implementation address that can be changed. This address is stored in storage in the location specified by
https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
implementation behind the proxy.

Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
{TransparentUpgradeableProxy}.

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [constructor](#constructor)
  - [_implementation](#_implementation)
  - [_upgradeTo](#_upgradeto)
- [Events](#events)
  - [Upgraded](#upgraded)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### constructor
No description
> Initializes the upgradeable proxy with an initial implementation specified by `_logic`.

If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
function call, and allows initializating the storage of the proxy like a Solidity constructor.

#### Declaration
```solidity
  function constructor(
  ) public
```

#### Modifiers:
No modifiers



### _implementation
No description
> Returns the current implementation address.

#### Declaration
```solidity
  function _implementation(
  ) internal returns (address impl)
```

#### Modifiers:
No modifiers



### _upgradeTo
No description
> Upgrades the proxy to a new implementation.

Emits an {Upgraded} event.

#### Declaration
```solidity
  function _upgradeTo(
  ) internal
```

#### Modifiers:
No modifiers





## Events

### Upgraded
No description
> Emitted when the implementation is upgraded.
  


