// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IXcmTransactor.sol";
import "../s2s/types/PalletEthereumXcm.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "./DarwiniaLib.sol";

contract DarwiniaEndpoint {
    address public constant DISPATCH = 0x0000000000000000000000000000000000000401;
    bytes2 public immutable transactThroughSignedCallIndex = 0x2d06;
    bytes2 public immutable darwiniaParaId = 0xf91f;

    function dispatchOnParachain(bytes2 paraId, bytes memory dispatchCall, uint64 weight) external {
        transactThroughSigned(
            paraId, 
            dispatchCall,
            weight
        );
    }

    /////////////////////////////////////////////
    // INTERNAL FUNCTIONS
    /////////////////////////////////////////////
    function transactThroughSigned(
        bytes2 paraId,
        bytes memory call,
        uint64 weight
    ) internal {
        (bool success, bytes memory data) = DISPATCH.call(
            DarwiniaLib.buildCall_TransactThroughSigned(
                transactThroughSignedCallIndex, // callIndex
                paraId, // astar paraid
                darwiniaParaId, // dariwnia paraid
                hex"", // call
                0 // weight TODO: fix
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
