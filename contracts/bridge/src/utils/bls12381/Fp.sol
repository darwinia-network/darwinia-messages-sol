// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

struct Fp {
    uint a;
    uint b;
}

library FP {

    // Base field modulus = 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
    function p() internal pure returns (Fp memory) {
        return Fp(0x1a0111ea397fe69a4b1ba7b6434bacd7, 0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab);
    }

    function one() internal pure returns (Fp memory) {
        return Fp(0, 1);
    }

    function three() internal pure returns (Fp memory) {
        return Fp(0, 3);
    }

    function four() internal pure returns (Fp memory) {
        return Fp(0, 4);
    }

    function is_valid(Fp memory x) internal pure returns (bool) {
        return gt(p(), x);
    }

    function is_zero(Fp memory x) internal pure returns (bool) {
        return x.a == 0 && x.b == 0;
    }

    function eq(Fp memory x, Fp memory y) internal pure returns (bool) {
        return (x.a == y.a && x.b == y.b);
    }

    function gt(Fp memory x, Fp memory y) internal pure returns (bool) {
        return (x.a > y.a || (x.a == y.a && x.b > y.b));
    }

    function add(Fp memory x, Fp memory y) internal pure returns (Fp memory z) {
        z.b = x.b + y.b;
        z.a = x.a + y.a + (z.b >= x.b && z.b >= y.b ? 0 : 1);
        if (gt(z, p()) {
            z = sub(z, p());
        }
    }

    function sub(Fp memory x, Fp memory y) internal pure returns (Fp memory z) {
        if (gt(y, x)) {
            x = add(x, p());
        }
        z.b = x.b - y.b;
        z.a = x.a - y.a - (z.b <= x.b ? 0 : 1);
    }

    function from(bytes memory data, uint start, uint end) internal view returns (Fp memory) {
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
