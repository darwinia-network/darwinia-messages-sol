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

pragma solidity 0.8.17;

import "../utils/ScaleCodec.sol";

contract BEEFYCommitmentScheme {
    using ScaleCodec for uint32;
    using ScaleCodec for uint64;

    /// Next BEEFY authority set
    /// @param id ID of the next set
    /// @param len Number of validators in the set
    /// @param root Merkle Root Hash build from BEEFY AuthorityIds
    struct NextValidatorSet {
        uint64 id;
        uint32 len;
        bytes32 root;
    }

    /// The payload being signed
    /// @param network Source chain network identifier
    /// @param mmr MMR root hash
    /// @param messageRoot Darwnia message root commitment hash
    /// @param nextValidatorSet Next BEEFY authority set
    struct Payload {
        bytes32 network;
        bytes32 mmr;
        bytes32 messageRoot;
        NextValidatorSet nextValidatorSet;
    }

    /// The Commitment, with its payload, is the core thing we are trying to verify with this contract.
    /// It contains a next validator set or not and a MMR root that commits to the darwinia history,
    /// including past blocks and can be used to verify darwinia blocks.
    /// @param payload the payload of the new commitment in beefy justifications (in
    ///  our case, this is a next validator set and a new MMR root for all past darwinia blocks)
    /// @param blockNumber block number for the given commitment
    /// @param validatorSetId validator set id that signed the given commitment
    struct Commitment {
        Payload payload;
        uint32 blockNumber;
        uint64 validatorSetId;
    }

    bytes4 internal constant PAYLOAD_SCALE_ENCOD_PREFIX = 0x04646280;

    function hash(Commitment memory commitment)
        public
        pure
        returns (bytes32)
    {
        // Encode and hash the Commitment
        return keccak256(
            abi.encodePacked(
                PAYLOAD_SCALE_ENCOD_PREFIX,
                hash(commitment.payload),
                commitment.blockNumber.encode32(),
                commitment.validatorSetId.encode64()
            )
        );
    }

    function hash(Payload memory payload)
        internal
        pure
        returns (bytes32)
    {
        // Encode and hash the Payload
        return keccak256(
            abi.encodePacked(
                payload.network,
                payload.mmr,
                payload.messageRoot,
                encode(payload.nextValidatorSet)
            )
        );
    }

    function encode(NextValidatorSet memory nextValidatorSet)
        internal
        pure
        returns (bytes memory)
    {
        // Encode the NextValidatorSet
        return abi.encodePacked(
                nextValidatorSet.id.encode64(),
                nextValidatorSet.len.encode32(),
                nextValidatorSet.root
            );
    }
}
