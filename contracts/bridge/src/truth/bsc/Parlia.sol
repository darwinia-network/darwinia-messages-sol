// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../utils/Bytes.sol";
import "../../utils/ECDSA.sol";
import "../../spec/BinanceSmartChain.sol";

contract Parlia is BinanceSmartChain {
    using Bytes for bytes;

    uint64 public immutable CHAIN_ID;
    uint64 public immutable PERIOD;

    uint constant private EPOCH = 200;
    uint64 constant private MAX_GAS_LIMIT = 0x7fffffffffffffff;
    uint64 constant private MIN_GAS_LIMIT = 5000;

    bytes32 constant private KECCAK_EMPTY_LIST_RLP = 0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347;

    uint constant private DIFF_INTURN = 2;
    uint constant private DIFF_NOTURN = 1;

    uint constant private VANITY_LENGTH = 32;
    uint constant private SIGNATURE_LENGTH = 65;
    uint constant private ADDRESS_LENGTH = 20;

    struct StoredBlockHeader {
        bytes32 parent_hash;
        bytes32 state_root;
        bytes32 transactions_root;
        bytes32 receipts_root;
        uint256 number;
        uint256 timestamp;
        bytes32 hash;
    }

    // Finalized BSC checkpoint
    StoredBlockHeader public finalized_checkpoint;
    // Finalized BSC authorities root
    bytes32 public finalized_authorities_root;

    constructor(uint64 chain_id, uint64 period, BSCHeader memory header) {
        finalized_authorities_root = hash(extract_authorities(header.extra_data));
        bytes32 block_hash = hash(header);
        finalized_checkpoint = StoredBlockHeader({
            parent_hash: header.parent_hash,
            state_root: header.state_root,
            transactions_root: header.transactions_root,
            receipts_root: header.receipts_root,
            number: header.number,
            timestamp: header.timestamp,
            hash: block_hash
        });
        CHAIN_ID = chain_id;
        PERIOD = period;
    }

    function import_finalized_epoch_header(BSCHeader[] calldata headers, address[] calldata finalized_authorities) external payable {
        // check finalized_authorities is correct
        require(hash(finalized_authorities) == finalized_authorities_root, "!finalized_authorities");
        // ensure valid length
        // we should submit at least `N/2 + 1` headers
        require(finalized_authorities.length / 2 < headers.length, "!headers_size");
        BSCHeader memory checkpoint = headers[0];

        // ensure valid header number
        // the first group headers that relayer submitted should exactly follow the initial
        // checkpoint eg. the initial header number is x, the first call of this extrinsic
        // should submit headers with numbers [x + epoch_length, x + epoch_length + 1, ...]
        require(finalized_checkpoint.number + EPOCH == checkpoint.number, "!number");
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
        address[] memory new_authority_set = extract_authorities(checkpoint.extra_data);

        for (uint i = 1; i < headers.length; i++) {
            contextless_checks(headers[i]);
            // check parent
            contextual_checks(headers[i], headers[i-1]);

            // who signed this header
            address signerN = recover_creator(headers[i]);
            bytes32 leafN = keccak256(abi.encodePacked(signerN));

            // TODO: signerN must in finalized_checkpint_root
            // TODO: headers must signed by different authority
        }

        // TODO: if already have `N/2` valid headers signed by different authority separately
        // do finalize new authority set
        finalized_authorities_root = hash(new_authority_set);
        finalized_checkpoint = StoredBlockHeader({
            parent_hash: checkpoint.parent_hash,
            state_root: checkpoint.state_root,
            transactions_root: checkpoint.transactions_root,
            receipts_root: checkpoint.receipts_root,
            number: checkpoint.number,
            timestamp: checkpoint.timestamp,
            hash: hash(checkpoint)
        });
    }

    function contextless_checks(BSCHeader memory header) internal pure {
        // genesis block is always valid dead-end
        if (header.number == 0) return;

        // ensure nonce is empty
        require(header.nonce == 0, "!nonce");

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
            require(validator_bytes_len == 0, "!validators_size");
        }
    }

    function contextual_checks(BSCHeader calldata header, BSCHeader calldata parent) internal view {
        // parent sanity check
        require(hash(parent) == header.parent_hash &&
                parent.number == header.number + 1,
                "!ancestor");

        // ensure block's timestamp isn't too close to it's parent
        // and header. timestamp is greater than parents'
        require(header.timestamp < add(parent.timestamp, PERIOD), "!timestamp");
    }

    function recover_creator(BSCHeader memory header) internal view returns (address) {
        bytes memory extra_data = header.extra_data;

        require(extra_data.length > VANITY_LENGTH, "!vanity");
        require(extra_data.length >= VANITY_LENGTH + SIGNATURE_LENGTH, "!signature");

        // split `signed extra_data` and `signature`
        bytes memory signed_data = extra_data.substr(0, extra_data.length - SIGNATURE_LENGTH);
        bytes memory signature = extra_data.substr(extra_data.length - SIGNATURE_LENGTH, extra_data.length);
        bytes32 message = hash_with_chain_id(header, CHAIN_ID);
        require(signature.length == 65, "!signature");
        (bytes32 r, bytes32 vs) = extract_sign(signature);
        return ECDSA.recover(message, r, vs);
    }

    function extract_sign(bytes memory signature) internal pure returns(bytes32 r, bytes32 vs) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        bytes32 vs = (bytes32(uint(v)) << 255) | s;
        return (r, vs);
    }

	/// Extract authority set from extra_data.
    ///
    /// Layout of extra_data:
    /// ----
    /// VANITY: 32 bytes
    /// Signers: N * 32 bytes as hex encoded (20 characters)
    /// Signature: 65 bytes
    /// --
    function extract_authorities(bytes memory extra_data) internal pure returns (address[] memory) {
        uint len = extra_data.length;
        require(len > VANITY_LENGTH + SIGNATURE_LENGTH, "!signer");
        bytes memory signers_raw = extra_data.substr(VANITY_LENGTH, len - SIGNATURE_LENGTH);
        uint num_signers = signers_raw.length / ADDRESS_LENGTH;
        address[] memory signers = new address[](num_signers);
        for (uint i = 0; i < num_signers; i++) {
            signers[i] = bytesToAddress(signers_raw.substr(i * ADDRESS_LENGTH, ADDRESS_LENGTH));
        }
        return signers;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
          addr := mload(add(bys,20))
        }
    }

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
}

