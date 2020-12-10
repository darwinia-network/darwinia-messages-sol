pragma solidity >=0.5.0 <0.6.0;

pragma experimental ABIEncoderV2;

contract IRelay {
      function verifyAndDecodeReceipt(
        bytes32 root,
        uint32 MMRIndex,
        uint32 blockNumber,
        bytes memory blockHeader,
        bytes32[] memory peaks,
        bytes32[] memory siblings,
        bytes memory proofstr,
        bytes memory key
    ) public view returns (bytes memory);

     function appendRoot(
        bytes32 hash,
        bytes memory message,
        bytes[] memory signatures
    ) public;

    function _getMMRRoot(uint32 index) public view returns (bytes32);
}