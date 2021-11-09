// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

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
     * @param nextValidatorSet Next BEEFY authority set
    */
    struct Payload {
        bytes32 network;
        bytes32 mmr;
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
     *     "Payload(bytes32 network,bytes32 mmr,NextValidatorSet nextValidatorSet)",
     *     "NextValidatorSet(uint64 id,uint32 len,bytes32 root)",
     *     ")"
     * )
     */
    bytes32 internal constant PAYLOAD_TYPEHASH = 0xe22bd99038907f2b6f08088cca39bfd3caba1b02d6adbf9e47869eb2ea61eba3;

    /**
     * Hash of the Commitment Schema
     * keccak256(abi.encodePacked(
     *     "Commitment(Payload payload,uint32 blockNumber,uint64 validatorSetId)",
     *     "Payload(bytes32 network,bytes32 mmr,NextValidatorSet nextValidatorSet)",
     *     "NextValidatorSet(uint64 id,uint32 len,bytes32 root)",
     *     ")"
     * )
     */
    bytes32 internal constant COMMITMENT_TYPEHASH = 0xfb7618382249e6518a69252ccf86f0a991565f2a2cd2d7af9c6b59cb805b9f0b;

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
