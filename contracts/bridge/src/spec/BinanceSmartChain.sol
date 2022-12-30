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

import "../utils/rlp/RLPEncode.sol";

/// @title BinanceSmartChain
/// @notice Binance smart chain specification
contract BinanceSmartChain {
    /// @notice BSC(Binance Smart Chain) header
    /// @param parent_hash Parent block hash
    /// @param uncle_hash Block uncles hash
    /// @param coinbase Validator address
    /// @param state_root Block state root
    /// @param transactions_root Block transactions root
    /// @param receipts_root Block receipts root
    /// @param log_bloom Block logs bloom, represents a 2048 bit bloom filter
    /// @param difficulty Block difficulty
    /// @param number Block number
    /// @param gas_limit Block gas limit
    /// @param gas_used Gas used for transactions execution
    /// @param timestamp Block timestamp
    /// @param extra_data Block extra data
    /// @param mix_digest Block mix digest
    /// @param nonce Block nonce, represents a 64-bit hash
    struct BSCHeader {
        bytes32 parent_hash;
        bytes32 uncle_hash;
        address coinbase;
        bytes32 state_root;
        bytes32 transactions_root;
        bytes32 receipts_root;
        bytes log_bloom;
        uint256 difficulty;
        uint256 number;
        uint64 gas_limit;
        uint64 gas_used;
        uint64 timestamp;
        bytes extra_data;
        bytes32 mix_digest;
        bytes8 nonce;
    }

    /// @notice Compute hash of this header (keccak of the RLP with seal)
    function hash(BSCHeader memory header) internal pure returns (bytes32) {
        return keccak256(rlp(header));
    }

    /// @notice Compute hash of this header with chain id
    function hash_with_chain_id(BSCHeader memory header, uint64 chain_id) internal pure returns (bytes32) {
        return keccak256(rlp_chain_id(header, chain_id));
    }

    /// @notice Compute the RLP of this header
    function rlp(BSCHeader memory header) internal pure returns (bytes memory data) {
        bytes[] memory list = new bytes[](15);

        list[0] = RLPEncode.writeBytes(abi.encodePacked(header.parent_hash));
        list[1] = RLPEncode.writeBytes(abi.encodePacked(header.uncle_hash));
        list[2] = RLPEncode.writeAddress(header.coinbase);
        list[3] = RLPEncode.writeBytes(abi.encodePacked(header.state_root));
        list[4] = RLPEncode.writeBytes(abi.encodePacked(header.transactions_root));
        list[5] = RLPEncode.writeBytes(abi.encodePacked(header.receipts_root));
        list[6] = RLPEncode.writeBytes(header.log_bloom);
        list[7] = RLPEncode.writeUint(header.difficulty);
        list[8] = RLPEncode.writeUint(header.number);
        list[9] = RLPEncode.writeUint(header.gas_limit);
        list[10] = RLPEncode.writeUint(header.gas_used);
        list[11] = RLPEncode.writeUint(header.timestamp);
        list[12] = RLPEncode.writeBytes(header.extra_data);
        list[13] = RLPEncode.writeBytes(abi.encodePacked(header.mix_digest));
        list[14] = RLPEncode.writeBytes(abi.encodePacked(header.nonce));

        data = RLPEncode.writeList(list);
    }

    /// @notice Compute the RLP of this header with chain id
    function rlp_chain_id(BSCHeader memory header, uint64 chain_id) internal pure returns (bytes memory data) {
        bytes[] memory list = new bytes[](16);

        list[0] = RLPEncode.writeUint(chain_id);
        list[1] = RLPEncode.writeBytes(abi.encodePacked(header.parent_hash));
        list[2] = RLPEncode.writeBytes(abi.encodePacked(header.uncle_hash));
        list[3] = RLPEncode.writeAddress(header.coinbase);
        list[4] = RLPEncode.writeBytes(abi.encodePacked(header.state_root));
        list[5] = RLPEncode.writeBytes(abi.encodePacked(header.transactions_root));
        list[6] = RLPEncode.writeBytes(abi.encodePacked(header.receipts_root));
        list[7] = RLPEncode.writeBytes(header.log_bloom);
        list[8] = RLPEncode.writeUint(header.difficulty);
        list[9] = RLPEncode.writeUint(header.number);
        list[10] = RLPEncode.writeUint(header.gas_limit);
        list[11] = RLPEncode.writeUint(header.gas_used);
        list[12] = RLPEncode.writeUint(header.timestamp);
        list[13] = RLPEncode.writeBytes(header.extra_data);
        list[14] = RLPEncode.writeBytes(abi.encodePacked(header.mix_digest));
        list[15] = RLPEncode.writeBytes(abi.encodePacked(header.nonce));

        data = RLPEncode.writeList(list);
    }
}
