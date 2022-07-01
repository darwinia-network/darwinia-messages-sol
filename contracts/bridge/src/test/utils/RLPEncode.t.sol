// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "../test.sol";
import "../../utils/RLPEncode.sol";

contract RLPEncodeTest is DSTest {
    function test_encode_bytes() public {
        assertEq0(
            RLPEncode.encodeBytes(hex'deadbeef'),
            hex'84deadbeef'
        );
        assertEq0(
            RLPEncode.encodeBytes(hex'0f'),
            hex'0f'
        );
        assertEq0(
            RLPEncode.encodeBytes(hex'0400'),
            hex'820400'
        );
    }

    function test_encode_string() public {
        assertEq0(
            RLPEncode.encodeString(''),
            hex'80'
        );
        assertEq0(
            RLPEncode.encodeString('dog'),
            hex'83646f67'
        );
        assertEq0(
            RLPEncode.encodeString('Lorem ipsum dolor sit amet, consectetur adipisicing elit'),
            hex'b8384c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e7365637465747572206164697069736963696e6720656c6974'
        );
    }

    function test_encode_address() public {
        assertEq0(
            RLPEncode.encodeAddress(0xaa6e07aC6B69723eCAdfe1483A75d72E7740ECDC),
            hex'94aa6e07ac6b69723ecadfe1483a75d72e7740ecdc'
        );
    }

    function test_encode_uint() public {
        assertEq0(
            RLPEncode.encodeUint(0),
            hex'80'
        );
        assertEq0(
            RLPEncode.encodeUint(15),
            hex'0f'
        );
        assertEq0(
            RLPEncode.encodeUint(1024),
            hex'820400'
        );
    }

    function test_encode_bool() public {
        assertEq0(
            RLPEncode.encodeBool(true),
            hex'01'
        );
        assertEq0(
            RLPEncode.encodeBool(false),
            hex'80'
        );
    }

    function test_encode_list() public {
        bytes[] memory p = new bytes[](1);
        p[0] = RLPEncode.encodeBytes(hex'f843a120bb1a6e4ccaed62181ab95a202f4e45c3f9f171ce3aff3cad7b56641d0929f678a0de3ab968a3335494010c90e8741a537971d635808651318a7b752898fd30cdeb');
        bytes memory data = RLPEncode.encodeList(p);
        assertEq0(data, hex'f847b845f843a120bb1a6e4ccaed62181ab95a202f4e45c3f9f171ce3aff3cad7b56641d0929f678a0de3ab968a3335494010c90e8741a537971d635808651318a7b752898fd30cdeb');
    }
}
