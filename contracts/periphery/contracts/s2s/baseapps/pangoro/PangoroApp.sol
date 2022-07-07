// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../BaseApp.sol";
import "../../calls/PangolinCalls.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";

pragma experimental ABIEncoderV2;

// Remote call from Pangoro SmartChain
abstract contract PangoroApp is BaseApp {
    function _init() internal {
        bridgeConfigs[_PANGOLIN_CHAIN_ID] = BridgeConfig(
            0x1103,
            0x30d35416864cf657db51d3bc8505602f2edb70953213f33a6ef6b8a5e3ffcab2,
            0xd86d7f611f4d004e041fda08f633f10196c246acb9b55077390e3ca723a0ca1f
        );
    }

    function _buildMessageTransactCall(
        bytes4 _targetChainId,
        address _to,
        bytes memory _input,
        uint256 _gasLimit
    ) internal pure override returns (bytes memory, uint64) {
        bytes memory call;
        uint64 weight;

        if (_targetChainId == _PANGOLIN_CHAIN_ID) {
            (call, weight) = PangolinCalls.ethereum_messageTransact(
                _gasLimit,
                _to,
                _input
            );
        } else {
            revert("Unsupported target chain");
        }

        return (call, weight);
    }
}
