// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../interfaces/ILightClient.sol";

contract InboundLaneVerifier {
    /**
     * @dev The contract address of on-chain light client
     */
    ILightClient public immutable lightClient;

    /* State */
    // indentify slot
    // slot 0 ------------------------------------------------------------
    // @dev bridged lane position of the leaf in the `lane_message_merkle_tree`, index starting with 0
    uint32 public bridgedLanePosition;
    // @dev Bridged chain position of the leaf in the `chain_message_merkle_tree`, index starting with 0
    uint32 public bridgedChainPosition;
    // @dev This lane position of the leaf in the `lane_message_merkle_tree`, index starting with 0
    uint32 public thisLanePosition;
    // @dev This chain position of the leaf in the `chain_message_merkle_tree`, index starting with 0
    uint32 public thisChainPosition;

    // ------------------------------------------------------------------

    constructor(
        address _lightClient,
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition
    ) {
        lightClient = ILightClient(_lightClient);
        thisChainPosition = _thisChainPosition;
        thisLanePosition = _thisLanePosition;
        bridgedChainPosition = _bridgedChainPosition;
        bridgedLanePosition = _bridgedLanePosition;
    }

    /* Private Functions */

    function verify_messages_proof(
        bytes32 outlane_data_hash,
        bytes memory encoded_proof
    ) internal view {
        require(
            lightClient.verify_messages_proof(outlane_data_hash, thisChainPosition, bridgedLanePosition, encoded_proof),
            "Verifer: InvalidProof"
        );
    }

    function getLaneInfo() external view returns (uint32,uint32,uint32,uint32) {
        return (thisChainPosition,thisLanePosition,bridgedChainPosition,bridgedLanePosition);
    }

    // 32 bytes to identify an unique message from source chain
    // MessageKey encoding:
    // BridgedChainPosition | BridgedLanePosition | ThisChainPosition | ThisLanePosition | Nonce
    // [0..8)   bytes ---- Reserved
    // [8..12)  bytes ---- BridgedChainPosition
    // [16..20) bytes ---- BridgedLanePosition
    // [12..16) bytes ---- ThisChainPosition
    // [20..24) bytes ---- ThisLanePosition
    // [24..32) bytes ---- Nonce, max of nonce is `uint64(-1)`
    function encodeMessageKey(uint64 nonce) public view returns (uint256) {
        return (uint256(bridgedChainPosition) << 160) + (uint256(bridgedLanePosition) << 128) + (uint256(thisChainPosition) << 96) + (uint256(thisLanePosition) << 64) + uint256(nonce);
    }
}

