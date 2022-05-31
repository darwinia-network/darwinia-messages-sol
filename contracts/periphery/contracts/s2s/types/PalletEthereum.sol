// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/Bytes.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "./CommonTypes.sol";

library PalletEthereum {
    struct SubstrateTransactCall {
        bytes2 callIndex;
        address target;
        bytes input;
    }

    function encodeSubstrateTransactCall(SubstrateTransactCall memory call) internal pure returns (bytes memory) {
        return abi.encodePacked(
            call.callIndex, 
            call.target, 
            ScaleCodec.encodeBytes(call.input)
        );
    }
}