// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../BaseApp.sol";
import "../../calls/PangolinCalls.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";

pragma experimental ABIEncoderV2;

// Remote call from Pangoro SmartChain
abstract contract PangoroApp is BaseApp {
    function init() internal {
        bridgeConfigs[PANGOLIN_CHAIN_ID] = BridgeConfig(
            0x1103,
            0x30d35416864cf657db51d3bc8505602f2edb70953213f33a6ef6b8a5e3ffcab2,
            0xd86d7f611f4d004e041fda08f633f10196c246acb9b55077390e3ca723a0ca1f
        );
    }

    function transactOnPangolin(
        bytes4 outboundLaneId,
        uint32 specVersionOfPangolin,
        address to,
        bytes memory input,
        uint256 gasLimit
    ) internal returns (uint64) {
        (bytes memory call, uint64 weight) = PangolinCalls
            .ethereum_messageTransact(gasLimit, to, input);

        return
            sendMessage(
                PANGOLIN_CHAIN_ID,
                outboundLaneId,
                MessagePayload(specVersionOfPangolin, weight, call)
            );
    }
}