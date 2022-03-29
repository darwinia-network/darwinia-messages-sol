// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../../../lib/ds-test/src/test.sol";
import "../../utils/BinaryMerkleProof.sol";

contract BinaryMerkleProofTest is DSTest {

// └─ ad4e8946ee8f8a4b98c6ece5d271d842abc752aa6b3a133efb44e2c13dd5a635
//    ├─ 777611620e9efc9152fbfdf25b0eb7cb3876c51ce3630e77bb4204e7001252fb
//    │  ├─ 950a019d53380dd2d4e240aaace158b09aac75689325fbdb4994748a9ce04c89
//    │  └─ 3ad9e2f40f14c1834af2848ff5d8b568ffb5aec4ea137dbcd69411d5a5b3082c
//    └─ 0fdef50f4e46e1db97d092c03e160fd45d6fd9bde3424790c1c5fe140bb93850
//       └─ 0fdef50f4e46e1db97d092c03e160fd45d6fd9bde3424790c1c5fe140bb93850
    function test_verify_merkle_leaf_at_position() public {
        bytes32 root = hex"ad4e8946ee8f8a4b98c6ece5d271d842abc752aa6b3a133efb44e2c13dd5a635";
        bytes32 leaf = hex"950a019d53380dd2d4e240aaace158b09aac75689325fbdb4994748a9ce04c89";
        uint pos = 0;
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = hex"3ad9e2f40f14c1834af2848ff5d8b568ffb5aec4ea137dbcd69411d5a5b3082c";
        proof[1] = hex"0fdef50f4e46e1db97d092c03e160fd45d6fd9bde3424790c1c5fe140bb93850";
        assertTrue(BinaryMerkleProof.verifyMerkleLeafAtPosition(
            root,
            leaf,
            pos,
            proof
        ));
    }

    function testFail_verify_merkle_leaf_at_position() public {
        bytes32 root = hex"ad4e8946ee8f8a4b98c6ece5d271d842abc752aa6b3a133efb44e2c13dd5a635";
        bytes32 leaf = hex"950a019d53380dd2d4e240aaace158b09aac75689325fbdb4994748a9ce04c89";
        uint pos = 1;
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = hex"3ad9e2f40f14c1834af2848ff5d8b568ffb5aec4ea137dbcd69411d5a5b3082c";
        proof[1] = hex"0fdef50f4e46e1db97d092c03e160fd45d6fd9bde3424790c1c5fe140bb93850";
        assertTrue(BinaryMerkleProof.verifyMerkleLeafAtPosition(
            root,
            leaf,
            pos,
            proof
        ));
    }
}
