# FeeMarket





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Modifiers](#modifiers)
  - [onlyOwner](#onlyowner)
  - [onlyOutBound](#onlyoutbound)
  - [enoughBalance](#enoughbalance)
- [Functions](#functions)
  - [constructor](#constructor)
  - [receive](#receive)
  - [setOwner](#setowner)
  - [setOutbound](#setoutbound)
  - [setParaTime](#setparatime)
  - [setParaRelay](#setpararelay)
  - [deposit](#deposit)
  - [withdraw](#withdraw)
  - [totalSupply](#totalsupply)
  - [getOrderBook](#getorderbook)
  - [getTopRelayers](#gettoprelayers)
  - [getOrderFee](#getorderfee)
  - [getOrder](#getorder)
  - [isRelayer](#isrelayer)
  - [market_fee](#market_fee)
  - [enroll](#enroll)
  - [unenroll](#unenroll)
  - [addRelayer](#addrelayer)
  - [removeRelayer](#removerelayer)
  - [pruneRelayer](#prunerelayer)
  - [moveRelayer](#moverelayer)
  - [assign](#assign)
  - [settle](#settle)
- [Events](#events)
  - [SetOwner](#setowner)
  - [SetOutbound](#setoutbound)
  - [SetParaTime](#setparatime)
  - [SetParaRelay](#setpararelay)
  - [Slash](#slash)
  - [Reward](#reward)
  - [Deposit](#deposit)
  - [Withdrawal](#withdrawal)
  - [Locked](#locked)
  - [UnLocked](#unlocked)
  - [AddRelayer](#addrelayer)
  - [RemoveRelayer](#removerelayer)
  - [OrderAssgigned](#orderassgigned)
  - [OrderSettled](#ordersettled)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| VAULT | address |
| slashTime | uint32 |
| relayTime | uint32 |
| assignedRelayersNumber | uint32 |
| collateralPerorder | uint256 |
| owner | address |
| outbounds | mapping(address => uint256) |
| balanceOf | mapping(address => uint256) |
| lockedOf | mapping(address => uint256) |
| relayers | mapping(address => address) |
| relayerCount | uint256 |
| feeOf | mapping(address => uint256) |
| orderOf | mapping(uint256 => struct FeeMarket.Order) |
| assignedRelayers | mapping(uint256 => mapping(uint256 => struct FeeMarket.OrderExt)) |


## Modifiers

### onlyOwner
No description


#### Declaration
```solidity
  modifier onlyOwner
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



### setOwner
No description


#### Declaration
```solidity
  function setOwner(
  ) external onlyOwner
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |



### setOutbound
No description


#### Declaration
```solidity
  function setOutbound(
  ) external onlyOwner
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |



### setParaTime
No description


#### Declaration
```solidity
  function setParaTime(
  ) external onlyOwner
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |



### setParaRelay
No description


#### Declaration
```solidity
  function setParaRelay(
  ) external onlyOwner
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |



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



### totalSupply
No description


#### Declaration
```solidity
  function totalSupply(
  ) public returns (uint256)
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



### getOrder
No description


#### Declaration
```solidity
  function getOrder(
  ) external returns (struct FeeMarket.Order, struct FeeMarket.OrderExt[])
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



### market_fee
No description


#### Declaration
```solidity
  function market_fee(
  ) external returns (uint256 fee)
```

#### Modifiers:
No modifiers



### enroll
No description


#### Declaration
```solidity
  function enroll(
  ) public
```

#### Modifiers:
No modifiers



### unenroll
No description


#### Declaration
```solidity
  function unenroll(
  ) public
```

#### Modifiers:
No modifiers



### addRelayer
No description


#### Declaration
```solidity
  function addRelayer(
  ) public enoughBalance
```

#### Modifiers:
| Modifier |
| --- |
| enoughBalance |



### removeRelayer
No description


#### Declaration
```solidity
  function removeRelayer(
  ) public
```

#### Modifiers:
No modifiers



### pruneRelayer
No description


#### Declaration
```solidity
  function pruneRelayer(
  ) public
```

#### Modifiers:
No modifiers



### moveRelayer
No description


#### Declaration
```solidity
  function moveRelayer(
  ) public
```

#### Modifiers:
No modifiers



### assign
No description


#### Declaration
```solidity
  function assign(
  ) public onlyOutBound returns (bool)
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

### SetOwner
No description

  


### SetOutbound
No description

  


### SetParaTime
No description

  


### SetParaRelay
No description

  


### Slash
No description

  


### Reward
No description

  


### Deposit
No description

  


### Withdrawal
No description

  


### Locked
No description

  


### UnLocked
No description

  


### AddRelayer
No description

  


### RemoveRelayer
No description

  


### OrderAssgigned
No description

  


### OrderSettled
No description

  


