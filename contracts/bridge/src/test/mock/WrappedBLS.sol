// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../utils/bls12381/BLS.sol";

contract WrappedBLS {
    function expand_message_xmd(bytes32 message) public pure returns (bytes memory) {
        return BLS.expand_message_xmd(message);
    }

    function hash_to_field_fq2(bytes32 message) public view returns (Fp2[2] memory result) {
        return BLS.hash_to_field_fq2(message);
    }

    function map_to_curve(Fp2 memory f) public view returns (G2Point memory) {
        return G2.map_to_curve(f);
    }

    function hash_to_curve_g2(bytes32 message) public view returns (G2Point memory) {
        return BLS.hash_to_curve_g2(message);
    }

    function bls_pairing_check(G1Point memory pk, G2Point memory h, G2Point memory s) public view returns (bool) {
        return BLS.bls_pairing_check(pk, h, s);
    }

    function deserialize_g1(bytes memory g1) public pure returns (G1Point memory) {
        return G1.deserialize(g1);
    }

    function serialize_g1(G1Point memory g1) public pure returns (bytes memory) {
        return G1.serialize(g1);
    }

    function deserialize_g2(bytes memory g2) public pure returns (G2Point memory) {
        return G2.deserialize(g2);
    }

    function serialize_g2(G2Point memory g2) public pure returns (bytes memory) {
        return G2.serialize(g2);
    }

    function aggregate_pks(bytes[] calldata pubkeys) public view returns (G1Point memory) {
        return BLS.aggregate_pks(pubkeys);
    }

    function fast_aggregate_verify(
        bytes[] calldata uncompressed_pubkeys,
        bytes32 message,
        bytes calldata uncompressed_signature
    ) public view returns (bool) {
        return BLS.fast_aggregate_verify(uncompressed_pubkeys, message, uncompressed_signature);
    }
}
