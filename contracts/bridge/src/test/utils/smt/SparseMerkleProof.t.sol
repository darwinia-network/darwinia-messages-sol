// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

import "../../test.sol";
import "../../../utils/smt/SparseMerkleProof.sol";

contract SparseMerkleProofTest is DSTest {
    // └─ 609cb3db293942026cbe8a4af05e7c3bf84d5d0ddd3e7992cba7679672a7320b
    //    ├─ fce70162d9cd6f7eaa27bd32c59b918b73504d82ce1857aee333bbbbf3047ed8
    //    │  ├─ 2156125536ad8579550f90b9ce42bc89e1b0afe53429e7d2b72812cc9ed21fbf
    //    │  └─ e8fdeb54f7c1e6c5a2bbf26f95ca5b182e13540419623b7b32f843b7124c7d2f
    //    └─ d8ac990c2064ff16b14142fb8eef4b6158814f90f718da31a21a28ff06ed3aaa
    //       ├─ 1218485dabb222fb1e7703a88737abbc3f37cb6c8601f6b07d775ddba17ce393
    //       └─ aee3dbe89996e687f3374b5325eda4687bfe27401b5ce2d9b225ab0cb209e562
    function test_multi_verify() public {
        bytes32 root = hex"609cb3db293942026cbe8a4af05e7c3bf84d5d0ddd3e7992cba7679672a7320b";
        uint depth = 2;
        bytes32 indices = hex"0301";
        bytes32[] memory leaves = new bytes32[](2);
        leaves[0] = hex"aee3dbe89996e687f3374b5325eda4687bfe27401b5ce2d9b225ab0cb209e562";
        leaves[1] = hex"e8fdeb54f7c1e6c5a2bbf26f95ca5b182e13540419623b7b32f843b7124c7d2f";
        bytes32[] memory decommitments = new bytes32[](2);
        decommitments[0] = hex"1218485dabb222fb1e7703a88737abbc3f37cb6c8601f6b07d775ddba17ce393";
        decommitments[1] = hex"2156125536ad8579550f90b9ce42bc89e1b0afe53429e7d2b72812cc9ed21fbf";
        assertTrue(SparseMerkleProof.multiVerify(
            root,
            depth,
            indices,
            leaves,
            decommitments
        ));
    }

    function testFail_multi_verify() public pure {
        bytes32 root = hex"609cb3db293942026cbe8a4af05e7c3bf84d5d0ddd3e7992cba7679672a7320b";
        uint depth = 2;
        bytes32 indices = hex"0103";
        bytes32[] memory leaves = new bytes32[](2);
        leaves[0] = hex"e8fdeb54f7c1e6c5a2bbf26f95ca5b182e13540419623b7b32f843b7124c7d2f";
        leaves[1] = hex"aee3dbe89996e687f3374b5325eda4687bfe27401b5ce2d9b225ab0cb209e562";
        bytes32[] memory decommitments = new bytes32[](2);
        decommitments[0] = hex"2156125536ad8579550f90b9ce42bc89e1b0afe53429e7d2b72812cc9ed21fbf";
        decommitments[1] = hex"1218485dabb222fb1e7703a88737abbc3f37cb6c8601f6b07d775ddba17ce393";
        SparseMerkleProof.multiVerify(
            root,
            depth,
            indices,
            leaves,
            decommitments
        );
    }

    // └─ ad4e8946ee8f8a4b98c6ece5d271d842abc752aa6b3a133efb44e2c13dd5a635
    //    ├─ 777611620e9efc9152fbfdf25b0eb7cb3876c51ce3630e77bb4204e7001252fb
    //    │  ├─ 950a019d53380dd2d4e240aaace158b09aac75689325fbdb4994748a9ce04c89
    //    │  └─ 3ad9e2f40f14c1834af2848ff5d8b568ffb5aec4ea137dbcd69411d5a5b3082c
    //    └─ 0fdef50f4e46e1db97d092c03e160fd45d6fd9bde3424790c1c5fe140bb93850
    //       └─ 0fdef50f4e46e1db97d092c03e160fd45d6fd9bde3424790c1c5fe140bb93850
    function test_single_verify() public {
        bytes32 root = hex"ad4e8946ee8f8a4b98c6ece5d271d842abc752aa6b3a133efb44e2c13dd5a635";
        bytes32 leaf = hex"950a019d53380dd2d4e240aaace158b09aac75689325fbdb4994748a9ce04c89";
        uint pos = 0;
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = hex"3ad9e2f40f14c1834af2848ff5d8b568ffb5aec4ea137dbcd69411d5a5b3082c";
        proof[1] = hex"0fdef50f4e46e1db97d092c03e160fd45d6fd9bde3424790c1c5fe140bb93850";
        assertTrue(SparseMerkleProof.singleVerify(
            root,
            leaf,
            pos,
            proof
        ));
    }

    function testFail_single_verify() public {
        bytes32 root = hex"ad4e8946ee8f8a4b98c6ece5d271d842abc752aa6b3a133efb44e2c13dd5a635";
        bytes32 leaf = hex"950a019d53380dd2d4e240aaace158b09aac75689325fbdb4994748a9ce04c89";
        uint pos = 1;
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = hex"3ad9e2f40f14c1834af2848ff5d8b568ffb5aec4ea137dbcd69411d5a5b3082c";
        proof[1] = hex"0fdef50f4e46e1db97d092c03e160fd45d6fd9bde3424790c1c5fe140bb93850";
        assertTrue(SparseMerkleProof.singleVerify(
            root,
            leaf,
            pos,
            proof
        ));
    }
}
