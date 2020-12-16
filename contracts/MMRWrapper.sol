// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./MMR.sol";

contract MMRWrapper {
    bool public result;
    constructor() public {
    }

    function verifyProof(
        bytes32 root,
        uint256 width,
        uint256 index,
        bytes memory value,
        bytes32 valueHash,
        bytes32[] memory peaks,
        bytes32[] memory siblings
    ) public returns (uint8){
        result = MMR.inclusionProof(root, width, index, value, peaks, siblings);
    }

    function getResult() public view returns (bool) {
        return result;
    }
}