// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@darwinia/contracts-utils/contracts/SafeMath.sol";
import "@darwinia/contracts-verify/contracts/MerkleProof.sol";
import "../interfaces/ILightClientBridge.sol";
import "../interfaces/ICrossChainFilter.sol";

contract BasicInboundChannel {
    uint256 public constant MAX_GAS_PER_MESSAGE = 100000;

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
     * @param messagesRoot root hash of messages
     * @param blockNumber block number for the block this leaf describes
     */
    struct BeefyMMRLeaf {
        bytes32 parentHash;
        bytes32 messagesRoot;
        uint32 blockNumber;
    }

    event MessageDispatched(uint256 indexed nonce, bool indexed result, bytes returndata);

    uint256 public laneId;
    uint256 public nonce;
    ILightClientBridge public lightClientBridge;

    constructor(uint256 _landId, uint256 _nonce, ILightClientBridge _lightClientBridge) public {
        laneId = _landId;
        nonce = _nonce;
        lightClientBridge = _lightClientBridge;
    }

    function submit(
        Message[] memory messages,
        uint256 numOfLanes,
        bytes32[] memory proof,
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
        verifyMessages(messages, beefyMMRLeaf, numOfLanes, proof);
        processMessages(messages);
    }

    function verifyMessages(
        Message[] memory messages,
        BeefyMMRLeaf memory leaf,
        uint256 numOfLanes,
        bytes32[] memory proof
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
            validateMessagesMatchRoot(messages, leaf.messagesRoot, numOfLanes, proof),
            "Channel: invalid messages"
        );

        // Require there is enough gas to play all messages
        require(
            gasleft() >= messages.length * MAX_GAS_PER_MESSAGE,
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
        uint256 numOfLanes,
        bytes32[] memory proof
    ) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encode(messages));
        return
            MerkleProof.verifyMerkleLeafAtPosition(
                root,
                hash,
                laneId,
                numOfLanes,
                proof
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
