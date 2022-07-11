// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../BaseApp.sol";
import "../../calls/PangoroCalls.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/AccountId.sol";

// Remote call from Pangolin SmartChain
abstract contract PangolinApp is BaseApp {
    constructor() internal {
        bridgeConfigs[_PANGORO_CHAIN_ID] = BridgeConfig(
            0x2b03,
            0x7621b367d09b75f6876b13089ee0ded52edb70953213f33a6ef6b8a5e3ffcab2,
            0xc9b76e645ba80b6ca47619d64cb5e58d96c246acb9b55077390e3ca723a0ca1f
        );

        bridgeConfigs[_PANGOLIN_PARACHAIN_CHAIN_ID] = BridgeConfig(
            0x3f03,
            0x39bf2363dd0720bd6e11a4c86f4949322edb70953213f33a6ef6b8a5e3ffcab2,
            0xdcdffe6202217f0ecb0ec75d8a09b32c96c246acb9b55077390e3ca723a0ca1f
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

        if (_targetChainId == _PANGORO_CHAIN_ID) {
            (call, weight) = PangoroCalls.ethereum_messageTransact(
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
