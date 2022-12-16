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
import "../../../utils/ECDSA.sol";
import "../../../spec/POSACommitmentScheme.sol";
import "../../../truth/darwinia/POSALightClient.sol";

interface Hevm {
    function sign(uint256,bytes32) external returns (uint8,bytes32,bytes32);
    function addr(uint256) external returns (address);
}

contract POSALightClientTest is POSACommitmentScheme, DSTest {
    // solhint-disable-next-line const-name-snakecase
    uint constant sk = 2;
    Hevm internal hevm = Hevm(HEVM_ADDRESS);
    bytes32 private constant DOMAIN_SEPARATOR = 0x38a6d9f96ef6e79768010f6caabfe09abc43e49792d5c787ef0d4fc802855947;

    address alice;
    POSALightClient lightclient;

    function setUp() public {
        address[] memory relayers = new address[](1);
        alice = hevm.addr(sk);
        relayers[0] = alice;
        lightclient = new POSALightClient(
            DOMAIN_SEPARATOR,
            relayers, 1, 0
        );
    }

    function test_import_message_commitment() public {
        Commitment memory commitment = Commitment(
            1,
            0x63308ee345ce0d61223b6c1c85bb4ff3618274d3aef3bd74aa4e30d871f05d6d,
            lightclient.nonce()
        );
        bytes32 struct_hash = hash(commitment);
        bytes32 digest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, struct_hash);
        (uint8 v, bytes32 r, bytes32 s) = hevm.sign(sk, digest);
        bytes[] memory signs = new bytes[](1);
        signs[0] = abi.encodePacked(r, s, v);

        lightclient.import_message_commitment(commitment, signs);

        assertEq(lightclient.merkle_root(), commitment.message_root);
        assertEq(lightclient.block_number(), commitment.block_number);
    }

    function test_message_commitment_hash() public {
        bytes memory data = abi.encode(
                COMMIT_TYPEHASH,
                3,
                0x0000000000000000000000000000000000000000000000000000000000000000,
                0
            );
        bytes32 struct_hash = keccak256(data);
        bytes32 digest = ECDSA.toTypedDataHash(domain_separator_darwinia(), struct_hash);
        assertEq(digest, 0x9ff72bb99d4a7ecd6c68fd49b0f69c9a61ced3fe1003bf0fab68973c2591d0e1);
    }

    function test_message_commitment_hash2() public {
        bytes memory data = abi.encode(
                COMMIT_TYPEHASH,
                9,
                0x0101010101010101010101010101010101010101010101010101010101010101,
                0
            );
        bytes32 struct_hash = keccak256(data);
        bytes32 digest = ECDSA.toTypedDataHash(domain_separator_darwinia(), struct_hash);
        assertEq(digest, 0xab023a4b2e14eac7518885bec31cf79c691793ede728b47f8a8a159e1774b007);
    }

    function test_message_commitment_hash3() public {
        bytes memory data = abi.encode(
                COMMIT_TYPEHASH,
                3926690,
                0x502cc17dd3575ce54f67c02c9ae215968f4582c4dbe0bec4d83571db6afb2079,
                4
            );
        bytes32 struct_hash = keccak256(data);
        bytes32 digest = ECDSA.toTypedDataHash(domain_separator(), struct_hash);
        assertEq(digest, 0x554bcd23878199a38384829887e16116d0a70a4c254bdbd149f117ac7f00b956);
    }

    function domain_separator() public pure returns (bytes32 s) {
        s = keccak256(
                abi.encodePacked(
                    "45",
                    "Pangoro",
                    "::"
                    "ecdsa-authority"
                )
            );
    }

    function domain_separator_darwinia() public pure returns (bytes32 s) {
        s = keccak256(
                abi.encodePacked(
                    "46",
                    "Darwinia",
                    "::"
                    "ecdsa-authority"
                )
            );
    }
}
