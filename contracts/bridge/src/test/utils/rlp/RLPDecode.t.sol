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

import "../../test.sol";
import "../../../utils/rlp/RLPDecode.sol";

contract RLPDecodeTest is DSTest {
    function test_readBytes_bytestring00_succeeds() external {
        assertEq0(RLPDecode.readBytes(hex"00"), hex"00");
    }

    function test_readBytes_bytestring01_succeeds() external {
        assertEq0(RLPDecode.readBytes(hex"01"), hex"01");
    }

    function test_readBytes_bytestring7f_succeeds() external {
        assertEq0(RLPDecode.readBytes(hex"7f"), hex"7f");
    }

    function testFail_readBytes_revertListItem_reverts() external pure {
        // vm.expectRevert("RLPDecode: decoded item type for bytes is not a data item");
        RLPDecode.readBytes(hex"c7c0c1c0c3c0c1c0");
    }

    function testFail_readBytes_invalidStringLength_reverts() external pure {
        // vm.expectRevert(
        //     "RLPDecode: length of content must be > than length of string length (long string)"
        // );
        RLPDecode.readBytes(hex"b9");
    }

    function testFail_readBytes_invalidListLength_reverts() external pure {
        // vm.expectRevert(
        //     "RLPDecode: length of content must be > than length of list length (long list)"
        // );
        RLPDecode.readBytes(hex"ff");
    }

    function testFail_readBytes_invalidRemainder_reverts() external pure {
        // vm.expectRevert("RLPDecode: bytes value contains an invalid remainder");
        RLPDecode.readBytes(hex"800a");
    }

    function testFail_readBytes_invalidPrefix_reverts() external pure {
        // vm.expectRevert(
        //     "RLPDecode: invalid prefix, single byte < 0x80 are not prefixed (short string)"
        // );
        RLPDecode.readBytes(hex"810a");
    }

    function test_decode_list_empty_succeeds() external {
        RLPDecode.RLPItem[] memory list = RLPDecode.readList(hex"c0");
        assertEq(list.length, 0);
    }

    function test_decode_list_multiList_succeeds() external {
        RLPDecode.RLPItem[] memory list = RLPDecode.readList(hex"c6827a77c10401");
        assertEq(list.length, 3);

        assertEq0(RLPDecode.readRawBytes(list[0]), hex"827a77");
        assertEq0(RLPDecode.readRawBytes(list[1]), hex"c104");
        assertEq0(RLPDecode.readRawBytes(list[2]), hex"01");
    }

    function test_decode_list_shortListMax1_succeeds() external {
        RLPDecode.RLPItem[] memory list = RLPDecode.readList(
            hex"f784617364668471776572847a78637684617364668471776572847a78637684617364668471776572847a78637684617364668471776572"
        );

        assertEq(list.length, 11);
        assertEq0(RLPDecode.readRawBytes(list[0]), hex"8461736466");
        assertEq0(RLPDecode.readRawBytes(list[1]), hex"8471776572");
        assertEq0(RLPDecode.readRawBytes(list[2]), hex"847a786376");
        assertEq0(RLPDecode.readRawBytes(list[3]), hex"8461736466");
        assertEq0(RLPDecode.readRawBytes(list[4]), hex"8471776572");
        assertEq0(RLPDecode.readRawBytes(list[5]), hex"847a786376");
        assertEq0(RLPDecode.readRawBytes(list[6]), hex"8461736466");
        assertEq0(RLPDecode.readRawBytes(list[7]), hex"8471776572");
        assertEq0(RLPDecode.readRawBytes(list[8]), hex"847a786376");
        assertEq0(RLPDecode.readRawBytes(list[9]), hex"8461736466");
        assertEq0(RLPDecode.readRawBytes(list[10]), hex"8471776572");
    }

    function test_decode_list_longList1_succeeds() external {
        RLPDecode.RLPItem[] memory list = RLPDecode.readList(
            hex"f840cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376"
        );

        assertEq(list.length, 4);
        assertEq0(RLPDecode.readRawBytes(list[0]), hex"cf84617364668471776572847a786376");
        assertEq0(RLPDecode.readRawBytes(list[1]), hex"cf84617364668471776572847a786376");
        assertEq0(RLPDecode.readRawBytes(list[2]), hex"cf84617364668471776572847a786376");
        assertEq0(RLPDecode.readRawBytes(list[3]), hex"cf84617364668471776572847a786376");
    }

    function test_decode_list_longList2_succeeds() external {
        RLPDecode.RLPItem[] memory list = RLPDecode.readList(
            hex"f90200cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376cf84617364668471776572847a786376"
        );
        assertEq(list.length, 32);

        for (uint256 i = 0; i < 32; i++) {
            assertEq0(RLPDecode.readRawBytes(list[i]), hex"cf84617364668471776572847a786376");
        }
    }

    function testFail_decode_list_listLongerThan32Elements_reverts() external pure {
        // vm.expectRevert(stdError.indexOOBError);
        RLPDecode.readList(
            hex"e1454545454545454545454545454545454545454545454545454545454545454545"
        );
    }

    function test_decode_list_listOfLists_succeeds() external {
        RLPDecode.RLPItem[] memory list = RLPDecode.readList(hex"c4c2c0c0c0");
        assertEq(list.length, 2);
        assertEq0(RLPDecode.readRawBytes(list[0]), hex"c2c0c0");
        assertEq0(RLPDecode.readRawBytes(list[1]), hex"c0");
    }

    function test_decode_list_listOfLists2_succeeds() external {
        RLPDecode.RLPItem[] memory list = RLPDecode.readList(hex"c7c0c1c0c3c0c1c0");
        assertEq(list.length, 3);

        assertEq0(RLPDecode.readRawBytes(list[0]), hex"c0");
        assertEq0(RLPDecode.readRawBytes(list[1]), hex"c1c0");
        assertEq0(RLPDecode.readRawBytes(list[2]), hex"c3c0c1c0");
    }

    function test_decode_list_dictTest1_succeeds() external {
        RLPDecode.RLPItem[] memory list = RLPDecode.readList(
            hex"ecca846b6579318476616c31ca846b6579328476616c32ca846b6579338476616c33ca846b6579348476616c34"
        );
        assertEq(list.length, 4);

        assertEq0(RLPDecode.readRawBytes(list[0]), hex"ca846b6579318476616c31");
        assertEq0(RLPDecode.readRawBytes(list[1]), hex"ca846b6579328476616c32");
        assertEq0(RLPDecode.readRawBytes(list[2]), hex"ca846b6579338476616c33");
        assertEq0(RLPDecode.readRawBytes(list[3]), hex"ca846b6579348476616c34");
    }

    function testFail_decode_list_invalidShortList_reverts() external pure {
        // vm.expectRevert(
        //     "RLPDecode: length of content must be greater than list length (short list)"
        // );
        RLPDecode.readList(hex"efdebd");
    }

    function testFail_decode_list_longStringLength_reverts() external pure {
        // vm.expectRevert(
        //     "RLPDecode: length of content must be greater than list length (short list)"
        // );
        RLPDecode.readList(hex"efb83600");
    }

    function testFail_decode_list_notLongEnough_reverts() external pure {
        // vm.expectRevert(
        //     "RLPDecode: length of content must be greater than list length (short list)"
        // );
        RLPDecode.readList(
            hex"efdebdaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        );
    }

    function testFail_decode_list_int32Overflow_reverts() external pure {
        // vm.expectRevert(
        //     "RLPDecode: length of content must be greater than total length (long string)"
        // );
        RLPDecode.readList(hex"bf0f000000000000021111");
    }

    function testFail_decode_list_int32Overflow2_reverts() external pure {
        // vm.expectRevert(
        //     "RLPDecode: length of content must be greater than total length (long list)"
        // );
        RLPDecode.readList(hex"ff0f000000000000021111");
    }

    function testFail_decode_list_incorrectLengthInArray_reverts() external pure {
        // vm.expectRevert(
        //     "RLPDecode: length of content must not have any leading zeros (long string)"
        // );
        RLPDecode.readList(
            hex"b9002100dc2b275d0f74e8a53e6f4ec61b27f24278820be3f82ea2110e582081b0565df0"
        );
    }

    function testFail_decode_list_leadingZerosInLongLengthArray1_reverts() external pure {
        // vm.expectRevert(
        //     "RLPDecode: length of content must not have any leading zeros (long string)"
        // );
        RLPDecode.readList(
            hex"b90040000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f"
        );
    }

    function testFail_decode_list_leadingZerosInLongLengthArray2_reverts() external pure {
        // vm.expectRevert(
        //     "RLPDecode: length of content must not have any leading zeros (long string)"
        // );
        RLPDecode.readList(hex"b800");
    }

    function testFail_decode_list_leadingZerosInLongLengthList1_reverts() external pure {
        // vm.expectRevert("RLPDecode: length of content must not have any leading zeros (long list)");
        RLPDecode.readList(
            hex"fb00000040000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f"
        );
    }

    function testFail_decode_list_nonOptimalLongLengthArray1_reverts() external pure {
        // vm.expectRevert("RLPDecode: length of content must be greater than 55 bytes (long string)");
        RLPDecode.readList(hex"b81000112233445566778899aabbccddeeff");
    }

    function testFail_decode_list_nonOptimalLongLengthArray2_reverts() external pure {
        // vm.expectRevert("RLPDecode: length of content must be greater than 55 bytes (long string)");
        RLPDecode.readList(hex"b801ff");
    }

    function testFail_decode_list_invalidValue_reverts() external pure {
        // vm.expectRevert(
        //     "RLPDecode: length of content must be greater than string length (short string)"
        // );
        RLPDecode.readList(hex"91");
    }

    function testFail_decode_list_invalidRemainder_reverts() external pure {
        // vm.expectRevert("RLPDecode: list item has an invalid data remainder");
        RLPDecode.readList(hex"c000");
    }

    function testFail_decode_list_notEnoughContentForString1_reverts() external pure {
        // vm.expectRevert(
        //     "RLPDecode: length of content must be greater than total length (long string)"
        // );
        RLPDecode.readList(hex"ba010000aabbccddeeff");
    }

    function testFail_decode_list_notEnoughContentForString2_reverts() external pure {
        // vm.expectRevert(
        //     "RLPDecode: length of content must be greater than total length (long string)"
        // );
        RLPDecode.readList(hex"b840ffeeddccbbaa99887766554433221100");
    }

    function testFail_decode_list_notEnoughContentForList1_reverts() external pure {
        // vm.expectRevert(
        //     "RLPDecode: length of content must be greater than total length (long list)"
        // );
        RLPDecode.readList(hex"f90180");
    }

    function testFail_decode_list_notEnoughContentForList2_reverts() external pure {
        // vm.expectRevert(
        //     "RLPDecode: length of content must be greater than total length (long list)"
        // );
        RLPDecode.readList(hex"ffffffffffffffffff0001020304050607");
    }

    function testFail_decode_list_longStringLessThan56Bytes_reverts() external pure {
        // vm.expectRevert("RLPDecode: length of content must be greater than 55 bytes (long string)");
        RLPDecode.readList(hex"b80100");
    }

    function testFail_decode_list_longListLessThan56Bytes_reverts() external pure {
        // vm.expectRevert("RLPDecode: length of content must be greater than 55 bytes (long list)");
        RLPDecode.readList(hex"f80100");
    }
}
