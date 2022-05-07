// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "../test.sol";
import "../../utils/ScaleCodec.sol";

contract ScaleCodecTest is DSTest {

    function test_decode_uint_compact() public {
        assertEq(ScaleCodec.decodeUintCompact(hex"00"), 0);
        assertEq(ScaleCodec.decodeUintCompact(hex"fc"), 63);

        assertEq(ScaleCodec.decodeUintCompact(hex"0101"), 64);
        assertEq(ScaleCodec.decodeUintCompact(hex"fdff"), 16383);

        assertEq(ScaleCodec.decodeUintCompact(hex"02000100"), 16384);
        assertEq(ScaleCodec.decodeUintCompact(hex"feffffff"), 1073741823);
    }

    function testFail_decode_uint_compact() public {
        assertEq(ScaleCodec.decodeUintCompact(hex"0300000040"), 1073741824);
        assertEq(ScaleCodec.decodeUintCompact(hex"070000000001"), 1 << 32);
        assertEq(ScaleCodec.decodeUintCompact(hex"0fffffffffffffff"), 1 << 48);
        assertEq(ScaleCodec.decodeUintCompact(hex"130000000000000001"), 1 << 56);
    }

    function test_decode_uint256() public {
        assertEq(ScaleCodec.decodeUint256(hex"1d0000"), 29);
        assertEq(ScaleCodec.decodeUint256(hex"1d000000000000000000000000000000"), 29);
        assertEq(ScaleCodec.decodeUint256(hex"3412"), 4660);
        assertEq(ScaleCodec.decodeUint256(hex"201f1e1d1c1b1a1817161514131211100f0e0d0c0b0a09080706050403020100"), 1780731860627700044960722568376592200742329637303199754547880948779589408);
    }

    function test_encode64() public {
        assertEq(ScaleCodec.encode64(1921902728173129883), hex"9b109d3d59f8ab1a");
    }

    function test_encode32() public {
        assertEq(ScaleCodec.encode32(447477849), hex"59f8ab1a");
    }

    function test_encode16() public {
        assertEq(ScaleCodec.encode16(6827), hex"ab1a");
    }
}
