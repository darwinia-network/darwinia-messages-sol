// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "@darwinia/contracts-utils/contracts/SafeMath.sol";
import "@darwinia/contracts-utils/contracts/Scale.sol";
import "@darwinia/contracts-utils/contracts/Hash.sol";
import "./interfaces/ILightClientBridge.sol";

contract BasicInboundChannel {
    uint256 public constant MAX_GAS_PER_MESSAGE = 100000;

    uint64 public nonce;

    struct Message {
        address target;
        uint64 nonce;
        bytes payload;
    }

    event MessageDispatched(uint64 nonce, bool result);

    ILightClientBridge public lightClientBridge;

    constructor(ILightClientBridge _lightClientBridge) public {
        nonce = 0;
        lightClientBridge = _lightClientBridge;
    }

    // TODO: Submit should take in all inputs required for verification,
    function submit(
        Message[] memory messages,
        bytes memory beefyMMRLeaf,
        bytes memory blockHeader,
        uint256 beefyMMRLeafIndex,
        uint256 beefyMMRLeafCount,
        bytes32[] memory peaks,
        bytes32[] memory siblings 
    ) public {
        require(
            lightClientBridge.verifyBeefyMerkleLeaf(
                beefyMMRLeaf,
                beefyMMRLeafIndex,
                beefyMMRLeafCount,
                peaks,
                siblings
            ),
            "Invalid proof"
        );
        verifyMessages(messages, beefyMMRLeaf, blockHeader);
        processMessages(messages);
    }

    //TODO: verifyMessages should accept all needed proofs
    function verifyMessages(Message[] memory messages, bytes memory beefyMMRLeaf, bytes memory blockHeader)
        internal
        view
        returns (bool success)
    {

        // struct MMRLeaf {
        //     bytes32 blockHash;
        //     bytes32 beefyNextAuthoritySetRoot;
        // }
        (bytes32 blockHash,) = abi.decode(beefyMMRLeaf, (bytes32,bytes32));
        require(blockHash == Hash.blake2bHash(blockHeader), "invalid block header");
        uint32 blockNumber = Scale.decodeBlockNumberFromBlockHeader(blockHeader);
        require(
            blockNumber <= lightClientBridge.getFinalizedBlockNumber(),
            "block not finalized"
        );
        bytes32 messagesRoot = Scale.decodeMessagesRootFromBlockHeader(blockHeader);

        // Validate that the commitment matches the commitment contents
        require(
            validateMessagesMatchRoot(messages, messagesRoot),
            "invalid messages"
        );

        // Require there is enough gas to play all messages
        require(
            gasleft() >= messages.length * MAX_GAS_PER_MESSAGE,
            "insufficient gas for delivery of all messages"
        );

        return true;
    }

    function processMessages(Message[] memory messages) internal {
        for (uint256 i = 0; i < messages.length; i++) {
            // Check message nonce is correct and increment nonce for replay protection
            require(messages[i].nonce == nonce + 1, "invalid nonce");

            nonce = nonce + 1;

            // Deliver the message to the target
            (bool success, ) =
                messages[i].target.call{value: 0, gas: MAX_GAS_PER_MESSAGE}(
                    messages[i].payload
                );

            emit MessageDispatched(messages[i].nonce, success);
        }
    }

    function validateMessagesMatchRoot(
        Message[] memory messages,
        bytes32 root
    ) internal pure returns (bool) {
        return keccak256(abi.encode(messages)) == root;
    }
}
