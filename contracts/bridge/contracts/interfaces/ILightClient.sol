// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

interface ILightClient {
    function verify_lane_data_proof(
        bytes32 lane_data_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata proof
    ) external view returns (bool);
}
