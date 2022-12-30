# State


State specification


## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [toEVMAccount](#toevmaccount)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### toEVMAccount
Convert data input to EVMAccount



#### Declaration
```solidity
  function toEVMAccount(
    bytes data
  ) internal returns (struct State.EVMAccount)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`data` | bytes | RLP data of EVMAccount

#### Returns:
| Type | Description |
| --- | --- |
|`EVMAccount` | object


