// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../test.sol";
import "../../../utils/bls12381/Fp2.sol";

contract FP2Test is DSTest {
    using FP2 for Fp2;

    function test_serialize() public {
        Fp2 memory q2 = Fp2(FP.q(), FP.zero());
        assertEq0(q2.serialize(), hex'0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab');
    }

    function test_is_zero() public {
        Fp2 memory q2 = Fp2(FP.q(), FP.zero());
        Fp2 memory zero2 = Fp2(FP.zero(), FP.zero());
        assertTrue(zero2.is_zero());
        assertTrue(!q2.is_zero());
    }
}
