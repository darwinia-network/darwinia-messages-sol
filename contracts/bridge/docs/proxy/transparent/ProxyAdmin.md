# ProxyAdmin



> This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [getProxyImplementation](#getproxyimplementation)
  - [getProxyAdmin](#getproxyadmin)
  - [upgrade](#upgrade)
  - [upgradeAndCall](#upgradeandcall)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### getProxyImplementation
No description
> Returns the current implementation of `proxy`.

Requirements:

- This contract must be the admin of `proxy`.

#### Declaration
```solidity
  function getProxyImplementation(
  ) public returns (address)
```

#### Modifiers:
No modifiers



### getProxyAdmin
No description
> Returns the current admin of `proxy`.

Requirements:

- This contract must be the admin of `proxy`.

#### Declaration
```solidity
  function getProxyAdmin(
  ) public returns (address)
```

#### Modifiers:
No modifiers



### upgrade
No description
> Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.

Requirements:

- This contract must be the admin of `proxy`.

#### Declaration
```solidity
  function upgrade(
  ) public onlyOwner
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |



### upgradeAndCall
No description
> Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
{TransparentUpgradeableProxy-upgradeToAndCall}.

Requirements:

- This contract must be the admin of `proxy`.

#### Declaration
```solidity
  function upgradeAndCall(
  ) public onlyOwner
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |





