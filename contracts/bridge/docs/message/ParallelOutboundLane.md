# ParallelOutboundLane


Everything about outgoing messages sending.

> See https://itering.notion.site/Basic-Message-Channel-c41f0c9e453c478abb68e93f6a067c52

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Functions](#functions)
  - [constructor](#constructor)
  - [send_message](#send_message)
  - [message_size](#message_size)
  - [imt_branch](#imt_branch)
  - [encodeMessageKey](#encodemessagekey)
- [Events](#events)
  - [MessageAccepted](#messageaccepted)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->




## Functions

### constructor
No description
> Deploys the OutboundLane contract


#### Declaration
```solidity
  function constructor(
    uint32 _thisChainPosition,
    uint32 _thisLanePosition,
    uint32 _bridgedChainPosition,
    uint32 _bridgedLanePosition
  ) public LaneIdentity
```

#### Modifiers:
| Modifier |
| --- |
| LaneIdentity |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_thisChainPosition` | uint32 | The thisChainPosition of outbound lane
|`_thisLanePosition` | uint32 | The lanePosition of this outbound lane
|`_bridgedChainPosition` | uint32 | The bridgedChainPosition of outbound lane
|`_bridgedLanePosition` | uint32 | The lanePosition of target inbound lane

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
|`nonce` | Latest nonce
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
  ) public returns (uint64)
```

#### Modifiers:
No modifiers



### imt_branch
No description


#### Declaration
```solidity
  function imt_branch(
  ) public returns (bytes32[32])
```

#### Modifiers:
No modifiers



### encodeMessageKey
No description


#### Declaration
```solidity
  function encodeMessageKey(
  ) public returns (uint256)
```

#### Modifiers:
No modifiers





## Events

### MessageAccepted
No description

  


