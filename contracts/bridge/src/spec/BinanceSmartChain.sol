// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../utils/RLPEncode.sol";

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

        list[0] = RLPEncode.encodeBytes(abi.encodePacked(header.parent_hash));
        list[1] = RLPEncode.encodeBytes(abi.encodePacked(header.uncle_hash));
        list[2] = RLPEncode.encodeAddress(header.coinbase);
        list[3] = RLPEncode.encodeBytes(abi.encodePacked(header.state_root));
        list[4] = RLPEncode.encodeBytes(abi.encodePacked(header.transactions_root));
        list[5] = RLPEncode.encodeBytes(abi.encodePacked(header.receipts_root));
        list[6] = RLPEncode.encodeBytes(header.log_bloom);
        list[7] = RLPEncode.encodeUint(header.difficulty);
        list[8] = RLPEncode.encodeUint(header.number);
        list[9] = RLPEncode.encodeUint(header.gas_limit);
        list[10] = RLPEncode.encodeUint(header.gas_used);
        list[11] = RLPEncode.encodeUint(header.timestamp);
        list[12] = RLPEncode.encodeBytes(header.extra_data);
        list[13] = RLPEncode.encodeBytes(abi.encodePacked(header.mix_digest));
        list[14] = RLPEncode.encodeBytes(abi.encodePacked(header.nonce));

        data = RLPEncode.encodeList(list);
    }

    // Compute the RLP of this header with chain id
    function rlp_chain_id(BSCHeader memory header, uint64 chain_id) internal pure returns (bytes memory data) {
        bytes[] memory list = new bytes[](16);

        list[0] = RLPEncode.encodeUint(chain_id);
        list[1] = RLPEncode.encodeBytes(abi.encodePacked(header.parent_hash));
        list[2] = RLPEncode.encodeBytes(abi.encodePacked(header.uncle_hash));
        list[3] = RLPEncode.encodeAddress(header.coinbase);
        list[4] = RLPEncode.encodeBytes(abi.encodePacked(header.state_root));
        list[5] = RLPEncode.encodeBytes(abi.encodePacked(header.transactions_root));
        list[6] = RLPEncode.encodeBytes(abi.encodePacked(header.receipts_root));
        list[7] = RLPEncode.encodeBytes(header.log_bloom);
        list[8] = RLPEncode.encodeUint(header.difficulty);
        list[9] = RLPEncode.encodeUint(header.number);
        list[10] = RLPEncode.encodeUint(header.gas_limit);
        list[11] = RLPEncode.encodeUint(header.gas_used);
        list[12] = RLPEncode.encodeUint(header.timestamp);
        list[13] = RLPEncode.encodeBytes(header.extra_data);
        list[14] = RLPEncode.encodeBytes(abi.encodePacked(header.mix_digest));
        list[15] = RLPEncode.encodeBytes(abi.encodePacked(header.nonce));

        data = RLPEncode.encodeList(list);
    }
}
