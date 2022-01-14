// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../../../interfaces/IMessageCommitment.sol";

contract ChainMessageCommitter {
    event Registry(uint256 position, address committer);

    uint256 public immutable thisChainPosition;
    uint256 public maxChainPosition;
    mapping(uint256 => address) public chains;

    address public setter;

    modifier onlySetter {
        require(msg.sender == setter, "Commit: forbidden");
        _;
    }

    constructor(uint256 _thisChainPosition) {
        thisChainPosition = _thisChainPosition;
        maxChainPosition = _thisChainPosition;
        setter = msg.sender;
    }

    function changeSetter(address _setter) external onlySetter {
        setter = _setter;
    }

    function registry(address laneCommitter) external onlySetter {
        uint256 position = IMessageCommitment(laneCommitter).bridgedChainPosition();
        require(thisChainPosition != position, "Commit: invalid ThisChainPosition");
        require(thisChainPosition == IMessageCommitment(laneCommitter).thisChainPosition(), "Commit: invalid ThisChainPosition");
        chains[position] = laneCommitter;
        maxChainPosition = max(maxChainPosition, position);
        emit Registry(position, laneCommitter);
    }

    function commitment(uint256 chainPos) public view returns (bytes32) {
        address committer = chains[chainPos];
        if (committer == address(0)) {
            return bytes32(0);
        } else {
            return IMessageCommitment(committer).commitment();
        }
    }

    // we use sparse tree to commit
    function commitment() public view returns (bytes32) {
        uint256 chainCount = maxChainPosition + 1;
        bytes32[] memory hashes = new bytes32[](roundUpToPow2(chainCount));
        for (uint256 pos = 0; pos < chainCount; pos++) {
            hashes[pos] = commitment(pos);
        }
        uint256 hashLength = hashes.length;
        for (uint256 j = 0; hashLength > 1; j = 0) {
            for (uint256 i = 0; i < hashLength; i = i + 2) {
                hashes[j] = keccak256(abi.encodePacked(hashes[i], hashes[i + 1]));
                j = j + 1;
            }
            hashLength = hashLength - j;
        }
        return hashes[0];
    }

    // --- Math ---
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }

    function roundUpToPow2(uint256 len) internal pure returns (uint256) {
        if (len <= 1) return 1;
        else return 2 * roundUpToPow2((len + 1) / 2);
    }
}
