// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./EcdsaAuthority.sol";
import "../common/MessageVerifier.sol";
import "../../spec/POSACommitmentScheme.sol";

contract POSALightClient is POSACommitmentScheme, MessageVerifier, EcdsaAuthority {
    event MessageRootImported(uint256 block_number, bytes32 message_root);

    uint256 internal latest_block_number;
    bytes32 internal latest_message_root;

    constructor(
        bytes32 _domain_separator,
        address[] memory _relayers,
        uint256 _threshold,
        uint256 _nonce
    ) EcdsaAuthority(_domain_separator, _relayers, _threshold, _nonce) {}

    function block_number() public view returns (uint256) {
        return latest_block_number;
    }

    function message_root() public view override returns (bytes32) {
        return latest_message_root;
    }

    /// @dev Import message commitment which signed by RelayAuthorities
    /// @param commitment contains the message_root with block_number that is used for message verify
    /// @param signatures The signatures of the relayers signed the commitment.
    function import_message_commitment(
        Commitment calldata commitment,
        bytes[] calldata signatures
    ) external payable {
        // Hash the commitment
        bytes32 commitment_hash = hash(commitment);
        // Verify commitment signed by ecdsa-authority
        _check_relayer_signatures(commitment_hash, signatures);
        // Only import new block
        require(commitment.block_number > latest_block_number, "!new");
        latest_block_number = commitment.block_number;
        latest_message_root = commitment.message_root;
        emit MessageRootImported(commitment.block_number, commitment.message_root);
    }
}
