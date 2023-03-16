// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IXcmTransactor.sol";
import "../interfaces/ICrossChainFilter.sol";
import "../s2s/types/PalletEthereumXcm.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "./DarwiniaLib.sol";

contract DarwiniaEndpoint is ICrossChainFilter {
    address public constant DISPATCH = 0x0000000000000000000000000000000000000401;
    bytes2 public immutable send = 0x2100;
    bytes2 public immutable fromParachain = 0xe520;

    function dispatchOnParachain(bytes2 paraId, bytes memory dispatchCall, uint64 weight) external {
        transactThroughSigned(
            paraId, 
            dispatchCall,
            weight
        );
    }

    function cross_chain_filter(
        uint32 bridgedChainPosition,
        uint32 bridgedLanePosition,
        address sourceAccount,
        bytes calldata payload
    ) external view returns (bool) {
        return true;
    }

    /////////////////////////////////////////////
    // INTERNAL FUNCTIONS
    /////////////////////////////////////////////
    function transactThroughSigned(
        bytes2 toParachain,
        bytes memory call,
        uint64 weight
    ) internal {
        (bool success, bytes memory data) = DISPATCH.call(
            abi.encodePacked(
                send, // call index
                hex"00010100", toParachain, // dest: V2(01, X1(Parachain(ParaId)))
                DarwiniaLib.xcmTransactOnParachain( // xcm
                    fromParachain,
                    call,
                    weight //  TODO: fix
                )
            )
        );

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
