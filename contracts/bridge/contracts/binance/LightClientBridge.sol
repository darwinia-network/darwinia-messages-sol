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

    event CleanExpiredCommitment(uint256 id);

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
     *  our case, this is a next validator set and a new MMR root for all past darwinia blocks)
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
        address payable senderAddress;
        bytes32 commitmentHash;
        uint256 blockNumber;
        uint256[] validatorClaimsBitfield;
    }

    /* State */

    uint256 public currentId;
    bytes32 public latestMMRRoot;
    uint256 public latestBlockNumber;
    mapping(uint256 => ValidationData) public validationData;

    /* Constants */

    /**
     * Hash of the NextValidatorSet Schema
     * keccak256("NextValidatorSet(uint64 id,uint32 len,bytes32 root)")
     */
    bytes32 internal constant NEXTVALIDATORSET_TYPEHASH = 0x599882aa3cf9166c2c8867b0e7c41899bd7c26ee7898f261a5f495738da7dbd0;

    /**
     * Hash of the Payload Schema
     * keccak256(abi.encodePacked(
     *     "Payload(bytes32 network,bytes32 mmr,NextValidatorSet nextValidatorSet)",
     *     "NextValidatorSet(uint64 id,uint32 len,bytes32 root)",
     *     ")"
     * )
     */
    bytes32 internal constant PAYLOAD_TYPEHASH = 0xe22bd99038907f2b6f08088cca39bfd3caba1b02d6adbf9e47869eb2ea61eba3;

    /**
     * Hash of the Commitment Schema
     * keccak256(abi.encodePacked(
     *     "Commitment(Payload payload,uint32 blockNumber,uint64 validatorSetId)",
     *     "Payload(bytes32 network,bytes32 mmr,NextValidatorSet nextValidatorSet)",
     *     "NextValidatorSet(uint64 id,uint32 len,bytes32 root)",
     *     ")"
     * )
     */
    bytes32 internal constant COMMITMENT_TYPEHASH = 0xfb7618382249e6518a69252ccf86f0a991565f2a2cd2d7af9c6b59cb805b9f0b;

    /**
     * @dev Block wait period after `newSignatureCommitment` to pick the random block hash
    */
    uint256 public constant BLOCK_WAIT_PERIOD = 12;

    /**
     * @dev Block wait period after `newSignatureCommitment` to pick the random block hash
     *  120000000/2^25 = 3.57 ether is recommended for Ethereum
    */
    uint256 public constant MIN_SUPPORT = 4 ether;

    /**
     * @dev A vault to store expired commitment or malicious commitment slashed asset
     */
    address payable public immutable SLASH_VAULT;

    /**
     * @notice Deploys the LightClientBridge contract
     * @param network source chain network name
     * @param slashVault initial SLASH_VAULT
     * @param guards initial guards of guard set
     * @param threshold initial threshold of guard set
     * @param validatorSetId initial validator set id
     * @param validatorSetLen length of initial validator set
     * @param validatorSetRoot initial validator set merkle tree root
    */
    constructor(
        bytes32 network,
        address payable slashVault,
        address[] memory guards,
        uint256 threshold,
        uint256 validatorSetId,
        uint256 validatorSetLen,
        bytes32 validatorSetRoot
    ) public GuardRegistry(network, guards, threshold) {
        SLASH_VAULT = slashVault;
        _updateValidatorSet(validatorSetId, validatorSetLen, validatorSetRoot);
    }

    /* Public Functions */

    function getFinalizedBlockNumber() external view returns (uint256) {
        return latestBlockNumber;
    }

    function validatorBitfield(uint256 id) external view returns (uint256[] memory) {
        return validationData[id].validatorClaimsBitfield; 
    }

    function requiredNumberOfValidatorSigs() public view returns (uint256) {
        if (validatorSetLen < 36) {
            return validatorSetLen * 2 / 3 + 1;
        }
        return 25;
    }

    function createRandomBitfield(uint256 id)
        public
        view
        returns (uint256[] memory)
    {
        ValidationData storage data = validationData[id];
        return _createRandomBitfield(data);
    }

    function _createRandomBitfield(ValidationData storage data)
        internal
        view
        returns (uint256[] memory)
    {
        require(data.blockNumber > 0, "Bridge: invalid id");
        return
            randomNBitsWithPriorCheck(
                getSeed(data.blockNumber),
                data.validatorClaimsBitfield,
                requiredNumberOfValidatorSigs(),
                validatorSetLen
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
         * Encode and hash the Commitment
         */
        return keccak256(
            abi.encode(
                COMMITMENT_TYPEHASH,
                hash(commitment.payload),
                commitment.blockNumber,
                commitment.validatorSetId
            )
        );
    }

    function hash(Payload memory payload)
        internal
        pure
        returns (bytes32)
    {
        /**
         * Encode and hash the Payload
         */
        return keccak256(
            abi.encode(
                PAYLOAD_TYPEHASH,
                payload.network,
                payload.mmr,
                hash(payload.nextValidatorSet)
            )
        );
    }

    function hash(NextValidatorSet memory nextValidatorSet)
        internal
        pure
        returns (bytes32)
    {
        /**
         * Encode and hash the NextValidatorSet
         */
        return keccak256(
            abi.encode(
                NEXTVALIDATORSET_TYPEHASH,
                nextValidatorSet.id,
                nextValidatorSet.len,
                nextValidatorSet.root
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
    ) public payable returns (uint256) {
        /**
         * @dev Check that the bitfield actually contains enough claims to be succesful, ie, > 2/3
         */
        require(
            countSetBits(validatorClaimsBitfield) > (validatorSetLen * 2) / 3,
            "Bridge: Bitfield not enough validators"
        );

        verifySignature(
            validatorSignature,
            validatorSetRoot,
            validatorAddress,
            validatorSetLen,
            validatorPosition,
            validatorAddressMerkleProof,
            commitmentHash
        );

        /**
         * @notice Lock up the sender stake as collateral
         */
        require(msg.value == MIN_SUPPORT, "Bridge: Collateral mismatch");

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
     * @param guardSignatures The signatures of the guards which to double-check the commitmentHash
     */
    function completeSignatureCommitment(
        uint256 id,
        Commitment memory commitment,
        Proof memory validatorProof,
        bytes[] memory guardSignatures
    ) public {
        // only current epoch
        require(commitment.validatorSetId == validatorSetId, "Bridge: Invalid validator set id");

        verifyCommitment(id, commitment, validatorProof, guardSignatures);

        processPayload(commitment.payload, commitment.blockNumber);

        /**
         * @dev We no longer need the data held in state, so delete it for a gas refund
         */
        delete validationData[id];

        /**
         * @notice If relayer do `completeSignatureCommitment` late or failed, `MIN_SUPPORT` will be slashed
         */
        msg.sender.transfer(MIN_SUPPORT);

        emit FinalVerificationSuccessful(msg.sender, id);
    }

    /**
     * @notice Clean up the expired commitment and slash
     * @param id the identifier generated by submit commitment
     */
    function cleanExpiredCommitment(uint256 id) public {
        ValidationData storage data = validationData[id];
        require(block.number > data.blockNumber + 256, "Bridge: Only expired");
        SLASH_VAULT.transfer(MIN_SUPPORT);
        delete validationData[id];
        emit CleanExpiredCommitment(id);
    }

    /* Private Functions */

    function verifyCommitment(
        uint256 id,
        Commitment memory commitment,
        Proof memory validatorProof,
        bytes[] memory guardSignatures
    ) private view {
        ValidationData storage data = validationData[id];

        /**
         * @dev verify that network is the same as `network`
         */
        require(
            commitment.payload.network == NETWORK,
            "Bridge: Commitment is not part of this network"
        );

        /**
         * @dev verify that sender is the same as in `newSignatureCommitment`
         */
        require(
            msg.sender == data.senderAddress,
            "Bridge: Sender address does not match original validation data"
        );

        uint256[] memory randomBitfield = _createRandomBitfield(data);

        // Encode and hash the commitment
        bytes32 commitmentHash = createCommitmentHash(commitment);

        require(
            commitmentHash == data.commitmentHash,
            "Bridge: Commitment must match commitment hash"
        );

        verifyValidatorProofSignatures(
            randomBitfield,
            validatorProof,
            requiredNumberOfValidatorSigs(),
            commitmentHash
        );

        // Guard Registry double-check the commitmentHash
        checkGuardSignatures(commitmentHash, guardSignatures);
    }

    function verifyValidatorProofSignatures(
        uint256[] memory randomBitfield,
        Proof memory proof,
        uint256 requiredNumOfSignatures,
        bytes32 commitmentHash
    ) private view {
        verifyProofSignatures(
            validatorSetRoot,
            validatorSetLen,
            randomBitfield,
            proof,
            requiredNumOfSignatures,
            commitmentHash
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
        /**
         * @dev verify that block wait period has passed
         */
        require(
            block.number > blockNumber + BLOCK_WAIT_PERIOD,
            "Bridge: Block wait period not over"
        );

        require(
            block.number <= blockNumber + BLOCK_WAIT_PERIOD + 256,
            "Bridge: Block number has expired"
        );

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
