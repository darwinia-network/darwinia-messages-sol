# RLPEncode





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [writeBytes](#writebytes)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### writeBytes
RLP encodes a byte string.




#### Declaration
```solidity
  function writeBytes(
    bytes _in
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_in` | bytes | The byte string to encode.


#### Returns:
| Type | Description |
| --- | --- |
|`The` | RLP encoded string in bytes.
### writeList
RLP encodes a list of RLP encoded byte byte strings.




#### Declaration
```solidity
  function writeList(
    bytes[] _in
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_in` | bytes[] | The list of RLP encoded byte strings.


#### Returns:
| Type | Description |
| --- | --- |
|`The` | RLP encoded list of items in bytes.
### writeString
RLP encodes a string.




#### Declaration
```solidity
  function writeString(
    string _in
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_in` | string | The string to encode.


#### Returns:
| Type | Description |
| --- | --- |
|`The` | RLP encoded string in bytes.
### writeAddress
RLP encodes an address.




#### Declaration
```solidity
  function writeAddress(
    address _in
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_in` | address | The address to encode.


#### Returns:
| Type | Description |
| --- | --- |
|`The` | RLP encoded address in bytes.
### writeUint
RLP encodes a uint.




#### Declaration
```solidity
  function writeUint(
    uint256 _in
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_in` | uint256 | The uint256 to encode.


#### Returns:
| Type | Description |
| --- | --- |
|`The` | RLP encoded uint256 in bytes.
### writeBool
RLP encodes a bool.




#### Declaration
```solidity
  function writeBool(
    bool _in
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_in` | bool | The bool to encode.


#### Returns:
| Type | Description |
| --- | --- |
|`The` | RLP encoded bool in bytes.


