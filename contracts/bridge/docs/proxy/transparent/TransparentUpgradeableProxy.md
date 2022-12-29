# TransparentUpgradeableProxy



> This contract implements a proxy that is upgradeable by an admin.

To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
clashing], which can potentially be used in an attack, this contract uses the
https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
things that go hand in hand:

1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
that call matches one of the admin functions exposed by the proxy itself.
2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
implementation. If the admin tries to call a function on the implementation it will fail with an error that says
"admin cannot fallback to proxy target".

These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
to sudden errors when trying to call a function from the proxy implementation.

Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Modifiers](#modifiers)
  - [ifAdmin](#ifadmin)
- [Functions](#functions)
  - [constructor](#constructor)
  - [admin](#admin)
  - [implementation](#implementation)
  - [upgradeTo](#upgradeto)
  - [upgradeToAndCall](#upgradetoandcall)
  - [_admin](#_admin)
  - [_beforeFallback](#_beforefallback)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| _ADMIN | address |


## Modifiers

### ifAdmin
No description
> Modifier used internally that will delegate the call to the implementation unless the sender is the admin.

#### Declaration
```solidity
  modifier ifAdmin
```



## Functions

### constructor
No description
> Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.

#### Declaration
```solidity
  function constructor(
  ) public UpgradeableProxy
```

#### Modifiers:
| Modifier |
| --- |
| UpgradeableProxy |



### admin
No description
> Returns the current admin.

NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.

TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
`0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`

#### Declaration
```solidity
  function admin(
  ) external ifAdmin returns (address admin_)
```

#### Modifiers:
| Modifier |
| --- |
| ifAdmin |



### implementation
No description
> Returns the current implementation.

NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.

TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
`0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`

#### Declaration
```solidity
  function implementation(
  ) external ifAdmin returns (address implementation_)
```

#### Modifiers:
| Modifier |
| --- |
| ifAdmin |



### upgradeTo
No description
> Upgrade the implementation of the proxy.

NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.

#### Declaration
```solidity
  function upgradeTo(
  ) external ifAdmin
```

#### Modifiers:
| Modifier |
| --- |
| ifAdmin |



### upgradeToAndCall
No description
> Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
proxied contract.

NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.

#### Declaration
```solidity
  function upgradeToAndCall(
  ) external ifAdmin
```

#### Modifiers:
| Modifier |
| --- |
| ifAdmin |



### _admin
No description
> Returns the current admin.

#### Declaration
```solidity
  function _admin(
  ) internal returns (address adm)
```

#### Modifiers:
No modifiers



### _beforeFallback
No description
> Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.

#### Declaration
```solidity
  function _beforeFallback(
  ) internal
```

#### Modifiers:
No modifiers





