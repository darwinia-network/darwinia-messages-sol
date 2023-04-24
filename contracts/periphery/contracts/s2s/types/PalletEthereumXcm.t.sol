// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../../ds-test/test.sol";
import "./PalletEthereumXcm.sol";

import "hardhat/console.sol";

pragma experimental ABIEncoderV2;

contract PalletEthereumXcmTest is DSTest {
    function setUp() public {}

    function testEncodeTransactCall() public {
        PalletEthereumXcm.AccessListType memory list;
        list.some = false;

        bytes memory data = PalletEthereumXcm.encodeTransactCall(
            PalletEthereumXcm.TransactCall(
                hex"2600",
                PalletEthereumXcm.EthereumXcmTransaction(
                    1,
                    PalletEthereumXcm.EthereumXcmTransactionV2(
                        600000,
                        PalletEthereumXcm.TransactionAction(
                            0, 0x0000000000000000000000000000000000000000
                        ),
                        0,
                        hex"1234",
                        list
                    )
                )
            )
        );

        assertEq0(data, hex"260001c027090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008123400");
    }

    function testEncodeTransactCall2() public {
        bytes memory data = PalletEthereumXcm.buildTransactCall(
            hex"2600",
            600000,
            0x0000000000000000000000000000000000000000,
            0,
            hex"1234"
        );

        assertEq0(data, hex"260001c027090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008123400");
    }

    function testAccessListType() public {
        // none
        PalletEthereumXcm.AccessListType memory list;
        list.some = false;
        bytes memory data = PalletEthereumXcm.encodeAccessListType(list);
        assertEq0(data, hex"00");

        // some
        PalletEthereumXcm.AccessListType memory list4 = PalletEthereumXcm.AccessListType(
            true,
            new PalletEthereumXcm.TupleOfH160AndVecOfH256[](0)     
        );
        bytes memory data4 = PalletEthereumXcm.encodeAccessListType(list4);
        assertEq0(data4, hex"0100");

        // some
        PalletEthereumXcm.AccessListType memory list3 = PalletEthereumXcm.AccessListType(
            true,
            new PalletEthereumXcm.TupleOfH160AndVecOfH256[](1)     
        );
        //
        PalletEthereumXcm.TupleOfH160AndVecOfH256 memory tuple2 = PalletEthereumXcm.TupleOfH160AndVecOfH256(
            address(0),
            new bytes32[](0)
        );
        //
        list3.arr[0] = tuple2;
        bytes memory data3 = PalletEthereumXcm.encodeAccessListType(list3);
        assertEq0(data3, hex"0104000000000000000000000000000000000000000000");

        // some
        PalletEthereumXcm.AccessListType memory list2 = PalletEthereumXcm.AccessListType(
            true,
            new PalletEthereumXcm.TupleOfH160AndVecOfH256[](1)     
        );
        //
        PalletEthereumXcm.TupleOfH160AndVecOfH256 memory tuple = PalletEthereumXcm.TupleOfH160AndVecOfH256(
            address(0),
            new bytes32[](1)
        );
        tuple.vecOfH256[0] = bytes32(0x30d35416864cf657db51d3bc8505602f2edb70953213f33a6ef6b8a5e3ffcab2);
        //
        list2.arr[0] = tuple;
        bytes memory data2 = PalletEthereumXcm.encodeAccessListType(list2);
        assertEq0(data2, hex"010400000000000000000000000000000000000000000430d35416864cf657db51d3bc8505602f2edb70953213f33a6ef6b8a5e3ffcab2");
    }
}