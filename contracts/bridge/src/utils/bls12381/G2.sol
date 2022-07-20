// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./Fp2.sol";

struct G2Point {
    Fp2 x;
    Fp2 y;
}

library G2 {
    using FP2 for Fp2;

    uint8 private constant G2_ADD = 0x0D;
    uint8 private constant G2_MUL = 0x0E;
    uint8 private constant MAP_FP2_TO_G2 = 0x12;

    function eq(G2Point memory p, G2Point memory q)
        internal
        pure
        returns (bool)
    {
        return (p.x.eq(q.x) && p.y.eq(q.y));
    }

    function add(G2Point memory p, G2Point memory q) internal view returns (G2Point memory) {
        uint[16] memory input;
        input[0]  = p.x.c0.a;
        input[1]  = p.x.c0.b;
        input[2]  = p.x.c1.a;
        input[3]  = p.x.c1.b;
        input[4]  = p.y.c0.a;
        input[5]  = p.y.c0.b;
        input[6]  = p.y.c1.a;
        input[7]  = p.y.c1.b;
        input[8]  = q.x.c0.a;
        input[9]  = q.x.c0.b;
        input[10] = q.x.c1.a;
        input[11] = q.x.c1.b;
        input[12] = q.y.c0.a;
        input[13] = q.y.c0.b;
        input[14] = q.y.c1.a;
        input[15] = q.y.c1.b;
        uint[8] memory output;

        assembly {
            if iszero(staticcall(800, G2_ADD, input, 512, output, 256)) {
                 returndatacopy(0, 0, returndatasize())
                 revert(0, returndatasize())
            }
        }

        return from(output);
    }

    function mul(G2Point memory p, uint scalar) internal view returns (G2Point memory) {
        uint[9] memory input;
        input[0] = p.x.c0.a;
        input[1] = p.x.c0.b;
        input[2] = p.x.c1.a;
        input[3] = p.x.c1.b;
        input[4] = p.y.c0.a;
        input[5] = p.y.c0.b;
        input[6] = p.y.c1.a;
        input[7] = p.y.c1.b;
        input[8] = scalar;
        uint[8] memory output;

        assembly {
            if iszero(staticcall(45000, G2_MUL, input, 288, output, 256)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        return from(output);
    }

    function map_to_curve(Fp2 memory f) internal view returns (G2Point memory) {
        uint[4] memory input;
        input[0] = f.c0.a;
        input[1] = f.c0.b;
        input[2] = f.c1.a;
        input[3] = f.c1.b;
        uint[8] memory output;

        assembly {
            if iszero(staticcall(75000, MAP_FP2_TO_G2, input, 64, output, 128)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        return from(output);
    }

    function from(uint[8] memory x) internal view returns (G2Point memory) {
        return G2Point(
            Fp2(
                Fp(x[0], x[1]),
                Fp(x[2], x[3])
            ),
            Fp2(
                Fp(x[4], x[5]),
                Fp(x[6], x[7])
            )
        );
    }

    function decode(bytes memory pubkey) internal view returns (G2Point memory) {}
}
