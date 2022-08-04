// SPDX-License-Identifier: Apache-2.0
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
