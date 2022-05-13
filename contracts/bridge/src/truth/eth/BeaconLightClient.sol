// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../utils/Bitfield.sol";
import "../../utils/Bytes.sol";

interface BLS {
        function FastAggregateVerify(
            bytes[] calldata pubkeys,
            bytes calldata message,
            bytes32[3] calldata signature
        ) external pure returns (bool);
}

contract BeaconLightClient is Bitfield {
    using Bytes for bytes;

    address constant private bls = address(0x1b);

    // TODO: check
    uint64 constant private SYNC_COMMITTEE_SIZE = 512;
    uint64 constant private NEXT_SYNC_COMMITTEE_INDEX = 23;
    uint64 constant private NEXT_SYNC_COMMITTEE_DEPTH = 5;

    uint64 constant private FINALIZED_ROOT_INDEX = 41;
    uint64 constant private FINALIZED_ROOT_DEPTH = 6;

    uint64 constant private EPOCHS_PER_SYNC_COMMITTEE_PERIOD = 256;
    uint64 constant private SLOTS_PER_EPOCH = 32;

    uint64 constant private MIN_SYNC_COMMITTEE_PARTICIPANTS = 1;

    bytes4 constant private DOMAIN_SYNC_COMMITTEE = 0x07000000;

    struct ForkData {
        bytes4 current_version;
        bytes32 genesis_validators_root;
    }

    struct SigningData {
        bytes32 object_root;
        bytes32 domain;
    }

    struct SyncAggregate {
        uint256[2] sync_committee_bits;
        bytes32[3] sync_committee_signature;
    }

    struct SyncCommittee {
        bytes serialized_pubkeys;
        bytes aggregate_pubkey;
    }

    struct BeaconBlockHeader {
        uint64 slot;
        uint64 proposer_index;
        bytes32 parent_root;
        bytes32 state_root;
        bytes32 body_root;
    }

    struct LightClientUpdate {
        // The beacon block header that is attested to by the sync committee
        BeaconBlockHeader attested_header;

        // Next sync committee corresponding to the active header
        SyncCommittee next_sync_committee;
        bytes32[] next_sync_committee_branch;

        // The finalized beacon block header attested to by Merkle branch
        BeaconBlockHeader finalized_header;
        bytes32[] finality_branch;

        // Sync committee aggregate signature
        SyncAggregate sync_aggregate;

        // Fork version for the aggregate signature
        bytes4 fork_version;
    }

    // Beacon block header that is finalized
    BeaconBlockHeader finalized_header;
    // Sync committees corresponding to the header
    SyncCommittee current_sync_committee;
    SyncCommittee next_sync_committee;

    // // Best available header to switch finalized head to if we see nothing else
    // LightClientUpdate best_valid_update;
    // // Most recent available reasonably-safe header
    // BeaconBlockHeader optimistic_header;
    // // Max number of active participants in a sync committee (used to calculate safety threshold)
    // uint64 previous_max_active_participants;
    // uint64 current_max_active_participants;

    function process_light_client_update(
        LightClientUpdate calldata update,
        bytes32 genesis_validators_root
    ) external payable {
        validate_light_client_update(update, genesis_validators_root);
        uint256[2] memory sync_committee_bits = update.sync_aggregate.sync_committee_bits;
        // Update finalized header
        if (
            sum(sync_committee_bits) * 3 >= SYNC_COMMITTEE_SIZE * 2
            && is_finality_update(update)
        ) {
            // Normal update through 2/3 threshold
            apply_light_client_update(update);
            // store.best_valid_update = None
        }
    }

    function apply_light_client_update(LightClientUpdate calldata update) internal {
        BeaconBlockHeader memory active_header = get_active_header(update);
        uint64 finalized_period = compute_sync_committee_period(compute_epoch_at_slot(finalized_header.slot));
        uint64 update_period = compute_sync_committee_period(compute_epoch_at_slot(active_header.slot));
        if (update_period == finalized_period + 1) {
            current_sync_committee = next_sync_committee;
            next_sync_committee = next_sync_committee;
        }
        finalized_header = active_header;
        // if store.finalized_header.slot > store.optimistic_header.slot:
        //     store.optimistic_header = store.finalized_header
    }

    function validate_light_client_update(
        LightClientUpdate calldata update,
        bytes32 genesis_validators_root
    ) internal view {
        // Verify update slot is larger than slot of current best finalized header
        BeaconBlockHeader memory active_header = get_active_header(update);
        require(active_header.slot > finalized_header.slot, "!update");

        // Verify update does not skip a sync committee period
        uint64 finalized_period = compute_sync_committee_period(compute_epoch_at_slot(finalized_header.slot));
        uint64 update_period = compute_sync_committee_period(compute_epoch_at_slot(active_header.slot));
        require(update_period == finalized_period ||
                update_period == finalized_period + 1,
               "!period");

        // Verify that the `finalized_header`, if present, actually is the finalized header saved in the
        // state of the `attested header`
        require(update.finality_branch.length == FINALIZED_ROOT_DEPTH - 1, "!finality_branch");
        if (!is_finality_update(update)) {
            for (uint64 i = 0; i < floorlog2(FINALIZED_ROOT_INDEX); ++i) {
                require(update.finality_branch[i] == bytes32(0), "!zero");
            }
        } else {
            require(is_valid_merkle_branch(
                        hash_tree_root(update.finalized_header),
                        update.finality_branch,
                        floorlog2(FINALIZED_ROOT_INDEX),
                        get_subtree_index(FINALIZED_ROOT_INDEX),
                        update.attested_header.state_root
                    ),
                    "!finalized_header"
            );
        }

        // Verify update next sync committee if the update period incremented
        require(update.next_sync_committee_branch.length == NEXT_SYNC_COMMITTEE_DEPTH - 1, "!next_sync_committee_branch");
        SyncCommittee memory sync_committee;
        if (update_period == finalized_period) {
            sync_committee = current_sync_committee;
            for (uint64 i = 0; i < floorlog2(NEXT_SYNC_COMMITTEE_INDEX); ++i) {
                require(update.next_sync_committee_branch[i] == bytes32(0), "!zero");
            }
        } else {
            sync_committee = next_sync_committee;
            require(is_valid_merkle_branch(
                        hash_tree_root(update.next_sync_committee),
                        update.next_sync_committee_branch,
                        floorlog2(NEXT_SYNC_COMMITTEE_INDEX),
                        get_subtree_index(NEXT_SYNC_COMMITTEE_INDEX),
                        active_header.state_root
                    ),
                    "!sync_committee"
            );
        }
        SyncAggregate memory sync_aggregate = update.sync_aggregate;

        // Verify sync committee has sufficient participants
        require(sum(sync_aggregate.sync_committee_bits) >= MIN_SYNC_COMMITTEE_PARTICIPANTS, "!participants");

        // Verify sync committee aggregate signature
        uint participants = sum(sync_aggregate.sync_committee_bits);
        bytes[] memory participant_pubkeys = new bytes[](participants);
        uint64 n = 0;
        for (uint64 i = 0; i < SYNC_COMMITTEE_SIZE; ++i) {
            uint index = i / 256;
            uint8 offset = uint8(i % 256);
            if (isSet(sync_aggregate.sync_committee_bits[index], offset)) {
                participant_pubkeys[n++] = sync_committee.serialized_pubkeys.substr(i * 48, 48);
            }
        }
        bytes32 domain = compute_domain(DOMAIN_SYNC_COMMITTEE, update.fork_version, genesis_validators_root);
        bytes32 signing_root = compute_signing_root(update.attested_header, domain);
        bytes memory message = abi.encode(signing_root);
        require(BLS(bls).FastAggregateVerify(participant_pubkeys, message, sync_aggregate.sync_committee_signature), "!sig");
    }

    // Check if ``leaf`` at ``index`` verifies against the Merkle ``root`` and ``branch``.
    function is_valid_merkle_branch(
        bytes32 leaf,
        bytes32[] memory branch,
        uint64 depth,
        uint64 index,
        bytes32 root
    ) internal pure returns (bool) {
        bytes32 value = leaf;
        for (uint i = 0; i < depth; ++i) {
            if ((index / (2**i)) % 2 == 1) {
                value = hash_node(branch[i], value);
            } else {
                value = hash_node(value, branch[i]);
            }
        }
        return value == root;
    }

    function get_subtree_index(uint generalized_index) internal pure returns (uint64){
        return uint64(generalized_index % 2**(floorlog2(generalized_index)));
    }

    // Return the signing root for the corresponding signing data.
    function compute_signing_root(BeaconBlockHeader calldata beacon_header, bytes32 domain) internal pure returns (bytes32){
        return hash_tree_root(SigningData({
                object_root: hash_tree_root(beacon_header),
                domain: domain
            })
        );
    }

    // Return the 32-byte fork data root for the ``current_version`` and ``genesis_validators_root``.
    // This is used primarily in signature domains to avoid collisions across forks/chains.
    function compute_fork_data_root(bytes4 current_version, bytes32 genesis_validators_root) internal pure returns (bytes32){
        return hash_tree_root(ForkData({
                current_version: current_version,
                genesis_validators_root: genesis_validators_root
            })
        );
    }

    //  Return the domain for the ``domain_type`` and ``fork_version``.
    function compute_domain(bytes4 domain_type, bytes4 fork_version, bytes32 genesis_validators_root) internal pure returns (bytes32){
        bytes32 fork_data_root = compute_fork_data_root(fork_version, genesis_validators_root);
        return bytes32(domain_type) | fork_data_root >> 32;
    }

    //  Return the epoch number at ``slot``.
    function compute_epoch_at_slot(uint64 slot) internal pure returns(uint64){
        return slot / SLOTS_PER_EPOCH;
    }

    function compute_sync_committee_period(uint64 epoch) internal pure returns (uint64) {
        return epoch / EPOCHS_PER_SYNC_COMMITTEE_PERIOD;
    }

    function get_active_header(LightClientUpdate calldata update) internal view returns (BeaconBlockHeader memory){
        // The "active header" is the header that the update is trying to convince us
        // to accept. If a finalized header is present, it's the finalized header,
        // otherwise it's the attested header
        if(is_finality_update(update)) return update.finalized_header;
        else return update.attested_header;
    }

    function is_finality_update(LightClientUpdate calldata update) internal view returns (bool) {
        return hash_tree_root(update.finalized_header) != hash_tree_root(finalized_header);
    }

    function sum(uint256[2] memory x) internal pure returns (uint256) {
        return countSetBits(x[0]) + countSetBits(x[1]);
    }

    // Find the log base 2 of an integer with the MSB N set in O(N) operations
    function floorlog2(uint x) internal pure returns (uint64 r) {
        require(x > 0, "!positive");
        while ((x >>= 1) > 0) {
            r++;
        }
    }

    function hash_tree_root(BeaconBlockHeader memory beacon_header) internal pure returns (bytes32) {
        bytes32[] memory leaves = new bytes32[](5);
        leaves[0] = bytes32(to_little_endian_64(beacon_header.slot));
        leaves[1] = bytes32(to_little_endian_64(beacon_header.proposer_index));
        leaves[2] = beacon_header.parent_root;
        leaves[3] = beacon_header.state_root;
        leaves[4] = beacon_header.body_root;
        return merkle_root(leaves);
    }

    function hash_tree_root(SyncCommittee memory sync_committee) internal pure returns (bytes32) {
        bytes memory pubkeys_chunks = sync_committee.serialized_pubkeys;
        bytes32[] memory pubkeys_leaves = new bytes32[](768);
        for (uint i = 0; i < 768 * 32; i += 32) {
            bytes memory key = pubkeys_chunks.substr(i, 32);
            pubkeys_leaves[i] = abi.decode(key, (bytes32));
        }
        bytes32 pubkeys_root = merkle_root(pubkeys_leaves);

        bytes memory aggregate_pubkey_leaves = abi.encodePacked(sync_committee.aggregate_pubkey, bytes16(0));
        bytes32 aggregate_pubkey_root = keccak256(aggregate_pubkey_leaves);

        return hash_node(pubkeys_root, aggregate_pubkey_root);
    }

    function hash_tree_root(SigningData memory signing_data) internal pure returns (bytes32) {
        return hash_node(signing_data.object_root, signing_data.domain);
    }

    function hash_tree_root(ForkData memory fork_data) internal pure returns (bytes32) {
        return hash_node(bytes32(fork_data.current_version), fork_data.genesis_validators_root);
    }

    function merkle_root(bytes32[] memory leaves) internal pure returns (bytes32) {
        uint len = leaves.length;
        if (len == 0) return bytes32(0);
        else if (len == 1) return keccak256(abi.encodePacked(leaves[0]));
        else if (len == 2) return hash_node(leaves[0], leaves[1]);
        uint bottom_length = get_power_of_two_ceil(len);
        bytes32[] memory o = new bytes32[](bottom_length * 2);
        for (uint i = 0; i < bottom_length * 2; ++i) {
            o[bottom_length + i] = leaves[i];
        }
        for (uint i = bottom_length - 1; i >= 0; --i) {
            o[i] = hash_node(o[i * 2], o[i * 2 + 1]);
        }
        return o[1];
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

    //  Get the power of 2 for given input, or the closest higher power of 2 if the input is not a power of 2.
    function get_power_of_two_ceil(uint x) internal pure returns(uint){
        if(x <= 1) return 1;
        else if(x == 2) return 2;
        else return 2 * get_power_of_two_ceil((x + 1) >> 2);
    }

    function to_little_endian_64(uint64 value) internal pure returns (bytes8 r) {
        ret = new bytes(8);
        bytes8 bytesValue = bytes8(value);
        // Byteswapping during copying to bytes.
        ret[0] = bytesValue[7];
        ret[1] = bytesValue[6];
        ret[2] = bytesValue[5];
        ret[3] = bytesValue[4];
        ret[4] = bytesValue[3];
        ret[5] = bytesValue[2];
        ret[6] = bytesValue[1];
        ret[7] = bytesValue[0];

        r = abi.decode(ret, (bytes8));
    }
}
