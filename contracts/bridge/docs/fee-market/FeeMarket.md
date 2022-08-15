# FeeMarket





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Modifiers](#modifiers)
  - [onlySetter](#onlysetter)
  - [onlyOutBound](#onlyoutbound)
  - [enoughBalance](#enoughbalance)
- [Functions](#functions)
  - [constructor](#constructor)
  - [receive](#receive)
  - [setSetter](#setsetter)
  - [setOutbound](#setoutbound)
  - [setParaTime](#setparatime)
  - [setParaRelay](#setpararelay)
  - [market_fee](#market_fee)
  - [totalSupply](#totalsupply)
  - [getOrder](#getorder)
  - [getOrderBook](#getorderbook)
  - [getTopRelayers](#gettoprelayers)
  - [getOrderFee](#getorderfee)
  - [getAssignedRelayer](#getassignedrelayer)
  - [getSlotFee](#getslotfee)
  - [isRelayer](#isrelayer)
  - [deposit](#deposit)
  - [withdraw](#withdraw)
  - [enroll](#enroll)
  - [leave](#leave)
  - [enrol](#enrol)
  - [delist](#delist)
  - [prune](#prune)
  - [move](#move)
  - [assign](#assign)
  - [settle](#settle)
- [Events](#events)
  - [Assgigned](#assgigned)
  - [Delist](#delist)
  - [Deposit](#deposit)
  - [Enrol](#enrol)
  - [Locked](#locked)
  - [Reward](#reward)
  - [SetOutbound](#setoutbound)
  - [Settled](#settled)
  - [Slash](#slash)
  - [UnLocked](#unlocked)
  - [Withdrawal](#withdrawal)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| slashTime | uint32 |
| relayTime | uint32 |
| assignedRelayersNumber | uint32 |
| priceRatio | uint32 |
| collateralPerOrder | uint256 |
| relayerCount | uint256 |
| setter | address |
| outbounds | mapping(address => uint256) |
| balanceOf | mapping(address => uint256) |
| lockedOf | mapping(address => uint256) |
| relayers | mapping(address => address) |
| feeOf | mapping(address => uint256) |
| orderOf | mapping(uint256 => struct FeeMarket.Order) |
| assignedRelayers | mapping(uint256 => mapping(uint256 => struct FeeMarket.OrderExt)) |
| VAULT | address |


## Modifiers

### onlySetter
No description


#### Declaration
```solidity
  modifier onlySetter
```


### onlyOutBound
No description


#### Declaration
```solidity
  modifier onlyOutBound
```


### enoughBalance
No description


#### Declaration
```solidity
  modifier enoughBalance
```



## Functions

### constructor
No description


#### Declaration
```solidity
  function constructor(
  ) public
```

#### Modifiers:
No modifiers



### receive
No description


#### Declaration
```solidity
  function receive(
  ) external
```

#### Modifiers:
No modifiers



### setSetter
No description


#### Declaration
```solidity
  function setSetter(
  ) external onlySetter
```

#### Modifiers:
| Modifier |
| --- |
| onlySetter |



### setOutbound
No description


#### Declaration
```solidity
  function setOutbound(
  ) external onlySetter
```

#### Modifiers:
| Modifier |
| --- |
| onlySetter |



### setParaTime
No description


#### Declaration
```solidity
  function setParaTime(
  ) external onlySetter
```

#### Modifiers:
| Modifier |
| --- |
| onlySetter |



### setParaRelay
No description


#### Declaration
```solidity
  function setParaRelay(
  ) external onlySetter
```

#### Modifiers:
| Modifier |
| --- |
| onlySetter |



### market_fee
No description


#### Declaration
```solidity
  function market_fee(
  ) external returns (uint256 fee)
```

#### Modifiers:
No modifiers



### totalSupply
No description


#### Declaration
```solidity
  function totalSupply(
  ) external returns (uint256)
```

#### Modifiers:
No modifiers



### getOrder
No description


#### Declaration
```solidity
  function getOrder(
  ) external returns (struct FeeMarket.Order, struct FeeMarket.OrderExt[])
```

#### Modifiers:
No modifiers



### getOrderBook
No description


#### Declaration
```solidity
  function getOrderBook(
  ) external returns (uint256, address[], uint256[], uint256[])
```

#### Modifiers:
No modifiers



### getTopRelayers
No description


#### Declaration
```solidity
  function getTopRelayers(
  ) public returns (address[])
```

#### Modifiers:
No modifiers



### getOrderFee
No description


#### Declaration
```solidity
  function getOrderFee(
  ) public returns (uint256 fee)
```

#### Modifiers:
No modifiers



### getAssignedRelayer
No description


#### Declaration
```solidity
  function getAssignedRelayer(
  ) public returns (address)
```

#### Modifiers:
No modifiers



### getSlotFee
No description


#### Declaration
```solidity
  function getSlotFee(
  ) public returns (uint256)
```

#### Modifiers:
No modifiers



### isRelayer
No description


#### Declaration
```solidity
  function isRelayer(
  ) public returns (bool)
```

#### Modifiers:
No modifiers



### deposit
No description


#### Declaration
```solidity
  function deposit(
  ) public
```

#### Modifiers:
No modifiers



### withdraw
No description


#### Declaration
```solidity
  function withdraw(
  ) public
```

#### Modifiers:
No modifiers



### enroll
No description


#### Declaration
```solidity
  function enroll(
  ) external
```

#### Modifiers:
No modifiers



### leave
No description


#### Declaration
```solidity
  function leave(
  ) public
```

#### Modifiers:
No modifiers



### enrol
No description


#### Declaration
```solidity
  function enrol(
  ) public enoughBalance
```

#### Modifiers:
| Modifier |
| --- |
| enoughBalance |



### delist
No description


#### Declaration
```solidity
  function delist(
  ) public
```

#### Modifiers:
No modifiers



### prune
No description


#### Declaration
```solidity
  function prune(
  ) public
```

#### Modifiers:
No modifiers



### move
No description


#### Declaration
```solidity
  function move(
  ) external
```

#### Modifiers:
No modifiers



### assign
No description


#### Declaration
```solidity
  function assign(
  ) external onlyOutBound returns (bool)
```

#### Modifiers:
| Modifier |
| --- |
| onlyOutBound |



### settle
No description


#### Declaration
```solidity
  function settle(
  ) external onlyOutBound returns (bool)
```

#### Modifiers:
| Modifier |
| --- |
| onlyOutBound |





## Events

### Assgigned
No description

  


### Delist
No description

  


### Deposit
No description

  


### Enrol
No description

  


### Locked
No description

  


### Reward
No description

  


### SetOutbound
No description

  


### Settled
No description

  


### Slash
No description

  


### UnLocked
No description

  


### Withdrawal
No description

  


