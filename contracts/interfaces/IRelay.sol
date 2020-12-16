// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

interface IRelay {
      function verifyRootAndDecodeReceipt(
        bytes32 root,
        uint32 MMRIndex,
        uint32 blockNumber,
        bytes memory blockHeader,
        bytes32[] memory peaks,
        bytes32[] memory siblings,
        bytes memory proofstr,
        bytes memory key
    ) external view returns (bytes memory);

     function appendRoot(
        bytes32 hash,
        bytes memory message,
        bytes[] memory signatures
    ) external;

    function _getMMRRoot(uint32 index) external view returns (bytes32);
}