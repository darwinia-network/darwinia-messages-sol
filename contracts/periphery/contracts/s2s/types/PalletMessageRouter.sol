// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/Bytes.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "./Utils.sol";

library PalletMessageRouter {
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

    // pub enum VersionedXcm<Call> {
    //     ...
    //     V2(v2::Xcm<Call>),
    // }
    function encodeVersionedXcmV2WithTransacts(Transact[] memory _transacts)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory data = ScaleCodec.encodeUintCompact(_transacts.length);
        for (uint i = 0; i < _transacts.length; i++) {
            data = abi.encodePacked(
                data,
                encodeInstructionTransact(_transacts[i])
            );
        }
        return Utils.encodeEnumItem(2, data);
    }
}
