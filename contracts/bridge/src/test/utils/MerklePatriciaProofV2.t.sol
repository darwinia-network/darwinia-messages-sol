// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import "../test.sol";
import "../../utils/MerklePatriciaProofV2.sol";

contract MerklePatriciaProofV2Test is DSTest {
    function test_verify_single_storage_proof() public {
        assertEq(validateProof(rootHash, paths, proof), hex'');
    }
}
