# SerialOutboundLane


Everything about outgoing messages sending.

> See https://itering.notion.site/Basic-Message-Channel-c41f0c9e453c478abb68e93f6a067c52

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [constructor](#constructor)
  - [send_message](#send_message)
  - [commitment](#commitment)
  - [message_size](#message_size)
  - [data](#data)
- [Events](#events)
  - [MessageAccepted](#messageaccepted)
  - [MessagesDelivered](#messagesdelivered)
  - [MessagePruned](#messagepruned)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| outboundLaneNonce | struct SerialOutboundLane.OutboundLaneNonce |
| messages | mapping(uint64 => bytes32) |
| FEE_MARKET | address |



## Functions

### constructor
No description
> Deploys the OutboundLane contract


#### Declaration
```solidity
  function constructor(
    address _verifier,
    address _thisChainPosition,
    uint32 _thisLanePosition,
    uint32 _bridgedChainPosition,
    uint32 _bridgedLanePosition,
    uint32 _oldest_unpruned_nonce,
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
|`_verifier` | address | The contract address of on-chain verifier
|`_thisChainPosition` | address | The thisChainPosition of outbound lane
|`_thisLanePosition` | uint32 | The lanePosition of this outbound lane
|`_bridgedChainPosition` | uint32 | The bridgedChainPosition of outbound lane
|`_bridgedLanePosition` | uint32 | The lanePosition of target inbound lane
|`_oldest_unpruned_nonce` | uint32 | The oldest_unpruned_nonce of outbound lane
|`_latest_received_nonce` | uint64 | The latest_received_nonce of outbound lane
|`_latest_generated_nonce` | uint64 | The latest_generated_nonce of outbound lane

### send_message
No description
> Send message over lane.
Submitter could be a contract or just an EOA address.
At the beginning of the launch, submmiter is permission, after the system is stable it will be permissionless.


#### Declaration
```solidity
  function send_message(
    address target,
    bytes encoded
  ) external returns (uint64)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`target` | address | The target contract address which you would send cross chain message to
|`encoded` | bytes | The calldata which encoded by ABI Encoding

#### Returns:
| Type | Description |
| --- | --- |
|`nonce` | Latest generated nonce
### receive_messages_delivery_proof
Receive messages delivery proof from bridged chain.


#### Declaration
```solidity
  function receive_messages_delivery_proof(
  ) external
```

#### Modifiers:
No modifiers



### commitment
Return the commitment of lane data.


#### Declaration
```solidity
  function commitment(
  ) external returns (bytes32)
```

#### Modifiers:
No modifiers



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
Get lane data from the storage.


#### Declaration
```solidity
  function data(
  ) public returns (struct SourceChain.OutboundLaneDataStorage lane_data)
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

  


