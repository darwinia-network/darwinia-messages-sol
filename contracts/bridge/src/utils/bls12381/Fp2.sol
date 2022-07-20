// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./Fp.sol";

struct Fp2 {
    Fp c0;
    Fp c1;
}

library FP2 {
    using FP for Fp;

    function eq(Fp2 memory x, Fp2 memory y) internal pure returns (bool) {
        return (x.c0.eq(y.c0) && x.c1.eq(y.c1));
    }
}