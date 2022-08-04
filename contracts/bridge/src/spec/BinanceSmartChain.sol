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

import "../utils/rlp/RLPEncode.sol";

contract BinanceSmartChain {
    // BSC(Binance Smart Chain) header
    struct BSCHeader {
        // Parent block hash
        bytes32 parent_hash;
        // Block uncles hash
        bytes32 uncle_hash;
        // validator address
        address coinbase;
        // Block state root
        bytes32 state_root;
        // Block transactions root
        bytes32 transactions_root;
        // Block receipts root
        bytes32 receipts_root;
        // Block logs bloom, represents a 2048 bit bloom filter
        bytes log_bloom;
        // Block difficulty
        uint256 difficulty;
        // Block number
        uint256 number;
        // Block gas limit
        uint64 gas_limit;
        // Gas used for transactions execution
        uint64 gas_used;
        // Block timestamp
        uint64 timestamp;
        // Block extra data
        bytes extra_data;
        // Block mix digest
        bytes32 mix_digest;
        // Block nonce, represents a 64-bit hash
        bytes8 nonce;
    }

    // Compute hash of this header (keccak of the RLP with seal)
    function hash(BSCHeader memory header) internal pure returns (bytes32) {
        return keccak256(rlp(header));
    }

    // Compute hash of this header with chain id
    function hash_with_chain_id(BSCHeader memory header, uint64 chain_id) internal pure returns (bytes32) {
        return keccak256(rlp_chain_id(header, chain_id));
    }

    // Compute the RLP of this header
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

    // Compute the RLP of this header with chain id
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
