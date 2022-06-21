// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

contract BinanceSmartChain {
    /// BSC(Binance Smart Chain) header
    struct BSCHeader {
        /// Parent block hash
        bytes32 parent_hash;
        /// Block uncles hash
        bytes32 uncle_hash;
        /// validator address
        address coinbase;
        /// Block state root
        bytes32 state_root;
        /// Block transactions root
        bytes32 transactions_root;
        /// Block receipts root
        bytes32 receipts_root;
        /// Block logs bloom, represents a 2048 bit bloom filter
        bytes log_bloom;
        /// Block difficulty
        uint256 difficulty;
        /// Block number
        uint256 number;
        /// Block gas limit
        uint64 gas_limit;
        /// Gas used for transactions execution
        uint64 gas_used;
        /// Block timestamp
        uint64 timestamp;
        /// Block extra data
        bytes extra_data;
        /// Block mix digest
        bytes32 mix_digest;
        /// Block nonce, represents a 64-bit hash
        bytes8 nonce;
    }

    function hash(BSCHeader memory header) internal pure returns (bytes32) {
        return keccack256(rlp(header));
    }

    function hash_with_chain_id(BSCHeader memory header, uint64 chain_id) internal pure (bytes32) {
        return keccack256(rlp_chain_id(header, chain_id));
    }

    function rlp(BSCHeader memory header) internal pure returns (bytes32) {

    }

    function rlp_chain_id(BSCHeader memory header, chain_id) internal pure returns (bytes32) {

    }

    function hash(address[] memory signers) internal pure returns (bytes32) {
        bytes32[] hashed_signers = new bytes32[](signers.length);
        for (uint i = 0; i < signers.length; i++) {
            hashed_signers[i] = keccak256(abi.encodePacked(signers[i]));
        }
        return hash(hashed_signers);
    }

    function hash(bytes32[] memory leaves) internal pure returns (bytes32) {
        uint len = leaves.length;
        if (len == 0) return bytes32(0);
        else if (len == 1) return leaves[0];
        else if (len == 2) return hash_node(leaves[0], leaves[1]);
        uint bottom_length = get_power_of_two_ceil(len);
        bytes32[] memory o = new bytes32[](bottom_length * 2);
        for (uint i = 0; i < len; ++i) {
            o[bottom_length + i] = leaves[i];
        }
        for (uint i = bottom_length - 1; i > 0; --i) {
            o[i] = hash_node(o[i * 2], o[i * 2 + 1]);
        }
        return o[1];
    }

    function get_power_of_two_ceil(uint256 x) internal pure returns (uint256) {
        if (x <= 1) return 1;
        else if (x == 2) return 2;
        else return 2 * get_power_of_two_ceil((x + 1) >> 1);
    }

    function hash_node(bytes32 left, bytes32 right)
        internal
        pure
        returns (bytes32 hash)
    {
        assembly {
            mstore(0x00, left)
            mstore(0x20, right)
            hash := keccak256(0x00, 0x40)
        }
        return hash;
    }
}
