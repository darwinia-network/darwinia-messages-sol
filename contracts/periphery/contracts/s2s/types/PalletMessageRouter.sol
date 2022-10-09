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
        XcmTypes.EnumItem_VersionedXcm_V2 message;
        uint8 target;
    }

    function encodeForwardCall(ForwardCall memory _call)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _call.callIndex,
                XcmTypes.encodeEnumItem_VersionedXcm_V2(_call.message),
                _call.target
            );
    }

    function buildForwardCall(
        bytes2 _callIndex,
        bytes memory _callOnTarget,
        uint8 target
    ) internal pure returns (bytes memory) {
        // XCM to be sent to target
        XcmTypes.EnumItem_VersionedXcm_V2 memory xcm = XcmTypes.EnumItem_VersionedXcm_V2(
            XcmTypes.Xcm(
                XcmTypes.EnumItem_Instruction_Transact(
                    1, // originType: SovereignAccount
                    5000000000, // requireWeightAtMost
                    _callOnTarget
                )
            )
        );

        // ForwardToMoonbeamCall
        PalletMessageRouter.ForwardCall
            memory call = PalletMessageRouter.ForwardCall(
                _callIndex,
                xcm,
                target
            );

        return PalletMessageRouter.encodeForwardCall(call);
    }
}
