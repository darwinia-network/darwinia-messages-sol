// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@darwinia/contracts-utils/contracts/ECDSA.sol";
import "@darwinia/contracts-utils/contracts/Bitfield.sol";
import "@darwinia/contracts-verify/contracts/MerkleProof.sol";
import "@darwinia/contracts-verify/contracts/KeccakMMR.sol";
import "./ValidatorRegistry.sol";
import "./GuardRegistry.sol";

/**
 * @title A entry contract for the Ethereum-like light client
 * @author echo
 * @notice The light client is the trust layer of the bridge
 * @dev See https://hackmd.kahub.in/Nx9YEaOaTRCswQjVbn4WsQ?view
 */
contract LightClientBridge is Bitfield, ValidatorRegistry, GuardRegistry {

    /* Events */

    /**
     * @notice Notifies an observer that the prover's attempt at initital
     * verification was successful.
     * @dev Note that the prover must wait until `n` blocks have been mined
     * subsequent to the generation of this event before the 2nd tx can be sent
     * @param prover The address of the calling prover
     * @param blockNumber The blocknumber in which the initial validation
     * succeeded
     * @param id An identifier to provide disambiguation
     */
    event InitialVerificationSuccessful(
        address prover,
        uint256 blockNumber,
        uint256 id
    );

    /**
     * @notice Notifies an observer that the complete verification process has
     *  finished successfuly and the new commitmentHash will be accepted
     * @param prover The address of the successful prover
     * @param id the identifier used
     */
    event FinalVerificationSuccessful(
        address prover,
        uint256 id
    );

    event NewMMRRoot(bytes32 mmrRoot, uint256 blockNumber);

    /* Types */

    /**
     * Next BEEFY authority set
     * @param id ID of the next set
     * @param len Number of validators in the set
     * @param root Merkle Root Hash build from BEEFY AuthorityIds
    */
    struct NextValidatorSet {
        uint64 id;
        uint32 len; 
        bytes32 root;
    }

    /**
     * The payload being signed
     * @param network Source chain network identifier
     * @param mmr MMR root hash
     * @param nextValidatorSet Next BEEFY authority set
    */
    struct Payload {
        bytes32 network;
        bytes32 mmr;
        NextValidatorSet nextValidatorSet; 
    }

    /**
     * The Commitment, with its payload, is the core thing we are trying to verify with this contract.
     * It contains a next validator set or not and a MMR root that commits to the darwinia history,
     * including past blocks and can be used to verify darwinia blocks. 
     * @param payload the payload of the new commitment in beefy justifications (in
     * our case, this is a next validator set and a new MMR root for all past darwinia blocks)
     * @param blockNumber block number for the given commitment
     * @param validatorSetId validator set id that signed the given commitment
     */
    struct Commitment {
        Payload payload;
        uint32 blockNumber;
        uint64 validatorSetId;
    }

    /**
     * The Proof is a collection of proofs used to verify the signatures from the signers signing
     * each new justification.
     * @param signatures an array of signatures from the chosen signers
     * @param positions an array of the positions of the chosen signers
     * @param signers an array of the address of each signer
     * @param signerProofs an array of merkle proofs from the chosen validators proving that their addresses
     * are in the validator set
     */
    struct Proof {
        bytes[] signatures;
        uint256[] positions;
        address[] signers;
        bytes32[][] signerProofs;
    }

    /**
     * The ValidationData is the set of data used to link each pair of initial and complete verification transactions.
     * @param senderAddress the sender of the initial transaction
     * @param commitmentHash the hash of the commitment they are claiming has been signed
     * @param blockNumber the block number for this commitment
     * @param validatorClaimsBitfield a bitfield signalling which validators they claim have signed
     */
    struct ValidationData {
        address senderAddress;
        bytes32 commitmentHash;
        uint256 blockNumber;
        uint256[] validatorClaimsBitfield;
    }

    /**
     * The GuardMessage is used to update guard set which is sign by most of guards.
     * @param network source chain network name
     * @param methodID which method guard need to call
     * @param nextGuardSetId The id of the next guard set
     * @param nextGuardSetLen The number of guards in the next guard set
     * @param nextGuardSetRoot The merkle root of the merkle tree of the next guards
     * @param nextGuardSetThreshold The threshold of the next guards
     */
    struct GuardMessage {
        bytes32 network;
        bytes4 methodID;
        uint32 nextGuardSetId;
        uint32 nextGuardSetLen;
        bytes32 nextGuardSetRoot;
        uint32 nextGuardSetThreshold;
    }

    /* State */

    // 'Crab', 'Darwinia', 'Pangolin'
    bytes32 public network;
    uint256 public currentId;
    bytes32 public latestMMRRoot;
    uint256 public latestBlockNumber;
    mapping(uint256 => ValidationData) public validationData;

    /* Constants */

    uint256 public constant PICK_NUMERATOR = 1;
    uint256 public constant THRESHOLD_NUMERATOR = 2;
    uint256 public constant THRESHOLD_DENOMINATOR = 3;
    uint256 public constant BLOCK_WAIT_PERIOD = 12;

    /**
     * @notice Deploys the LightClientBridge contract
     * @param _network source chain network name 
     * @param validatorSetId initial validator set id
     * @param numOfValidators number of initial validator set
     * @param validatorSetRoot initial validator set merkle tree root
     * @param guardSetId initial guard set id
     * @param numOfGuards number of initial guard set
     * @param guardSetRoot initial guard set merkle tree root
     * @param guardSetThreshold initial guard threshold
    */
    constructor(
        bytes32 _network,
        uint256 validatorSetId,
        uint256 numOfValidators,
        bytes32 validatorSetRoot,
        uint256 guardSetId,
        uint256 numOfGuards,
        bytes32 guardSetRoot,
        uint256 guardSetThreshold
    ) public {
        network = _network;
        _updateValidatorSet(validatorSetId, numOfValidators, validatorSetRoot);
        _updateGuardSet(guardSetId, numOfGuards, guardSetRoot, guardSetThreshold);
    }

    /* Public Functions */

    function getFinalizedBlockNumber() external view returns (uint256) {
        return latestBlockNumber;
    }

    function validatorBitfield(uint256 id) external view returns (uint256[] memory) {
        return validationData[id].validatorClaimsBitfield; 
    }

    function requiredNumberOfValidatorSigs() public view returns (uint256) {
        return (numOfValidators * PICK_NUMERATOR) / THRESHOLD_DENOMINATOR;
    }

    function requiredNumberOfGuardSigs() public view returns (uint256) {
        return guardThreshold;
    }

    function createRandomBitfield(uint256 id)
        public
        view
        returns (uint256[] memory)
    {
        ValidationData storage data = validationData[id];

        require(data.blockNumber > 0, "Bridge: invalid id");

        /**
         * @dev verify that block wait period has passed
         */
        require(
            block.number >= data.blockNumber + BLOCK_WAIT_PERIOD,
            "Bridge: Block wait period not over"
        );

        return
            randomNBitsWithPriorCheck(
                getSeed(data.blockNumber),
                data.validatorClaimsBitfield,
                requiredNumberOfValidatorSigs(),
                numOfValidators
            );
    }

    function createInitialBitfield(uint256[] calldata bitsToSet, uint256 length)
        external
        pure
        returns (uint256[] memory)
    {
        return createBitfield(bitsToSet, length);
    }

    function createCommitmentHash(Commitment memory commitment)
        public
        pure 
        returns (bytes32)
    {
        /**
         * Encode and hash the commitment
         */
        return keccak256(
                abi.encodePacked(
                    commitment.payload.network,
                    commitment.payload.mmr,
                    commitment.payload.nextValidatorSet.id,
                    commitment.payload.nextValidatorSet.len,
                    commitment.payload.nextValidatorSet.root,
                    commitment.blockNumber,
                    commitment.validatorSetId
                )
            );
    }

    function createGuardMessageHash(GuardMessage memory message)
        public
        pure 
        returns (bytes32)
    {
        /**
         * Encode and hash the message
         */
        return keccak256(
                abi.encodePacked(
                    message.network,
                    message.methodID,
                    message.nextGuardSetId,
                    message.nextGuardSetLen,
                    message.nextGuardSetRoot,
                    message.nextGuardSetThreshold
                )
            );
    }

    /**
     * @notice Executed by the apps in order to verify commitment
     * @param beefyMMRLeafHash contains the merkle leaf hash
     * @param beefyMMRLeafIndex contains the merkle leaf index
     * @param beefyMMRLeafCount contains the merkle leaf count
     * @param peaks contains the merkle maintain range peaks
     * @param siblings contains the merkle maintain range siblings
     */
    function verifyBeefyMerkleLeaf(
        bytes32 beefyMMRLeafHash,
        uint256 beefyMMRLeafIndex,
        uint256 beefyMMRLeafCount,
        bytes32[] calldata peaks,
        bytes32[] calldata siblings 
    ) external view returns (bool) {
        return
            KeccakMMR.inclusionProof(
                latestMMRRoot,
                beefyMMRLeafCount,
                beefyMMRLeafIndex,
                beefyMMRLeafHash,
                peaks,
                siblings
            );
    }

    /**
     * @notice Executed by the prover in order to begin the process of block
     * acceptance by the light client
     * @param commitmentHash contains the commitmentHash signed by the validator(s)
     * @param validatorClaimsBitfield a bitfield containing a membership status of each
     * validator who has claimed to have signed the commitmentHash
     * @param validatorSignature the signature of one validator
     * @param validatorPosition the position of the validator, index starting at 0
     * @param validatorAddress the public key of the validator
     * @param validatorAddressMerkleProof proof required for validation of the public key in the validator merkle tree
     */
    function newSignatureCommitment(
        bytes32 commitmentHash,
        uint256[] memory validatorClaimsBitfield,
        bytes memory validatorSignature,
        uint256 validatorPosition,
        address validatorAddress,
        bytes32[] memory validatorAddressMerkleProof
    ) public returns (uint256) {
        /**
         * @dev Check that the bitfield actually contains enough claims to be succesful, ie, > 2/3
         */
        require(
            countSetBits(validatorClaimsBitfield) >
                (numOfValidators * THRESHOLD_NUMERATOR) /
                    THRESHOLD_DENOMINATOR,
            "Bridge: Bitfield not enough validators"
        );

        verifySignature(
            validatorSignature,
            validatorSetRoot,
            validatorAddress,
            numOfValidators,
            validatorPosition,
            validatorAddressMerkleProof,
            commitmentHash
        );

        /**
         * @todo Lock up the sender stake as collateral
         */
        // TODO

        // Accept and save the commitment
        validationData[currentId] = ValidationData(
            msg.sender,
            commitmentHash,
            block.number,
            validatorClaimsBitfield
        );

        emit InitialVerificationSuccessful(msg.sender, block.number, currentId);

        currentId = currentId + 1;
        return currentId;
    }

    /**
     * @notice Performs the second step in the validation logic
     * @param id an identifying value generated in the previous transaction
     * @param commitment contains the full commitment that was used for the commitmentHash
     * @param validatorProof a struct containing the data needed to verify all validator signatures
     * @param guardBitfield A bitfield containing a membership status of each
     * guard who has claimed to have signed the commitmentHash
     * @param guardProof A struct containing the data needed to verify the guards signatures
     */
    function completeSignatureCommitment(
        uint256 id,
        Commitment memory commitment,
        Proof memory validatorProof,
        uint256[] memory guardBitfield,
        Proof memory guardProof
    ) public {
        // only current epoch
        require(commitment.validatorSetId == validatorSetId, "Bridge: Invalid validator set id");

        verifyCommitment(id, commitment, validatorProof, guardBitfield, guardProof);

        processPayload(commitment.payload, commitment.blockNumber);

        /**
         * @dev We no longer need the data held in state, so delete it for a gas refund
         */
        delete validationData[id];

        emit FinalVerificationSuccessful(msg.sender, id);
    }

    /**
     * @notice Update guard set
     * @dev This function should call out to the guard registry contract
     * @param guardMessage Contains the full guard message that was used for the messageHash
     * @param guardProof A struct containing the data needed to verify the guards signatures
     * @param guardBitfield A bitfield containing a membership status of each
     * guard who has claimed to have signed the messageHash
     */
    function updateGuardSet(
        GuardMessage memory guardMessage,
        Proof memory guardProof,
        uint256[] memory guardBitfield
    ) public {
        require(guardMessage.network == network, "Bridge: Invalid guard message network");
        //bytes4(keccak256("updateGuardSet((bytes32,bytes4,uint32,uint32,bytes32,uint32),(bytes[],uint256[],address[],bytes32[]),uint256[])"))
        require(guardMessage.methodID == hex"1e8b8a6b", "Bridge: Invalid guard message method ID");
        require(guardMessage.nextGuardSetId == guardSetId + 1, "Bridge: Invalid next guard set id");

        uint256 requiredNumOfGuardSigs = requiredNumberOfGuardSigs();
        require(
            countSetBits(guardBitfield) >= requiredNumOfGuardSigs,
            "Bridge: Bitfield not enough guards"
        );

        bytes32 messageHash = createGuardMessageHash(guardMessage);

        verifyGuardProofSignatures(
            guardBitfield,
            guardProof,
            requiredNumOfGuardSigs,
            messageHash
        );

        _updateGuardSet(
            guardMessage.nextGuardSetId,
            guardMessage.nextGuardSetLen,
            guardMessage.nextGuardSetRoot,
            guardMessage.nextGuardSetThreshold
        );
    }

    /* Private Functions */

    function verifyCommitment(
        uint256 id,
        Commitment memory commitment,
        Proof memory validatorProof,
        uint256[] memory guardBitfield,
        Proof memory guardProof
    ) private view {
        ValidationData storage data = validationData[id];

        /**
         * @dev verify that network is the same as `network`
         */
        require(
            commitment.payload.network == network,
            "Bridge: Commitment is not part of this network"
        );

        /**
         * @dev verify that sender is the same as in `newSignatureCommitment`
         */
        require(
            msg.sender == data.senderAddress,
            "Bridge: Sender address does not match original validation data"
        );

        /**
         * @dev verify that block wait period has passed
         */
        require(
            block.number >= data.blockNumber + BLOCK_WAIT_PERIOD,
            "Bridge: Block wait period not over"
        );

        uint256 requiredNumOfValidatorSigs = requiredNumberOfValidatorSigs();

        uint256[] memory randomBitfield = randomNBitsWithPriorCheck(
            getSeed(data.blockNumber),
            data.validatorClaimsBitfield,
            requiredNumOfValidatorSigs,
            numOfValidators
        );

        // Encode and hash the commitment
        bytes32 commitmentHash = createCommitmentHash(commitment);

        require(
            commitmentHash == data.commitmentHash,
            "Bridge: Commitment must match commitment hash"
        );

        verifyValidatorProofSignatures(
            randomBitfield,
            validatorProof,
            requiredNumOfValidatorSigs,
            commitmentHash
        );

        uint256 requiredNumOfGuardSigs = requiredNumberOfGuardSigs();
        require(
            countSetBits(guardBitfield) == requiredNumOfGuardSigs,
            "Bridge: count Bitfield should equel threshold"
        );

        verifyGuardProofSignatures(
            guardBitfield,
            guardProof,
            requiredNumOfGuardSigs,
            commitmentHash
        );
    }

    function verifyValidatorProofSignatures(
        uint256[] memory randomBitfield,
        Proof memory proof,
        uint256 requiredNumOfSignatures,
        bytes32 commitmentHash
    ) private view {
        verifyProofSignatures(
            validatorSetRoot,
            numOfValidators,
            randomBitfield,
            proof,
            requiredNumOfSignatures,
            commitmentHash
        );
    }

    function verifyGuardProofSignatures(
        uint256[] memory guardBitfield,
        Proof memory proof,
        uint256 requiredNumOfSignatures,
        bytes32 hash
    ) private view {
        verifyProofSignatures(
            guardSetRoot,
            numOfGuards,
            guardBitfield,
            proof,
            requiredNumOfSignatures,
            hash 
        );
    }

    function verifyProofSignatures(
        bytes32 root,
        uint256 width,
        uint256[] memory bitfield,
        Proof memory proof,
        uint256 requiredNumOfSignatures,
        bytes32 commitmentHash
    ) private pure {

        verifyProofLengths(requiredNumOfSignatures, proof);

        /**
         *  @dev For each randomSignature, do:
         */
        for (uint256 i = 0; i < requiredNumOfSignatures; i++) {
            uint256 pos = proof.positions[i];
            /**
             * @dev Check if validator in bitfield
             */
            require(
                isSet(bitfield, pos),
                "Bridge: signer must be once in bitfield"
            );

            /**
             * @dev Remove validator from bitfield such that no validator can appear twice in signatures
             */
            clear(bitfield, pos);

            verifySignature(
                proof.signatures[i],
                root,
                proof.signers[i],
                width,
                pos,
                proof.signerProofs[i],
                commitmentHash
            );
        }
    }

    function verifyProofLengths(
        uint256 requiredNumOfSignatures,
        Proof memory proof
    ) private pure {
        /**
         * @dev verify that required number of signatures, positions, public keys and merkle proofs are
         * submitted
         */
        require(
            proof.signatures.length == requiredNumOfSignatures,
            "Bridge: Number of signatures does not match required"
        );
        require(
            proof.positions.length == requiredNumOfSignatures,
            "Bridge: Number of validator positions does not match required"
        );
        require(
            proof.signers.length == requiredNumOfSignatures,
            "Bridge: Number of validator public keys does not match required"
        );
        require(
            proof.signerProofs.length == requiredNumOfSignatures,
            "Bridge: Number of validator public keys does not match required"
        );
    }

    function verifySignature(
        bytes memory signature,
        bytes32 root,
        address signer,
        uint256 width,
        uint256 position,
        bytes32[] memory addrMerkleProof,
        bytes32 commitmentHash
    ) private pure {

        /**
         * @dev Check if merkle proof is valid
         */
        require(
            checkAddrInSet(
                root,
                signer,
                width,
                position,
                addrMerkleProof
            ),
            "Bridge: signer must be in signer set at correct position"
        );

        /**
         * @dev Check if signature is correct
         */
        require(
            ECDSA.recover(commitmentHash, signature) == signer,
            "Bridge: Invalid Signature"
        );
    }

    /**
     * @notice Checks if an address is a member of the merkle tree
     * @param root the root of the merkle tree
     * @param addr The address to check
     * @param pos The position to check, index starting at 0
     * @param width the width or number of leaves in the tree
     * @param proof Merkle proof required for validation of the address
     * @return Returns true if the address is in the set
     */
    function checkAddrInSet(
        bytes32 root,
        address addr,
        uint256 width,
        uint256 pos,
        bytes32[] memory proof
    ) public pure returns (bool) {
        bytes32 hashedLeaf = keccak256(abi.encodePacked(addr));
        return
            MerkleProof.verifyMerkleLeafAtPosition(
                root,
                hashedLeaf,
                pos,
                width,
                proof
            );
    }

    /**
     * @notice Deterministically generates a seed from the block hash at the block number of creation of the validation
     * @dev Note that `blockhash(blockNum)` will only work for the 256 most recent blocks. If
     * `completeSignatureCommitment` is called too late, a new call to `newSignatureCommitment` is necessary to reset
     * validation data's block number
     * @param blockNumber block number
     * @return onChainRandNums an array storing the random numbers generated inside this function
     */
    function getSeed(uint256 blockNumber)
        private
        view
        returns (uint256)
    {
        uint256 randomSeedBlockNum = blockNumber + BLOCK_WAIT_PERIOD;
        // @note Create a hash seed from the block number
        bytes32 randomSeedBlockHash = blockhash(randomSeedBlockNum);

        return uint256(randomSeedBlockHash);
    }

    /**
     * @notice Perform some operation[s] using the payload
     * @param payload The payload variable passed in via the initial function
     * @param blockNumber The blockNumber variable passed in via the initial function
     */
    function processPayload(Payload memory payload, uint256 blockNumber) private {
        // Check the payload is newer than the latest
        // Check that payload.leaf.block_number is > last_known_block_number;
        require(blockNumber > latestBlockNumber, "Bridge: Import old block");

        latestMMRRoot = payload.mmr;
        latestBlockNumber = blockNumber;

        applyValidatorSetChanges(
            payload.nextValidatorSet.id,
            payload.nextValidatorSet.len,
            payload.nextValidatorSet.root
        );
        emit NewMMRRoot(latestMMRRoot, blockNumber);
    }

    /**
     * @notice Check if the payload includes a new validator set,
     * and if it does then update the new validator set
     * @dev This function should call out to the validator registry contract
     * @param nextValidatorSetId The id of the next validator set
     * @param nextValidatorSetLen The number of validators in the next validator set
     * @param nextValidatorSetRoot The merkle root of the merkle tree of the next validators
     */
    function applyValidatorSetChanges(
        uint64 nextValidatorSetId,
        uint32 nextValidatorSetLen,
        bytes32 nextValidatorSetRoot
    ) private {
        // TODO: check nextValidatorSet can null or not
        require(nextValidatorSetId == 0 || nextValidatorSetId == validatorSetId + 1, "Bridge: Invalid next validator set id");
        if (nextValidatorSetId == validatorSetId + 1) {
            _updateValidatorSet(
                nextValidatorSetId,
                nextValidatorSetLen,
                nextValidatorSetRoot
            );
        }
    }

}
