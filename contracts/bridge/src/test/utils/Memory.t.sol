// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

import "../test.sol";
import "../../utils/Memory.sol";

contract MemoryTest is DSTest {

    function test0() public {
        assertTrue(Memory.equals(0, 0, 0));
    }

    function test1() public {
        bytes memory bts = hex"0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f";
        bts;
        for (uint i = 0; i < 10; i++) {
            assertTrue(Memory.equals(0x15*i, 0x15*i, 50));
        }
    }

    function test2() public {
        bytes memory bts = hex"0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f0102030405060708090a0b0c0d0e0f";
        bts;
        for (uint i = 0; i < 10; i++) {
            assertTrue(Memory.equals(0x40, 0x40, 30*i));
        }
    }

    function test3() public {
        bytes memory bts = hex"0102030405060708090a0b";
        uint btsAddr;
        assembly {
            btsAddr := bts
        }
        assertTrue(!Memory.equals(btsAddr, btsAddr + 0x20, 10));
    }

    function test4() public {
        bytes memory bts = hex"0102030405060708090a0b";
        uint btsAddr;
        assembly {
            btsAddr := bts
        }
        assertTrue(!Memory.equals(btsAddr, btsAddr + 0x20, 10) && !Memory.equals(btsAddr + 0x20, btsAddr, 10));
    }

    function test5() public {
        assertTrue(Memory.equals(0, 0, new bytes(0)));
    }

    function testFail0() public pure {
        bytes memory bts = new bytes(2);
        Memory.equals(0, 3, bts);
    }

    function test6() public {
        uint cur;
        assembly {
            cur := mload(0x40)
        }
        uint mem = Memory.allocate(45);
        assert(mem == cur);
        uint newCur;
        assembly {
            newCur := mload(0x40)
        }
        assertTrue(newCur == cur + 45);
    }

    function test7() public {
        bytes memory bts = hex"0102030405060708090a0b";
        uint addr = Memory.ptr(bts);
        uint btsAddr;
        assembly {
            btsAddr := bts
        }
        assertTrue(addr == btsAddr);
    }

    function test8() public {
        bytes memory bts = hex"0102030405060708090a0b";
        uint addr = Memory.dataPtr(bts);
        uint btsDataAddr;
        assembly {
            btsDataAddr := add(bts, 0x20)
        }
        assertTrue(addr == btsDataAddr);
    }

    function test9() public {
        bytes memory bts = hex"0102030405060708090a0b";
        (uint addr, uint len) = Memory.fromBytes(bts);
        assert(len == bts.length);
        uint btsDataAddr;
        assembly {
            btsDataAddr := add(bts, 0x20)
        }
        assertTrue(addr == btsDataAddr);
    }

    function test10() public {
        bytes memory bts = hex"ffaaffaaffaaffaaffaaffaaffaaffffaaffaaffaaffaaffaaffaaffaaffffaaffaaffaaffaaffaaffaaffaaff";
        (uint src, uint len) = Memory.fromBytes(bts);
        uint dest = Memory.allocate(len);
        Memory.copy(src, dest, len);
        assertTrue(Memory.equals(dest, len, bts));
    }

    function test11() public {
        bytes memory bts = new bytes(0);
        bytes memory bts2 = hex"ffaa";
        (uint src, ) = Memory.fromBytes(bts);
        (uint dest, ) = Memory.fromBytes(bts2);
        Memory.copy(src, dest, 0);
        // Check that bts2 is still intact.
        assertTrue(bts2[0] == hex"ff");
        assertTrue(bts2[1] == hex"aa");
    }

    function test12() public {
        bytes memory bts = hex"ffaaffaaffaaffaaffaaffaaffaaffffaaffaaffaaffaaffaaffaaffaaffffaaffaaffaaffaaffaaffaaffaaff";
        (uint src, uint len) = Memory.fromBytes(bts);
        uint dest = Memory.allocate(len);
        Memory.copy(src, dest, len);
        assertTrue(Memory.equals(src, len, bts));
    }

    function test13() public {
        bytes memory bts = hex"ffaaffaaffaaffaaffaaffaaffaaff";
        (uint addr, uint len) = Memory.fromBytes(bts);
        bytes memory bts2 = Memory.toBytes(addr, len);
        assertTrue(bts2.length == bts.length);
        for (uint i = 0; i < bts.length; i++) {
            assertTrue(bts[i] == bts2[i]);
        }
    }

    function test14() public {
        uint n = 12345;
        uint addr = Memory.allocate(32);
        assembly {
            mstore(addr, n)
        }
        uint n2 = Memory.toUint(addr);
        assertTrue(n == n2);
    }

    function test15() public {
        bytes32 b32 = bytes32(uint(0x112233));
        uint addr = Memory.allocate(32);
        assembly {
            mstore(addr, b32)
        }
        bytes32 res = Memory.toBytes32(addr);
        assertTrue(res == b32);
    }
}
