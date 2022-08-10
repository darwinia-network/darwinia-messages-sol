# Bitfield





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [randomNBitsWithPriorCheck](#randomnbitswithpriorcheck)
  - [createBitfield](#createbitfield)
  - [countSetBits](#countsetbits)
  - [isSet](#isset)
  - [set](#set)
  - [clear](#clear)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### randomNBitsWithPriorCheck
Draws a random number, derives an index in the bitfield, and sets the bit if it is in the `prior` and not
yet set. Repeats that `n` times.


#### Declaration
```solidity
  function randomNBitsWithPriorCheck(
  ) internal returns (uint256 bitfield)
```

#### Modifiers:
No modifiers



### createBitfield
No description


#### Declaration
```solidity
  function createBitfield(
  ) internal returns (uint256 bitfield)
```

#### Modifiers:
No modifiers



### countSetBits
Calculates the number of set bits by using the hamming weight of the bitfield.
The alogrithm below is implemented after https://en.wikipedia.org/wiki/Hamming_weight#Efficient_implementation.
Further improvements are possible, see the article above.


#### Declaration
```solidity
  function countSetBits(
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers



### isSet
No description


#### Declaration
```solidity
  function isSet(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### set
No description


#### Declaration
```solidity
  function set(
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers



### clear
No description


#### Declaration
```solidity
  function clear(
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers





