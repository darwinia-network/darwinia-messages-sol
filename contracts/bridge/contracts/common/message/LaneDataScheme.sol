// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

contract LaneDataScheme {
    struct LaneData {
        bytes32 outboundLaneDataHash;
        bytes32 inboundLaneDataHash;
    }

    /**
     * Hash of the LaneData Schema
     * keccak256(abi.encodePacked(
     *     "LaneData(bytes32 outboundLaneDataHash,bytes32 inboundLaneDataHash)"
     *     ")"
     * )
     */
    bytes32 internal constant LANEDATA_TYPEHASH = 0x8f6ab5f61c30d2037b3accf5c8898c9242d2acc51072316f994ac5d6748dd567;

    function hash(LaneData memory land_data)
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                LANEDATA_TYPEHASH,
                land_data.outboundLaneDataHash,
                land_data.inboundLaneDataHash
            )
        );
    }
}
