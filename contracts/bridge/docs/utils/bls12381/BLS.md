# BLS





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [fast_aggregate_verify](#fast_aggregate_verify)
  - [bls_pairing_check](#bls_pairing_check)
  - [aggregate_pks](#aggregate_pks)
  - [hash_to_curve_g2](#hash_to_curve_g2)
  - [hash_to_field_fq2](#hash_to_field_fq2)
  - [expand_message_xmd](#expand_message_xmd)
  - [reduce_modulo](#reduce_modulo)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### fast_aggregate_verify
No description


#### Declaration
```solidity
  function fast_aggregate_verify(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### bls_pairing_check
No description


#### Declaration
```solidity
  function bls_pairing_check(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### aggregate_pks
No description


#### Declaration
```solidity
  function aggregate_pks(
  ) internal returns (struct G1Point)
```

#### Modifiers:
No modifiers



### hash_to_curve_g2
No description


#### Declaration
```solidity
  function hash_to_curve_g2(
  ) internal returns (struct G2Point)
```

#### Modifiers:
No modifiers



### hash_to_field_fq2
No description


#### Declaration
```solidity
  function hash_to_field_fq2(
  ) internal returns (struct Fp2[2] result)
```

#### Modifiers:
No modifiers



### expand_message_xmd
No description


#### Declaration
```solidity
  function expand_message_xmd(
  ) internal returns (bytes)
```

#### Modifiers:
No modifiers



### reduce_modulo
No description


#### Declaration
```solidity
  function reduce_modulo(
  ) internal returns (struct Fp)
```

#### Modifiers:
No modifiers





