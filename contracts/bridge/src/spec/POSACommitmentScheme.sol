// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../utils/ScaleCodec.sol";

contract POSACommitmentScheme {
    using ScaleCodec for uint32;

    /// The Commitment, with its payload, is the core thing we are trying to verify with this contract.
    /// @param blockNumber block number for the given commitment
    /// @param messageRoot Darwnia message root commitment hash
    struct Commitment {
        uint32 blockNumber;
        bytes32 messageRoot;
    }

    bytes4 internal constant PAYLOAD_SCALE_ENCOD_PREFIX = 0x04646280;

    function hash(Commitment memory commitment)
        public
        pure
        returns (bytes32)
    {
        // Encode and hash the Commitment
        return keccak256(
            abi.encodePacked(
                PAYLOAD_SCALE_ENCOD_PREFIX,
                commitment.blockNumber.encode32(),
                commitment.messageRoot
            )
        );
    }
}
