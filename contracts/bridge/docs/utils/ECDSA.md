# ECDSA



> Elliptic Curve Digital Signature Algorithm (ECDSA) operations.

These functions can be used to verify that a message was signed by the holder
of the private keys of a given address.

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [recover](#recover)
  - [recover](#recover-1)
  - [recover](#recover-2)
  - [toEthSignedMessageHash](#toethsignedmessagehash)
  - [toTypedDataHash](#totypeddatahash)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### recover
No description
> Returns the address that signed a hashed message (`hash`) with
`signature`. This address can then be used for verification purposes.

The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
this function rejects them by requiring the `s` value to be in the lower
half order, and the `v` value to be either 27 or 28.

IMPORTANT: `hash` _must_ be the result of a hash operation for the
verification to be secure: it is possible to craft signatures that
recover to arbitrary addresses for non-hashed data. A safe way to ensure
this is by receiving a hash of the original message (which may otherwise
be too long), and then calling {toEthSignedMessageHash} on it.

#### Declaration
```solidity
  function recover(
  ) internal returns (address)
```

#### Modifiers:
No modifiers



### recover
No description
> Returns the address that signed a hashed message (`hash`) with
`signature`. This address can then be used for verification purposes.

#### Declaration
```solidity
  function recover(
  ) internal returns (address)
```

#### Modifiers:
No modifiers



### recover
No description


#### Declaration
```solidity
  function recover(
  ) internal returns (address)
```

#### Modifiers:
No modifiers



### toEthSignedMessageHash
No description
> Returns an Ethereum Signed Message, created from a `hash`. This
replicates the behavior of the
https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
JSON-RPC method.

#### Declaration
```solidity
  function toEthSignedMessageHash(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### toTypedDataHash
No description
> Returns an Ethereum Signed Typed Data, created from a
`domainSeparator` and a `structHash`. This produces hash corresponding
to the one signed with the
https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
JSON-RPC method as part of EIP-712.

#### Declaration
```solidity
  function toTypedDataHash(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers





