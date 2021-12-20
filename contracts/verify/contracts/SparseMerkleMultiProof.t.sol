pragma solidity >=0.6.0 <0.7.0;

import "@darwinia/contracts-utils/contracts/ds-test/test.sol";
import "./SparseMerkleMultiProof.sol";

contract SparseMerkleMultiProofTest is DSTest {
    function verifyMultiProofWithDict(
        bytes32 root,
        uint256 depth,
        uint256[] memory indices,
        bytes32[] memory leafs,
        bytes32[] memory decommitments
    )
        public
        pure
        returns (bool)
    {
        return SparseMerkleMultiProof.verify(root, depth, indices, leafs, decommitments);
    }
}
