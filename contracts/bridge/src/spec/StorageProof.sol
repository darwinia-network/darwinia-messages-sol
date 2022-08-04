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

import "./State.sol";
import "../utils/rlp/RLPDecode.sol";
import "../utils/rlp/RLPEncode.sol";
import "../utils/trie/SecureMerkleTrie.sol";

library StorageProof {
    using State for bytes;
    using RLPDecode for bytes;
    using RLPDecode for RLPDecode.RLPItem;

    function verify_single_storage_proof(
        bytes32 root,
        address account,
        bytes memory account_proof,
        bytes32 storage_key,
        bytes memory storage_proof
    ) internal pure returns (bytes memory value) {
        bytes memory account_hash = abi.encodePacked(account);
        (bool exists, bytes memory data) = SecureMerkleTrie.get(
            account_hash,
            account_proof,
            root
        );
        require(exists == true, "!account_proof");
        State.EVMAccount memory acc = data.toEVMAccount();
        bytes memory storage_key_hash = abi.encodePacked(storage_key);
        (exists, value) = SecureMerkleTrie.get(
            storage_key_hash,
            storage_proof,
            acc.storage_root
        );
        require(exists == true, "!storage_proof");
        value = value.toRLPItem().readBytes();
    }

    function verify_multi_storage_proof(
        bytes32 root,
        address account,
        bytes memory account_proof,
        bytes32[] memory storage_keys,
        bytes[] memory storage_proofs
    ) internal view returns (bytes[] memory values) {
        uint key_size = storage_keys.length;
        require(key_size == storage_proofs.length, "!storage_proof_len");
        values = new bytes[](key_size);
        for (uint i = 0; i < key_size; i++) {
            values[i] = verify_single_storage_proof(
                root,
                account,
                account_proof,
                storage_keys[i],
                storage_proofs[i]
            );
        }
    }
}
