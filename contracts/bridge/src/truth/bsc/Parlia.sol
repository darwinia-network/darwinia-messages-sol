// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../utils/Bytes.sol";
import "../../utils/ECDSA.sol";
import "../../spec/BinanceSmartChain.sol";

contract Parlia {
    using Bytes for bytes;

    uint constant private EPOCH = 200;

    // Finalized BSC checkpoint
    BSCHeader public finalized_checkpint;
    // Finalized BSC authorities root
    bytes32 public finalized_authorities_root;

    constructor(BSCHeader calldata header) {
        authority_root = hash(extract_authorities(header.extra_data));
        finalized_authorities_root = hash(authority_root);
        finalized_checkpint = header;
    }

    function import_finalized_epoch_header(BSCHeader[] calldata headers, address[] calldata finalized_authorities) external payable {
        // check finalized_authorities is correct
        require(has(finalized_authorities) == finalized_authorities_root, "!finalized_authorities");
        // ensure valid length
        // we should submit at least `N/2 + 1` headers
        require(finalized_authorities.length / 2 < headers, "!headers_size");
        BSCHeader memory checkpoint = headers[0];

        // ensure valid header number
        // the first group headers that relayer submitted should exactly follow the initial
        // checkpoint eg. the initial header number is x, the first call of this extrinsic
        // should submit headers with numbers [x + epoch_length, x + epoch_length + 1, ...]
        require(finalized_checkpint.number + EPOCH == checkpoint.number, "!number");
        // ensure first element is checkpoint block header
        require(checkpoint.number % EPOCH == 0, "!checkpoint");

        // verify checkpoint
        // basic checks
        contextless_checks(checkpoint);

        // check signer
        address signer0 = recover_creator(checkpoint);
        bytes32 leaf = keccak256(abi.encodePacked(signer0));

        // TODO: check signer in finalized_authorities_root

        // extract new authority set from submitted checkpoint header
        address[] memery new_authority_set = extract_authorities(checkpoint);

        for (uint i = 1; i < headers.length; i++) {
            contextless_checks(headers[i]);
            // check parent
            contrxtual_checks(headers[i], headers[i-1]);

            // who signed this header
            address signerN = recover_creator(headers[i]);
            bytes32 leafN = keccak256(abi.encodePacked(signerN));

            // TODO: signerN must in finalized_checkpint_root
            // TODO: headers must signed by different authority
        }

        // TODO: if already have `N/2` valid headers signed by different authority separately
        // do finalize new authority set
        finalized_authorities_root = hash(new_authority_set);
        finalized_checkpint = checkpoint;
    }

    function contextless_checks(BSCHeader calldata header) internal pure {
        // genesis block is always valid dead-end
        if (header.number == 0) {
            return
        }

        // ensure nonce is empty
        require(header.nonce == bytes8(0), "!nonce");

        // gas limit check
        require(header.gas_limit >= MIN_GAS_LIMIT &&
                header.gas_limit <= MAX_GAS_LIMIT,
                "!gas_limit");

        // check gas used
        require(header.gas_used <= header.gas_limit, "!gas_used");

        // ensure block uncles are meaningless in PoA
        require(header.uncle_hash == KECCAK_EMPTY_LIST_RLP, "!uncle");

        // ensure difficulty is valid
        require(header.difficulty == DIFF_INTURN ||
                header.difficulty == DIFF_NOTURN,
                "!difficulty");

        // ensure block difficulty is meaningless (may bot be correct at this point)
        require(header.difficulty != 0, "!difficulty");

        // ensure mix digest is zero as we don't have fork pretection currently
        require(header.mix_digest == bytes32(0), "!mix_digest");

        // check extra-data contains vanity, validators and signature
        require(header.extra_data.length > VANITY_LENGTH, "!vanity");

        uint validator_bytes_len = sub(header.extra_data.length, VANITY_LENGTH + SIGNATURE_LENGTH);
        // ensure extra-data contains a validator list on checkpoint, but none otherwise
        bool is_checkpoint = header.number % EPOCH == 0;
        if (is_checkpoint) {
            // ensure blocks must at least contain one validator
            require(validator_bytes_len != 0, "!checkpoint_validators_size");
            // ensure validator bytes length is valid
            require(validator_bytes_len % ADDRESS_LENGTH == 0, "!checkpoint_validators_size");
        } else {
            require(validator_bytes_len == 0, "!validators_size")
        }
    }

    function contextual_checks(BSCHeader calldata header, BSCHeader calldata parent) {
        // parent sanity check
        require(hash(parent) == header.parent_hash &&
                parent.number == header.number + 1,
                "!ancestor");

        // ensure block's timestamp isn't too close to it's parent
        // and header. timestamp is greater than parents'
        require(header.timestamp < add(parent.timestamp, PERIOD), "!timestamp")
    }

    function recover_creator(BSCHeader calldata header) internal pure returns (address) {
        bytes memory extra_data = header.extra_data;

        require(extra_data.length > VANITY_LENGTH, "!vanity");
        require(extra_data.length >= VANITY_LENGTH + SIGNATURE_LENGTH, "!signature");

        // split `signed extra_data` and `signature`
        bytes memory signed_data = extra_data.substr(0, extra_data.length - SIGNATURE_LENGTH);
        bytes memory signature = extra_data.substr(extra_data.length - SIGNATURE_LENGTH, extra_data.length);

        bytes32 memory msg = hash_with_chain_id(CHAIN_ID);
        return ECDSA.recover(msg, signature);
    }

	/// Extract authority set from extra_data.
    ///
    /// Layout of extra_data:
    /// ----
    /// VANITY: 32 bytes
    /// Signers: N * 32 bytes as hex encoded (20 characters)
    /// Signature: 65 bytes
    /// --
    function extract_authorities(bytes calldata extra_data) internal pure returns (address[] memory) {
        uint len = extra_data.length;
        require(len > VANITY_LENGTH + SIGNATURE_LENGTH, "!signer");
        bytes memory signers_raw = extra_data.substr(VANITY_LENGTH, len - SIGNATURE_LENGTH);
        uint num_signers = signers_raw.length / ADDRESS_LENGTH;
        address[] memory signers = new address[](num_signers);
        for (uint i = 0; i < num_signers; i++) {
            signers[i] = signers_raw.substr(i * ADDRESS_LENGTH, ADDRESS_LENGTH);
        }
        return signers;
    }

    function hash(address[] memory signers) internal pure returns (bytes32) {
        bytes32[] hashed_signers = new bytes32[](signers.length);
        for (uint i = 0; i < signers.length; i++) {
            hashed_signers[i] = keccak256(abi.encodePacked(signers[i]));
        }
        return hash(hashed_signers);
    }

    function hash(bytes32[] memory leaves) internal pure returns (bytes32) {
        uint len = leaves.length;
        if (len == 0) return bytes32(0);
        else if (len == 1) return leaves[0];
        else if (len == 2) return hash_node(leaves[0], leaves[1]);
        uint bottom_length = get_power_of_two_ceil(len);
        bytes32[] memory o = new bytes32[](bottom_length * 2);
        for (uint i = 0; i < len; ++i) {
            o[bottom_length + i] = leaves[i];
        }
        for (uint i = bottom_length - 1; i > 0; --i) {
            o[i] = hash_node(o[i * 2], o[i * 2 + 1]);
        }
        return o[1];
    }

    function get_power_of_two_ceil(uint256 x) internal pure returns (uint256) {
        if (x <= 1) return 1;
        else if (x == 2) return 2;
        else return 2 * get_power_of_two_ceil((x + 1) >> 1);
    }

    function hash_node(bytes32 left, bytes32 right)
        internal
        pure
        returns (bytes32 hash)
    {
        assembly {
            mstore(0x00, left)
            mstore(0x20, right)
            hash := keccak256(0x00, 0x40)
        }
        return hash;
    }
}

