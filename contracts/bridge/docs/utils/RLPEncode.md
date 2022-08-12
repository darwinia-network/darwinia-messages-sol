# RLPEncode



> A simple RLP encoding library.


## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [encodeBytes](#encodebytes)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### encodeBytes
No description
> RLP encodes a byte string.


#### Declaration
```solidity
  function encodeBytes(
    bytes self
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`self` | bytes | The byte string to encode.

#### Returns:
| Type | Description |
| --- | --- |
|`The` | RLP encoded string in bytes.
### encodeList
No description
> RLP encodes a list of RLP encoded byte byte strings.


#### Declaration
```solidity
  function encodeList(
    bytes[] self
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`self` | bytes[] | The list of RLP encoded byte strings.

#### Returns:
| Type | Description |
| --- | --- |
|`The` | RLP encoded list of items in bytes.
### encodeString
No description
> RLP encodes a string.


#### Declaration
```solidity
  function encodeString(
    string self
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`self` | string | The string to encode.

#### Returns:
| Type | Description |
| --- | --- |
|`The` | RLP encoded string in bytes.
### encodeAddress
No description
> RLP encodes an address.


#### Declaration
```solidity
  function encodeAddress(
    address self
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`self` | address | The address to encode.

#### Returns:
| Type | Description |
| --- | --- |
|`The` | RLP encoded address in bytes.
### encodeUint
No description
> RLP encodes a uint.


#### Declaration
```solidity
  function encodeUint(
    uint256 self
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`self` | uint256 | The uint to encode.

#### Returns:
| Type | Description |
| --- | --- |
|`The` | RLP encoded uint in bytes.
### encodeInt
No description
> RLP encodes an int.


#### Declaration
```solidity
  function encodeInt(
    int256 self
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`self` | int256 | The int to encode.

#### Returns:
| Type | Description |
| --- | --- |
|`The` | RLP encoded int in bytes.
### encodeBool
No description
> RLP encodes a bool.


#### Declaration
```solidity
  function encodeBool(
    bool self
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`self` | bool | The bool to encode.

#### Returns:
| Type | Description |
| --- | --- |
|`The` | RLP encoded bool in bytes.


