// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../utils/ScaleCodec.sol";

contract POSACommitmentScheme {
    using ScaleCodec for uint32;

    /// The Commitment contains the message_root with block_number that is used for message verify
    /// @param block_number block number for the given commitment
    /// @param message_root Darwnia message root commitment hash
    struct Commitment {
        uint32 block_number;
        bytes32 message_root;
    }

    function hash(Commitment memory commitment)
        public
        pure
        returns (bytes32)
    {
        // Encode and hash the Commitment
        return keccak256(
            abi.encodePacked(
                commitment.block_number.encode32(),
                commitment.message_root
            )
        );
    }
}
