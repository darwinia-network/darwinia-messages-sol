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

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../test.sol";
import "../../../utils/ECDSA.sol";
import "../../../truth/darwinia/EcdsaAuthority.sol";

interface Hevm {
    function sign(uint256,bytes32) external returns (uint8,bytes32,bytes32);
    function addr(uint256) external returns (address);
}

contract EcdsaAuthorityTest is DSTest {
    uint constant sk = 1;
    Hevm internal hevm = Hevm(HEVM_ADDRESS);
    address private constant SENTINEL             = address(0x1);
    bytes4  private constant ADD_RELAYER_SIG      = bytes4(0xb7aafe32);
    bytes4  private constant REMOVE_RELAYER_SIG   = bytes4(0x8621d1fa);
    bytes4  private constant SWAP_RELAYER_SIG     = bytes4(0xcb76085b);
    bytes4  private constant CHANGE_THRESHOLD_SIG = bytes4(0x3c823333);
    bytes32 private constant RELAY_TYPEHASH       = 0x30a82982a8d5050d1c83bbea574aea301a4d317840a8c4734a308ffaa6a63bc8;

    EcdsaAuthority authority;
    address alice;

    function setUp() public {
        address[] memory relayers = new address[](1);
        alice = hevm.addr(sk);
        relayers[0] = alice;
        authority = new EcdsaAuthority(
            domain_separator(),
            relayers,
            1,
            0
        );
    }

    function test_add_relayer() public {
        address bob = address(0xbb);
        uint threshold = 1;
        perform_add_relayer(bob, threshold);
        address[] memory e = authority.get_relayers();
        assertEq(e.length, 2);
        assertEq(bob, e[0]);
        assertEq(alice, e[1]);
        assertEq(authority.get_threshold(), threshold);
    }

    function test_remove_relayer() public {
        address bob = address(0xbbbb);
        uint threshold = 1;
        perform_add_relayer(bob, threshold);

        bytes32 struct_hash = keccak256(
            abi.encode(
                RELAY_TYPEHASH,
                REMOVE_RELAYER_SIG,
                abi.encode(SENTINEL, bob, threshold),
                authority.nonce()
            )
        );
        bytes32 digest = ECDSA.toTypedDataHash(domain_separator(), struct_hash);
        (uint8 v, bytes32 r, bytes32 s) = hevm.sign(sk, digest);
        bytes[] memory signs = new bytes[](1);
        signs[0] = abi.encodePacked(r, s, v);
        authority.remove_relayer(SENTINEL, bob, threshold, signs);

        address[] memory e = authority.get_relayers();
        assertEq(e.length, 1);
        assertEq(alice, e[0]);
        assertEq(authority.get_threshold(), threshold);
    }

    function test_swap_relayer() public {
        address bob = address(0xbbbb);
        bytes32 struct_hash = keccak256(
            abi.encode(
                RELAY_TYPEHASH,
                SWAP_RELAYER_SIG,
                abi.encode(SENTINEL, alice, bob),
                authority.nonce()
            )
        );
        bytes32 digest = ECDSA.toTypedDataHash(domain_separator(), struct_hash);
        (uint8 v, bytes32 r, bytes32 s) = hevm.sign(sk, digest);
        bytes[] memory signs = new bytes[](1);
        signs[0] = abi.encodePacked(r, s, v);
        authority.swap_relayer(SENTINEL, alice, bob, signs);

        address[] memory e = authority.get_relayers();
        assertEq(e.length, 1);
        assertEq(bob, e[0]);
    }

    function test_add_relayer_hash() public {
        bytes memory data = abi.encode(
                RELAY_TYPEHASH,
                ADD_RELAYER_SIG,
                abi.encode(address(0), 1),
                0
            );
        bytes32 struct_hash = keccak256(data);
        bytes32 digest = ECDSA.toTypedDataHash(domain_separator_darwinia(), struct_hash);
        assertEq(digest, 0xa787153e9fec0acd8c2cbe3d3fa8091a58e69c1b2830e778fe60b8aec0991df6);
    }

    function test_rm_relayer_hash() public {
        bytes memory data = abi.encode(
                RELAY_TYPEHASH,
                REMOVE_RELAYER_SIG,
                abi.encode(SENTINEL, 0x0101010101010101010101010101010101010101, 1),
                0
            );
        bytes32 struct_hash = keccak256(data);
        bytes32 digest = ECDSA.toTypedDataHash(domain_separator_darwinia(), struct_hash);
        assertEq(digest, 0x0b2ecc3333b4b346ac0158de3e1a15989180ca9046284ecf25b08e3cb685ce14);
    }

    function test_swap_relayer_hash() public {
        bytes memory data = abi.encode(
                RELAY_TYPEHASH,
                SWAP_RELAYER_SIG,
                abi.encode(SENTINEL, SENTINEL, SENTINEL),
                0
            );
        bytes32 struct_hash = keccak256(data);
        bytes32 digest = ECDSA.toTypedDataHash(domain_separator(), struct_hash);
        assertEq(digest, 0xe0048b398f49e08acbe5d5acc8beceecf2734c2cd4e73ec683302822ecc8811e);
    }

    function test_swap_relayer_hash2() public {
        bytes memory data = abi.encode(
                RELAY_TYPEHASH,
                SWAP_RELAYER_SIG,
                abi.encode(SENTINEL, 0x0101010101010101010101010101010101010101, 0x0202020202020202020202020202020202020202),
                0
            );
        bytes32 struct_hash = keccak256(data);
        bytes32 digest = ECDSA.toTypedDataHash(domain_separator_darwinia(), struct_hash);
        assertEq(digest, 0x7ce94dac9a010fa6459cd29e9cb1732fcdc86a752cf05ac653f81a8a250969cc);
    }

    function test_add_relayer_with_threshold() public {
        address cici = address(0xc);
        uint threshold = 2;
        perform_add_relayer(cici, threshold);
        address[] memory e = authority.get_relayers();
        assertEq(e.length, 2);
        assertEq(cici, e[0]);
        assertEq(alice, e[1]);
        assertEq(authority.get_threshold(), threshold);
    }

    function testFail_add_relayer_with_sentinel() public {
        perform_add_relayer(SENTINEL, 1);
    }

    function testFail_add_relayer_with_zero_threshold() public {
        perform_add_relayer(address(0xcc), 0);
    }

    function testFail_add_relayer_with_wrong_threshold() public {
        perform_add_relayer(address(0xccc), 3);
    }

    function perform_add_relayer(address x, uint threshold) public {
        bytes32 struct_hash = keccak256(
            abi.encode(
                RELAY_TYPEHASH,
                ADD_RELAYER_SIG,
                abi.encode(x, threshold),
                authority.nonce()
            )
        );
        bytes32 digest = ECDSA.toTypedDataHash(domain_separator(), struct_hash);
        (uint8 v, bytes32 r, bytes32 s) = hevm.sign(sk, digest);
        bytes[] memory signs = new bytes[](1);
        signs[0] = abi.encodePacked(r, s, v);
        authority.add_relayer(x, threshold, signs);
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

    // keccak256(
    //     "chain_id | spec_name | :: | pallet_name"
    // );
    // string pallet_name = ecdsa-authority
    // string spec_name = Darwinia / Crab / Pangolin
    // string chain_id = 46 / 44 / 43
    function test_domain_separator() public {
        bytes32 s = keccak256(
                abi.encodePacked(
                    "46",
                    "Darwinia",
                    "::"
                    "ecdsa-authority"
                )
            );
        assertEq(s, 0xf8a76f5ceeff36d74ff99c4efc0077bcc334721f17d1d5f17cfca78455967e1e);
        bytes32 h = keccak256(abi.encodePacked("\x19\x01", s, bytes32(0)));
        assertEq(h, 0x1cb3a6858ee5a0568c75b8cee35137943c35e0f81228edb64028fd086efd801b);
    }
}
