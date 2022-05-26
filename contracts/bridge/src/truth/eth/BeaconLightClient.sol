// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../utils/Bytes.sol";
import "../../utils/Bitfield.sol";
import "../../spec/BeaconChain.sol";
import "../../spec/ChainMessagePosition.sol";
import "../common/StorageVerifier.sol";

interface IBLS {
        function fast_aggregate_verify(
            bytes[] calldata pubkeys,
            bytes calldata message,
            bytes calldata signature
        ) external pure returns (bool);
}

contract BeaconLightClient is BeaconChain, Bitfield, StorageVerifier {
    using Bytes for bytes;

    // address(0x1c)
    address private immutable BLS_PRECOMPILE;

    // TODO: check
    uint64 constant private NEXT_SYNC_COMMITTEE_INDEX = 55;
    uint64 constant private NEXT_SYNC_COMMITTEE_DEPTH = 5;

    uint64 constant private LATEST_EXECUTION_PAYLOAD_STATE_ROOT_INDEX = 898;
    uint64 constant private LATEST_EXECUTION_PAYLOAD_STATE_ROOT_DEPTH = 9;

    uint64 constant private FINALIZED_ROOT_INDEX = 105;
    uint64 constant private FINALIZED_ROOT_DEPTH = 6;

    uint64 constant private EPOCHS_PER_SYNC_COMMITTEE_PERIOD = 256;
    uint64 constant private SLOTS_PER_EPOCH = 32;

    uint64 constant private MIN_SYNC_COMMITTEE_PARTICIPANTS = 1;

    bytes4 constant private DOMAIN_SYNC_COMMITTEE = 0x07000000;

    bytes32 constant private EMPTY_BEACON_HEADER_HASH = 0xc78009fdf07fc56a11f122370658a353aaa542ed63e44c4bc15ff4cd105ab33c;

    struct SyncAggregate {
        uint256[2] sync_committee_bits;
        bytes sync_committee_signature;
    }


    struct LightClientUpdate {
        // The beacon block header that is attested to by the sync committee
        BeaconBlockHeader attested_header;

        // Current sync committee corresponding to the attested header
        SyncCommittee current_sync_committee;

        // Next sync committee corresponding to the active header
        SyncCommittee next_sync_committee;
        bytes32[] next_sync_committee_branch;

        // The finalized beacon block header attested to by Merkle branch
        BeaconBlockHeader finalized_header;
        bytes32[] finality_branch;

        // Execution payload header in beacon state [New in Bellatrix]
        bytes32 latest_execution_payload_state_root;
        bytes32[] latest_execution_payload_state_root_branch;

        // Sync committee aggregate signature
        SyncAggregate sync_aggregate;

        // Fork version for the aggregate signature
        bytes4 fork_version;
    }

    // Beacon block header that is finalized
    BeaconBlockHeader finalized_header;

    // Sync committees corresponding to the header
    bytes32 current_sync_committee_hash;
    bytes32 next_sync_committee_hash;

    // Execution payload state root
    bytes32 latest_execution_payload_state_root;

    // // Best available header to switch finalized head to if we see nothing else
    // LightClientUpdate best_valid_update;
    // // Most recent available reasonably-safe header
    // BeaconBlockHeader optimistic_header;
    // // Max number of active participants in a sync committee (used to calculate safety threshold)
    // uint64 previous_max_active_participants;
    // uint64 current_max_active_participants;

    constructor(
        address _bls,
        uint64 _slot,
        uint64 _proposer_index,
        bytes32 _parent_root,
        bytes32 _state_root,
        bytes32 _body_root,
        bytes32 _current_sync_committee_hash,
        bytes32 _next_sync_committee_hash
    ) StorageVerifier(uint32(ChainMessagePosition.ETH2), 0, 1, 2) {
        BLS_PRECOMPILE = _bls;
        finalized_header = BeaconBlockHeader(_slot, _proposer_index, _parent_root, _state_root, _body_root);
        current_sync_committee_hash = _current_sync_committee_hash;
        next_sync_committee_hash = _next_sync_committee_hash;
    }

    function state_root() public view override returns (bytes32) {
        return latest_execution_payload_state_root;
    }

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
            current_sync_committee_hash = next_sync_committee_hash;
            next_sync_committee_hash = hash_tree_root(update.next_sync_committee);
        }
        finalized_header = active_header;
        latest_execution_payload_state_root = update.latest_execution_payload_state_root;
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
        require(update.finality_branch.length == FINALIZED_ROOT_DEPTH, "!finality_branch");
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
        require(update.next_sync_committee_branch.length == NEXT_SYNC_COMMITTEE_DEPTH, "!next_sync_committee_branch");
        SyncCommittee memory sync_committee = update.current_sync_committee;
        if (update_period == finalized_period) {
            require(hash_tree_root(sync_committee) == current_sync_committee_hash, "!sync_committee");
            for (uint64 i = 0; i < floorlog2(NEXT_SYNC_COMMITTEE_INDEX); ++i) {
                require(update.next_sync_committee_branch[i] == bytes32(0), "!zero");
            }
        } else {
            require(hash_tree_root(sync_committee) == next_sync_committee_hash, "!sync_committee");
            require(is_valid_merkle_branch(
                        hash_tree_root(update.next_sync_committee),
                        update.next_sync_committee_branch,
                        floorlog2(NEXT_SYNC_COMMITTEE_INDEX),
                        get_subtree_index(NEXT_SYNC_COMMITTEE_INDEX),
                        active_header.state_root
                    ),
                    "!sync_committee_branch"
            );
        }

        // Verify latest_execution_payload_state_root in finalized beacon state
        require(update.latest_execution_payload_state_root_branch.length == LATEST_EXECUTION_PAYLOAD_STATE_ROOT_DEPTH, "!execution_payload_state_root_branch");
        if (!is_finality_update(update)) {
            for (uint64 i = 0; i < floorlog2(LATEST_EXECUTION_PAYLOAD_STATE_ROOT_INDEX); ++i) {
                require(update.latest_execution_payload_state_root_branch[i] == bytes32(0), "!zero");
            }
        } else {
            require(is_valid_merkle_branch(
                    update.latest_execution_payload_state_root,
                    update.latest_execution_payload_state_root_branch,
                    floorlog2(LATEST_EXECUTION_PAYLOAD_STATE_ROOT_INDEX),
                    get_subtree_index(LATEST_EXECUTION_PAYLOAD_STATE_ROOT_INDEX),
                    active_header.state_root
                ),
                "!state_root"
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
            // TODO check
            if (isSet(sync_aggregate.sync_committee_bits[index], offset)) {
                participant_pubkeys[n++] = sync_committee.pubkeys[i];
            }
        }
        bytes32 domain = compute_domain(DOMAIN_SYNC_COMMITTEE, update.fork_version, genesis_validators_root);
        bytes32 signing_root = compute_signing_root(update.attested_header, domain);
        bytes memory message = abi.encodePacked(signing_root);
        bytes memory signature = sync_aggregate.sync_committee_signature;
        require(signature.length == BLSSIGNATURE_LENGTH, "!signature");
        require(fast_aggregate_verify(participant_pubkeys, message, signature), "!bls");
    }

    function fast_aggregate_verify(bytes[] memory pubkeys, bytes memory message, bytes memory signature) internal view returns (bool valid) {
        bytes memory input = abi.encodeWithSelector(
            IBLS.fast_aggregate_verify.selector,
            pubkeys,
            message,
            signature
        );
        (bool ok, bytes memory out) = BLS_PRECOMPILE.staticcall(input);
        if (ok) {
            if (out.length == 32) {
                valid = abi.decode(out, (bool));
            }
        } else {
            if (out.length > 0) {
                assembly {
                    let returndata_size := mload(out)
                    revert(add(32, out), returndata_size)
                }
            } else {
                revert("!verify");
            }
        }
    }

    function get_subtree_index(uint generalized_index) internal pure returns (uint64){
        return uint64(generalized_index % 2**(floorlog2(generalized_index)));
    }

    //  Return the epoch number at ``slot``.
    function compute_epoch_at_slot(uint64 slot) internal pure returns(uint64){
        return slot / SLOTS_PER_EPOCH;
    }

    function compute_sync_committee_period(uint64 epoch) internal pure returns (uint64) {
        return epoch / EPOCHS_PER_SYNC_COMMITTEE_PERIOD;
    }

    function get_active_header(LightClientUpdate calldata update) internal pure returns (BeaconBlockHeader memory){
        // The "active header" is the header that the update is trying to convince us
        // to accept. If a finalized header is present, it's the finalized header,
        // otherwise it's the attested header
        if(is_finality_update(update)) return update.finalized_header;
        else return update.attested_header;
    }

    function is_finality_update(LightClientUpdate calldata update) internal pure returns (bool) {
        return hash_tree_root(update.finalized_header) != EMPTY_BEACON_HEADER_HASH;
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
