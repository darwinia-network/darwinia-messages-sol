// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./Fp.sol";

struct G1Point {
    Fp x;
    Fp y;
}

library G1 {
    using FP for Fp;

    uint8 private constant G1_ADD = 0x0A;
    uint8 private constant G1_MUL = 0x0B;
    uint8 private constant MAP_FP_TO_G1 = 0x11;

    function negativeP1() internal pure returns (G1Point memory p) {
        p.x.a = 31827880280837800241567138048534752271;
        p.x.b = 88385725958748408079899006800036250932223001591707578097800747617502997169851;
        p.y.a = 22997279242622214937712647648895181298;
        p.y.b = 46816884707101390882112958134453447585552332943769894357249934112654335001290;
    }

    function eq(G1Point memory p, G1Point memory q)
        internal
        pure
        returns (bool)
    {
        return (p.x.eq(q.x) && p.y.eq(q.y));
    }

    function add(G1Point memory p, G1Point memory q) internal view returns (G1Point memory) {
        uint[8] memory input;
        input[0] = p.x.a;
        input[1] = p.x.b;
        input[2] = p.y.a;
        input[3] = p.y.b;
        input[4] = q.x.a;
        input[5] = q.x.b;
        input[6] = q.y.a;
        input[7] = q.y.b;
        uint[4] memory output;

        assembly {
            if iszero(staticcall(500, G1_ADD, input, 256, output, 128)) {
                 returndatacopy(0, 0, returndatasize())
                 revert(0, returndatasize())
            }
        }

        return from(output);
    }

    function mul(G1Point memory p, uint scalar) internal view returns (G1Point memory) {
        uint[5] memory input;
        input[0] = p.x.a;
        input[1] = p.x.b;
        input[2] = p.y.a;
        input[3] = p.y.b;
        input[4] = scalar;
        uint[4] memory output;

        assembly {
            if iszero(staticcall(12000, G1_MUL, input, 160, output, 128)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        return from(output);
    }

    function map_to_curve(Fp memory f) internal view returns (G1Point memory) {
        uint[2] memory input;
        input[0] = f.a;
        input[1] = f.b;
        uint[4] memory output;

        assembly {
            if iszero(staticcall(5500, MAP_FP_TO_G1, input, 64, output, 128)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        return from(output);
    }

    function from(uint[4] memory x) internal view returns (G1Point memory) {
        return G1Point(Fp(x[0], x[1]), Fp(x[2], x[3]));
    }

    function decode(bytes memory pubkey) internal view returns (G1Point memory) {}
}
