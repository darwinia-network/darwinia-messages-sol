// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./MMR.sol";

contract MMRWrapper {
    bool public result;
    constructor() public {
    }

    function verifyProof(
        bytes32 root,
        uint256 width,
        uint256 blockNumber,
        bytes memory value,
        bytes32 valueHash,
        bytes32[] memory peaks,
        bytes32[] memory siblings
    ) public returns (uint8){
        result = MMR.inclusionProof(root, width, blockNumber, value, peaks, siblings);
    }

    function getResult() public view returns (bool) {
        return result;
    }
}