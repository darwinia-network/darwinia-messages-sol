// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IXcmTransactor.sol";
import "../s2s/types/PalletEthereumXcm.sol";

contract DarwiniaEndpoint {
    address public constant DISPATCH = 0x0000000000000000000000000000000000000401;
    // TODO: correct 
    uint64 public constant ASTAR_WEIGHT_PER_GAS = 40_000;
    bytes2 public constant ASTAR_PARA_ID = 0x0000;
    bytes2 public constant ASTAR_TRANSACT_CALL_INDEX = 0x0000;

    function executeOnAstar(address to, bytes memory input, uint256 gasLimit) external {
        // the `EthereumXcm`.`Transact` call which will be execute on astar
        // TODO: optimization
        bytes memory transactCall = PalletEthereumXcm.buildTransactCall(
            ASTAR_TRANSACT_CALL_INDEX, // `EthereumXcm`.`Transact`
            gasLimit,
            to,
            0, // value
            input
        );

        transactThroughSigned(
            ASTAR_PARA_ID, 
            uint64(gasLimit * ASTAR_WEIGHT_PER_GAS),
            transactCall
        );
    }

    /////////////////////////////////////////////
    // INTERNAL FUNCTIONS
    /////////////////////////////////////////////
    function transactThroughSigned(
        bytes2 astarParaId,
        uint64 callWeight,
        bytes memory call
    ) internal {
        // the `XcmTransactor`.`TransactThroughSigned` call
        bytes2 darwiniaParaId = 0xf91f;
        bytes memory callDataOfTransactThroughSigned = abi.encodePacked(
            hex"2d06", // `XcmTransactor`.`TransactThroughSigned`

            // DEST: V2(01, X1(Parachain(ParaId)))
            //       00(01, 01(       00(  e520)))
            hex"00010100", astarParaId, 

            // FEE: AsMultiLocation(V2(01, X2(Parachain(ParaId), PalletInstance(05))), feeAmount)
            //                   01(00(01, 02(       00(  e520),             04(05))), 00)
            hex"0100010200", darwiniaParaId, hex"040500",

            // CALL
            call, // TODO: add length prefix

            // WEIGHTINFO TODO: ?
            callWeight, // transactrequiredweightatmost
            hex"00" // overallweight
        );

        (bool success, bytes memory data) = DISPATCH.call(callDataOfTransactThroughSigned);

        if (!success) {
            if (data.length > 0) {
                assembly {
                    let resultDataSize := mload(data)
                    revert(add(32, data), resultDataSize)
                }
            } else {
                revert("!dispatch");
            }
        }
    }
}
