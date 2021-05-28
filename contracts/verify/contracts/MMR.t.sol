// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
import "@darwinia/contracts-utils/contracts/ds-test/test.sol";
import "./MMR.sol";

contract MMRWrapper is DSTest {
    bool public result;
    constructor() public {
    }

    function verifyProof(
        bytes32 root,
        uint256 width,
        uint256 blockNumber,
        bytes memory value,
        bytes32 /*valueHash*/,
        bytes32[] memory peaks,
        bytes32[] memory siblings
    ) public returns (uint8){
        result = MMR.inclusionProof(root, width, blockNumber, value, peaks, siblings);
    }

    function getResult() public view returns (bool) {
        return result;
    }

    function testMountainHeight(uint256 size) public logs_gas{
       MMR.mountainHeight(size);
    }
}
