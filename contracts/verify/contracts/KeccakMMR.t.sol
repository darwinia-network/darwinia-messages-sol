// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
import "@darwinia/contracts-utils/contracts/ds-test/test.sol";
import "./KeccakMMR.sol";

contract KeccakMMRWrapper is DSTest {

    function verifyProof(
        bytes32 root,
        uint256 width,
        uint256 blockNumber,
        bytes memory value,
        bytes32[] memory peaks,
        bytes32[] memory siblings
    ) public pure returns (bool){
        return KeccakMMR.inclusionProof(root, width, blockNumber, value, peaks, siblings);
    }

    function testMountainHeight(uint256 size) public logs_gas {
       KeccakMMR.mountainHeight(size);
    }

    function mountainHeight(uint256 size) public pure returns (uint8) {
       return KeccakMMR.mountainHeight(size);
    }

    function getSize(uint width) public pure returns (uint256) {
        return KeccakMMR.getSize(width);
    }

    function peakBagging(bytes32[] memory peaks) pure public returns (bytes32) {
        return KeccakMMR.peakBagging(peaks);
    }

    function hashBranch(bytes32 left, bytes32 right) pure public returns (bytes32) {
        return KeccakMMR.hashBranch(left, right);
    }

    function hashLeaf(bytes memory data) pure public returns (bytes32) {
        return KeccakMMR.hashLeaf(data);
    }

    function heightAt(uint256 index) public pure returns (uint8 height) {
        return KeccakMMR.heightAt(index);
    }

    function getChildren(uint256 index) public pure returns (uint256 left, uint256 right) {
        return KeccakMMR.getChildren(index);
    }

    function getPeakIndexes(uint256 width) public pure returns (uint256[] memory peakIndexes) {
        return KeccakMMR.getPeakIndexes(width);
    }

    function numOfPeaks(uint256 width) public pure returns (uint num) {
        return KeccakMMR.numOfPeaks(width);
    }
}
