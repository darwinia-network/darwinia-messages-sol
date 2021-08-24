# BasicInboundChannel


The basic inbound channel is the message layer of the bridge

> See https://itering.notion.site/Basic-Message-Channel-c41f0c9e453c478abb68e93f6a067c52

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [constructor](#constructor)
  - [submit](#submit)
  - [verifyMessages](#verifymessages)
  - [processMessages](#processmessages)
  - [validateMessagesMatchRoot](#validatemessagesmatchroot)
  - [hashMMRLeaf](#hashmmrleaf)
- [Events](#events)
  - [MessageDispatched](#messagedispatched)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| MAX_GAS_PER_MESSAGE | uint256 |
| GAS_BUFFER | uint256 |
| chainId | uint256 |
| laneId | uint256 |
| nonce | uint256 |
| lightClientBridge | contract ILightClientBridge |



## Functions

### constructor
Deploys the BasicInboundChannel contract



#### Declaration
```solidity
  function constructor(
    uint256 _landId,
    uint256 _nonce,
    uint256 _lightClientBridge
  ) public
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_landId` | uint256 | The position of the leaf in the message merkle tree, index starting with 0
|`_nonce` | uint256 | ID of the next message, which is incremented in strict order
|`_lightClientBridge` | uint256 | The contract address of on-chain light client

### submit
Deliver and dispatch the messages



#### Declaration
```solidity
  function submit(
    struct BasicInboundChannel.Message[] messages,
    uint256 numOfChains,
    bytes32[] chainProof,
    bytes32 chainMessageRoot,
    uint256 numOfLanes,
    bytes32[] laneProof,
    struct BasicInboundChannel.BeefyMMRLeaf beefyMMRLeaf,
    uint256 beefyMMRLeafIndex,
    uint256 beefyMMRLeafCount,
    bytes32[] peaks,
    bytes32[] siblings
  ) public
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`messages` | struct BasicInboundChannel.Message[] | All the messages in the source chain block of this channel which need be delivered
|`numOfChains` | uint256 | Number of all chain
|`chainProof` | bytes32[] | The merkle proof required for validation of the messages in the chain message merkle tree
|`chainMessageRoot` | bytes32 | The merkle root of all channels message on this chain, and merkle leaf of messageRoot 
|`numOfLanes` | uint256 | Number of all channels
|`laneProof` | bytes32[] | The merkle proof required for validation of the messages in the lane message merkle tree
|`beefyMMRLeaf` | struct BasicInboundChannel.BeefyMMRLeaf | Beefy MMR leaf which the message root is located
|`beefyMMRLeafIndex` | uint256 | Beefy MMR index which the beefy leaf is located
|`beefyMMRLeafCount` | uint256 | Beefy MMR width of the MMR tree
|`peaks` | bytes32[] | The proof required for validation the leaf
|`siblings` | bytes32[] | The proof required for validation the leaf

### verifyMessages
No description


#### Declaration
```solidity
  function verifyMessages(
  ) internal
```

#### Modifiers:
No modifiers



### processMessages
No description


#### Declaration
```solidity
  function processMessages(
  ) internal
```

#### Modifiers:
No modifiers



### validateMessagesMatchRoot
No description


#### Declaration
```solidity
  function validateMessagesMatchRoot(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### hashMMRLeaf
No description


#### Declaration
```solidity
  function hashMMRLeaf(
  ) internal returns (bytes32)
```

#### Modifiers:
No modifiers





## Events

### MessageDispatched
Notifies an observer that the message has dispatched


  

#### Params:
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`nonce` | uint256 | :white_check_mark: | The message nonce
|`result` | bool | :white_check_mark: | The message result
|`returndata` | bytes |  | The return data of message call, when return false, it's the reason of the error
