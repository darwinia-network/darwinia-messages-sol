pragma solidity >=0.4.25 <0.7.0;

import "./Blake2b.sol";
import "./MMR.sol";

// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

contract DarwiniaRelay {
    using Blake2b for Blake2b.Instance;
    using MMR for MMR.Tree;

    MMR.Tree mTree;

    struct Header {
        uint32 version;
        bytes32 prevBlock;
        bytes32 merkleRoot;
        uint32 time;
        uint32 nBits;
        uint32 nonce;
    }

    struct Tree {
        bytes32 root;
        uint256 size;
        uint256 width;
        mapping(uint256 => bytes32) hashes;
        mapping(bytes32 => bytes) data;
    }
    
    constructor() public {
    }

    function append(bytes memory data, bytes32 leafHash) public {
        mTree.append(data, leafHash);
    }

    function getRoot() public view returns (bytes32) {
        return mTree.getRoot();
    }

    function getSize() public view returns (uint256) {
        return mTree.getSize();
    }

    function getMerkleProof(uint256 index) public view returns (
        bytes32 root,
        uint256 width,
        bytes32[] memory peakBagging,
        bytes32[] memory siblings
    )
    {
        return mTree.getMerkleProof(index);
    }

    function bytesToBytes32(bytes memory b, uint256 offset)
        private
        pure
        returns (bytes32)
    {
        bytes32 out;

        for (uint256 i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function Blake2bHash(bytes memory input) public returns (bytes32) {
        return MMR.Blake2bHash(input);
    }

    // function verifyProof(
    //     bytes32 root,
    //     uint256 width,
    //     uint256 index,
    //     bytes memory value,
    //     bytes32[] memory peaks,
    //     bytes32[] memory siblings
    // ) public view returns (bool) {
    //     return MMR.inclusionProof(root, width, index, value, peaks, siblings);
    // }

    // function getSize(uint256 width) public pure returns (uint256) {
    //     return (width << 1) - numOfPeaks(width);
    // }

    // function numOfPeaks(uint256 width) public pure returns (uint256 num) {
    //     uint256 bits = width;
    //     while (bits > 0) {
    //         if (bits % 2 == 1) num++;
    //         bits = bits >> 1;
    //     }
    //     return num;
    // }

    // /**
    //  * @dev It returns all peaks of the smallest merkle mountain range tree which includes
    //  *      the given index(size)
    //  */
    // function getPeakIndexes(uint256 width)
    //     public
    //     pure
    //     returns (uint256[] memory peakIndexes)
    // {
    //     peakIndexes = new uint256[](numOfPeaks(width));
    //     uint256 count;
    //     uint256 size;
    //     for (uint256 i = 255; i > 0; i--) {
    //         if (width & (1 << (i - 1)) != 0) {
    //             // peak exists
    //             size = size + (1 << i) - 1;
    //             peakIndexes[count++] = size;
    //         }
    //     }
    //     require(count == peakIndexes.length, "Invalid bit calculation");
    // }

    // /**
    //  * @dev it returns the hash of a leaf node with hash(M | DATA )
    //  *      M is the index of the node
    //  */
    // function hashLeaf(uint256 index, bytes32 dataHash)
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     return keccak256(abi.encodePacked(index, dataHash));
    // }

    // /**
    //  * @dev It returns the children when it is a parent node
    //  */
    // function getChildren(uint256 index)
    //     public
    //     pure
    //     returns (uint256 left, uint256 right)
    // {
    //     left = index - (uint256(1) << (heightAt(index) - 1));
    //     right = index - 1;
    //     require(left != right, "Not a parent");
    // }

    // /**
    //  * @dev It returns the height of the index
    //  */
    // function heightAt(uint256 index) public pure returns (uint8 height) {
    //     uint256 reducedIndex = index;
    //     uint256 peakIndex;
    //     // If an index has a left mountain subtract the mountain
    //     while (reducedIndex > peakIndex) {
    //         reducedIndex -= (uint256(1) << height) - 1;
    //         height = mountainHeight(reducedIndex);
    //         peakIndex = (uint256(1) << height) - 1;
    //     }
    //     // Index is on the right slope
    //     height = height - uint8((peakIndex - reducedIndex));
    // }

    // /**
    //  * @dev It returns the height of the highest peak
    //  */
    // function mountainHeight(uint256 size) public pure returns (uint8) {
    //     uint8 height = 1;
    //     while (uint256(1) << height <= size + height) {
    //         height++;
    //     }
    //     return height - 1;
    // }

    // /**
    //  * @dev It returns the hash a parent node with hash(M | Left child | Right child)
    //  *      M is the index of the node
    //  */
    // function hashBranch(
    //     uint256 index,
    //     bytes32 left,
    //     bytes32 right
    // ) public pure returns (bytes32) {
    //     return keccak256(abi.encodePacked(index, left, right));
    // }
}
