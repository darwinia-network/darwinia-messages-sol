// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./State.sol";
import "../utils/RLPDecode.sol";
import "../utils/RLPEncode.sol";
import "../utils/MerklePatriciaProofV1.sol";

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
        bytes memory account_hash = abi.encodePacked(keccak256(abi.encodePacked(account)));
        bytes memory data = MerklePatriciaProofV1.validateMPTProof(
            root,
            account_hash,
            RLPEncode.encodeList(account_proof)
        );
        State.Account memory acc = data.toAccount();
        bytes memory storage_key_hash = abi.encodePacked(keccak256(abi.encodePacked(storage_key)));
        bytes memory rlp_value = MerklePatriciaProofV1.validateMPTProof(
            acc.storage_root,
            storage_key_hash,
            RLPEncode.encodeList(storage_proof)
        );
        value = rlp_value.toRlpItem().toBytes();
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
