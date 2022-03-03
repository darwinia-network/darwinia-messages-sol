# InboundLane


The inbound lane is the message layer of the bridge

> See https://itering.notion.site/Basic-Message-Channel-c41f0c9e453c478abb68e93f6a067c52

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Modifiers](#modifiers)
  - [nonReentrant](#nonreentrant)
- [Functions](#functions)
  - [constructor](#constructor)
  - [receive_messages_proof](#receive_messages_proof)
  - [relayers_size](#relayers_size)
  - [relayers_back](#relayers_back)
  - [data](#data)
  - [commitment](#commitment)
  - [receive_state_update](#receive_state_update)
  - [receive_message](#receive_message)
  - [dispatch](#dispatch)
  - [filter](#filter)
- [Events](#events)
  - [MessageDispatched](#messagedispatched)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| MAX_GAS_PER_MESSAGE | uint256 |
| GAS_BUFFER | uint256 |
| MAX_UNCONFIRMED_MESSAGES | uint256 |
| inboundLaneNonce | struct InboundLane.InboundLaneNonce |
| relayers | mapping(uint64 => struct TargetChain.UnrewardedRelayer) |
| locked | uint256 |


## Modifiers

### nonReentrant
No description


#### Declaration
```solidity
  modifier nonReentrant
```



## Functions

### constructor
Deploys the InboundLane contract



#### Declaration
```solidity
  function constructor(
    address _lightClientBridge,
    uint32 _thisChainPosition,
    uint32 _thisLanePosition,
    uint32 _bridgedChainPosition,
    uint32 _bridgedLanePosition,
    uint64 _last_confirmed_nonce,
    uint64 _last_delivered_nonce
  ) public InboundLaneVerifier
```

#### Modifiers:
| Modifier |
| --- |
| InboundLaneVerifier |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_lightClientBridge` | address | The contract address of on-chain light client
|`_thisChainPosition` | uint32 | The thisChainPosition of inbound lane
|`_thisLanePosition` | uint32 | The lanePosition of this inbound lane
|`_bridgedChainPosition` | uint32 | The bridgedChainPosition of inbound lane
|`_bridgedLanePosition` | uint32 | The lanePosition of target outbound lane
|`_last_confirmed_nonce` | uint64 | The last_confirmed_nonce of inbound lane
|`_last_delivered_nonce` | uint64 | The last_delivered_nonce of inbound lane

### receive_messages_proof
No description


#### Declaration
```solidity
  function receive_messages_proof(
  ) public nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| nonReentrant |



### relayers_size
No description


#### Declaration
```solidity
  function relayers_size(
  ) public returns (uint64 size)
```

#### Modifiers:
No modifiers



### relayers_back
No description


#### Declaration
```solidity
  function relayers_back(
  ) public returns (address pre_relayer)
```

#### Modifiers:
No modifiers



### data
No description


#### Declaration
```solidity
  function data(
  ) public returns (struct TargetChain.InboundLaneData lane_data)
```

#### Modifiers:
No modifiers



### commitment
No description


#### Declaration
```solidity
  function commitment(
  ) external returns (bytes32)
```

#### Modifiers:
No modifiers



### receive_state_update
No description


#### Declaration
```solidity
  function receive_state_update(
  ) internal returns (uint64)
```

#### Modifiers:
No modifiers



### receive_message
No description


#### Declaration
```solidity
  function receive_message(
  ) internal returns (uint256 dispatch_results)
```

#### Modifiers:
No modifiers



### dispatch
No description


#### Declaration
```solidity
  function dispatch(
  ) internal returns (bool dispatch_result, bytes returndata)
```

#### Modifiers:
No modifiers



### filter
No description


#### Declaration
```solidity
  function filter(
  ) internal returns (bool canCall)
```

#### Modifiers:
No modifiers





## Events

### MessageDispatched
Notifies an observer that the message has dispatched


  

#### Params:
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`thisChainPosition` | uint32 |  | The thisChainPosition of the message
|`thisLanePosition` | uint32 |  | The thisLanePosition of the message
|`bridgedChainPosition` | uint32 |  | The bridgedChainPosition of the message
|`bridgedLanePosition` | uint32 |  | The bridgedLanePosition of the message
|`nonce` | uint64 |  | The message nonce
|`result` | bool |  | The message result
|`returndata` | bytes |  | The return data of message call, when return false, it's the reason of the error
