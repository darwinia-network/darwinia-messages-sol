pragma solidity >=0.4.21 <0.6.0;

import "./MMR.sol";

contract MMRWrapper {
    using MMR for MMR.Tree;

    MMR.Tree mTree;
    constructor() public {

    }

    function append(bytes memory data,  bytes32 leafHash) public {
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

    // function verifyProof( bytes32 root,
    //     uint256 width,
    //     uint256 index,
    //     bytes memory value,
    //     bytes32[] memory peaks,
    //     bytes32[] memory siblings
    //     ) public view returns (bool){
    //     return mTree.inclusionProof(width, index, value, peaks, siblings);
    // }
}