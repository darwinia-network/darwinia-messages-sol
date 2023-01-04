// hevm: flattened sources of src/truth/eth/BeaconLCMandatoryReward.sol
// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.17;

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

    function _max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
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

    /// @notice Beacon block body
    /// @param randao_reveal Randao reveal
    /// @param eth1_data Eth1 data vote
    /// @param graffiti Arbitrary data
    /// @param proposer_slashings Proposer slashings
    /// @param attester_slashings Attester slashings
    /// @param attestations Attestations
    /// @param deposits Deposits
    /// @param voluntary_exits Voluntary exits
    /// @param sync_aggregate Sync aggregate
    /// @param execution_payload Execution payload [New in Bellatrix]
    struct BeaconBlockBody {
        bytes32 randao_reveal;
        bytes32 eth1_data;
        bytes32 graffiti;
        bytes32 proposer_slashings;
        bytes32 attester_slashings;
        bytes32 attestations;
        bytes32 deposits;
        bytes32 voluntary_exits;
        bytes32 sync_aggregate;
        ExecutionPayload execution_payload;
    }

    /// @notice Execution payload, execution block header fields
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
    /// @param transactions Transactions
    struct ExecutionPayload {
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
        bytes32 transactions;
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

    /// @notice Return hash tree root of beacon block body
    function hash_tree_root(BeaconBlockBody memory beacon_block_body) internal pure returns (bytes32) {
        bytes32[] memory leaves = new bytes32[](10);
        leaves[0] = beacon_block_body.randao_reveal;
        leaves[1] = beacon_block_body.eth1_data;
        leaves[2] = beacon_block_body.graffiti;
        leaves[3] = beacon_block_body.proposer_slashings;
        leaves[4] = beacon_block_body.attester_slashings;
        leaves[5] = beacon_block_body.attestations;
        leaves[6] = beacon_block_body.deposits;
        leaves[7] = beacon_block_body.voluntary_exits;
        leaves[8] = beacon_block_body.sync_aggregate;
        leaves[9] = hash_tree_root(beacon_block_body.execution_payload);
        return merkle_root(leaves);
    }

    /// @notice Return hash tree root of execution payload
    function hash_tree_root(ExecutionPayload memory execution_payload) internal pure returns (bytes32) {
        bytes32[] memory leaves = new bytes32[](14);
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
        leaves[13] = execution_payload.transactions;
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
    /// @param finality_branch Finalized header corresponding to `attested_header.state_root`
    /// @param sync_aggregate Sync committee aggregate signature
    /// @param fork_version Fork version for the aggregate signature
    /// @param signature_slot Slot at which the aggregate signature was created (untrusted)
    struct FinalizedHeaderUpdate {
        BeaconBlockHeader attested_header;
        SyncCommittee signature_sync_committee;
        BeaconBlockHeader finalized_header;
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

////// src/truth/eth/BeaconLCMandatoryReward.sol
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

/* import "../../spec/BeaconLightClientUpdate.sol"; */

interface IBeaconLightClient {
    function import_next_sync_committee(
        BeaconLightClientUpdate.FinalizedHeaderUpdate calldata header_update,
        BeaconLightClientUpdate.SyncCommitteePeriodUpdate calldata sc_update
    ) external;
    function sync_committee_roots(uint64 period) external view returns (bytes32);
}

contract BeaconLCMandatoryReward {
    uint256 public reward;
    address public setter;
    address public consensusLayer;

    modifier onlySetter {
        require(msg.sender == setter, "forbidden");
        _;
    }

    constructor(address consensusLayer_, uint256 reward_) {
        reward = reward_;
        setter = msg.sender;
        consensusLayer = consensusLayer_;
    }

    receive() external payable {}

    function is_imported(uint64 next_period) external view returns (bool) {
        return IBeaconLightClient(consensusLayer).sync_committee_roots(next_period) != bytes32(0);
    }

    function import_mandatory_next_sync_committee_for_reward(
        BeaconLightClientUpdate.FinalizedHeaderUpdate calldata header_update,
        BeaconLightClientUpdate.SyncCommitteePeriodUpdate calldata sc_update
    ) external {
        IBeaconLightClient(consensusLayer).import_next_sync_committee(header_update, sc_update);

        payable(msg.sender).transfer(reward);
    }

    function changeReward(uint reward_) external onlySetter {
        reward = reward_;
    }

    function changeConsensusLayer(address consensusLayer_) external onlySetter {
        consensusLayer = consensusLayer_;
    }

    function withdraw(uint wad) public onlySetter {
        payable(setter).transfer(wad);
    }
}

