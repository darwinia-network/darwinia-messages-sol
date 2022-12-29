# SerialInboundLane


The inbound lane is the message layer of the bridge, Everything about incoming messages receival

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
  - [commitment](#commitment)
  - [data](#data)
- [Events](#events)
  - [MessageDispatched](#messagedispatched)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| inboundLaneNonce | struct SerialInboundLane.InboundLaneNonce |
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
No description
> Deploys the InboundLane contract


#### Declaration
```solidity
  function constructor(
    address _verifier,
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
|`_verifier` | address | The contract address of on-chain verifier
|`_thisChainPosition` | uint32 | The thisChainPosition of inbound lane
|`_thisLanePosition` | uint32 | The lanePosition of this inbound lane
|`_bridgedChainPosition` | uint32 | The bridgedChainPosition of inbound lane
|`_bridgedLanePosition` | uint32 | The lanePosition of target outbound lane
|`_last_confirmed_nonce` | uint64 | The last_confirmed_nonce of inbound lane
|`_last_delivered_nonce` | uint64 | The last_delivered_nonce of inbound lane

### receive_messages_proof
Receive messages proof from bridged chain.

The weight of the call assumes that the transaction always brings outbound lane
state update. Because of that, the submitter (relayer) has no benefit of not including
this data in the transaction, so reward confirmations lags should be minimal.


#### Declaration
```solidity
  function receive_messages_proof(
  ) external nonReentrant
```

#### Modifiers:
| Modifier |
| --- |
| nonReentrant |



### commitment
Return the commitment of lane data.


#### Declaration
```solidity
  function commitment(
  ) external returns (bytes32)
```

#### Modifiers:
No modifiers



### data
Get lane data from the storage.


#### Declaration
```solidity
  function data(
  ) public returns (struct TargetChain.InboundLaneData lane_data)
```

#### Modifiers:
No modifiers





## Events

### MessageDispatched
No description
> Notifies an observer that the message has dispatched

  

#### Params:
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`nonce` | uint64 |  | The message nonce
|`result` | bool |  | The message result
