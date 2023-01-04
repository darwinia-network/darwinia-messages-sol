# RLPDecode


RLPReader is a library for parsing RLP-encoded byte arrays into Solidity types. Adapted
        from Solidity-RLP (https://github.com/hamdiallam/Solidity-RLP) by Hamdi Allam with
        various tweaks to improve readability.


## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [toRLPItem](#torlpitem)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| MAX_LIST_LENGTH | uint256 |



## Functions

### toRLPItem
Converts bytes to a reference to memory position and length.




#### Declaration
```solidity
  function toRLPItem(
    bytes _in
  ) internal returns (struct RLPDecode.RLPItem)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_in` | bytes | Input bytes to convert.


#### Returns:
| Type | Description |
| --- | --- |
|`Output` | memory reference.
### readList
Reads an RLP list value into a list of RLP items.




#### Declaration
```solidity
  function readList(
    struct RLPDecode.RLPItem _in
  ) internal returns (struct RLPDecode.RLPItem[])
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_in` | struct RLPDecode.RLPItem | RLP list value.


#### Returns:
| Type | Description |
| --- | --- |
|`Decoded` | RLP list items.
### readList
Reads an RLP list value into a list of RLP items.




#### Declaration
```solidity
  function readList(
    bytes _in
  ) internal returns (struct RLPDecode.RLPItem[])
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_in` | bytes | RLP list value.


#### Returns:
| Type | Description |
| --- | --- |
|`Decoded` | RLP list items.
### readBytes
Reads an RLP bytes value into bytes.




#### Declaration
```solidity
  function readBytes(
    struct RLPDecode.RLPItem _in
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_in` | struct RLPDecode.RLPItem | RLP bytes value.


#### Returns:
| Type | Description |
| --- | --- |
|`Decoded` | bytes.
### readBytes
Reads an RLP bytes value into bytes.




#### Declaration
```solidity
  function readBytes(
    bytes _in
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_in` | bytes | RLP bytes value.


#### Returns:
| Type | Description |
| --- | --- |
|`Decoded` | bytes.
### readRawBytes
Reads the raw bytes of an RLP item.




#### Declaration
```solidity
  function readRawBytes(
    struct RLPDecode.RLPItem _in
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_in` | struct RLPDecode.RLPItem | RLP item to read.


#### Returns:
| Type | Description |
| --- | --- |
|`Raw` | RLP bytes.
### readString
Reads an RLP string value into a string.



#### Declaration
```solidity
  function readString(
    struct RLPDecode.RLPItem _in
  ) internal returns (string)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_in` | struct RLPDecode.RLPItem | RLP string value.

#### Returns:
| Type | Description |
| --- | --- |
|`Decoded` | string.
### readString
Reads an RLP string value into a string.



#### Declaration
```solidity
  function readString(
    bytes _in
  ) internal returns (string)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_in` | bytes | RLP string value.

#### Returns:
| Type | Description |
| --- | --- |
|`Decoded` | string.
### readBytes32
Reads an RLP bytes32 value into a bytes32.



#### Declaration
```solidity
  function readBytes32(
    struct RLPDecode.RLPItem _in
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_in` | struct RLPDecode.RLPItem | RLP bytes32 value.

#### Returns:
| Type | Description |
| --- | --- |
|`Decoded` | bytes32.
### readBytes32
Reads an RLP bytes32 value into a bytes32.



#### Declaration
```solidity
  function readBytes32(
    bytes _in
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_in` | bytes | RLP bytes32 value.

#### Returns:
| Type | Description |
| --- | --- |
|`Decoded` | bytes32.
### readUint256
Reads an RLP uint256 value into a uint256.



#### Declaration
```solidity
  function readUint256(
    struct RLPDecode.RLPItem _in
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_in` | struct RLPDecode.RLPItem | RLP uint256 value.

#### Returns:
| Type | Description |
| --- | --- |
|`Decoded` | uint256.
### readUint256
Reads an RLP uint256 value into a uint256.



#### Declaration
```solidity
  function readUint256(
    bytes _in
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_in` | bytes | RLP uint256 value.

#### Returns:
| Type | Description |
| --- | --- |
|`Decoded` | uint256.


