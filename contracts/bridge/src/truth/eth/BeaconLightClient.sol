pragma solidity 0.7.6;
pragma abicoder v2;

import "../../utils/Bitfield.sol";

contract BeaconLightClient is Bitfield {
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
        bytes32 genesis_validators_root
    }

    struct SigningData {
        bytes32 object_root;
        bytes4 domain;
    }

    // a BLS12-381 public key
    struct BLSPubkey {
        bytes32 key_a;
        bytes16 key_b;
    }

    // a BLS12-381 signature
    struct BLSSignature {
        bytes32[3] sig;
    }

    struct SyncAggregate {
        uint256[2] sync_committee_bits;
        BLSSignature sync_committee_signature;
    }

    struct SyncCommittee {
        BLSPubkey pubkeys;
        BLSPubkey[SYNC_COMMITTEE_SIZE] aggregate_pubkey;
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
        bytes32[NEXT_SYNC_COMMITTEE_DEPTH-1] next_sync_committee_branch;

        // The finalized beacon block header attested to by Merkle branch
        BeaconBlockHeader finalized_header;
        bytes32[FINALIZED_ROOT_DEPTH-1] finality_branch;

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
            // apply_light_client_update(store, update)
            // store.best_valid_update = None
        }
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
        SyncCommittee memory sync_committee;
        if update_period == finalized_period{
            sync_committee = current_sync_committee
            for (uint64 i = 0; i < floorlog2(NEXT_SYNC_COMMITTEE_INDEX); ++i) {
                require(update.next_sync_committee_branch[i] == bytes32(0), "!zero");
            }
        } else {
            sync_committee = next_sync_committee
            require(is_valid_merkle_branch(
                hash_tree_root(update.next_sync_committee),
                update.next_sync_committee_branch,
                floorlog2(NEXT_SYNC_COMMITTEE_INDEX),
                get_subtree_index(NEXT_SYNC_COMMITTEE_INDEX),
                active_header.state_root),
                "!sync_committee"
            );
        }
        SyncAggregate memory sync_aggregate = update.sync_aggregate;

        // Verify sync committee has sufficient participants
        require(sum(sync_aggregate.sync_committee_bits) >= MIN_SYNC_COMMITTEE_PARTICIPANTS, "!participants");

        // Verify sync committee aggregate signature
        uint64 participants = sum(sync_aggregate.sync_committee_bits);
        BLSPubkey[] memory participant_pubkeys = new BLSPubkey[participants];
        uint64 n = 0;
        for (uint64 i = 0; i < SYNC_COMMITTEE_SIZE; ++i) {
            uint index = i / 256;
            uint8 offset = i % 256;
            if (isSet(sync_aggregate.sync_committee_bits[index], offset)) {
                participant_pubkeys[n++] = sync_committee.pubkeys[i];
            }
        }
        bytes32 domain = compute_domain(DOMAIN_SYNC_COMMITTEE, update.fork_version, genesis_validators_root);
        bytes32 signing_root = compute_signing_root(update.attested_header, domain);
        require(BLS.FastAggregateVerify(participant_pubkeys, signing_root, sync_aggregate.sync_committee_signature), "!sig");
    }

    // Return the signing root for the corresponding signing data.
    function compute_signing_root(BeaconBlockHeader calldata beacon_header, domain: Domain) internal pure returns (bytes32){
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
        return abi.encodePacked(
            domain_type,
            bytes28(fork_data_root >> 32);
        );
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
}
