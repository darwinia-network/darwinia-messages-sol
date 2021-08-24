// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@darwinia/contracts-utils/contracts/SafeMath.sol";
import "@darwinia/contracts-verify/contracts/MerkleProof.sol";
import "../interfaces/ILightClientBridge.sol";
import "../interfaces/ICrossChainFilter.sol";

/**
 * @title A entry contract for syncing message from Darwinia to Ethereum-like chain
 * @author echo
 * @notice The basic inbound channel is the message layer of the bridge
 * @dev See https://itering.notion.site/Basic-Message-Channel-c41f0c9e453c478abb68e93f6a067c52
 */
contract BasicInboundChannel {
    /* Constants */
    /**
     * @dev Gas used per message needs to be less than 100000 wei
     */
    uint256 public constant MAX_GAS_PER_MESSAGE = 100000;
    /**
     * @dev Gas buffer for executing `submit` tx
     */
    uint256 public constant GAS_BUFFER = 60000;


    /**
     * The Message is the structure of DarwiniaRPC which should be delivery to Ethereum-like chain
     * @param sourceAccount The derived DVM address of pallet ID which send the message
     * @param targetContract The targe contract address which receive the message
     * @param laneContract The inbound channel contract address which the message commuting to
     * @param nonce The ID used to uniquely identify the message
     * @param payload The calldata which encoded by ABI Encoding
     */
    struct Message {
        address sourceAccount;
        address targetContract;
        address laneContract;
        uint256 nonce;
        bytes payload; /*abi.encodePacked(SELECTOR, PARAMS)*/
    }

    /**
     * The BeefyMMRLeaf is the structure of each leaf in each MMR that each commitment's payload commits to.
     * @param parentHash parent hash of the block this leaf describes
     * @param messagesRoot merkle root of all chain messages
     * @param blockNumber block number for the block this leaf describes
     */
    struct BeefyMMRLeaf {
        bytes32 parentHash;
        bytes32 messagesRoot;
        uint32 blockNumber;
    }

    /**
     * @notice Notifies an observer that the message has dispatched
     * @param nonce The message nonce
     * @param result The message result
     * @param returndata The return data of message call, when return false, it's the reason of the error
     */
    event MessageDispatched(uint256 indexed nonce, bool indexed result, bytes returndata);

    /* State */

    /**
     * @dev The position of the leaf in the chain message merkle tree, index starting with 0
     */
    uint256 public chainId;

    /**
     * @dev The position of the leaf in the lane message merkle tree, index starting with 0
     */
    uint256 public laneId;

    /**
     * @dev ID of the next message, which is incremented in strict order
     * @notice When upgrading the channel, this value must be synchronized
     */
    uint256 public nonce;

    /**
     * @dev The contract address of on-chain light client
     */
    ILightClientBridge public lightClientBridge;

    /**
     * @notice Deploys the BasicInboundChannel contract
     * @param _landId The position of the leaf in the message merkle tree, index starting with 0
     * @param _nonce ID of the next message, which is incremented in strict order
     * @param _lightClientBridge The contract address of on-chain light client
     */
    constructor(uint256 _chainId, uint256 _landId, uint256 _nonce, ILightClientBridge _lightClientBridge) public {
        chainId = _chainId;
        laneId = _landId;
        nonce = _nonce;
        lightClientBridge = _lightClientBridge;
    }

    /* Public Functions */

    /**
     * @notice Deliver and dispatch the messages
     * @param messages All the messages in the source chain block of this channel which need be delivered
     * @param numOfChains Number of all chain
     * @param chainProof The merkle proof required for validation of the messages in the chain message merkle tree
     * @param chainMessageRoot The merkle root of all channels message on this chain, and merkle leaf of messageRoot 
     * @param numOfLanes Number of all channels
     * @param laneProof The merkle proof required for validation of the messages in the lane message merkle tree
     * @param beefyMMRLeaf Beefy MMR leaf which the message root is located
     * @param beefyMMRLeafIndex Beefy MMR index which the beefy leaf is located
     * @param beefyMMRLeafCount Beefy MMR width of the MMR tree
     * @param peaks The proof required for validation the leaf
     * @param siblings The proof required for validation the leaf
     */
    function submit(
        Message[] memory messages,
        uint256 numOfChains,
        bytes32[] memory chainProof,
        bytes32 chainMessageRoot,
        uint256 numOfLanes,
        bytes32[] memory laneProof,
        BeefyMMRLeaf memory beefyMMRLeaf,
        uint256 beefyMMRLeafIndex,
        uint256 beefyMMRLeafCount,
        bytes32[] memory peaks,
        bytes32[] memory siblings 
    ) public {
        bytes32 beefyMMRLeafHash = hashMMRLeaf(beefyMMRLeaf);
        require(
            lightClientBridge.verifyBeefyMerkleLeaf(
                beefyMMRLeafHash,
                beefyMMRLeafIndex,
                beefyMMRLeafCount,
                peaks,
                siblings
            ),
            "Channel: Invalid proof"
        );
        verifyMessages(messages, beefyMMRLeaf, numOfChains, chainProof, chainMessageRoot, numOfLanes, laneProof);
        processMessages(messages);
    }

    /* Private Functions */

    function verifyMessages(
        Message[] memory messages,
        BeefyMMRLeaf memory leaf,
        uint256 numOfChains,
        bytes32[] memory chainProof,
        bytes32 chainMessageRoot,
        uint256 numOfLanes,
        bytes32[] memory laneProof
    )
        internal
        view
    {
        require(
            leaf.blockNumber <= lightClientBridge.getFinalizedBlockNumber(),
            "Channel: block not finalized"
        );
        // Validate that the commitment matches the commitment contents
        require(
            validateMessagesMatchRoot(messages, leaf.messagesRoot, numOfChains, chainProof, chainMessageRoot, numOfLanes, laneProof),
            "Channel: invalid messages"
        );

        // Require there is enough gas to play all messages
        require(
            gasleft() >= (messages.length * MAX_GAS_PER_MESSAGE) + GAS_BUFFER,
            "Channel: insufficient gas for delivery of all messages"
        );
    }

    function processMessages(Message[] memory messages) internal {
        for (uint256 i = 0; i < messages.length; i++) {
            Message memory message = messages[i];
            // Check message nonce is correct and increment nonce for replay protection
            require(message.nonce == nonce + 1, "Channel: invalid nonce");
            require(message.laneContract == address(this), "Channel: invalid lane contract");

            nonce = nonce + 1;

            /**
             * @notice The app layer must implement the interface `ICrossChainFilter`
             */
            try ICrossChainFilter(message.targetContract).crossChainFilter(message.sourceAccount, message.payload) 
                returns (bool ok) 
            {
                if (ok) {
                    // Deliver the message to the target
                    (bool success, bytes memory returndata) =
                        message.targetContract.call{value: 0, gas: MAX_GAS_PER_MESSAGE}(
                            message.payload
                    );
                    emit MessageDispatched(message.nonce, success, returndata);
                } else {
                    emit MessageDispatched(message.nonce, false, "Channel: filter failed");
                }
            } catch (bytes memory reason) {
                emit MessageDispatched(message.nonce, false, reason);
            }
        }
    }

    function validateMessagesMatchRoot(
        Message[] memory messages,
        bytes32 root,
        uint256 numOfChains,
        bytes32[] memory chainProof,
        bytes32 chainMessageRoot,
        uint256 numOfLanes,
        bytes32[] memory laneProof
    ) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encode(messages));
        return
            MerkleProof.verifyMerkleLeafAtPosition(
                chainMessageRoot,
                hash,
                laneId,
                numOfLanes,
                laneProof 
            )
            && 
            MerkleProof.verifyMerkleLeafAtPosition(
                root,
                chainMessageRoot,
                chainId,
                numOfChains,
                chainProof
            );
    }

    function hashMMRLeaf(BeefyMMRLeaf memory leaf)
        internal
        pure
        returns (bytes32) 
    {
        return keccak256(
                abi.encodePacked(
                    leaf.parentHash,
                    leaf.messagesRoot,
                    leaf.blockNumber
                )
            );
    }
}
