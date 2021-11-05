// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

interface ILightClientBridge {
    function verifyBeefyMerkleLeaf(
        bytes32 beefyMMRLeafHash,
        uint256 beefyMMRLeafIndex,
        uint256 beefyMMRLeafCount,
        bytes32[] calldata peaks,
        bytes32[] calldata siblings
    ) external view returns (bool);

    function getFinalizedBlockNumber() external view returns (uint256);

    function validate_messages_match_root(
        bytes32 lane_hash,
        uint256 chain_pos,
        uint256 lane_pos,
        bytes calldata proof
    ) external view returns (bool);
}
