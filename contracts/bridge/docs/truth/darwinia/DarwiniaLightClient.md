# DarwiniaLightClient


The light client is the trust layer of the bridge

> See https://hackmd.kahub.in/Nx9YEaOaTRCswQjVbn4WsQ?view

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [constructor](#constructor)
  - [getFinalizedChainMessagesRoot](#getfinalizedchainmessagesroot)
  - [getFinalizedBlockNumber](#getfinalizedblocknumber)
  - [getCurrentId](#getcurrentid)
  - [validatorBitfield](#validatorbitfield)
  - [threshold](#threshold)
  - [createRandomBitfield](#createrandombitfield)
  - [_createRandomBitfield](#_createrandombitfield)
  - [createInitialBitfield](#createinitialbitfield)
  - [verify_messages_proof](#verify_messages_proof)
  - [verify_messages_delivery_proof](#verify_messages_delivery_proof)
  - [validate_lane_data_match_root](#validate_lane_data_match_root)
  - [validateLaneDataMatchRoot](#validatelanedatamatchroot)
  - [newSignatureCommitment](#newsignaturecommitment)
  - [completeSignatureCommitment](#completesignaturecommitment)
  - [cleanExpiredCommitment](#cleanexpiredcommitment)
  - [checkAddrInSet](#checkaddrinset)
- [Events](#events)
  - [BEEFYAuthoritySetUpdated](#beefyauthoritysetupdated)
  - [InitialVerificationSuccessful](#initialverificationsuccessful)
  - [NewMessageRoot](#newmessageroot)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| slot0 | struct DarwiniaLightClient.Slot0 |
| authoritySetRoot | bytes32 |
| latestChainMessagesRoot | bytes32 |
| validationData | mapping(uint32 => struct DarwiniaLightClient.ValidationData) |
| MAX_COUNT | uint256 |
| BLOCK_WAIT_PERIOD | uint256 |
| MIN_SUPPORT | uint256 |
| SLASH_VAULT | address |
| NETWORK | bytes32 |



## Functions

### constructor
Deploys the LightClientBridge contract



#### Declaration
```solidity
  function constructor(
    bytes32 network,
    address slashVault,
    uint64 currentAuthoritySetId,
    uint32 currentAuthoritySetLen,
    bytes32 currentAuthoritySetRoot
  ) public
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`network` | bytes32 | source chain network name
|`slashVault` | address | initial SLASH_VAULT
|`currentAuthoritySetId` | uint64 | The id of the current authority set
|`currentAuthoritySetLen` | uint32 | The length of the current authority set
|`currentAuthoritySetRoot` | bytes32 | The merkle tree of the current authority set

### getFinalizedChainMessagesRoot
No description


#### Declaration
```solidity
  function getFinalizedChainMessagesRoot(
  ) external returns (bytes32)
```

#### Modifiers:
No modifiers



### getFinalizedBlockNumber
No description


#### Declaration
```solidity
  function getFinalizedBlockNumber(
  ) external returns (uint256)
```

#### Modifiers:
No modifiers



### getCurrentId
No description


#### Declaration
```solidity
  function getCurrentId(
  ) external returns (uint32)
```

#### Modifiers:
No modifiers



### validatorBitfield
No description


#### Declaration
```solidity
  function validatorBitfield(
  ) external returns (uint256)
```

#### Modifiers:
No modifiers



### threshold
No description


#### Declaration
```solidity
  function threshold(
  ) public returns (uint256)
```

#### Modifiers:
No modifiers



### createRandomBitfield
No description


#### Declaration
```solidity
  function createRandomBitfield(
  ) public returns (uint256)
```

#### Modifiers:
No modifiers



### _createRandomBitfield
No description


#### Declaration
```solidity
  function _createRandomBitfield(
  ) internal returns (uint256)
```

#### Modifiers:
No modifiers



### createInitialBitfield
No description


#### Declaration
```solidity
  function createInitialBitfield(
  ) external returns (uint256)
```

#### Modifiers:
No modifiers



### verify_messages_proof
No description


#### Declaration
```solidity
  function verify_messages_proof(
  ) external returns (bool)
```

#### Modifiers:
No modifiers



### verify_messages_delivery_proof
No description


#### Declaration
```solidity
  function verify_messages_delivery_proof(
  ) external returns (bool)
```

#### Modifiers:
No modifiers



### validate_lane_data_match_root
No description


#### Declaration
```solidity
  function validate_lane_data_match_root(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### validateLaneDataMatchRoot
No description


#### Declaration
```solidity
  function validateLaneDataMatchRoot(
  ) internal returns (bool)
```

#### Modifiers:
No modifiers



### newSignatureCommitment
Executed by the prover in order to begin the process of block
acceptance by the light client



#### Declaration
```solidity
  function newSignatureCommitment(
    bytes32 commitmentHash,
    uint256 validatorClaimsBitfield
  ) external returns (uint32)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`commitmentHash` | bytes32 | contains the commitmentHash signed by the current authority set
|`validatorClaimsBitfield` | uint256 | a bitfield containing a membership status of each
validator who has claimed to have signed the commitmentHash

### completeSignatureCommitment
Performs the second step in the validation logic



#### Declaration
```solidity
  function completeSignatureCommitment(
    uint32 id,
    struct BEEFYCommitmentScheme.Commitment commitment,
    struct DarwiniaLightClient.CommitmentMultiProof validatorProof
  ) external
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`id` | uint32 | an identifying value generated in the previous transaction
|`commitment` | struct BEEFYCommitmentScheme.Commitment | contains the full commitment that was used for the commitmentHash
|`validatorProof` | struct DarwiniaLightClient.CommitmentMultiProof | a struct containing the data needed to verify all validator signatures

### cleanExpiredCommitment
Clean up the expired commitment and slash



#### Declaration
```solidity
  function cleanExpiredCommitment(
    uint32 id
  ) external
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`id` | uint32 | the identifier generated by submit commitment

### checkAddrInSet
Checks if an address is a member of the merkle tree



#### Declaration
```solidity
  function checkAddrInSet(
    bytes32 root,
    address addr,
    uint256 pos,
    bytes32[] proof
  ) public returns (bool)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`root` | bytes32 | the root of the merkle tree
|`addr` | address | The address to check
|`pos` | uint256 | The position to check, index starting at 0
|`proof` | bytes32[] | Merkle proof required for validation of the address

#### Returns:
| Type | Description |
| --- | --- |
|`Returns` | true if the address is in the set
### _updateAuthoritySet
Updates the current authority set



#### Declaration
```solidity
  function _updateAuthoritySet(
    uint64 _authoritySetId,
    uint32 _authoritySetLen,
    bytes32 _authoritySetRoot
  ) internal
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_authoritySetId` | uint64 | The new authority set id
|`_authoritySetLen` | uint32 | The new length of authority set
|`_authoritySetRoot` | bytes32 | The new authority set root



## Events

### BEEFYAuthoritySetUpdated
No description

  


### InitialVerificationSuccessful
Notifies an observer that the prover's attempt at initital
verification was successful.

> Note that the prover must wait until `n` blocks have been mined
subsequent to the generation of this event before the 2nd tx can be sent

  

#### Params:
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`prover` | address |  | The address of the calling prover
|`blockNumber` | uint256 |  | The blocknumber in which the initial validation
succeeded
|`id` | uint256 |  | An identifier to provide disambiguation
### FinalVerificationSuccessful
Notifies an observer that the complete verification process has
 finished successfuly and the new commitmentHash will be accepted


  

#### Params:
| Param | Type | Indexed | Description |
| --- | --- | :---: | --- |
|`prover` | address |  | The address of the successful prover
|`id` | uint256 |  | the identifier used
### CleanExpiredCommitment
No description

  


### NewMessageRoot
No description

  


