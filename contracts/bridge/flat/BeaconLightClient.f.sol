// hevm: flattened sources of src/truth/eth/BeaconLightClient.sol
// SPDX-License-Identifier: GPL-3.0 AND Apache-2.0 AND MIT
pragma solidity =0.8.17;

////// src/interfaces/ILightClient.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.8.17; */

/// @title ILane
/// @notice A interface for light client
interface ILightClient {
    /// @notice Return the merkle root of light client
    /// @return merkle root
    function merkle_root() external view returns (bytes32);
    /// @notice Return the block number of light client
    /// @return block number
    function block_number() external view returns (uint256);
}

////// src/utils/Math.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.8.17; */

contract Math {
    /// Get the power of 2 for given input, or the closest higher power of 2 if the input is not a power of 2.
    /// Commonly used for "how many nodes do I need for a bottom tree layer fitting x elements?"
    /// Example: 0->1, 1->1, 2->2, 3->4, 4->4, 5->8, 6->8, 7->8, 8->8, 9->16.
    function get_power_of_two_ceil(uint256 x) internal pure returns (uint256) {
        if (x <= 1) return 1;
        else if (x == 2) return 2;
        else return 2 * get_power_of_two_ceil((x + 1) >> 1);
    }

    function log_2(uint256 x) internal pure returns (uint256 pow) {
        require(0 < x && x < 0x8000000000000000000000000000000000000000000000000000000000000001, "invalid");
        uint256 a = 1;
        while (a < x) {
            a <<= 1;
            pow++;
        }
    }
}

////// src/spec/MerkleProof.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.8.17; */

/* import "../utils/Math.sol"; */

/// @title MerkleProof
/// @notice Merkle proof specification
contract MerkleProof is Math {
    /// @notice Check if ``leaf`` at ``index`` verifies against the Merkle ``root`` and ``branch``.
    function is_valid_merkle_branch(
        bytes32 leaf,
        bytes32[] memory branch,
        uint64 depth,
        uint64 index,
        bytes32 root
    ) internal pure returns (bool) {
        bytes32 value = leaf;
        for (uint i = 0; i < depth; ) {
            if ((index / (2**i)) % 2 == 1) {
                value = hash_node(branch[i], value);
            } else {
                value = hash_node(value, branch[i]);
            }
            unchecked { ++i; }
        }
        return value == root;
    }

    function merkle_root(bytes32[] memory leaves) internal pure returns (bytes32) {
        uint len = leaves.length;
        if (len == 0) return bytes32(0);
        else if (len == 1) return hash(abi.encodePacked(leaves[0]));
        else if (len == 2) return hash_node(leaves[0], leaves[1]);
        uint bottom_length = get_power_of_two_ceil(len);
        bytes32[] memory o = new bytes32[](bottom_length * 2);
        unchecked {
            for (uint i = 0; i < len; ++i) {
                o[bottom_length + i] = leaves[i];
            }
            for (uint i = bottom_length - 1; i > 0; --i) {
                o[i] = hash_node(o[i * 2], o[i * 2 + 1]);
            }
        }
        return o[1];
    }


    function hash_node(bytes32 left, bytes32 right)
        internal
        pure
        returns (bytes32)
    {
        return hash(abi.encodePacked(left, right));
    }

    function hash(bytes memory value) internal pure returns (bytes32) {
        return sha256(value);
    }
}

////// src/utils/ScaleCodec.sol
//
// Inspired: https://github.com/Snowfork/snowbridge/blob/main/core/packages/contracts/contracts/ScaleCodec.sol

/* pragma solidity 0.8.17; */

library ScaleCodec {
    // Decodes a SCALE encoded uint256 by converting bytes (bid endian) to little endian format
    function decodeUint256(bytes memory data) internal pure returns (uint256) {
        uint256 number;
        unchecked {
            for (uint256 i = data.length; i > 0; i--) {
                number = number + uint256(uint8(data[i - 1])) * (2**(8 * (i - 1)));
            }
        }
        return number;
    }

    // Decodes a SCALE encoded compact unsigned integer
    function decodeUintCompact(bytes memory data)
        internal
        pure
        returns (uint256 v)
    {
        uint8 b = readByteAtIndex(data, 0); // read the first byte
        uint8 mode = b & 3; // bitwise operation

        if (mode == 0) {
            // [0, 63]
            return b >> 2; // right shift to remove mode bits
        } else if (mode == 1) {
            // [64, 16383]
            uint8 bb = readByteAtIndex(data, 1); // read the second byte
            uint64 r = bb; // convert to uint64
            r <<= 6; // multiply by * 2^6
            r += b >> 2; // right shift to remove mode bits
            return r;
        } else if (mode == 2) {
            // [16384, 1073741823]
            uint8 b2 = readByteAtIndex(data, 1); // read the next 3 bytes
            uint8 b3 = readByteAtIndex(data, 2);
            uint8 b4 = readByteAtIndex(data, 3);

            uint32 x1 = uint32(b) | (uint32(b2) << 8); // convert to little endian
            uint32 x2 = x1 | (uint32(b3) << 16);
            uint32 x3 = x2 | (uint32(b4) << 24);

            x3 >>= 2; // remove the last 2 mode bits
            return uint256(x3);
        } else if (mode == 3) {
            // [1073741824, 4503599627370496]
            // solhint-disable-next-line
            uint8 l = b >> 2; // remove mode bits
            require(
                l > 32,
                "Not supported: number cannot be greater than 32 bytes"
            );
        } else {
            revert("Code should be unreachable");
        }
    }

    // Read a byte at a specific index and return it as type uint8
    function readByteAtIndex(bytes memory data, uint8 index)
        internal
        pure
        returns (uint8)
    {
        return uint8(data[index]);
    }

    // Sources:
    //   * https://ethereum.stackexchange.com/questions/15350/how-to-convert-an-bytes-to-address-in-solidity/50528
    //   * https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel

    function reverse256(uint256 input) internal pure returns (uint256 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v = ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64) |
            ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);

        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    function reverse128(uint128 input) internal pure returns (uint128 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000) >> 32) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v = (v >> 64) | (v << 64);
    }

    function reverse64(uint64 input) internal pure returns (uint64 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = (v >> 32) | (v << 32);
    }

    function reverse32(uint32 input) internal pure returns (uint32 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00) >> 8) |
            ((v & 0x00FF00FF) << 8);

        // swap 2-byte long pairs
        v = (v >> 16) | (v << 16);
    }

    function reverse16(uint16 input) internal pure returns (uint16 v) {
        v = input;

        // swap bytes
        v = (v >> 8) | (v << 8);
    }

    function encode256(uint256 input) internal pure returns (bytes32) {
        return bytes32(reverse256(input));
    }

    function encode128(uint128 input) internal pure returns (bytes16) {
        return bytes16(reverse128(input));
    }

    function encode64(uint64 input) internal pure returns (bytes8) {
        return bytes8(reverse64(input));
    }

    function encode32(uint32 input) internal pure returns (bytes4) {
        return bytes4(reverse32(input));
    }

    function encode16(uint16 input) internal pure returns (bytes2) {
        return bytes2(reverse16(input));
    }

    function encode8(uint8 input) internal pure returns (bytes1) {
        return bytes1(input);
    }
}

////// src/spec/BeaconChain.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.8.17; */

/* import "./MerkleProof.sol"; */
/* import "../utils/ScaleCodec.sol"; */

/// @title BeaconChain
/// @notice Beacon chain specification
contract BeaconChain is MerkleProof {
    /// @notice bls public key length
    uint64 constant internal BLSPUBLICKEY_LENGTH = 48;
    /// @notice bls signature length
    uint64 constant internal BLSSIGNATURE_LENGTH = 96;
    /// @notice sync committee size
    uint64 constant internal SYNC_COMMITTEE_SIZE = 512;

    /// @notice Fork data
    /// @param current_version Current verison
    /// @param genesis_validators_root Genesis validators root
    struct ForkData {
        bytes4 current_version;
        bytes32 genesis_validators_root;
    }

    /// @notice Signing data
    /// @param object_root Root of signing object
    /// @param domain Domain
    struct SigningData {
        bytes32 object_root;
        bytes32 domain;
    }

    /// @notice Sync committee
    /// @param pubkeys Pubkeys of sync committee
    /// @param aggregate_pubkey Aggregate pubkey of sync committee
    struct SyncCommittee {
        bytes[SYNC_COMMITTEE_SIZE] pubkeys;
        bytes aggregate_pubkey;
    }

    /// @notice Beacon block header
    /// @param slot Slot
    /// @param proposer_index Index of proposer
    /// @param parent_root Parent root hash
    /// @param state_root State root hash
    /// @param body_root Body root hash
    struct BeaconBlockHeader {
        uint64 slot;
        uint64 proposer_index;
        bytes32 parent_root;
        bytes32 state_root;
        bytes32 body_root;
    }


    /// @notice Light client header
    /// @param beacon Beacon block header
    /// @param execution Execution payload header corresponding to `beacon.body_root` [New in Capella]
    /// @param execution_branch Execution payload header proof corresponding to `beacon.body_root` [New in Capella]
    struct LightClientHeader {
        BeaconBlockHeader beacon;
        ExecutionPayloadHeader execution;
        bytes32[] execution_branch;
    }

    /// @notice Execution payload header in Capella
    /// @param parent_hash Parent hash
    /// @param fee_recipient Beneficiary
    /// @param state_root State root
    /// @param receipts_root Receipts root
    /// @param logs_bloom Logs bloom
    /// @param prev_randao Difficulty
    /// @param block_number Number
    /// @param gas_limit Gas limit
    /// @param gas_used Gas used
    /// @param timestamp Timestamp
    /// @param extra_data Extra data
    /// @param base_fee_per_gas Base fee per gas
    /// @param block_hash Hash of execution block
    /// @param transactions_root Root of transactions
    /// @param withdrawals_root Root of withdrawals [New in Capella]
    struct ExecutionPayloadHeader {
        bytes32 parent_hash;
        address fee_recipient;
        bytes32 state_root;
        bytes32 receipts_root;
        bytes32 logs_bloom;
        bytes32 prev_randao;
        uint64 block_number;
        uint64 gas_limit;
        uint64 gas_used;
        uint64 timestamp;
        bytes32 extra_data;
        uint256 base_fee_per_gas;
        bytes32 block_hash;
        bytes32 transactions_root;
        bytes32 withdrawals_root;
    }

    /// @notice Return the signing root for the corresponding signing data.
    function compute_signing_root(BeaconBlockHeader memory beacon_header, bytes32 domain) internal pure returns (bytes32){
        return hash_tree_root(SigningData({
                object_root: hash_tree_root(beacon_header),
                domain: domain
            })
        );
    }

    /// @notice Return the 32-byte fork data root for the ``current_version`` and ``genesis_validators_root``.
    /// This is used primarily in signature domains to avoid collisions across forks/chains.
    function compute_fork_data_root(bytes4 current_version, bytes32 genesis_validators_root) internal pure returns (bytes32){
        return hash_tree_root(ForkData({
                current_version: current_version,
                genesis_validators_root: genesis_validators_root
            })
        );
    }

    /// @notice Return the domain for the ``domain_type`` and ``fork_version``.
    function compute_domain(bytes4 domain_type, bytes4 fork_version, bytes32 genesis_validators_root) internal pure returns (bytes32){
        bytes32 fork_data_root = compute_fork_data_root(fork_version, genesis_validators_root);
        return bytes32(domain_type) | fork_data_root >> 32;
    }

    /// @notice Return hash tree root of fork data
    function hash_tree_root(ForkData memory fork_data) internal pure returns (bytes32) {
        return hash_node(bytes32(fork_data.current_version), fork_data.genesis_validators_root);
    }

    /// @notice Return hash tree root of signing data
    function hash_tree_root(SigningData memory signing_data) internal pure returns (bytes32) {
        return hash_node(signing_data.object_root, signing_data.domain);
    }

    /// @notice Return hash tree root of sync committee
    function hash_tree_root(SyncCommittee memory sync_committee) internal pure returns (bytes32) {
        bytes32[] memory pubkeys_leaves = new bytes32[](SYNC_COMMITTEE_SIZE);
        for (uint i = 0; i < SYNC_COMMITTEE_SIZE; ++i) {
            bytes memory key = sync_committee.pubkeys[i];
            require(key.length == BLSPUBLICKEY_LENGTH, "!key");
            pubkeys_leaves[i] = hash(abi.encodePacked(key, bytes16(0)));
        }
        bytes32 pubkeys_root = merkle_root(pubkeys_leaves);

        require(sync_committee.aggregate_pubkey.length == BLSPUBLICKEY_LENGTH, "!agg_key");
        bytes32 aggregate_pubkey_root = hash(abi.encodePacked(sync_committee.aggregate_pubkey, bytes16(0)));

        return hash_node(pubkeys_root, aggregate_pubkey_root);
    }

    /// @notice Return hash tree root of beacon block header
    function hash_tree_root(BeaconBlockHeader memory beacon_header) internal pure returns (bytes32) {
        bytes32[] memory leaves = new bytes32[](5);
        leaves[0] = bytes32(to_little_endian_64(beacon_header.slot));
        leaves[1] = bytes32(to_little_endian_64(beacon_header.proposer_index));
        leaves[2] = beacon_header.parent_root;
        leaves[3] = beacon_header.state_root;
        leaves[4] = beacon_header.body_root;
        return merkle_root(leaves);
    }

    /// @notice Return hash tree root of execution payload in Capella
    function hash_tree_root(ExecutionPayloadHeader memory execution_payload) internal pure returns (bytes32) {
        bytes32[] memory leaves = new bytes32[](15);
        leaves[0]  = execution_payload.parent_hash;
        leaves[1]  = bytes32(bytes20(execution_payload.fee_recipient));
        leaves[2]  = execution_payload.state_root;
        leaves[3]  = execution_payload.receipts_root;
        leaves[4]  = execution_payload.logs_bloom;
        leaves[5]  = execution_payload.prev_randao;
        leaves[6]  = bytes32(to_little_endian_64(execution_payload.block_number));
        leaves[7]  = bytes32(to_little_endian_64(execution_payload.gas_limit));
        leaves[8]  = bytes32(to_little_endian_64(execution_payload.gas_used));
        leaves[9]  = bytes32(to_little_endian_64(execution_payload.timestamp));
        leaves[10] = execution_payload.extra_data;
        leaves[11] = to_little_endian_256(execution_payload.base_fee_per_gas);
        leaves[12] = execution_payload.block_hash;
        leaves[13] = execution_payload.transactions_root;
        leaves[14] = execution_payload.withdrawals_root;
        return merkle_root(leaves);
    }

    /// @notice Return little endian of uint64
    function to_little_endian_64(uint64 value) internal pure returns (bytes8) {
        return ScaleCodec.encode64(value);
    }

    /// @notice Return little endian of uint256
    function to_little_endian_256(uint256 value) internal pure returns (bytes32) {
        return ScaleCodec.encode256(value);
    }
}

////// src/spec/BeaconLightClientUpdate.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.8.17; */

/* import "./BeaconChain.sol"; */

/// @title BeaconLightClientUpdate
/// @notice Beacon light client update specification
contract BeaconLightClientUpdate is BeaconChain {
    /// @notice Sync aggregate
    /// @param sync_committee_bits Sync committee bits
    /// @param sync_committee_signature Sync committee signature
    struct SyncAggregate {
        bytes32[2] sync_committee_bits;
        bytes sync_committee_signature;
    }

    /// @notice Finalized header update
    /// @param attested_header Header attested to by the sync committee
    /// @param signature_sync_committee  Sync committee corresponding to sign attested header
    /// @param finalized_header The finalized beacon block header
    /// @param finality_branch Finalized header proof corresponding to `attested_header.state_root`
    /// @param sync_aggregate Sync committee aggregate signature
    /// @param fork_version Fork version for the aggregate signature
    /// @param signature_slot Slot at which the aggregate signature was created (untrusted)
    struct FinalizedHeaderUpdate {
        LightClientHeader attested_header;
        SyncCommittee signature_sync_committee;
        LightClientHeader finalized_header;
        bytes32[] finality_branch;
        SyncAggregate sync_aggregate;
        bytes4 fork_version;
        uint64 signature_slot;
    }

    /// @notice Sync committee period update
    /// @param next_sync_committee Next sync committee
    /// @param next_sync_committee_branch Next sync committee corresponding to `attested_header.state_root`
    struct SyncCommitteePeriodUpdate {
        SyncCommittee next_sync_committee;
        bytes32[] next_sync_committee_branch;
    }
}

////// src/utils/Bits.sol
//
// Inspired: https://github.com/ethereum/solidity-examples

/* pragma solidity 0.8.17; */

library Bits {
    uint256 private constant ONE = uint256(1);
    uint256 private constant ONES = type(uint256).max;

    // Sets the bit at the given 'index' in 'self' to '1'.
    // Returns the modified value.
    function setBit(uint256 self, uint8 index) internal pure returns (uint256) {
        return self | (ONE << index);
    }

    // Sets the bit at the given 'index' in 'self' to '0'.
    // Returns the modified value.
    function clearBit(uint256 self, uint8 index)
        internal
        pure
        returns (uint256)
    {
        return self & ~(ONE << index);
    }

    // Sets the bit at the given 'index' in 'self' to:
    //  '1' - if the bit is '0'
    //  '0' - if the bit is '1'
    // Returns the modified value.
    function toggleBit(uint256 self, uint8 index)
        internal
        pure
        returns (uint256)
    {
        return self ^ (ONE << index);
    }

    // Get the value of the bit at the given 'index' in 'self'.
    function bit(uint256 self, uint8 index) internal pure returns (uint8) {
        return uint8((self >> index) & 1);
    }

    // Check if the bit at the given 'index' in 'self' is set.
    // Returns:
    //  'true' - if the value of the bit is '1'
    //  'false' - if the value of the bit is '0'
    function bitSet(uint256 self, uint8 index) internal pure returns (bool) {
        return (self >> index) & 1 == 1;
    }

    // Checks if the bit at the given 'index' in 'self' is equal to the corresponding
    // bit in 'other'.
    // Returns:
    //  'true' - if both bits are '0' or both bits are '1'
    //  'false' - otherwise
    function bitEqual(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (bool) {
        return ((self ^ other) >> index) & 1 == 0;
    }

    // Get the bitwise NOT of the bit at the given 'index' in 'self'.
    function bitNot(uint256 self, uint8 index) internal pure returns (uint8) {
        return uint8(1 - ((self >> index) & 1));
    }

    // Computes the bitwise AND of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitAnd(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (uint8) {
        return uint8(((self & other) >> index) & 1);
    }

    // Computes the bitwise OR of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitOr(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (uint8) {
        return uint8(((self | other) >> index) & 1);
    }

    // Computes the bitwise XOR of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitXor(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (uint8) {
        return uint8(((self ^ other) >> index) & 1);
    }

    // Gets 'numBits' consecutive bits from 'self', starting from the bit at 'startIndex'.
    // Returns the bits as a 'uint'.
    // Requires that:
    //  - '0 < numBits <= 256'
    //  - 'startIndex < 256'
    //  - 'numBits + startIndex <= 256'
    function bits(
        uint256 self,
        uint8 startIndex,
        uint16 numBits
    ) internal pure returns (uint256) {
        require(0 < numBits && startIndex < 256 && startIndex + numBits <= 256);
        return (self >> startIndex) & (ONES >> (256 - numBits));
    }

    // Computes the index of the highest bit set in 'self'.
    // Returns the highest bit set as an 'uint8'.
    // Requires that 'self != 0'.
    function highestBitSet(uint256 self) internal pure returns (uint8 highest) {
        require(self != 0);
        uint256 val = self;
        unchecked {
            for (uint8 i = 128; i >= 1; i >>= 1) {
                if (val & (((ONE << i) - 1) << i) != 0) {
                    highest += i;
                    val >>= i;
                }
            }
        }
    }

    // Computes the index of the lowest bit set in 'self'.
    // Returns the lowest bit set as an 'uint8'.
    // Requires that 'self != 0'.
    function lowestBitSet(uint256 self) internal pure returns (uint8 lowest) {
        require(self != 0);
        uint256 val = self;
        unchecked {
            for (uint8 i = 128; i >= 1; i >>= 1) {
                if (val & ((ONE << i) - 1) == 0) {
                    lowest += i;
                    val >>= i;
                }
            }
        }
    }
}

////// src/utils/Bitfield.sol
//
// Inspired: https://github.com/Snowfork/snowbridge/blob/main/core/packages/contracts/contracts/utils/Bitfield.sol

/* pragma solidity 0.8.17; */

/* import "./Bits.sol"; */

contract Bitfield {
    using Bits for uint256;

    /// @dev Constants used to efficiently calculate the hamming weight of a bitfield. See
    /// https://en.wikipedia.org/wiki/Hamming_weight#Efficient_implementation for an explanation of those constants.
    uint256 private constant M1 =
        0x5555555555555555555555555555555555555555555555555555555555555555;
    uint256 private constant M2 =
        0x3333333333333333333333333333333333333333333333333333333333333333;
    uint256 private constant M4 =
        0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f;
    uint256 private constant M8 =
        0x00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff;
    uint256 private constant M16 =
        0x0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff;
    uint256 private constant M32 =
        0x00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff;
    uint256 private constant M64 =
        0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff;
    uint256 private constant M128 =
        0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;

    uint256[20] private BIG_PRIME = [
        1000003,1000033,1000037,1000039,1000081,1000099,1000117,1000121,1000133,1000151,
        1000159,1000171,1000183,1000187,1000193,1000199,1000211,1000213,1000231,1000249
    ];

    /// @notice Draws a random number, derives an index in the bitfield, and sets the bit if it is in the `prior` and not
    /// yet set. Repeats that `n` times.
    function randomNBitsWithPriorCheck(
        uint256 seed,
        uint256 prior,
        uint256 n,
        uint256 length
    ) internal view returns (uint256 bitfield) {
        require(
            n <= countSetBits(prior),
            "invalid n"
        );
        require(
            length <= 256 && n <= length,
            "invalid length"
        );

        unchecked {
            uint256 prime = BIG_PRIME[seed%20];
            uint256 begin = seed % 256;
            uint256 found = 0;

            for (uint256 i = 0; found < n; ++i) {
                uint8 index = uint8((prime * (begin + i)) % length);

                // require randomly seclected bit to be set in prior
                if ((prior >> index) & 1 == 1) {
                    bitfield = set(bitfield, index);
                    found++;
                }
            }
        }

        return bitfield;
    }

    function createBitfield(uint8[] memory bitsToSet)
        internal
        pure
        returns (uint256 bitfield)
    {
        uint256 length = bitsToSet.length;
        for (uint256 i = 0; i < length; ) {
            bitfield = set(bitfield, bitsToSet[i]);
            unchecked { ++i; }
        }

        return bitfield;
    }

    /// @notice Calculates the number of set bits by using the hamming weight of the bitfield.
    /// The alogrithm below is implemented after https://en.wikipedia.org/wiki/Hamming_weight#Efficient_implementation.
    /// Further improvements are possible, see the article above.
    function countSetBits(uint256 x) internal pure returns (uint256) {
        unchecked {
            x = (x & M1) + ((x >> 1) & M1); //put count of each  2 bits into those  2 bits
            x = (x & M2) + ((x >> 2) & M2); //put count of each  4 bits into those  4 bits
            x = (x & M4) + ((x >> 4) & M4); //put count of each  8 bits into those  8 bits
            x = (x & M8) + ((x >> 8) & M8); //put count of each 16 bits into those 16 bits
            x = (x & M16) + ((x >> 16) & M16); //put count of each 32 bits into those 32 bits
            x = (x & M32) + ((x >> 32) & M32); //put count of each 64 bits into those 64 bits
            x = (x & M64) + ((x >> 64) & M64); //put count of each 128 bits into those 128 bits
            x = (x & M128) + ((x >> 128) & M128); //put count of each 256 bits into those 256 bits
        }
        return x;
    }

    function isSet(uint256 self, uint8 index)
        internal
        pure
        returns (bool)
    {
        return self.bit(index) == 1;
    }

    function set(uint256 self, uint8 index) internal pure returns (uint256) {
        return self.setBit(index);
    }

    function clear(uint256 self, uint8 index) internal pure returns (uint256) {
        return self.clearBit(index);
    }
}

////// src/truth/eth/BeaconLightClient.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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
//
// Etherum beacon light client.
// Current arthitecture diverges from spec's proposed updated splitting them into:
// - Finalized header updates: To import a recent finalized header signed by a known sync committee by `import_finalized_header`.
// - Sync period updates: To advance to the next committee by `import_next_sync_committee`.
//
// To stay synced to the current sync period it needs:
// - Get sync_period_update at least once per period.
//
// To get light-client best finalized update at period N:
// - Fetch best finalized block's sync_aggregate_header in period N
// - Fetch parent_block/attested_block by sync_aggregate_header's parent_root
// - Fetch finalized_checkpoint_root and finalized_checkpoint_root_witness in attested_block
// - Fetch finalized_header by finalized_checkpoint_root
//
// - sync_aggregate -> parent_block/attested_block -> finalized_checkpoint -> finalized_header
//
// To get light-client sync period update at period N:
// - Fetch the finalized_header in light-client
// - Fetch the finalized_block by finalized_header.slot
// - Fetch next_sync_committee and next_sync_committee_witness in finalized_block
//
// - finalized_header -> next_sync_committee
//
// ```
//                       Finalized               Block   Sync
//                       Checkpoint              Header  Aggreate
// ----------------------|-----------------------|-------|---------> time
//                        <---------------------   <----
//                         finalizes               signs
// ```
//
// To initialize, it needs:
// - BLS verify contract
// - Trust finalized_header
// - current_sync_committee of the trust finalized_header
// - genesis_validators_root of genesis state
//
// When to trigger a committee update sync:
//
//  period 0         period 1         period 2
// -|----------------|----------------|----------------|-> time
//              | now
//               - active current_sync_committee
//               - known next_sync_committee, signed by current_sync_committee
//
//
// next_sync_committee can be imported at any time of the period, not strictly at the period borders.
// - No need to query for period 0 next_sync_committee until the end of period 0
// - After the import next_sync_committee of period 0, populate period 1's committee
//
// Inspired: https://github.com/ethereum/annotated-spec/blob/master/altair/sync-protocol.md

/* pragma solidity 0.8.17; */

/* import "../../interfaces/ILightClient.sol"; */
/* import "../../utils/Bitfield.sol"; */
/* import "../../spec/BeaconLightClientUpdate.sol"; */

interface IBLS {
    function fast_aggregate_verify(
        bytes[] calldata pubkeys,
        bytes calldata message,
        bytes calldata signature
    ) external pure returns (bool);
}

contract BeaconLightClient is ILightClient, BeaconLightClientUpdate, Bitfield {
    /// @dev Finalized beacon block header
    BeaconBlockHeader public finalized_header;
    /// @dev Finalized execution payload header block_number corresponding to `beacon.body_root` [New in Capella]
    uint256 private finalized_execution_payload_header_block_number;
    /// @dev Finalized execution payload header state_root corresponding to `beacon.body_root` [New in Capella]
    bytes32 private finalized_execution_payload_header_state_root;
    /// @dev Sync committees corresponding to the header
    /// sync_committee_perid => sync_committee_root
    mapping (uint64 => bytes32) public sync_committee_roots;

    /// @dev bls12-381 precompile address(0x0800)
    address private immutable BLS_PRECOMPILE;
    /// @dev Beacon chain genesis validators root
    bytes32 public immutable GENESIS_VALIDATORS_ROOT;
    // A bellatrix beacon state has 25 fields, with a depth of 5.
    // | field                               | gindex | depth |
    // | ----------------------------------- | ------ | ----- |
    // | execution_payload                   | 25     | 4     |
    // | next_sync_committee                 | 55     | 5     |
    // | finalized_checkpoint_root           | 105    | 6     |
    uint64 constant private EXECUTION_PAYLOAD_INDEX          = 25;
    uint64 constant private EXECUTION_PAYLOAD_DEPTH          = 4;
    uint64 constant private NEXT_SYNC_COMMITTEE_INDEX        = 55;
    uint64 constant private NEXT_SYNC_COMMITTEE_DEPTH        = 5;
    uint64 constant private FINALIZED_CHECKPOINT_ROOT_INDEX  = 105;
    uint64 constant private FINALIZED_CHECKPOINT_ROOT_DEPTH  = 6;
    uint64 constant private SLOTS_PER_EPOCH                  = 32;
    uint64 constant private EPOCHS_PER_SYNC_COMMITTEE_PERIOD = 256;
    bytes4 constant private DOMAIN_SYNC_COMMITTEE            = 0x07000000;

    event FinalizedHeaderImported(BeaconBlockHeader finalized_header);
    event NextSyncCommitteeImported(uint64 indexed period, bytes32 indexed sync_committee_root);
    event FinalizedExecutionPayloadHeaderImported(uint256 block_number, bytes32 state_root);

    constructor(
        address _bls,
        uint64 _slot,
        uint64 _proposer_index,
        bytes32 _parent_root,
        bytes32 _state_root,
        bytes32 _body_root,
        bytes32 _current_sync_committee_hash,
        bytes32 _genesis_validators_root
    ) {
        BLS_PRECOMPILE = _bls;
        finalized_header = BeaconBlockHeader(_slot, _proposer_index, _parent_root, _state_root, _body_root);
        sync_committee_roots[compute_sync_committee_period(_slot)] = _current_sync_committee_hash;
        GENESIS_VALIDATORS_ROOT = _genesis_validators_root;
    }

    /// @dev Return beacon light client finalized header's slot
    /// @return slot
    function slot() public view returns (uint64) {
        return finalized_header.slot;
    }

    /// @dev Return execution payload block number
    /// @return block number
    function block_number() public view override returns (uint256) {
        return finalized_execution_payload_header_block_number;
    }

    /// @dev Return execution payload state root
    /// @return merkle root
    function merkle_root() public view override returns (bytes32) {
        return finalized_execution_payload_header_state_root;
    }

    /// @dev follow beacon api: /beacon/light_client/updates/?start_period={period}&count={count}
    function import_next_sync_committee(
        FinalizedHeaderUpdate calldata header_update,
        SyncCommitteePeriodUpdate calldata sc_update
    ) external {
        require(is_supermajority(header_update.sync_aggregate.sync_committee_bits), "!supermajor");
        require(header_update.signature_slot > header_update.attested_header.beacon.slot &&
                header_update.attested_header.beacon.slot >= header_update.finalized_header.beacon.slot,
                "!skip");
        verify_light_client_header(header_update);

        uint64 attested_period = compute_sync_committee_period(header_update.attested_header.beacon.slot);
        uint64 finalized_period = compute_sync_committee_period(header_update.finalized_header.beacon.slot);
        uint64 signature_period = compute_sync_committee_period(header_update.signature_slot);
        require(signature_period == finalized_period &&
                finalized_period == attested_period,
                "!period");

        bytes32 singature_sync_committee_root = sync_committee_roots[signature_period];
        require(singature_sync_committee_root != bytes32(0), "!missing");
        require(singature_sync_committee_root == hash_tree_root(header_update.signature_sync_committee), "!sync_committee");

        require(verify_signed_header(
                header_update.sync_aggregate,
                header_update.signature_sync_committee,
                header_update.fork_version,
                header_update.attested_header.beacon),
                "!sign");

        if (header_update.finalized_header.beacon.slot > finalized_header.slot) {
            apply_light_client_update(header_update);
        }

        bytes32 next_sync_committee_root = hash_tree_root(sc_update.next_sync_committee);
        require(verify_next_sync_committee(
                next_sync_committee_root,
                sc_update.next_sync_committee_branch,
                header_update.attested_header.beacon.state_root),
                "!next_sync_committee"
        );

        uint64 next_period = signature_period + 1;
        require(sync_committee_roots[next_period] == bytes32(0), "imported");
        sync_committee_roots[next_period] = next_sync_committee_root;
        emit NextSyncCommitteeImported(next_period, next_sync_committee_root);
    }

    /// @dev follow beacon api: /eth/v1/beacon/light_client/finality_update/
    function import_finalized_header(FinalizedHeaderUpdate calldata update) external {
        require(is_supermajority(update.sync_aggregate.sync_committee_bits), "!supermajor");
        require(update.signature_slot > update.attested_header.beacon.slot &&
                update.attested_header.beacon.slot >= update.finalized_header.beacon.slot,
                "!skip");
        verify_light_client_header(update);

        uint64 finalized_period = compute_sync_committee_period(finalized_header.slot);
        uint64 signature_period = compute_sync_committee_period(update.signature_slot);
        require(signature_period == finalized_period ||
                signature_period == finalized_period + 1,
                "!signature_period");
        bytes32 singature_sync_committee_root = sync_committee_roots[signature_period];

        require(singature_sync_committee_root != bytes32(0), "!missing");
        require(singature_sync_committee_root == hash_tree_root(update.signature_sync_committee), "!sync_committee");

        require(verify_signed_header(
                update.sync_aggregate,
                update.signature_sync_committee,
                update.fork_version,
                update.attested_header.beacon),
                "!sign");

        require(update.finalized_header.beacon.slot > finalized_header.slot, "!new");
        apply_light_client_update(update);
    }

    function verify_signed_header(
        SyncAggregate calldata sync_aggregate,
        SyncCommittee calldata sync_committee,
        bytes4 fork_version,
        BeaconBlockHeader calldata header
    ) internal view returns (bool) {
        // Verify sync committee aggregate signature
        uint participants = sum(sync_aggregate.sync_committee_bits);
        bytes[] memory participant_pubkeys = new bytes[](participants);
        uint64 n = 0;
        unchecked {
            for (uint64 i = 0; i < SYNC_COMMITTEE_SIZE; ++i) {
                uint index = i >> 8;
                uint sindex = i / 8 % 32;
                uint offset = i % 8;
                if (uint8(sync_aggregate.sync_committee_bits[index][sindex]) >> offset & 1 == 1) {
                    participant_pubkeys[n++] = sync_committee.pubkeys[i];
                }
            }
        }

        bytes32 domain = compute_domain(DOMAIN_SYNC_COMMITTEE, fork_version, GENESIS_VALIDATORS_ROOT);
        bytes32 signing_root = compute_signing_root(header, domain);
        bytes memory message = abi.encodePacked(signing_root);
        bytes memory signature = sync_aggregate.sync_committee_signature;
        require(signature.length == BLSSIGNATURE_LENGTH, "!signature");
        return IBLS(BLS_PRECOMPILE).fast_aggregate_verify(participant_pubkeys, message, signature);
    }

    function apply_light_client_update(FinalizedHeaderUpdate calldata update) internal {
        finalized_header = update.finalized_header.beacon;
        finalized_execution_payload_header_block_number = update.finalized_header.execution.block_number;
        finalized_execution_payload_header_state_root = update.finalized_header.execution.state_root;
        emit FinalizedHeaderImported(update.finalized_header.beacon);
        emit FinalizedExecutionPayloadHeaderImported(
            update.finalized_header.execution.block_number
            , update.finalized_header.execution.state_root
        );
    }

    function verify_light_client_header(FinalizedHeaderUpdate calldata update) internal pure {
        require(verify_finalized_header(
                update.finalized_header.beacon,
                update.finality_branch,
                update.attested_header.beacon.state_root),
                "!finalized_header"
        );
        require(verify_execution_payload(
                update.attested_header.execution,
                update.attested_header.execution_branch,
                update.attested_header.beacon.body_root),
                "!attested_header_execution"
        );
        require(verify_execution_payload(
                update.finalized_header.execution,
                update.finalized_header.execution_branch,
                update.finalized_header.beacon.body_root),
                "!finalized_header_execution"
        );
    }

    function verify_finalized_header(
        BeaconBlockHeader calldata header,
        bytes32[] calldata finality_branch,
        bytes32 attested_header_state_root
    ) internal pure returns (bool) {
        require(finality_branch.length == FINALIZED_CHECKPOINT_ROOT_DEPTH, "!finality_branch");
        return is_valid_merkle_branch(
            hash_tree_root(header),
            finality_branch,
            FINALIZED_CHECKPOINT_ROOT_DEPTH,
            FINALIZED_CHECKPOINT_ROOT_INDEX,
            attested_header_state_root
        );
    }

    function verify_execution_payload(
        ExecutionPayloadHeader calldata header,
        bytes32[] calldata execution_branch,
        bytes32 beacon_header_body_root
    ) internal pure returns (bool) {
        require(execution_branch.length == EXECUTION_PAYLOAD_DEPTH, "!execution_branch");
        return is_valid_merkle_branch(
            hash_tree_root(header),
            execution_branch,
            EXECUTION_PAYLOAD_DEPTH,
            EXECUTION_PAYLOAD_INDEX,
            beacon_header_body_root
        );
    }

    function verify_next_sync_committee(
        bytes32 next_sync_committee_root,
        bytes32[] calldata next_sync_committee_branch,
        bytes32 header_state_root
    ) internal pure returns (bool) {
        require(next_sync_committee_branch.length == NEXT_SYNC_COMMITTEE_DEPTH, "!next_sync_committee_branch");
        return is_valid_merkle_branch(
            next_sync_committee_root,
            next_sync_committee_branch,
            NEXT_SYNC_COMMITTEE_DEPTH,
            NEXT_SYNC_COMMITTEE_INDEX,
            header_state_root
        );
    }

    function is_supermajority(bytes32[2] calldata sync_committee_bits) internal pure returns (bool) {
        return sum(sync_committee_bits) * 3 >= SYNC_COMMITTEE_SIZE * 2;
    }

    function compute_sync_committee_period(uint64 slot_) internal pure returns (uint64) {
        return slot_ / SLOTS_PER_EPOCH / EPOCHS_PER_SYNC_COMMITTEE_PERIOD;
    }

    function sum(bytes32[2] memory x) internal pure returns (uint256) {
        return countSetBits(uint(x[0])) + countSetBits(uint(x[1]));
    }
}

