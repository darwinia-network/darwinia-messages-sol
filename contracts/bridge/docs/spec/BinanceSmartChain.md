# BinanceSmartChain


Binance smart chain specification


## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [hash](#hash)
  - [hash_with_chain_id](#hash_with_chain_id)
  - [rlp](#rlp)
  - [rlp_chain_id](#rlp_chain_id)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### hash
Compute hash of this header (keccak of the RLP with seal)


#### Declaration
```solidity
  function hash(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### hash_with_chain_id
Compute hash of this header with chain id


#### Declaration
```solidity
  function hash_with_chain_id(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers



### rlp
Compute the RLP of this header


#### Declaration
```solidity
  function rlp(
  ) internal returns (bytes data)
```

#### Modifiers:
No modifiers



### rlp_chain_id
Compute the RLP of this header with chain id


#### Declaration
```solidity
  function rlp_chain_id(
  ) internal returns (bytes data)
```

#### Modifiers:
No modifiers





