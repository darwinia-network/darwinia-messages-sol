// SPDX-License-Identifier: MIT

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
        bytes[] memory account_proof,
        bytes32 storage_key,
        bytes[] memory storage_proof
    ) internal view returns (bytes memory value) {
        bytes memory account_hash = abi.encodePacked(account);
        (bool exists, bytes memory data) = SecureMerkleTrie.get(
            account_hash,
            RLPEncode.writeList(account_proof),
            root
        );
        require(exists == true, "!account_proof");
        State.EVMAccount memory acc = data.toEVMAccount();
        bytes memory storage_key_hash = abi.encodePacked(storage_key);
        (exists, value) = SecureMerkleTrie.get(
            storage_key_hash,
            RLPEncode.writeList(storage_proof),
            acc.storage_root
        );
        require(exists == true, "!storage_proof");
        value = value.toRLPItem().readBytes();
    }

    function verify_multi_storage_proof(
        bytes32 root,
        address account,
        bytes[] memory account_proof,
        bytes32[] memory storage_keys,
        bytes[][] memory storage_proofs
    ) internal view returns (bytes[] memory values) {
        uint key_size = storage_keys.length;
        require(key_size == storage_proofs.length);
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
