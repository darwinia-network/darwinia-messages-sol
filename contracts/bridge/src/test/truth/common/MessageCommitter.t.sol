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
pragma abicoder v2;

import "../../test.sol";
import "../../../truth/common/MessageCommitter.sol";

contract MesageCommitterTest is DSTest {
    MockMessageCommitter committer;

    function setUp() public {
        committer = new MockMessageCommitter();
    }

    function test_empty_commitment() public {
        assertEq(committer.commitment(), bytes32(0));
    }

    function testFail_prove_empty() public view {
        committer.proof(0);
    }

    function test_prove_one_leave() public {
        committer.mock_one_leave();
        MessageSingleProof memory proof = committer.proof(0);
        assertEq(proof.root, bytes32(uint(1)));
        assertEq(proof.proof.length, 0);
        assertEq(committer.commitment(), proof.root);
    }

    function test_prove_two_leaves() public {
        committer.mock_two_leaves();
        MessageSingleProof memory proof = committer.proof(0);
        assertEq(proof.root, 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0);
        assertEq(proof.proof.length, 1);
        assertEq(proof.proof[0], bytes32(uint(2)));
        assertEq(committer.commitment(), proof.root);

        proof = committer.proof(1);
        assertEq(proof.root, 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0);
        assertEq(proof.proof.length, 1);
        assertEq(proof.proof[0], bytes32(uint(1)));
        assertEq(committer.commitment(), proof.root);
    }

    function test_prove_three_leaves() public {
        committer.mock_three_leaves();
        MessageSingleProof memory proof = committer.proof(0);
        assertEq(proof.root, 0x222ff5e0b5877792c2bc1670e2ccd0c2c97cd7bb1672a57d598db05092d3d72c);
        assertEq(proof.proof.length, 2);
        assertEq(proof.proof[0], bytes32(uint(2)));
        assertEq(proof.proof[1], 0x101e368776582e57ab3d116ffe2517c0a585cd5b23174b01e275c2d8329c3d83);
        assertEq(committer.commitment(), proof.root);

        proof = committer.proof(1);
        assertEq(proof.root, 0x222ff5e0b5877792c2bc1670e2ccd0c2c97cd7bb1672a57d598db05092d3d72c);
        assertEq(proof.proof.length, 2);
        assertEq(proof.proof[0], bytes32(uint(1)));
        assertEq(proof.proof[1], 0x101e368776582e57ab3d116ffe2517c0a585cd5b23174b01e275c2d8329c3d83);
        assertEq(committer.commitment(), proof.root);

        proof = committer.proof(2);
        assertEq(proof.root, 0x222ff5e0b5877792c2bc1670e2ccd0c2c97cd7bb1672a57d598db05092d3d72c);
        assertEq(proof.proof.length, 2);
        assertEq(proof.proof[0], bytes32(uint(0)));
        assertEq(proof.proof[1], 0xe90b7bceb6e7df5418fb78d8ee546e97c83a08bbccc01a0644d599ccd2a7c2e0);
        assertEq(committer.commitment(), proof.root);
    }

    function testFail_prove_three_leaves_with_wrong_pos() public {
        committer.mock_three_leaves();
        committer.proof(3);
    }
}

contract Lane {
    bytes32 c;
    constructor(bytes32 _c) {
        c = _c;
    }
    function commitment() public view returns (bytes32) {
        return c;
    }
}

contract MockMessageCommitter is MessageCommitter {
    uint c;
    mapping(uint=>address) l;

    function mock_one_leave() public {
        l[0] = address(new Lane(bytes32(uint(1))));
        c = 1;
    }

    function mock_two_leaves() public {
        l[0] = address(new Lane(bytes32(uint(1))));
        l[1] = address(new Lane(bytes32(uint(2))));
        c = 2;
    }

    function mock_three_leaves() public {
        l[0] = address(new Lane(bytes32(uint(1))));
        l[1] = address(new Lane(bytes32(uint(2))));
        l[2] = address(new Lane(bytes32(uint(3))));
        c = 3;
    }

    function count() public view override returns (uint256) {
        return c;
    }
    function leaveOf(uint256 p) public view override returns (address) {
        return l[p];
    }
}
