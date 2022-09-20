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

import "./BeaconLightClient.sol";
import "./ExecutionLayer.sol";

contract BeaconLCMandatoryReward {
    uint256 public reward;
    address public setter;
    address public consensusLayer;
    address public executionLayer;

    modifier onlySetter {
        require(msg.sender == setter, "forbidden");
        _;
    }

    constructor(address consensusLayer_, address executionLayer_, uint256 reward_) {
        reward = reward_;
        consensusLayer = consensusLayer_;
        executionLayer = executionLayer_;
    }

    receive() external payable {}

    function import_mandatory_header(
        BeaconLightClient.FinalizedHeaderUpdate calldata beaconHeaderUpdate,
        BeaconLightClient.SyncCommitteePeriodUpdate calldata beaconSCUpdate,
        ExecutionLayer.ExecutionPayloadStateRootUpdate calldata executionUpdate
    ) external payable {
        BeaconLightClient(consensusLayer).import_finalized_header(beaconHeaderUpdate);
        BeaconLightClient(consensusLayer).import_next_sync_committee(beaconSCUpdate);
        ExecutionLayer(executionLayer).import_latest_execution_payload_state_root(executionUpdate);

        payable(msg.sender).transfer(reward);
    }

    function changeReward(uint reward_) external onlySetter {
        reward = reward_;
    }

    function changeLightClient(address consensusLayer_, address executionLayer_) external onlySetter {
        consensusLayer = consensusLayer_;
        executionLayer = executionLayer_;
    }

    function withdraw(uint wad) public onlySetter {
        payable(setter).transfer(wad);
    }
}
