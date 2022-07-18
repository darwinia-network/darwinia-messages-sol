//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import { B12_381Lib, B12 } from "./BLS12381.sol";

library BLS {
    string constant BLS_SIG_DST = "BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_+";

    function fast_aggregate_verify(
        bytes[] calldata pubkeys,
        bytes32 calldata message,
        bytes calldata signature
    ) internal view returns (bool) {
        B12.G1Point memory agg_key = aggregate_pks(pubkeys);
        B12.G2Point memory sign_point = B12.parseG2(signature, 0);
        B12.G2Point memory msg_point = hash_to_curve(message);
        return blsPairingCheck(agg_key, msg_point, sign_point);
    }

    function blsPairingCheck(B12.G1Point memory publicKey, B12.G2Point memory messageOnCurve, B12.G2Point memory signature) public view returns (bool) {
        uint[24] memory input;

        input[0] =  publicKey.X.a;
        input[1] =  publicKey.X.b;
        input[2] =  publicKey.Y.a;
        input[3] =  publicKey.Y.b;

        input[4] =  messageOnCurve.X.a.a;
        input[5] =  messageOnCurve.X.a.b;
        input[6] =  messageOnCurve.X.b.a;
        input[7] =  messageOnCurve.X.b.b;
        input[8] =  messageOnCurve.Y.a.a;
        input[9] =  messageOnCurve.Y.a.b;
        input[10] = messageOnCurve.Y.b.a;
        input[11] = messageOnCurve.Y.b.b;

        // NOTE: this constant is -P1, where P1 is the generator of the group G1.
        input[12] = 31827880280837800241567138048534752271;
        input[13] = 88385725958748408079899006800036250932223001591707578097800747617502997169851;
        input[14] = 22997279242622214937712647648895181298;
        input[15] = 46816884707101390882112958134453447585552332943769894357249934112654335001290;

        input[16] =  signature.X.a.a;
        input[17] =  signature.X.a.b;
        input[18] =  signature.X.b.a;
        input[19] =  signature.X.b.b;
        input[20] =  signature.Y.a.a;
        input[21] =  signature.Y.a.b;
        input[22] =  signature.Y.b.a;
        input[23] =  signature.Y.b.b;

        uint[1] memory output;

        bool success;
        assembly {
            success := staticcall(
                sub(gas(), 2000),
                0x10,
                input,
                768,
                output,
                32
            )
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success, "call to pairing precompile failed");

        return output[0] == 1;
    }

    function aggregate_pks(bytes[] calldata pubkeys) internal view returns (B12.G1Point memory) {
        uint len = pubkeys.length;
        require(len > 0, "!pubkeys");
        B12.G1Point memory g1 = B12.parseG1(pubkeys[0], 0);
        for (uint i = 1; i < len; i++) {
            g1 = B12_381Lib.g1Add(g1, B12.parseG1(pubkeys[i], 0));
        }
        // TODO: Ensure AggregatePublicKey is not infinity
        return g1;
    }

    function hash_to_curve(bytes32 message) internal view returns (B12.G2Point memory) {
        B12.Fp2[2] memory messageElementsInField = hash_to_field(message);
        B12.G2Point memory firstPoint = B12_381Lib.mapToG2(messageElementsInField[0]);
        B12.G2Point memory secondPoint = B12_381Lib.mapToG2(messageElementsInField[1]);
        return B12_381Lib.g2Add(firstPoint, secondPoint);
    }

    function hash_to_field(bytes32 message) internal view returns (B12.Fp2[2] memory result) {
        bytes memory some_bytes = expand_message(message);
        result[0] = B12.Fp2(
            convert_slice_to_fp(some_bytes, 0, 64),
            convert_slice_to_fp(some_bytes, 64, 128)
        );
        result[1] = B12.Fp2(
            convert_slice_to_fp(some_bytes, 128, 192),
            convert_slice_to_fp(some_bytes, 192, 256)
        );
    }

    function expand_message(bytes32 message) public pure returns (bytes memory) {
        bytes memory b0Input = new bytes(143);
        for (uint i = 0; i < 32; i++) {
            b0Input[i+64] = message[i];
        }
        b0Input[96] = 0x01;
        for (uint i = 0; i < 44; i++) {
            b0Input[i+99] = bytes(BLS_SIG_DST)[i];
        }

        bytes32 b0 = sha256(abi.encodePacked(b0Input));

        bytes memory output = new bytes(256);
        bytes32 chunk = sha256(abi.encodePacked(b0, byte(0x01), bytes(BLS_SIG_DST)));
        assembly {
            mstore(add(output, 0x20), chunk)
        }
        for (uint i = 2; i < 9; i++) {
            bytes32 input;
            assembly {
                input := xor(b0, mload(add(output, add(0x20, mul(0x20, sub(i, 2))))))
            }
            chunk = sha256(abi.encodePacked(input, byte(uint8(i)), bytes(BLS_SIG_DST)));
            assembly {
                mstore(add(output, add(0x20, mul(0x20, sub(i, 1)))), chunk)
            }
        }

        return output;
    }

    function convert_slice_to_fp(bytes memory data, uint start, uint end) private view returns (B12.Fp memory) {
        bytes memory fieldElement = reduce_modulo(data, start, end);
        uint a = slice_to_uint(fieldElement, 0, 16);
        uint b = slice_to_uint(fieldElement, 16, 48);
        return B12.Fp(a, b);
    }

    function slice_to_uint(bytes memory data, uint start, uint end) private pure returns (uint) {
        uint length = end - start;
        assert(length >= 0);
        assert(length <= 32);

        uint result;
        for (uint i = 0; i < length; i++) {
            byte b = data[start+i];
            result = result + (uint8(b) * 2**(8*(length-i-1)));
        }
        return result;
    }

    function reduce_modulo(bytes memory data, uint start, uint end) private view returns (bytes memory) {
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
            mstore(modulusAddr, or(mload(modulusAddr), 0x1a0111ea397fe69a4b1ba7b6434bacd7)) // pt 1
            mstore(add(p, add(0x90, length)), 0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab) // pt 2
            success := staticcall(
                sub(gas(), 2000),
                MOD_EXP_PRECOMPILE_ADDRESS,
                p,
                add(0xB0, length),
                add(result, 0x20),
                48)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success, "call to modular exponentiation precompile failed");
        return result;
    }
}
