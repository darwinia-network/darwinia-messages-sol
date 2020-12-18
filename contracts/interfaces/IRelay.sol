// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

pragma experimental ABIEncoderV2;

interface IRelay {
      function verifyRootAndDecodeReceipt(
        bytes32 root,
        uint32 MMRIndex,
        uint32 blockNumber,
        bytes calldata blockHeader,
        bytes32[] calldata peaks,
        bytes32[] calldata siblings,
        bytes calldata proofstr,
        bytes calldata key
    ) external view returns (bytes memory);

     function appendRoot(
        bytes calldata message,
        bytes[] calldata signatures
    ) external;

    function getMMRRoot(uint32 index) external view returns (bytes32);
}