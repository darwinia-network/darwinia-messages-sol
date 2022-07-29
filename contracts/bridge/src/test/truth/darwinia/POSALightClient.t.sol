// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
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
    uint constant sk = 1;
    Hevm internal hevm = Hevm(HEVM_ADDRESS);
    bytes32 private constant DOMAIN_SEPARATOR = 0x38a6d9f96ef6e79768010f6caabfe09abc43e49792d5c787ef0d4fc802855947;
    bytes32 private constant COMMIT_TYPEHASH = 0x2ea67489b4c8762e92cdf00de12ced5672416d28fa4265cd7fb78ddd61dd3f32;

    POSALightClient lightclient;
    address alice;

    function setUp() public {
        address[] memory relayers = new address[](1);
        alice = hevm.addr(sk);
        relayers[0] = alice;
        lightclient = new POSALightClient(
            DOMAIN_SEPARATOR,
            relayers,
            1,
            0
        );
    }

    function test_import_message_commitment() public {
        Commitment memory commitment = Commitment(1, 0x63308ee345ce0d61223b6c1c85bb4ff3618274d3aef3bd74aa4e30d871f05d6d);
        bytes32 struct_hash = keccak256(
            abi.encode(
                COMMIT_TYPEHASH,
                hash(commitment),
                lightclient.nonce()
            )
        );
        bytes32 digest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, struct_hash);
        (uint8 v, bytes32 r, bytes32 s) = hevm.sign(sk, digest);
        bytes[] memory signs = new bytes[](1);
        signs[0] = abi.encodePacked(r, s, v);

        lightclient.import_message_commitment(commitment, signs);

        assertEq(lightclient.message_root(), commitment.message_root);
        assertEq(lightclient.block_number(), commitment.block_number);
    }
}
