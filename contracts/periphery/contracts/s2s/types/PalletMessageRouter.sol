// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/Bytes.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "./Utils.sol";

library PalletMessageRouter {
    ///////////////////////
    // Calls
    ///////////////////////
    struct ForwardToMoonbeamCall {
        bytes2 callIndex;
        VersionedXcmV2WithTransacts message;
    }

    function encodeForwardToMoonbeamCall(ForwardToMoonbeamCall memory _call)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _call.callIndex,
                encodeVersionedXcmV2WithTransacts(_call.message)
            );
    }

    ///////////////////////
    // Types
    ///////////////////////
    struct VersionedXcmV2WithTransacts {
        Transact[] transacts;
    }

    // pub enum VersionedXcm<Call> {
    //     ...
    //     V2(v2::Xcm<Call>),
    // }
    function encodeVersionedXcmV2WithTransacts(VersionedXcmV2WithTransacts memory _obj)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory data = ScaleCodec.encodeUintCompact(_obj.transacts.length);
        for (uint i = 0; i < _obj.transacts.length; i++) {
            data = abi.encodePacked(
                data,
                encodeInstructionTransact(_obj.transacts[i])
            );
        }
        return Utils.encodeEnumItem(2, data);
    }

    struct Transact {
        uint8 originType;
        uint64 requireWeightAtMost;
        bytes call; // without length prefix
    }

    function encodeInstructionTransact(Transact memory _transact)
        internal
        pure
        returns (bytes memory)
    {
        require(_transact.call.length > 0, "Empty call");
        require(_transact.originType <= 3, "Illegal originType");
        bytes memory data = abi.encodePacked(
            _transact.originType,
            ScaleCodec.encodeUintCompact(_transact.requireWeightAtMost),
            ScaleCodec.encodeUintCompact(_transact.call.length),
            _transact.call
        );
        return Utils.encodeEnumItem(6, data);
    }
}
