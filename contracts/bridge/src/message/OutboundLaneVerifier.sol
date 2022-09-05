// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.7.6;
pragma abicoder v2;

import "../interfaces/IVerifier.sol";

contract OutboundLaneVerifier {
    /// @dev Indentify slot
    Slot0 internal slot0;

    /// @dev The contract address of on-chain verifier
    IVerifier public immutable VERIFIER;

    struct Slot0 {
        // Bridged lane position of the leaf in the `lane_message_merkle_tree`, index starting with 0
        uint32 bridged_lane_pos;
        // Bridged chain position of the leaf in the `chain_message_merkle_tree`, index starting with 0
        uint32 bridged_chain_pos;
        // This lane position of the leaf in the `lane_message_merkle_tree`, index starting with 0
        uint32 this_lane_pos;
        // This chain position of the leaf in the `chain_message_merkle_tree`, index starting with 0
        uint32 this_chain_pos;
    }

    constructor(
        address _verifier,
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition
    ) {
        VERIFIER = IVerifier(_verifier);
        slot0.this_chain_pos = _thisChainPosition;
        slot0.this_lane_pos = _thisLanePosition;
        slot0.bridged_chain_pos = _bridgedChainPosition;
        slot0.bridged_lane_pos = _bridgedLanePosition;
    }

    function _verify_messages_delivery_proof(
        bytes32 inlane_data_hash,
        bytes memory encoded_proof
    ) internal view {
        Slot0 memory _slot0 = slot0;
        require(
            VERIFIER.verify_messages_delivery_proof(
                inlane_data_hash,
                _slot0.this_chain_pos,
                _slot0.bridged_lane_pos,
                encoded_proof
            ), "!proof"
        );
    }

    function getLaneInfo() external view returns (uint32,uint32,uint32,uint32) {
        Slot0 memory _slot0 = slot0;
        return (
            _slot0.this_chain_pos,
            _slot0.this_lane_pos,
            _slot0.bridged_chain_pos,
            _slot0.bridged_lane_pos
        );
    }

    // 32 bytes to identify an unique message from source chain
    // MessageKey encoding:
    // ThisChainPosition | ThisLanePosition | BridgedChainPosition | BridgedLanePosition | Nonce
    // [0..8)   bytes ---- Reserved
    // [8..12)  bytes ---- ThisChainPosition
    // [16..20) bytes ---- ThisLanePosition
    // [12..16) bytes ---- BridgedChainPosition
    // [20..24) bytes ---- BridgedLanePosition
    // [24..32) bytes ---- Nonce, max of nonce is `uint64(-1)`
    function encodeMessageKey(uint64 nonce) public view returns (uint256) {
        Slot0 memory _slot0 = slot0;
        return (uint256(_slot0.this_chain_pos) << 160) +
                (uint256(_slot0.this_lane_pos) << 128) +
                (uint256(_slot0.bridged_chain_pos) << 96) +
                (uint256(_slot0.bridged_lane_pos) << 64) +
                uint256(nonce);
    }
}
