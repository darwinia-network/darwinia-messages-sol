// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

import "../munged/BeaconLightClient.f.sol";

contract BeaconLightClientHarness is BeaconLightClient {
    constructor(
        address _bls,
        uint64 _slot,
        uint64 _proposer_index,
        bytes32 _parent_root,
        bytes32 _state_root,
        bytes32 _body_root,
        bytes32 _current_sync_committee_hash,
        bytes32 _genesis_validators_root
    ) BeaconLightClient(
        _bls,
        _slot,
        _proposer_index,
        _parent_root,
        _state_root,
        _body_root,
        _current_sync_committee_hash,
        _genesis_validators_root
    ){}

    FinalizedHeaderUpdate finalized_header_update;
    // SyncCommitteePeriodUpdate sync_committee_update;
    // function call_ip_next_sync_committee() external {
    //     import_next_sync_committee(
    //         finalized_header_update,
    //         sync_committee_update
    //     );
    // }

    function call_ip_finalized_header() external {
        import_finalized_header(finalized_header_update);
    }
}
