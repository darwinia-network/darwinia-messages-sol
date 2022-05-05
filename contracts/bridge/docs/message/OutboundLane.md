# OutboundLane





## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Modifiers](#modifiers)
  - [nonReentrant](#nonreentrant)
  - [onlySetter](#onlysetter)
- [Functions](#functions)
  - [constructor](#constructor)
  - [setFeeMarket](#setfeemarket)
  - [changeSetter](#changesetter)
  - [send_message](#send_message)
  - [receive_messages_delivery_proof](#receive_messages_delivery_proof)
  - [message_size](#message_size)
  - [data](#data)
  - [commitment](#commitment)
  - [extract_inbound_lane_info](#extract_inbound_lane_info)
  - [confirm_delivery](#confirm_delivery)
  - [extract_dispatch_results](#extract_dispatch_results)
  - [on_messages_delivered](#on_messages_delivered)
  - [prune_messages](#prune_messages)
  - [settle_messages](#settle_messages)
  - [min](#min)
  - [max](#max)
- [Events](#events)
  - [MessageAccepted](#messageaccepted)
  - [MessagesDelivered](#messagesdelivered)
  - [MessagePruned](#messagepruned)
  - [CallbackMessageDelivered](#callbackmessagedelivered)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| MAX_GAS_PER_MESSAGE | uint256 |
| MAX_CALLDATA_LENGTH | uint256 |
| MAX_PENDING_MESSAGES | uint64 |
| MAX_PRUNE_MESSAGES_ATONCE | uint64 |
| outboundLaneNonce | struct OutboundLane.OutboundLaneNonce |
| messages | mapping(uint64 => bytes32) |
| fee_market | address |
| setter | address |
| locked | uint256 |


## Modifiers

### nonReentrant
No description


#### Declaration
```solidity
  modifier nonReentrant
```


### onlySetter
No description


#### Declaration
```solidity
  modifier onlySetter
```



## Functions

### constructor
Deploys the OutboundLane contract



#### Declaration
```solidity
  function constructor(
    address _lightClientBridge,
    uint32 _thisChainPosition,
    uint32 _thisLanePosition,
    uint32 _bridgedChainPosition,
    uint32 _bridgedLanePosition,
    uint64 _oldest_unpruned_nonce,
    uint64 _latest_received_nonce,
    uint64 _latest_generated_nonce
  ) public OutboundLaneVerifier
```

#### Modifiers:
| Modifier |
| --- |
| OutboundLaneVerifier |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_lightClientBridge` | address | The contract address of on-chain light client
|`_thisChainPosition` | uint32 | The thisChainPosition of outbound lane
|`_thisLanePosition` | uint32 | The lanePosition of this outbound lane
|`_bridgedChainPosition` | uint32 | The bridgedChainPosition of outbound lane
|`_bridgedLanePosition` | uint32 | The lanePosition of target inbound lane
|`_oldest_unpruned_nonce` | uint64 | The oldest_unpruned_nonce of outbound lane
|`_latest_received_nonce` | uint64 | The latest_received_nonce of outbound lane
|`_latest_generated_nonce` | uint64 | The latest_generated_nonce of outbound lane

### setFeeMarket
No description


#### Declaration
```solidity
  function setFeeMarket(
  ) external onlySetter nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlySetter |
| nonReentrant |



### changeSetter
No description


#### Declaration
```solidity
  function changeSetter(
  ) external onlySetter nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| onlySetter |
| nonReentrant |



### send_message
Send message over lane.
Submitter could be a contract or just an EOA address.
At the beginning of the launch, submmiter is permission, after the system is stable it will be permissionless.



#### Declaration
```solidity
  function send_message(
    address targetContract,
    bytes encoded
  ) external nonReentrant returns (uint256)
```

#### Modifiers:
| Modifier |
| --- |
| nonReentrant |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`targetContract` | address | The target contract address which you would send cross chain message to
|`encoded` | bytes | The calldata which encoded by ABI Encoding

### receive_messages_delivery_proof
No description


#### Declaration
```solidity
  function receive_messages_delivery_proof(
  ) external nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| nonReentrant |



### message_size
No description


#### Declaration
```solidity
  function message_size(
  ) public returns (uint64 size)
```

#### Modifiers:
No modifiers



### data
No description


#### Declaration
```solidity
  function data(
  ) public returns (struct SourceChain.OutboundLaneDataStorage lane_data)
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



### extract_inbound_lane_info
No description


#### Declaration
```solidity
  function extract_inbound_lane_info(
  ) internal returns (uint64 total_unrewarded_messages, uint64 last_delivered_nonce)
```

#### Modifiers:
No modifiers



### confirm_delivery
No description


#### Declaration
```solidity
  function confirm_delivery(
  ) internal returns (struct TargetChain.DeliveredMessages confirmed_messages)
```

#### Modifiers:
No modifiers



### extract_dispatch_results
No description


#### Declaration
```solidity
  function extract_dispatch_results(
  ) internal returns (uint256 received_dispatch_result)
```

#### Modifiers:
No modifiers



### on_messages_delivered
No description


#### Declaration
```solidity
  function on_messages_delivered(
  ) internal
```

#### Modifiers:
No modifiers



### prune_messages
No description


#### Declaration
```solidity
  function prune_messages(
  ) internal returns (uint64)
```

#### Modifiers:
No modifiers



### settle_messages
No description


#### Declaration
```solidity
  function settle_messages(
  ) internal
```

#### Modifiers:
No modifiers



### min
No description


#### Declaration
```solidity
  function min(
  ) internal returns (uint64 z)
```

#### Modifiers:
No modifiers



### max
No description


#### Declaration
```solidity
  function max(
  ) internal returns (uint64 z)
```

#### Modifiers:
No modifiers





## Events

### MessageAccepted
No description

  


### MessagesDelivered
No description

  


### MessagePruned
No description

  


### CallbackMessageDelivered
No description

  


