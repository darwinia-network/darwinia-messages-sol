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

contract POSACommitmentScheme {
    // keccak256(
    //     "Commitment(uint32 block_number,bytes32 message_root,uint256 nonce)"
    // );
    bytes32 internal constant COMMIT_TYPEHASH = 0xaca824a0c4edb3b2c17f33fea9cb21b33c7ee16c8e634c36b3bf851c9de7a223;

    /// The Commitment contains the message_root with block_number that is used for message verify
    /// @param block_number block number for the given commitment
    /// @param message_root Darwnia message root commitment hash
    struct Commitment {
        uint32 block_number;
        bytes32 message_root;
        uint256 nonce;
    }

    function hash(Commitment memory c)
        internal
        pure
        returns (bytes32)
    {
        // Encode and hash the Commitment
        return keccak256(
            abi.encode(
                COMMIT_TYPEHASH,
                c.block_number,
                c.message_root,
                c.nonce
            )
        );
    }
}
