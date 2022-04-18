// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../utils/ECDSA.sol";
import "../../utils/Bitfield.sol";
import "../../utils/SparseMerkleProof.sol";
import "../../spec/BEEFYCommitmentScheme.sol";
import "../../interfaces/ILightClient.sol";

/**
 * @title A entry contract for the Ethereum-like light client
 * @author echo
 * @notice The light client is the trust layer of the bridge
 * @dev See https://hackmd.kahub.in/Nx9YEaOaTRCswQjVbn4WsQ?view
 */
contract DarwiniaLightClient is ILightClient, Bitfield, BEEFYCommitmentScheme {

    /* Events */

    event BEEFYAuthoritySetUpdated(uint64 id, uint32 len, bytes32 root);

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

    event NewMessageRoot(bytes32 messageRoot, uint32 blockNumber);

    /* Types */

    struct Signature {
        bytes32 r;
        bytes32 vs;
    }

    /**
     * The Proof is a collection of proofs used to verify the signatures from the signers signing
     * each new justification.
     * @param signatures an array of signatures from the chosen signers
     * @param positions an array of the positions of the chosen signers
     * @param decommitments multi merkle proof from the chosen validators proving that their addresses
     * are in the validator set
     */
    struct CommitmentMultiProof {
        uint256 depth;
        bytes32 positions;
        bytes32[] decommitments;
        Signature[] signatures;
    }


    /*
     * @param signature the signature of one validator
     * @param position the position of the validator, index starting at 0
     * @param signer the public key of the validator
     * @param proof proof required for validation of the public key in the validator merkle tree
     */
    struct CommitmentSingleProof {
        uint256 position;
        address signer;
        bytes32[] proof;
        Signature signature;
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
        uint32 blockNumber;
        bytes32 commitmentHash;
        uint256 validatorClaimsBitfield;
    }

    struct MessagesProof {
        MessageSingleProof chainProof;
        MessageSingleProof laneProof;
    }

    struct MessageSingleProof {
        bytes32 root;
        bytes32[] proof;
    }

    /* State */

    struct Slot0 {
        uint64 authoritySetId;
        uint32 authoritySetLen;

        uint32 currentId;
        uint32 latestBlockNumber;
    }

    Slot0 public slot0;
    bytes32 public authoritySetRoot;
    bytes32 public latestChainMessagesRoot;
    mapping(uint32 => ValidationData) public validationData;

    /* Constants */
    uint256 public constant MAX_COUNT = 2**32 - 1;

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
     * @param currentAuthoritySetId The id of the current authority set
     * @param currentAuthoritySetLen The length of the current authority set
     * @param currentAuthoritySetRoot The merkle tree of the current authority set
    */
    constructor(
        bytes32 network,
        address slashVault,
        uint64 currentAuthoritySetId,
        uint32 currentAuthoritySetLen,
        bytes32 currentAuthoritySetRoot
    ) {
        NETWORK = network;
        SLASH_VAULT = slashVault;
        _updateAuthoritySet(currentAuthoritySetId, currentAuthoritySetLen, currentAuthoritySetRoot);
    }

    /* Public Functions */

    function getFinalizedChainMessagesRoot() external view returns (bytes32) {
        return latestChainMessagesRoot;
    }

    function getFinalizedBlockNumber() external view returns (uint256) {
        return slot0.latestBlockNumber;
    }

    function getCurrentId() external view returns (uint32) {
        return slot0.currentId;
    }

    function validatorBitfield(uint32 id) external view returns (uint256) {
        return validationData[id].validatorClaimsBitfield;
    }

    function threshold(uint32 len) public pure returns (uint256) {
        if (len <= 36) {
            return len - (len - 1) / 3;
        }
        return 25;
    }

    function createRandomBitfield(uint32 id)
        public
        view
        returns (uint256)
    {
        ValidationData memory data = validationData[id];
        uint32 len = slot0.authoritySetLen;
        return _createRandomBitfield(data.blockNumber, data.validatorClaimsBitfield, len);
    }

    function _createRandomBitfield(uint32 blockNumber, uint256 validatorClaimsBitfield, uint32 len)
        internal
        view
        returns (uint256)
    {
        return
            randomNBitsWithPriorCheck(
                // 97305812270498948356234269717382139654668916059389619269317605274241040845814,
                getSeed(blockNumber),
                validatorClaimsBitfield,
                threshold(len),
                len
            );
    }

    function createInitialBitfield(uint8[] calldata bitsToSet)
        external
        pure
        returns (uint256)
    {
        return createBitfield(bitsToSet);
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
        bytes calldata proof
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
        MessageSingleProof memory chainProof,
        MessageSingleProof memory laneProof
    ) internal pure returns (bool) {
        return
            SparseMerkleProof.singleVerify(
                laneProof.root,
                laneHash,
                lanePosition,
                laneProof.proof
            )
            &&
            SparseMerkleProof.singleVerify(
                chainProof.root,
                laneProof.root,
                chainPosition,
                chainProof.proof
            );
    }

    /**
     * @notice Executed by the prover in order to begin the process of block
     * acceptance by the light client
     * @param commitmentHash contains the commitmentHash signed by the current authority set
     * @param validatorClaimsBitfield a bitfield containing a membership status of each
     * validator who has claimed to have signed the commitmentHash
     */
    function newSignatureCommitment(
        bytes32 commitmentHash,
        uint256 validatorClaimsBitfield,
        CommitmentSingleProof calldata commitmentSingleProof
    ) external payable returns (uint32) {
        uint32 len = slot0.authoritySetLen;
        /**
         * @dev Check that the bitfield actually contains enough claims to be succesful, ie, >= 2/3 + 1
         */
        require(
            countSetBits(validatorClaimsBitfield) >= len - (len - 1) / 3,
            "Bridge: Bitfield not enough validators"
        );

        verifySignature(
            commitmentSingleProof.signature,
            authoritySetRoot,
            commitmentSingleProof.signer,
            len,
            commitmentSingleProof.position,
            commitmentSingleProof.proof,
            commitmentHash
        );

        /**
         * @notice Lock up the sender stake as collateral
         */
        require(msg.value == MIN_SUPPORT, "Bridge: Collateral mismatch");

        // Accept and save the commitment
        uint32 _currentId = slot0.currentId;
        require(_currentId < MAX_COUNT, "Bridge: Full");
        validationData[_currentId] = ValidationData(
            msg.sender,
            uint32(block.number),
            commitmentHash,
            validatorClaimsBitfield
        );

        emit InitialVerificationSuccessful(msg.sender, block.number, _currentId);

        slot0.currentId = _currentId + 1;
        return _currentId;
    }

    /**
     * @notice Performs the second step in the validation logic
     * @param id an identifying value generated in the previous transaction
     * @param commitment contains the full commitment that was used for the commitmentHash
     * @param validatorProof a struct containing the data needed to verify all validator signatures
     */
    function completeSignatureCommitment(
        uint32 id,
        Commitment calldata commitment,
        CommitmentMultiProof calldata validatorProof
    ) external payable {
        verifyCommitment(id, commitment, validatorProof);

        bool isNew = processPayload(commitment.payload, commitment.blockNumber);

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
    function cleanExpiredCommitment(uint32 id) external {
        ValidationData storage data = validationData[id];
        require(data.senderAddress != address(0), "Bridge: Empty");
        require(block.number > data.blockNumber + BLOCK_WAIT_PERIOD + 256, "Bridge: Only expired");
        payable(SLASH_VAULT).transfer(MIN_SUPPORT);
        delete validationData[id];
        emit CleanExpiredCommitment(id);
    }

    /* Private Functions */

    function verifyCommitment(
        uint32 id,
        Commitment calldata commitment,
        CommitmentMultiProof calldata validatorProof
    ) private view {
        ValidationData memory data = validationData[id];

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

        uint32 len = slot0.authoritySetLen;
        uint256 randomBitfield = _createRandomBitfield(data.blockNumber, data.validatorClaimsBitfield, len);

        // Encode and hash the commitment
        bytes32 commitmentHash = hash(commitment);

        require(
            commitmentHash == data.commitmentHash,
            "Bridge: Commitment must match commitment hash"
        );

        verifyValidatorProofSignatures(
            randomBitfield,
            validatorProof,
            commitmentHash,
            len
        );
    }

     function get_power_of_two_ceil(uint256 x) internal pure returns (uint256) {
         if (x <= 1) return 1;
         else if (x == 2) return 2;
         else return 2 * get_power_of_two_ceil((x + 1) >> 1);
     }

    function verifyValidatorProofSignatures(
        uint256 randomBitfield,
        CommitmentMultiProof calldata proof,
        bytes32 commitmentHash,
        uint32 len
    ) private view {
        verifyProofSignatures(
            authoritySetRoot,
            len,
            randomBitfield,
            proof,
            threshold(len),
            commitmentHash
        );
    }

    function verifyProofSignatures(
        bytes32 root,
        uint256 len,
        uint256 bitfield,
        CommitmentMultiProof calldata proof,
        uint256 requiredNumOfSignatures,
        bytes32 commitmentHash
    ) private pure {

        require(
            proof.signatures.length == requiredNumOfSignatures,
            "Bridge: Number of signatures does not match required"
        );

        uint256 width = get_power_of_two_ceil(len);
        /**
         *  @dev For each randomSignature, do:
         */
        bytes32[] memory leaves = new bytes32[](requiredNumOfSignatures);
        for (uint256 i = 0; i < requiredNumOfSignatures; ++i) {
            uint8 pos = uint8(proof.positions[i]);

            require(pos < len, "Bridge: invalid signer position");
            /**
             * @dev Check if validator in bitfield
             */
            require(
                (bitfield >> pos) & 1 == 1,
                "Bridge: signer must be once in bitfield"
            );

            /**
             * @dev Remove validator from bitfield such that no validator can appear twice in signatures
             */
            bitfield = clear(bitfield, pos);

            address signer = ECDSA.recover(commitmentHash, proof.signatures[i].r, proof.signatures[i].vs);
            leaves[i] = keccak256(abi.encodePacked(signer));
        }

        require((1 << proof.depth) == width, "Bridge: invalid depth");
        require(
            SparseMerkleProof.multiVerify(
                root,
                proof.depth,
                proof.positions,
                leaves,
                proof.decommitments
            ),
            "Bridge: invalid multi proof"
        );
    }

    function verifySignature(
        Signature calldata signature,
        bytes32 root,
        address signer,
        uint256 len,
        uint256 position,
        bytes32[] calldata proof,
        bytes32 commitmentHash
    ) private pure {
        require(position < len, "Bridge: invalid signer position");

        /**
         * @dev Check if merkle proof is valid
         */
        require(
            checkAddrInSet(
                root,
                signer,
                position,
                proof
            ),
            "Bridge: signer must be in signer set at correct position"
        );

        /**
         * @dev Check if signature is correct
         */
        require(
            ECDSA.recover(commitmentHash, signature.r, signature.vs) == signer,
            "Bridge: Invalid Signature"
        );
    }

    /**
     * @notice Checks if an address is a member of the merkle tree
     * @param root the root of the merkle tree
     * @param addr The address to check
     * @param pos The position to check, index starting at 0
     * @param proof Merkle proof required for validation of the address
     * @return Returns true if the address is in the set
     */
    function checkAddrInSet(
        bytes32 root,
        address addr,
        uint256 pos,
        bytes32[] calldata proof
    ) public pure returns (bool) {
        bytes32 hashedLeaf = keccak256(abi.encodePacked(addr));
        return
            SparseMerkleProof.singleVerify(
                root,
                hashedLeaf,
                pos,
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
            block.number < blockNumber + BLOCK_WAIT_PERIOD + 257,
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
    function processPayload(Payload calldata payload, uint32 blockNumber) private returns (bool) {
        if (blockNumber > slot0.latestBlockNumber) {
            latestChainMessagesRoot = payload.messageRoot;
            slot0.latestBlockNumber = blockNumber;

            applyAuthoritySetChanges(
                payload.nextValidatorSet.id,
                payload.nextValidatorSet.len,
                payload.nextValidatorSet.root
            );
            emit NewMessageRoot(latestChainMessagesRoot, blockNumber);
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Check if the payload includes a new authority set,
     * and if it does then update the new authority set
     * @param newAuthoritySetId The id of the new authority set
     * @param newAuthoritySetLen The length of the new authority set
     * @param newAuthoritySetRoot The new merkle tree of the new authority set
     */
    function applyAuthoritySetChanges(
        uint64 newAuthoritySetId,
        uint32 newAuthoritySetLen,
        bytes32 newAuthoritySetRoot
    ) private {
        uint64 _authoritySetId = slot0.authoritySetId;
        require(newAuthoritySetId == _authoritySetId || newAuthoritySetId == _authoritySetId + 1, "Bridge: Invalid new validator set id");
        if (newAuthoritySetId == _authoritySetId + 1) {
            _updateAuthoritySet(
                newAuthoritySetId,
                newAuthoritySetLen,
                newAuthoritySetRoot
            );
        }
    }

    /**
     * @notice Updates the current authority set
     * @param _authoritySetId The new authority set id
     * @param _authoritySetLen The new length of authority set
     * @param _authoritySetRoot The new authority set root
     */
    function _updateAuthoritySet(uint64 _authoritySetId, uint32 _authoritySetLen, bytes32 _authoritySetRoot) internal {
        require(0 < _authoritySetLen && _authoritySetLen < 257, "Bridge: Invalid authority set");
        slot0.authoritySetId = _authoritySetId;
        slot0.authoritySetLen = _authoritySetLen;
        authoritySetRoot = _authoritySetRoot;
        emit BEEFYAuthoritySetUpdated(_authoritySetId, _authoritySetLen, _authoritySetRoot);
    }
}
