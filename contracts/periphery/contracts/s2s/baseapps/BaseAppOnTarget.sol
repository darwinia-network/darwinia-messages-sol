// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../SmartChainXLib.sol";
import "./AppShare.sol";

// The base contract for developers to inherit
abstract contract BaseAppOnTarget is AppShare {
    // The chain id of the source chain
    bytes4 public srcChainId = 0;

    // Precompile address for getting state storage on the source chain
    address public tgtStoragePrecompileAddress = address(1024);

    // The storage key used to get last delivered nonce
    bytes32 public tgtStorageKeyForLastDeliveredNonce;

    // Message sender address on the source chain.
    // It will be used on the target chain.
    // It should be updated after the dapp is deployed on the source chain.
    // See more details in the 'deriveSenderFromRemote' below.
    address public srcMessageSender;

    ////////////////////////////////////
    // Internal functions
    ////////////////////////////////////

    /// @notice Determine if the `sender` is derived from remote.
    ///
    ///    // Add this 'require' to your function on the target chain which will be called
    ///    require(
    ///         derivedFromRemote(msg.sender),
    ///        "msg.sender is not derived from remote"
    ///    );
    ///
    /// @return bool Does the sender address authorized?
    function derivedFromRemote(address _sender) internal view returns (bool) {
        return
            _sender ==
            SmartChainXLib.deriveSenderFromRemote(srcChainId, srcMessageSender);
    }

    function lastDeliveredNonceOf(bytes4 _inboundLaneId)
        internal
        view
        returns (uint64)
    {
        return
            SmartChainXLib.lastDeliveredNonce(
                tgtStoragePrecompileAddress,
                tgtStorageKeyForLastDeliveredNonce,
                _inboundLaneId
            );
    }
}
