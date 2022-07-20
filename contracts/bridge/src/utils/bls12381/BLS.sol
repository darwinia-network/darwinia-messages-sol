//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./Pairing.sol";

library BLS {
    using G1 for G1Point;
    using G2 for G2Point;

    // Domain Separation Tag for signatures on G2 with a single byte the length of the DST appended
    string constant DST_G2 = "BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_+";

    // FastAggregateVerify
    //
    // Verifies an AggregateSignature against a list of PublicKeys.
    // PublicKeys must all be verified via Proof of Possession before running this function.
    // https://tools.ietf.org/html/draft-irtf-cfrg-bls-signature-02#section-3.3.4
    function fast_aggregate_verify(
        bytes[] calldata pubkeys,
        bytes32 message,
        bytes calldata signature
    ) internal view returns (bool) {
        G1Point memory agg_key = aggregate_pks(pubkeys);
        G2Point memory sign_point = G2.decode(signature);
        G2Point memory msg_point = hash_to_curve_g2(message);
        // Faster evaualtion checks e(PK, H) * e(-G1, S) == 1
        return bls_pairing_check(agg_key, msg_point, sign_point);
    }

    // e(PK, H) * e(-G1, S) == 1
    function bls_pairing_check(G1Point memory pk, G2Point memory h, G2Point memory s) internal view returns (bool) {
        G1Point memory ng1 = G1.negativeP1();
        return Pairing.pairing(pk, h, ng1, s);
    }

    function aggregate_pks(bytes[] calldata pubkeys) internal view returns (G1Point memory) {
        uint len = pubkeys.length;
        require(len > 0, "!pubkeys");
        G1Point memory g1 = G1.decode(pubkeys[0]);
        for (uint i = 1; i < len; i++) {
            g1 = g1.add(G1.decode(pubkeys[i]));
        }
        // TODO: Ensure AggregatePublicKey is not infinity
        return g1;
    }

    // Hash to Curve
    //
    // Takes a message as input and converts it to a Curve Point
    // https://tools.ietf.org/html/draft-irtf-cfrg-hash-to-curve-09#section-3
    // `MapToCurve` precompile includes `clear_cofactor`
    function hash_to_curve_g2(bytes32 message) internal view returns (G2Point memory) {
        Fp2[2] memory u = hash_to_field_fq2(message);
        G2Point memory q0 = G2.map_to_curve(u[0]);
        G2Point memory q1 = G2.map_to_curve(u[1]);
        return q0.add(q1);
    }


    // Hash To Field - Fp
    //
    // Take a message as bytes and convert it to a Field Point
    // https://tools.ietf.org/html/draft-irtf-cfrg-hash-to-curve-09#section-5.3
    function hash_to_field_fq2(bytes32 message) internal view returns (Fp2[2] memory result) {
        bytes memory uniform_bytes = expand_message_xmd(message);
        result[0] = Fp2(
            convert_slice_to_fp(uniform_bytes, 0, 64),
            convert_slice_to_fp(uniform_bytes, 64, 128)
        );
        result[1] = Fp2(
            convert_slice_to_fp(uniform_bytes, 128, 192),
            convert_slice_to_fp(uniform_bytes, 192, 256)
        );
    }

    // Expand Message XMD
    //
    // Take a message and convert it to pseudo random bytes of specified length
    // https://tools.ietf.org/html/draft-irtf-cfrg-hash-to-curve-09#section-5.4
    function expand_message_xmd(bytes32 message) internal pure returns (bytes memory) {
        bytes memory b0Input = new bytes(143);
        for (uint i = 0; i < 32; i++) {
            b0Input[i+64] = message[i];
        }
        b0Input[96] = 0x01;
        for (uint i = 0; i < 44; i++) {
            b0Input[i+99] = bytes(DST_G2)[i];
        }

        bytes32 b0 = sha256(b0Input);

        bytes memory output = new bytes(256);
        bytes32 chunk = sha256(abi.encodePacked(b0, byte(0x01), bytes(DST_G2)));
        assembly {
            mstore(add(output, 0x20), chunk)
        }
        for (uint i = 2; i < 9; i++) {
            bytes32 input;
            assembly {
                input := xor(b0, mload(add(output, add(0x20, mul(0x20, sub(i, 2))))))
            }
            chunk = sha256(abi.encodePacked(input, byte(uint8(i)), bytes(DST_G2)));
            assembly {
                mstore(add(output, add(0x20, mul(0x20, sub(i, 1)))), chunk)
            }
        }

        return output;
    }

    function convert_slice_to_fp(bytes memory data, uint start, uint end) internal view returns (Fp memory) {
        bytes memory f = reduce_modulo(data, start, end);
        uint a = slice_to_uint(f, 0, 16);
        uint b = slice_to_uint(f, 16, 48);
        return Fp(a, b);
    }

    function slice_to_uint(bytes memory data, uint start, uint end) internal pure returns (uint r) {
        uint len = end - start;
        require(0 <= len && len <= 32, "!slice");

        assembly{
            r := mload(add(add(data, 0x20), start))
        }

        return r >> (256 - len * 8);
    }

    function reduce_modulo(bytes memory data, uint start, uint end) internal view returns (bytes memory) {
        uint length = end - start;
        assert (length >= 0);
        assert (length <= data.length);

        bytes memory result = new bytes(48);

        bool success;
        assembly {
            let p := mload(0x40)
            // length of base
            mstore(p, length)
            // length of exponent
            mstore(add(p, 0x20), 0x20)
            // length of modulus
            mstore(add(p, 0x40), 48)
            // base
            // first, copy slice by chunks of EVM words
            let ctr := length
            let src := add(add(data, 0x20), start)
            let dst := add(p, 0x60)
            for { }
                or(gt(ctr, 0x20), eq(ctr, 0x20))
                { ctr := sub(ctr, 0x20) }
            {
                mstore(dst, mload(src))
                dst := add(dst, 0x20)
                src := add(src, 0x20)
            }
            // next, copy remaining bytes in last partial word
            let mask := sub(exp(256, sub(0x20, ctr)), 1)
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dst), mask)
            mstore(dst, or(destpart, srcpart))
            // exponent
            mstore(add(p, add(0x60, length)), 1)
            // modulus
            let modulusAddr := add(p, add(0x60, add(0x10, length)))
            // p.a
            mstore(modulusAddr, or(mload(modulusAddr), 0x1a0111ea397fe69a4b1ba7b6434bacd7))
            // p.b
            mstore(add(p, add(0x90, length)), 0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab)
            if iszero(staticcall(gas(), 0x05, p, add(0xB0, length), add(result, 0x20), 48)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        return result;
    }
}
