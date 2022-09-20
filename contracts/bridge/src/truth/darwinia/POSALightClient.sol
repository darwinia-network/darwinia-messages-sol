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

import "./EcdsaAuthority.sol";
import "../../spec/POSACommitmentScheme.sol";
import "../../interfaces/ILightClient.sol";

contract POSALightClient is POSACommitmentScheme, EcdsaAuthority, ILightClient {
    event MessageRootImported(uint256 block_number, bytes32 message_root);

    uint256 internal latest_block_number;
    bytes32 internal latest_message_root;

    constructor(
        bytes32 _domain_separator,
        address[] memory _relayers,
        uint256 _threshold,
        uint256 _nonce
    ) EcdsaAuthority(_domain_separator) {
        __ECDSA_init__(_relayers, _threshold, _nonce);
    }

    function block_number() public view returns (uint256) {
        return latest_block_number;
    }

    function merkle_root() public view override returns (bytes32) {
        return latest_message_root;
    }

    /// @dev Import message commitment which signed by RelayAuthorities
    /// @param commitment contains the message_root with block_number that is used for message verify
    /// @param signatures The signatures of the relayers signed the commitment.
    function import_message_commitment(
        Commitment calldata commitment,
        bytes[] calldata signatures
    ) external {
        // Hash the commitment
        bytes32 commitment_hash = hash(commitment);
        // Commitment match the nonce of ecdsa-authority
        require(commitment.nonce == nonce, "!nonce");
        // Verify commitment signed by ecdsa-authority
        _check_relayer_signatures(commitment_hash, signatures);
        // Only import new block
        require(commitment.block_number > latest_block_number, "!new");
        latest_block_number = commitment.block_number;
        latest_message_root = commitment.message_root;
        emit MessageRootImported(commitment.block_number, commitment.message_root);
    }
}
