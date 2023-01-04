# EthereumSerialLaneVerifier





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [constructor](#constructor)
  - [state_root](#state_root)
  - [LIGHT_CLIENT](#light_client)
  - [changeLightClient](#changelightclient)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### constructor
No description


#### Declaration
```solidity
  function constructor(
  ) public SerialLaneStorageVerifier
```

#### Modifiers:
| Modifier |
| --- |
| SerialLaneStorageVerifier |



### state_root
No description


#### Declaration
```solidity
  function state_root(
  ) public returns (bytes32)
```

#### Modifiers:
No modifiers



### LIGHT_CLIENT
No description


#### Declaration
```solidity
  function LIGHT_CLIENT(
  ) external returns (address)
```

#### Modifiers:
No modifiers



### changeLightClient
No description


#### Declaration
```solidity
  function changeLightClient(
  ) external onlySetter
```

#### Modifiers:
| Modifier |
| --- |
| onlySetter |





