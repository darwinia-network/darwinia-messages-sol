# Proxy



> This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
be specified by overriding the virtual {_implementation} function.

Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
different contract through the {_delegate} function.

The success and return data of the delegated call will be returned back to the caller of the proxy.

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [_delegate](#_delegate)
  - [_implementation](#_implementation)
  - [_fallback](#_fallback)
  - [fallback](#fallback)
  - [receive](#receive)
  - [_beforeFallback](#_beforefallback)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### _delegate
No description
> Delegates the current call to `implementation`.

This function does not return to its internal call site, it will return directly to the external caller.

#### Declaration
```solidity
  function _delegate(
  ) internal
```

#### Modifiers:
No modifiers



### _implementation
No description
> This is a virtual function that should be overridden so it returns the address to which the fallback function
and {_fallback} should delegate.

#### Declaration
```solidity
  function _implementation(
  ) internal returns (address)
```

#### Modifiers:
No modifiers



### _fallback
No description
> Delegates the current call to the address returned by `_implementation()`.

This function does not return to its internal call site, it will return directly to the external caller.

#### Declaration
```solidity
  function _fallback(
  ) internal
```

#### Modifiers:
No modifiers



### fallback
No description
> Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
function in the contract matches the call data.

#### Declaration
```solidity
  function fallback(
  ) external
```

#### Modifiers:
No modifiers



### receive
No description
> Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
is empty.

#### Declaration
```solidity
  function receive(
  ) external
```

#### Modifiers:
No modifiers



### _beforeFallback
No description
> Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
call, or as part of the Solidity `fallback` or `receive` functions.

If overridden should call `super._beforeFallback()`.

#### Declaration
```solidity
  function _beforeFallback(
  ) internal
```

#### Modifiers:
No modifiers





