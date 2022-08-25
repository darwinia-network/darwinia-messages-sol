// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

contract POSACommitmentScheme {
    // keccak256(
    //     "Commitment(uint32 block_number,bytes32 message_root,uint256 nonce)"
    // );
    bytes32 internal constant COMMIT_TYPEHASH = 0xaca824a0c4edb3b2c17f33fea9cb21b33c7ee16c8e634c36b3bf851c9de7a223;

    /// The Commitment contains the message_root with block_number that is used for message verify
    /// @param block_number block number for the given commitment
    /// @param message_root Darwnia message root commitment hash
    struct Commitment {
        uint32 block_number;
        bytes32 message_root;
        uint256 nonce;
    }

    function hash(Commitment memory c)
        internal
        pure
        returns (bytes32)
    {
        // Encode and hash the Commitment
        return keccak256(
            abi.encode(
                COMMIT_TYPEHASH,
                c.block_number,
                c.message_root,
                c.nonce
            )
        );
    }
}
