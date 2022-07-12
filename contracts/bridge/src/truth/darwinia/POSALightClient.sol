// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./RelayAuthorities.sol";
import "../common/MessageVerifier.sol";
import "../../spec/POSACommitmentScheme.sol";

contract POSALightClient is POSACommitmentScheme, MessageVerifier, RelayAuthorities {
    event MessageRootImported(uint256 block_number, bytes32 message_root);

    // keccak256(
    //     "SignCommitment(bytes32 network,bytes32 commitment,uint256 nonce)"
    // );
    bytes32 private constant COMMIT_TYPEHASH = 0x0324ca0ca4d529e0eefcc6d123bd17ec982498cf2e732160cc47d2504825e4b2;

    uint256 public latest_block_number;
    bytes32 public latest_messages_root;

    constructor(
        bytes32 _network,
        address[] memory _relayers,
        uint256 _threshold,
        uint256 _nonce
    ) RelayAuthorities(_network, _relayers, _threshold, _nonce) {}

    function message_root() public view override returns (bytes32) {
        return latest_messages_root;
    }

    /// @dev Import message commitment which signed by RelayAuthorities
    /// @param commitment contains the message_root with block_number that is used for message verify
    /// @param signatures The signatures of the relayers signed the commitment.
    function import_message_commitment(
        Commitment calldata commitment,
        bytes[] calldata signatures
    ) external payable {
        // Encode and hash the commitment
        bytes32 commitment_hash = hash(commitment);
        _verify_commitment(commitment_hash, signatures);

        require(commitment.block_number > latest_block_number, "!new");
        latest_block_number = commitment.block_number;
        latest_messages_root = commitment.message_root;
        emit MessageRootImported(commitment.block_number, commitment.message_root);
    }

    function _verify_commitment(bytes32 commitment_hash, bytes[] memory signatures) internal view {
        bytes32 struct_hash =
            keccak256(
                abi.encode(
                    COMMIT_TYPEHASH,
                    NETWORK,
                    commitment_hash,
                    nonce
                )
            );
        _check_relayer_signatures(struct_hash, signatures);
    }
}
