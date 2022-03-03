// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../../lib/ds-test/src/test.sol";
import "../../utils/SparseMerkleMultiProof.sol";

contract SparseMerkleMultiProofTest is DSTest {
// └─ 609cb3db293942026cbe8a4af05e7c3bf84d5d0ddd3e7992cba7679672a7320b
//    ├─ fce70162d9cd6f7eaa27bd32c59b918b73504d82ce1857aee333bbbbf3047ed8
//    │  ├─ 2156125536ad8579550f90b9ce42bc89e1b0afe53429e7d2b72812cc9ed21fbf
//    │  └─ e8fdeb54f7c1e6c5a2bbf26f95ca5b182e13540419623b7b32f843b7124c7d2f
//    └─ d8ac990c2064ff16b14142fb8eef4b6158814f90f718da31a21a28ff06ed3aaa
//       ├─ 1218485dabb222fb1e7703a88737abbc3f37cb6c8601f6b07d775ddba17ce393
//       └─ aee3dbe89996e687f3374b5325eda4687bfe27401b5ce2d9b225ab0cb209e562
    function test_verify() public {
        bytes32 root = hex"609cb3db293942026cbe8a4af05e7c3bf84d5d0ddd3e7992cba7679672a7320b";
        uint depth = 2;
        uint[] memory indices = new uint[](2);
        indices[0] = 3;
        indices[1] = 1;
        bytes32[] memory leaves = new bytes32[](2);
        leaves[0] = hex"aee3dbe89996e687f3374b5325eda4687bfe27401b5ce2d9b225ab0cb209e562";
        leaves[1] = hex"e8fdeb54f7c1e6c5a2bbf26f95ca5b182e13540419623b7b32f843b7124c7d2f";
        bytes32[] memory decommitments = new bytes32[](2);
        decommitments[0] = hex"1218485dabb222fb1e7703a88737abbc3f37cb6c8601f6b07d775ddba17ce393";
        decommitments[1] = hex"2156125536ad8579550f90b9ce42bc89e1b0afe53429e7d2b72812cc9ed21fbf";
        assertTrue(SparseMerkleMultiProof.verify(
            root,
            depth,
            indices,
            leaves,
            decommitments
        ));
    }

    function testFail_verify() public pure {
        bytes32 root = hex"609cb3db293942026cbe8a4af05e7c3bf84d5d0ddd3e7992cba7679672a7320b";
        uint depth = 2;
        uint[] memory indices = new uint[](2);
        indices[0] = 1;
        indices[1] = 3;
        bytes32[] memory leaves = new bytes32[](2);
        leaves[0] = hex"e8fdeb54f7c1e6c5a2bbf26f95ca5b182e13540419623b7b32f843b7124c7d2f";
        leaves[1] = hex"aee3dbe89996e687f3374b5325eda4687bfe27401b5ce2d9b225ab0cb209e562";
        bytes32[] memory decommitments = new bytes32[](2);
        decommitments[0] = hex"2156125536ad8579550f90b9ce42bc89e1b0afe53429e7d2b72812cc9ed21fbf";
        decommitments[1] = hex"1218485dabb222fb1e7703a88737abbc3f37cb6c8601f6b07d775ddba17ce393";
        SparseMerkleMultiProof.verify(
            root,
            depth,
            indices,
            leaves,
            decommitments
        );
    }
}
