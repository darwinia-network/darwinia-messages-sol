pragma solidity >=0.6.0 <0.7.0;

import "@darwinia/contracts-utils/contracts/ds-test/test.sol";
import "./MerkleMultiProof.sol";

contract MerkleMultiProofTest is DSTest {
    function verifyMultiProof(
        bytes32 root,
        bytes32[] memory leafs,
        bytes32[] memory proofs,
        bool[] memory proofFlag
    )
        public 
        pure
        returns (bool)
    {
        return MerkleMultiProof.verifyMultiProof(root, leafs, proofs, proofFlag);
    }
}
