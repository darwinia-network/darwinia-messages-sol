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
    struct ForwardToMoonbeamCall {
        bytes2 callIndex;
        XcmTypes.EnumItem_VersionedXcm_V2 message;
    }

    function encodeForwardToMoonbeamCall(ForwardToMoonbeamCall memory _call)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _call.callIndex,
                XcmTypes.encodeEnumItem_VersionedXcm_V2(_call.message)
            );
    }

    function buildForwardToMoonbeamCall(
        bytes2 _callIndex,
        bytes memory _callOnMoonbeam
    ) internal pure returns (bytes memory) {
        // XCM to be sent to moonbeam
        XcmTypes.EnumItem_VersionedXcm_V2 memory xcm = XcmTypes.EnumItem_VersionedXcm_V2(
            XcmTypes.Xcm(
                XcmTypes.EnumItem_Instruction_Transact(
                    1, // originType: SovereignAccount
                    5000000000, // requireWeightAtMost
                    _callOnMoonbeam
                )
            )
        );

        // ForwardToMoonbeamCall
        PalletMessageRouter.ForwardToMoonbeamCall
            memory call = PalletMessageRouter.ForwardToMoonbeamCall(
                _callIndex,
                xcm
            );

        return PalletMessageRouter.encodeForwardToMoonbeamCall(call);
    }
}
