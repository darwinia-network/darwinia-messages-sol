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

interface IBeaconLightClient {
    struct SyncCommittee {
        bytes[512] pubkeys;
        bytes aggregate_pubkey;
    }

    struct SyncCommitteePeriodUpdate {
        SyncCommittee next_sync_committee;
        bytes32[] next_sync_committee_branch;
    }

    function import_next_sync_committee(SyncCommitteePeriodUpdate calldata update) external;
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
        IBeaconLightClient.SyncCommitteePeriodUpdate calldata update
    ) external {
        IBeaconLightClient(consensusLayer).import_next_sync_committee(update);

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
