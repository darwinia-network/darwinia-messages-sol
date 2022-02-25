// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./BEEFYAuthorityRegistry.sol";
import "../../utils/ECDSA.sol";
import "../../utils/Bitfield.sol";
import "../../utils/MerkleProof.sol";
import "../../utils/SparseMerkleMultiProof.sol";
import "../../spec/BEEFYCommitmentScheme.sol";
import "../../../interfaces/ILightClient.sol";

/**
 * @title A entry contract for the Ethereum-like light client
 * @author echo
 * @notice The light client is the trust layer of the bridge
 * @dev See https://hackmd.kahub.in/Nx9YEaOaTRCswQjVbn4WsQ?view
 */
contract DarwiniaLightClient is ILightClient, Bitfield, BEEFYCommitmentScheme, BEEFYAuthorityRegistry {

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
        uint256 id,
        bool isNew
    );

    event CleanExpiredCommitment(uint256 id);

    event NewMMRRoot(bytes32 mmrRoot, uint256 blockNumber);

    event NewMessageRoot(bytes32 messageRoot, uint256 blockNumber);

    /* Types */

    /**
     * The Proof is a collection of proofs used to verify the signatures from the signers signing
     * each new justification.
     * @param signatures an array of signatures from the chosen signers
     * @param positions an array of the positions of the chosen signers
     * @param decommitments multi merkle proof from the chosen validators proving that their addresses
     * are in the validator set
     */
    struct MultiProof {
        uint256 depth;
        bytes[] signatures;
        uint256[] positions;
        bytes32[] decommitments;
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

    struct MessagesProof {
        MProof chainProof;
        MProof laneProof;
    }

    struct MProof {
        bytes32 root;
        uint256 count;
        bytes32[] proof;
    }

    /* State */

    uint256 public currentId;
    bytes32 public latestMMRRoot;
    bytes32 public latestChainMessagesRoot;
    uint256 public latestBlockNumber;
    mapping(uint256 => ValidationData) public validationData;

    /* Constants */

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
    address public immutable SLASH_VAULT;

    /**
     * @dev NETWORK Source chain network identify ('Crab', 'Darwinia', 'Pangolin')
     */
    bytes32 public immutable NETWORK;

    /**
     * @notice Deploys the LightClientBridge contract
     * @param network source chain network name
     * @param slashVault initial SLASH_VAULT
    */
    constructor(
        bytes32 network,
        address slashVault,
        uint64 currentAuthoritySetId,
        uint32 currentAuthoritySetLen,
        bytes32 currentAuthoritySetRoot,
        uint64 nextAuthoritySetId,
        uint32 nextAuthoritySetLen,
        bytes32 nextAuthoritySetRoot
    ) {
        SLASH_VAULT = slashVault;
        NETWORK = network;
        _updateCurrentAuthoritySet(AuthoritySet(currentAuthoritySetId, currentAuthoritySetLen, currentAuthoritySetRoot));
        _updateNextAuthoritySet(AuthoritySet(nextAuthoritySetId, nextAuthoritySetLen, nextAuthoritySetRoot));
    }

    /* Public Functions */

    function getFinalizedChainMessagesRoot() external view returns (bytes32) {
        return latestChainMessagesRoot;
    }

    function getFinalizedBlockNumber() external view returns (uint256) {
        return latestBlockNumber;
    }

    function validatorBitfield(uint256 id) external view returns (uint256[] memory) {
        return validationData[id].validatorClaimsBitfield;
    }

    function threshold(uint256 len) public pure returns (uint256) {
        if (len <= 36) {
            return len - len / 3;
        }
        return 25;
    }

    function createRandomBitfield(uint256 id, uint256 len)
        public
        view
        returns (uint256[] memory)
    {
        ValidationData storage data = validationData[id];
        return _createRandomBitfield(data, len);
    }

    function _createRandomBitfield(ValidationData storage data, uint256 authoritySetLen)
        internal
        view
        returns (uint256[] memory)
    {
        require(data.blockNumber > 0, "Bridge: invalid id");
        return
            randomNBitsWithPriorCheck(
                getSeed(data.blockNumber),
                data.validatorClaimsBitfield,
                threshold(authoritySetLen),
                authoritySetLen
            );
    }

    function createInitialBitfield(uint256[] calldata bitsToSet, uint256 length)
        external
        pure
        returns (uint256[] memory)
    {
        return createBitfield(bitsToSet, length);
    }

    function verify_messages_proof(
        bytes32 outlane_data_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external override view returns (bool) {
        return validate_lane_data_match_root(outlane_data_hash, chain_pos, lane_pos, encoded_proof);
    }

    function verify_messages_delivery_proof(
        bytes32 inlane_data_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external override view returns (bool) {
        return validate_lane_data_match_root(inlane_data_hash, chain_pos, lane_pos, encoded_proof);
    }

    function validate_lane_data_match_root(
        bytes32 lane_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes memory proof
    ) internal view returns (bool) {
        MessagesProof memory messages_proof = abi.decode(proof, (MessagesProof));
        // Validate that the commitment matches the commitment contents
        require(messages_proof.chainProof.root == latestChainMessagesRoot, "Lane: invalid ChainMessagesRoot");
        return validateLaneDataMatchRoot(
                lane_hash,
                chain_pos,
                lane_pos,
                messages_proof.chainProof,
                messages_proof.laneProof
            );
    }

    function validateLaneDataMatchRoot(
        bytes32 laneHash,
        uint256 chainPosition,
        uint256 lanePosition,
        MProof memory chainProof,
        MProof memory laneProof
    ) internal pure returns (bool) {
        return
            MerkleProof.verifyMerkleLeafAtPosition(
                laneProof.root,
                laneHash,
                lanePosition,
                laneProof.count,
                laneProof.proof
            )
            &&
            MerkleProof.verifyMerkleLeafAtPosition(
                chainProof.root,
                laneProof.root,
                chainPosition,
                chainProof.count,
                chainProof.proof
            );
    }

    /**
     * @notice Executed by the prover in order to begin the process of block
     * acceptance by the light client
     * @param commitment contains the full commitment
     * @param validatorClaimsBitfield a bitfield containing a membership status of each
     * validator who has claimed to have signed the commitmentHash
     * @param validatorSignature the signature of one validator
     * @param validatorPosition the position of the validator, index starting at 0
     * @param validatorAddress the public key of the validator
     * @param validatorAddressMerkleProof proof required for validation of the public key in the validator merkle tree
     */
    function newSignatureCommitment(
        Commitment memory commitment,
        uint256[] memory validatorClaimsBitfield,
        bytes memory validatorSignature,
        uint256 validatorPosition,
        address validatorAddress,
        bytes32[] memory validatorAddressMerkleProof
    ) public payable returns (uint256) {
        bytes32 commitmentHash = hash(commitment);
        require(commitment.validatorSetId + 1 == commitment.payload.nextValidatorSet.id, "Bridge: Invalid AuthoritySetId");
        AuthoritySet memory set = signedCommitmentAuthoritySet(commitment.validatorSetId);
        /**
         * @dev Check that the bitfield actually contains enough claims to be succesful, ie, >= 2/3
         */
        require(
            countSetBits(validatorClaimsBitfield) >= threshold(set.len),
            "Bridge: Bitfield not enough validators"
        );

        verifySignature(
            validatorSignature,
            set.root,
            validatorAddress,
            set.len,
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

    function signedCommitmentAuthoritySet(uint64 currentAuthoritySetId) internal view returns (AuthoritySet memory set) {
        require(currentAuthoritySetId == current.id || currentAuthoritySetId == next.id, "Bridge: Invalid CurrentAuthoritySetId");
        if (currentAuthoritySetId == current.id) {
            set = current;
        } else if (currentAuthoritySetId == next.id) {
            set = next;
        }
    }

    /**
     * @notice Performs the second step in the validation logic
     * @param id an identifying value generated in the previous transaction
     * @param commitment contains the full commitment that was used for the commitmentHash
     * @param validatorProof a struct containing the data needed to verify all validator signatures
     */
    function completeSignatureCommitment(
        uint256 id,
        Commitment memory commitment,
        MultiProof memory validatorProof
    ) public {
        require(commitment.validatorSetId + 1 == commitment.payload.nextValidatorSet.id, "Bridge: Invalid AuthoritySetId");
        AuthoritySet memory set = signedCommitmentAuthoritySet(commitment.validatorSetId);

        verifyCommitment(id, commitment, validatorProof, set);

        bool isNew = processPayload(commitment.payload, commitment.blockNumber, set);

        /**
         * @dev We no longer need the data held in state, so delete it for a gas refund
         */
        delete validationData[id];

        /**
         * @notice If relayer do `completeSignatureCommitment` late or failed, `MIN_SUPPORT` will be slashed
         */
        payable(msg.sender).transfer(MIN_SUPPORT);

        emit FinalVerificationSuccessful(msg.sender, id, isNew);
    }

    /**
     * @notice Clean up the expired commitment and slash
     * @param id the identifier generated by submit commitment
     */
    function cleanExpiredCommitment(uint256 id) public {
        ValidationData storage data = validationData[id];
        require(block.number > data.blockNumber + BLOCK_WAIT_PERIOD + 256, "Bridge: Only expired");
        payable(SLASH_VAULT).transfer(MIN_SUPPORT);
        delete validationData[id];
        emit CleanExpiredCommitment(id);
    }

    /* Private Functions */

    function verifyCommitment(
        uint256 id,
        Commitment memory commitment,
        MultiProof memory validatorProof,
        AuthoritySet memory set
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

        uint256[] memory randomBitfield = _createRandomBitfield(data, set.len);

        // Encode and hash the commitment
        bytes32 commitmentHash = hash(commitment);

        require(
            commitmentHash == data.commitmentHash,
            "Bridge: Commitment must match commitment hash"
        );

        verifyValidatorProofSignatures(
            randomBitfield,
            validatorProof,
            threshold(set.len),
            commitmentHash,
            set
        );
    }

    function roundUpToPow2(uint256 len) internal pure returns (uint256) {
        if (len <= 1) return 1;
        else return 2 * roundUpToPow2((len + 1) / 2);
    }

    function verifyValidatorProofSignatures(
        uint256[] memory randomBitfield,
        MultiProof memory proof,
        uint256 requiredNumOfSignatures,
        bytes32 commitmentHash,
        AuthoritySet memory set
    ) private pure {
        verifyProofSignatures(
            set.root,
            set.len,
            randomBitfield,
            proof,
            requiredNumOfSignatures,
            commitmentHash
        );
    }

    function verifyProofSignatures(
        bytes32 root,
        uint256 len,
        uint256[] memory bitfield,
        MultiProof memory proof,
        uint256 requiredNumOfSignatures,
        bytes32 commitmentHash
    ) private pure {

        verifyMultiProofLengths(requiredNumOfSignatures, proof);

        uint256 width = roundUpToPow2(len);
        /**
         *  @dev For each randomSignature, do:
         */
        bytes32[] memory leaves = new bytes32[](requiredNumOfSignatures);
        for (uint256 i = 0; i < requiredNumOfSignatures; i++) {
            uint256 pos = proof.positions[i];

            require(pos < len, "Bridge: invalid signer position");
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

            address signer = ECDSA.recover(commitmentHash, proof.signatures[i]);
            leaves[i] = keccak256(abi.encodePacked(signer));
        }

        require(1 << proof.depth == width, "Bridge: invalid depth");
        require(
            SparseMerkleMultiProof.verify(
                root,
                proof.depth,
                proof.positions,
                leaves,
                proof.decommitments
            ),
            "Bridge: invalid multi proof"
        );
    }

    function verifyMultiProofLengths(
        uint256 requiredNumOfSignatures,
        MultiProof memory proof
    ) private pure {
        require(
            proof.signatures.length == requiredNumOfSignatures,
            "Bridge: Number of signatures does not match required"
        );
        require(
            proof.positions.length == requiredNumOfSignatures,
            "Bridge: Number of validator positions does not match required"
        );
    }

    function verifySignature(
        bytes memory signature,
        bytes32 root,
        address signer,
        uint256 len,
        uint256 position,
        bytes32[] memory addrMerkleProof,
        bytes32 commitmentHash
    ) private pure {
        require(position < len, "Bridge: invalid signer position");
        uint256 width = roundUpToPow2(len);

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
    function processPayload(Payload memory payload, uint256 blockNumber, AuthoritySet memory set) private returns (bool) {
        if (blockNumber > latestBlockNumber) {
            latestMMRRoot = payload.mmr;
            latestChainMessagesRoot = payload.messageRoot;
            latestBlockNumber = blockNumber;

            applyAuthoritySetChanges(set);
            emit NewMMRRoot(latestMMRRoot, blockNumber);
            emit NewMessageRoot(latestChainMessagesRoot, blockNumber);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Check if the payload includes a new validator set,
     * and if it does then update the new validator set
     * @param set The next validator set
     */
    function applyAuthoritySetChanges(AuthoritySet memory set) private {
        if (set.id == next.id) {
            _updateCurrentAuthoritySet(next);
            _updateNextAuthoritySet(set);
        }
    }

}
