# LightClientBridge


The light client is the trust layer of the bridge

> See https://hackmd.kahub.in/Nx9YEaOaTRCswQjVbn4WsQ?view

## Contents
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Globals](#globals)
- [Functions](#functions)
  - [constructor](#constructor)
  - [getFinalizedBlockNumber](#getfinalizedblocknumber)
  - [validatorBitfield](#validatorbitfield)
  - [requiredNumberOfValidatorSigs](#requirednumberofvalidatorsigs)
  - [requiredNumberOfGuardSigs](#requirednumberofguardsigs)
  - [createRandomBitfield](#createrandombitfield)
  - [createInitialBitfield](#createinitialbitfield)
  - [createCommitmentHash](#createcommitmenthash)
  - [createGuardMessageHash](#createguardmessagehash)
  - [verifyBeefyMerkleLeaf](#verifybeefymerkleleaf)
  - [newSignatureCommitment](#newsignaturecommitment)
  - [completeSignatureCommitment](#completesignaturecommitment)
  - [updateGuardSet](#updateguardset)
  - [checkAddrInSet](#checkaddrinset)
- [Events](#events)
  - [InitialVerificationSuccessful](#initialverificationsuccessful)
  - [FinalVerificationSuccessful](#finalverificationsuccessful)
  - [NewMMRRoot](#newmmrroot)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| network | bytes32 |
| currentId | uint256 |
| latestMMRRoot | bytes32 |
| latestBlockNumber | uint256 |
| validationData | mapping(uint256 => struct LightClientBridge.ValidationData) |
| PICK_NUMERATOR | uint256 |
| THRESHOLD_NUMERATOR | uint256 |
| THRESHOLD_DENOMINATOR | uint256 |
| BLOCK_WAIT_PERIOD | uint256 |



## Functions

### constructor
Deploys the LightClientBridge contract



#### Declaration
```solidity
  function constructor(
    bytes32 _network,
    uint256 validatorSetId,
    uint256 numOfValidators,
    bytes32 validatorSetRoot,
    uint256 guardSetId,
    uint256 numOfGuards,
    bytes32 guardSetRoot,
    uint256 guardSetThreshold
  ) public
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`_network` | bytes32 | source chain network name 
|`validatorSetId` | uint256 | initial validator set id
|`numOfValidators` | uint256 | number of initial validator set
|`validatorSetRoot` | bytes32 | initial validator set merkle tree root
|`guardSetId` | uint256 | initial guard set id
|`numOfGuards` | uint256 | number of initial guard set
|`guardSetRoot` | bytes32 | initial guard set merkle tree root
|`guardSetThreshold` | uint256 | initial guard threshold

### getFinalizedBlockNumber
No description


#### Declaration
```solidity
  function getFinalizedBlockNumber(
  ) external returns (uint256)
```

#### Modifiers:
No modifiers



### validatorBitfield
No description


#### Declaration
```solidity
  function validatorBitfield(
  ) external returns (uint256[])
```

#### Modifiers:
No modifiers



### requiredNumberOfValidatorSigs
No description


#### Declaration
```solidity
  function requiredNumberOfValidatorSigs(
  ) public returns (uint256)
```

#### Modifiers:
No modifiers



### requiredNumberOfGuardSigs
No description


#### Declaration
```solidity
  function requiredNumberOfGuardSigs(
  ) public returns (uint256)
```

#### Modifiers:
No modifiers



### createRandomBitfield
No description


#### Declaration
```solidity
  function createRandomBitfield(
  ) public returns (uint256[])
```

#### Modifiers:
No modifiers



### createInitialBitfield
No description


#### Declaration
```solidity
  function createInitialBitfield(
  ) external returns (uint256[])
```

#### Modifiers:
No modifiers



### createCommitmentHash
No description


#### Declaration
```solidity
  function createCommitmentHash(
  ) public returns (bytes32)
```

#### Modifiers:
No modifiers



### createGuardMessageHash
No description


#### Declaration
```solidity
  function createGuardMessageHash(
  ) public returns (bytes32)
```

#### Modifiers:
No modifiers



### verifyBeefyMerkleLeaf
Executed by the apps in order to verify commitment



#### Declaration
```solidity
  function verifyBeefyMerkleLeaf(
    bytes32 beefyMMRLeafHash,
    uint256 beefyMMRLeafIndex,
    uint256 beefyMMRLeafCount,
    bytes32[] peaks,
    bytes32[] siblings
  ) external returns (bool)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`beefyMMRLeafHash` | bytes32 | contains the merkle leaf hash
|`beefyMMRLeafIndex` | uint256 | contains the merkle leaf index
|`beefyMMRLeafCount` | uint256 | contains the merkle leaf count
|`peaks` | bytes32[] | contains the merkle maintain range peaks
|`siblings` | bytes32[] | contains the merkle maintain range siblings

### newSignatureCommitment
Executed by the prover in order to begin the process of block
acceptance by the light client



#### Declaration
```solidity
  function newSignatureCommitment(
    bytes32 commitmentHash,
    uint256[] validatorClaimsBitfield,
    bytes validatorSignature,
    uint256 validatorPosition,
    address validatorAddress,
    bytes32[] validatorAddressMerkleProof
  ) public returns (uint256)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`commitmentHash` | bytes32 | contains the commitmentHash signed by the validator(s)
|`validatorClaimsBitfield` | uint256[] | a bitfield containing a membership status of each
validator who has claimed to have signed the commitmentHash
|`validatorSignature` | bytes | the signature of one validator
|`validatorPosition` | uint256 | the position of the validator, index starting at 0
|`validatorAddress` | address | the public key of the validator
|`validatorAddressMerkleProof` | bytes32[] | proof required for validation of the public key in the validator merkle tree

### completeSignatureCommitment
Performs the second step in the validation logic



#### Declaration
```solidity
  function completeSignatureCommitment(
    uint256 id,
    struct LightClientBridge.Commitment commitment,
    struct LightClientBridge.Proof validatorProof,
    uint256[] guardBitfield,
    struct LightClientBridge.Proof guardProof
  ) public
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`id` | uint256 | an identifying value generated in the previous transaction
|`commitment` | struct LightClientBridge.Commitment | contains the full commitment that was used for the commitmentHash
|`validatorProof` | struct LightClientBridge.Proof | a struct containing the data needed to verify all validator signatures
|`guardBitfield` | uint256[] | A bitfield containing a membership status of each
guard who has claimed to have signed the commitmentHash
|`guardProof` | struct LightClientBridge.Proof | A struct containing the data needed to verify the guards signatures

### updateGuardSet
Update guard set

> This function should call out to the guard registry contract


#### Declaration
```solidity
  function updateGuardSet(
    struct LightClientBridge.GuardMessage guardMessage,
    struct LightClientBridge.Proof guardProof,
    uint256[] guardBitfield
  ) public
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`guardMessage` | struct LightClientBridge.GuardMessage | Contains the full guard message that was used for the messageHash
|`guardProof` | struct LightClientBridge.Proof | A struct containing the data needed to verify the guards signatures
|`guardBitfield` | uint256[] | A bitfield containing a membership status of each
guard who has claimed to have signed the messageHash

### checkAddrInSet
Checks if an address is a member of the merkle tree



#### Declaration
```solidity
  function checkAddrInSet(
    bytes32 root,
    address addr,
    uint256 pos,
    uint256 width,
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
|`width` | uint256 | the width or number of leaves in the tree
|`proof` | bytes32[] | Merkle proof required for validation of the address

#### Returns:
| Type | Description |
| --- | --- |
|`Returns` | true if the address is in the set


## Events

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
### NewMMRRoot
No description

  


