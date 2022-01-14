// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILightClient {
    function verify_messages_proof(
        bytes32 outlane_data_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external view returns (bool);

    function verify_messages_delivery_proof(
        bytes32 inlane_data_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external view returns (bool);
}
