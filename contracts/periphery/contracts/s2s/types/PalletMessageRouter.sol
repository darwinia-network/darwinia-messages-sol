// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/Bytes.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "./TypeUtils.sol";
import "./XcmTypes.sol";

library PalletMessageRouter {
    ///////////////////////
    // Calls
    ///////////////////////
    struct ForwardCall {
        bytes2 callIndex;
        uint8 target;
        XcmTypes.EnumItem_VersionedXcm_V2 message;
    }

    function encodeForwardCall(ForwardCall memory _call)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _call.callIndex,
                _call.target,
                XcmTypes.encodeEnumItem_VersionedXcm_V2(_call.message)
            );
    }

    function buildForwardCall(
        bytes2 _callIndex,
        uint8 _target,
        bytes memory _callOnTarget,
        uint64 _requireWeightAtMost
    ) internal pure returns (bytes memory) {
        // Message to be sent to target
        XcmTypes.EnumItem_VersionedXcm_V2 memory message = buildXcmToBeForward(_callOnTarget, _requireWeightAtMost);

        // ForwardToMoonbeamCall
        PalletMessageRouter.ForwardCall
            memory call = PalletMessageRouter.ForwardCall(
                _callIndex,
                _target,
                message
            );

        return PalletMessageRouter.encodeForwardCall(call);
    }

    function buildXcmToBeForward(
        bytes memory _dispatchCallOnTarget,
        uint64 _requireWeightAtMost
    ) internal pure returns (XcmTypes.EnumItem_VersionedXcm_V2 memory) {
        return XcmTypes.EnumItem_VersionedXcm_V2(
            XcmTypes.Xcm(
                XcmTypes.EnumItem_Instruction_Transact(
                    1, // originType: SovereignAccount
                    _requireWeightAtMost,
                    _dispatchCallOnTarget
                )
            )
        );
    }
}
