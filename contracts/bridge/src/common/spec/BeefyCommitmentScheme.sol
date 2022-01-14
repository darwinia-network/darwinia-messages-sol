// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

contract BeefyCommitmentScheme {
    /**
     * Next BEEFY authority set
     * @param id ID of the next set
     * @param len Number of validators in the set
     * @param root Merkle Root Hash build from BEEFY AuthorityIds
    */
    struct NextValidatorSet {
        uint64 id;
        uint32 len;
        bytes32 root;
    }

    /**
     * The payload being signed
     * @param network Source chain network identifier
     * @param mmr MMR root hash
     * @param messageRoot Darwnia message root commitment hash
     * @param nextValidatorSet Next BEEFY authority set
    */
    struct Payload {
        bytes32 network;
        bytes32 mmr;
        bytes32 messageRoot;
        NextValidatorSet nextValidatorSet;
    }

    /**
     * The Commitment, with its payload, is the core thing we are trying to verify with this contract.
     * It contains a next validator set or not and a MMR root that commits to the darwinia history,
     * including past blocks and can be used to verify darwinia blocks.
     * @param payload the payload of the new commitment in beefy justifications (in
     *  our case, this is a next validator set and a new MMR root for all past darwinia blocks)
     * @param blockNumber block number for the given commitment
     * @param validatorSetId validator set id that signed the given commitment
     */
    struct Commitment {
        Payload payload;
        uint32 blockNumber;
        uint64 validatorSetId;
    }

    /**
     * Hash of the NextValidatorSet Schema
     * keccak256("NextValidatorSet(uint64 id,uint32 len,bytes32 root)")
     */
    bytes32 internal constant NEXTVALIDATORSET_TYPEHASH = 0x599882aa3cf9166c2c8867b0e7c41899bd7c26ee7898f261a5f495738da7dbd0;

    /**
     * Hash of the Payload Schema
     * keccak256(abi.encodePacked(
     *     "Payload(bytes32 network,bytes32 mmr,bytes32 messageRoot,NextValidatorSet nextValidatorSet)",
     *     "NextValidatorSet(uint64 id,uint32 len,bytes32 root)",
     *     ")"
     * )
     */
    bytes32 internal constant PAYLOAD_TYPEHASH = 0x62bbbb2624ffde1ec395c5f7f00ec3bec6217d975467b8deaf45d8dc276236a5;

    /**
     * Hash of the Commitment Schema
     * keccak256(abi.encodePacked(
     *     "Commitment(Payload payload,uint32 blockNumber,uint64 validatorSetId)",
     *     "Payload(bytes32 network,bytes32 mmr,bytes32 messageRoot,NextValidatorSet nextValidatorSet)",
     *     "NextValidatorSet(uint64 id,uint32 len,bytes32 root)",
     *     ")"
     * )
     */
    bytes32 internal constant COMMITMENT_TYPEHASH = 0xb962b25b1a6ae67dc9886e336d7136273db7f78be39c3b3a86664187b2807317;

    function hash(Commitment memory commitment)
        public
        pure
        returns (bytes32)
    {
        /**
         * Encode and hash the Commitment
         */
        return keccak256(
            abi.encode(
                COMMITMENT_TYPEHASH,
                hash(commitment.payload),
                commitment.blockNumber,
                commitment.validatorSetId
            )
        );
    }

    function hash(Payload memory payload)
        internal
        pure
        returns (bytes32)
    {
        /**
         * Encode and hash the Payload
         */
        return keccak256(
            abi.encode(
                PAYLOAD_TYPEHASH,
                payload.network,
                payload.mmr,
                payload.messageRoot,
                hash(payload.nextValidatorSet)
            )
        );
    }

    function hash(NextValidatorSet memory nextValidatorSet)
        internal
        pure
        returns (bytes32)
    {
        /**
         * Encode and hash the NextValidatorSet
         */
        return keccak256(
            abi.encode(
                NEXTVALIDATORSET_TYPEHASH,
                nextValidatorSet.id,
                nextValidatorSet.len,
                nextValidatorSet.root
            )
        );
    }

}
