// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/IMessageReceiver.sol";
import "@darwinia/contracts-utils/contracts/ScaleCodec.sol";

contract PangolinRouterToParachain is IMessageReceiver {
    bytes2 public immutable PANGOLIN_PARAID = 0xe520;
    bytes2 public immutable SEND_CALL_INDEX = 0x2100;
    address public constant DISPATCH =
        0x0000000000000000000000000000000000000401;

    // message:
    //  - paraId: bytes2 0x711f
    //  - call: bytes
    //  - weight: uint64
    //  - fungible: uint128
    function recv(address _fromDappAddress, bytes calldata _message) external {
        (
            bytes2 paraId,
            bytes memory call,
            uint64 weight,
            uint128 fungible
        ) = abi.decode(_message, (bytes2, bytes, uint64, uint128));

        transactOn(paraId, call, weight, fungible);
    }

    function transactOn(
        bytes2 paraId,
        bytes memory call,
        uint64 weight,
        uint128 fungible
    ) internal {
        bytes memory message = buildXcmPayload(
            PANGOLIN_PARAID,
            call,
            weight,
            fungible
        );

        bytes memory polkadotXcmSendCall = abi.encodePacked(
            // call index of `polkadotXcm.send`
            SEND_CALL_INDEX,
            // dest: V2(01, X1(Parachain(ParaId)))
            hex"00010100",
            paraId,
            message
        );

        (bool success, bytes memory data) = DISPATCH.call(polkadotXcmSendCall);

        if (!success) {
            if (data.length > 0) {
                assembly {
                    let resultDataSize := mload(data)
                    revert(add(32, data), resultDataSize)
                }
            } else {
                revert("!dispatch");
            }
        }
    }

    function buildXcmPayload(
        bytes2 fromParachain,
        bytes memory call,
        uint64 callWeight,
        uint128 fungible
    ) internal pure returns (bytes memory) {
        // xcm_version: 2
        // instructions:
        //
        //   - instruction: withdraw_asset
        //     assets:
        //       - &ring
        //         id:
        //           concrete:
        //             parents: 01,
        //             interior:
        //               X2:
        //                 - parachain: #{fromParachain}
        //                 - pallet_instance: 5
        //         fun:
        //           fungible: #{fungible}
        //
        //   - instruction: buy_execution
        //     fees: *ring
        //     weight_limit: unlimited
        //
        //   - instruction: transact
        //     origin_type: 1
        //     require_weight_at_most: #{callWeight}
        //     call: #{call}
        //
        bytes memory funEncoded = ScaleCodec.encodeUintCompact(fungible);
        return
            abi.encodePacked(
                // XcmVersion + Instruction Length
                hex"020c",
                // WithdrawAsset
                // --------------------------
                hex"000400010200",
                fromParachain,
                hex"040500",
                funEncoded,
                // BuyExecution
                // --------------------------
                hex"1300010200",
                fromParachain,
                hex"040500",
                funEncoded,
                hex"00", // weight limit
                // Transact
                // --------------------------
                hex"0601",
                ScaleCodec.encodeUintCompact(callWeight),
                ScaleCodec.encodeUintCompact(call.length),
                call
            );
    }
}
