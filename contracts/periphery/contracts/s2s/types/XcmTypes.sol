// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "@darwinia/contracts-utils/contracts/Bytes.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";
import "./TypeUtils.sol";

library XcmTypes {
    struct EnumItem_VersionedXcm_V2 {
        Xcm xcm;
    }

    function encodeEnumItem_VersionedXcm_V2(
        EnumItem_VersionedXcm_V2 memory _obj
    ) internal pure returns (bytes memory) {
        return TypeUtils.encodeEnumItem(2, encodeXcm(_obj.xcm));
    }

    struct Xcm {
        EnumItem_Instruction_Transact transact;
    }

    function encodeXcm(Xcm memory _obj) internal pure returns (bytes memory) {
        bytes memory data = ScaleCodec.encodeUintCompact(1); // 1 instructions
        return
            abi.encodePacked(
                data,
                encodeEnumItem_Instruction_Transact(_obj.transact)
            );
    }

    // *** Instruction::DescendOrigin ***
    struct EnumItem_Instruction_DescendOrigin {
        EnumItem_Junctions_X1 location;
    }

    function encodeEnumItem_Instruction_DescendOrigin(
        EnumItem_Instruction_DescendOrigin memory _obj
    ) internal pure returns (bytes memory) {
        return
            TypeUtils.encodeEnumItem(
                11,
                encodeEnumItem_Junctions_X1(_obj.location)
            );
    }

    //
    struct EnumItem_Junctions_X1 {
        EnumItem_Junction_AccountKey20 junction;
    }

    function encodeEnumItem_Junctions_X1(EnumItem_Junctions_X1 memory _obj)
        internal
        pure
        returns (bytes memory)
    {
        return
            TypeUtils.encodeEnumItem(
                1,
                encodeEnumItem_Junction_AccountKey20(_obj.junction)
            );
    }

    //
    struct EnumItem_Junction_AccountKey20 {
        EnumItem_NetworkId_Named network;
        address key;
    }

    function encodeEnumItem_Junction_AccountKey20(
        EnumItem_Junction_AccountKey20 memory _obj
    ) internal pure returns (bytes memory) {
        return
            TypeUtils.encodeEnumItem(
                3,
                abi.encodePacked(
                    encodeEnumItem_NetworkId_Named(_obj.network),
                    _obj.key
                )
            );
    }

    //
    struct EnumItem_NetworkId_Named {
        bytes named;
    }

    function encodeEnumItem_NetworkId_Named(
        EnumItem_NetworkId_Named memory _obj
    ) internal pure returns (bytes memory) {
        return
            TypeUtils.encodeEnumItem(
                1,
                abi.encodePacked(
                    ScaleCodec.encodeUintCompact(_obj.named.length),
                    _obj.named
                )
            );
    }

    // *** Instruction::Transact ***
    struct EnumItem_Instruction_Transact {
        uint8 originType;
        uint64 requireWeightAtMost;
        bytes call; // without length prefix
    }

    function encodeEnumItem_Instruction_Transact(
        EnumItem_Instruction_Transact memory _transact
    ) internal pure returns (bytes memory) {
        require(_transact.call.length > 0, "Empty call");
        require(_transact.originType <= 3, "Illegal originType");
        bytes memory data = abi.encodePacked(
            _transact.originType,
            ScaleCodec.encodeUintCompact(_transact.requireWeightAtMost),
            ScaleCodec.encodeUintCompact(_transact.call.length),
            _transact.call
        );
        return TypeUtils.encodeEnumItem(6, data);
    }
}