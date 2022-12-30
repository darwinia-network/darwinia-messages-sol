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

import "./State.sol";
import "../utils/rlp/RLPDecode.sol";
import "../utils/trie/SecureMerkleTrie.sol";

/// @title StorageProof
/// @notice Storage proof specification
library StorageProof {
    using State for bytes;
    using RLPDecode for bytes;
    using RLPDecode for RLPDecode.RLPItem;

    /// @notice Verify single storage proof
    /// @param root State root
    /// @param account Account address to be prove
    /// @param account_proof Merkle trie inclusion proof for the account
    /// @param storage_key Storage key to be prove
    /// @param storage_proof Merkle trie inclusion proof for storage key
    /// @return value of the key if it exists
    function verify_single_storage_proof(
        bytes32 root,
        address account,
        bytes[] memory account_proof,
        bytes32 storage_key,
        bytes[] memory storage_proof
    ) internal pure returns (bytes memory value) {
        bytes memory account_hash = abi.encodePacked(account);
        bytes memory data = SecureMerkleTrie.get(
            account_hash,
            account_proof,
            root
        );
        State.EVMAccount memory acc = data.toEVMAccount();
        bytes memory storage_key_hash = abi.encodePacked(storage_key);
        value = SecureMerkleTrie.get(
            storage_key_hash,
            storage_proof,
            acc.storage_root
        );
        value = value.toRLPItem().readBytes();
    }

    /// @notice Verify multi storage proof
    /// @param root State root
    /// @param account Account address to be prove
    /// @param account_proof Merkle trie inclusion proof for the account
    /// @param storage_keys Multi storage key to be prove
    /// @param storage_proofs Merkle trie inclusion multi proof for storage keys
    /// @return values of the keys if it exists
    function verify_multi_storage_proof(
        bytes32 root,
        address account,
        bytes[] memory account_proof,
        bytes32[] memory storage_keys,
        bytes[][] memory storage_proofs
    ) internal pure returns (bytes[] memory values) {
        uint key_size = storage_keys.length;
        require(key_size == storage_proofs.length, "!storage_proof_len");
        values = new bytes[](key_size);
        for (uint i = 0; i < key_size; ) {
            values[i] = verify_single_storage_proof(
                root,
                account,
                account_proof,
                storage_keys[i],
                storage_proofs[i]
            );
            unchecked { ++i; }
        }
    }
}
