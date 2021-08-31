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
| chainPosition | uint256 |
| channelPosition | uint256 |
| nonce | uint256 |
| lightClientBridge | contract ILightClientBridge |



## Functions

### constructor
Deploys the BasicInboundChannel contract



#### Declaration
```solidity
  function constructor(
    uint256 _chainPosition,
    uint256 _channelPosition,
    uint256 _nonce,
    contract ILightClientBridge _lightClientBridge
  ) public
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_chainPosition` | uint256 | The position of the leaf in the `chain_messages_merkle_tree`, index starting with 0
|`_channelPosition` | uint256 | The position of the leaf in the `channel_messages_merkle_tree`, index starting with 0
|`_nonce` | uint256 | ID of the next messages, which is incremented in strict order
|`_lightClientBridge` | contract ILightClientBridge | The contract address of on-chain light client

### submit
Deliver and dispatch the messages



#### Declaration
```solidity
  function submit(
    struct BasicInboundChannel.Message[] messages,
    uint256 chainCount,
    bytes32[] chainMessagesProof,
    bytes32 channelMessagesRoot,
    uint256 channelCount,
    bytes32[] channelMessagesProof,
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
|`chainCount` | uint256 | Number of all chain
|`chainMessagesProof` | bytes32[] | The merkle proof required for validation of the messages in the `chain_messages_merkle_tree`
|`channelMessagesRoot` | bytes32 | The merkle root of the channels, each channel is a leaf constructed by the hash of the messages in the channel
|`channelCount` | uint256 | Number of all channels
|`channelMessagesProof` | bytes32[] | The merkle proof required for validation of the messages in the `channel_messages_merkle_tree`
|`beefyMMRLeaf` | struct BasicInboundChannel.BeefyMMRLeaf | Beefy MMR leaf which the messages root is located
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
