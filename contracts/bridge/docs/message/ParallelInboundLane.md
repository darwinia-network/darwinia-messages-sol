# ParallelInboundLane


Everything about incoming messages receival

> See https://itering.notion.site/Basic-Message-Channel-c41f0c9e453c478abb68e93f6a067c52

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [constructor](#constructor)
  - [receive_message](#receive_message)
  - [_verify_message](#_verify_message)
  - [commitment](#commitment)
- [Events](#events)
  - [MessageDispatched](#messagedispatched)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| dones | mapping(uint256 => bool) |



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
    uint32 _bridgedLanePosition
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

### receive_message
Receive messages proof from bridged chain.


#### Declaration
```solidity
  function receive_message(
  ) external
```

#### Modifiers:
No modifiers



### _verify_message
No description


#### Declaration
```solidity
  function _verify_message(
  ) internal returns (bool)
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





## Events

### MessageDispatched
No description
> Notifies an observer that the message has dispatched

  

#### Params:
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`nonce` | uint64 |  | The message nonce
