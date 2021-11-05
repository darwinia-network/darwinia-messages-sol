// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

contract TargetChain {
    struct DeliveredMessages {
        uint256 begin;
        uint256 end;
        uint256 dispatch_results;
    }

    struct UnrewardedRelayer {
        address payable relayer;
        DeliveredMessages messages;
    }

    struct InboundLaneData {
        UnrewardedRelayer[] relayers;
        uint256 last_confirmed_nonce;
    }

    /**
     * Hash of the InboundLaneData Schema
     * keccak256(abi.encodePacked(
     *     "InboundLaneData(UnrewardedRelayer[] relayers,uint256 last_confirmed_nonce)",
     *     "UnrewardedRelayer(address relayer,DeliveredMessages messages)",
     *     "DeliveredMessages(uint256 begin,uint256 end,uint256 dispatch_results)"
     *     ")"
     * )
     */
    bytes32 internal constant INBOUNDLANEDATA_TYPETASH = 0xe0206b408dcea6820d150829d9cdbda81915a44d22dc7d582fbeaef4af0a7cc7;

    /**
     * Hash of the UnrewardedRelayer Schema
     * keccak256(abi.encodePacked(
     *     "UnrewardedRelayer(address relayer,DeliveredMessages messages)"
     *     ")"
     * )
     */
    bytes32 internal constant UNREWARDEDRELAYER_TYPETASH = 0x5a4aa0af73c7f5d93a664d3d678d10103a266e77779c6809ea90b94851216106;

    /**
     * Hash of the DeliveredMessages Schema
     * keccak256(abi.encodePacked(
     *     "DeliveredMessages(uint256 begin,uint256 end,uint256 dispatch_results)"
     *     ")"
     * )
     */
    bytes32 internal constant DELIVEREDMESSAGES_TYPETASH = 0x4fac2cc6d2c4efd6e36dc917cf7d5c24157fff4118169c91ea05772cfc06f24d;

    function hash(InboundLaneData memory inboundLaneData)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                INBOUNDLANEDATA_TYPETASH,
                hash(inboundLaneData.relayers),
                inboundLaneData.last_confirmed_nonce
            )
        );
    }

    function hash(UnrewardedRelayer[] memory relayers)
        internal
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encode(relayers.length);
        for (uint256 i = 0; i < relayers.length; i ++) {
            UnrewardedRelayer memory r = relayers[i];
            encoded = abi.encodePacked(
                encoded,
                abi.encode(
                    UNREWARDEDRELAYER_TYPETASH,
                    r.relayer,
                    hash(r.messages)
                )
            );
        }
        return keccak256(encoded);
    }

    function hash(DeliveredMessages memory messages)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                DELIVEREDMESSAGES_TYPETASH,
                messages.begin,
                messages.end,
                messages.dispatch_results
            )
        );
    }

}
