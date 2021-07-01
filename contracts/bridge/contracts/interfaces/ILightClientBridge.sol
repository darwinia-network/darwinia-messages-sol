// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

interface ILightClientBridge {
    function verifyBeefyMerkleLeaf(
        bytes calldata beefyMMRLeaf,
        uint256 beefyMMRLeafIndex,
        uint256 beefyMMRLeafCount,
        bytes32[] calldata peaks,
        bytes32[] calldata siblings 
    ) external view returns (bool);

    function getFinalizedBlockNumber() external view returns (uint256);
}
