// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../utils/ECDSA.sol";

/// @title Manages a set of relayers and a threshold to message commitment
/// @dev Stores the relayers and a threshold
contract RelayAuthorities {
    event AddedRelayer(address relayer);
    event RemovedRelayer(address relayer);
    event ChangedThreshold(uint256 threshold);

    // keccak256(
    //     "RelayAuthorities()"
    // );
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x5bc5177d952a43fbebee7e0da0540faefba2dec8fc94a6caeda2dba0fc92776d;

    // keccak256(
    //     "ChangeRelayer(bytes32 network,bytes4 sig,bytes params,uint256 nonce)"
    // );
    bytes32 private constant RELAY_TYPEHASH = 0x0324ca0ca4d529e0eefcc6d123bd17ec982498cf2e732160cc47d2504825e4b2;

    address private constant SENTINEL = address(0x1);

    /// @dev NETWORK Source chain network identifier ('Crab', 'Darwinia', 'Pangolin')
    bytes32 public immutable NETWORK;

    /// @dev Nonce to prevent replay of update operations
    uint256 public nonce;

    /// @dev Store all relayers in the linked list
    mapping(address => address) internal relayers;

    /// @dev Count of all relayers
    uint256 internal count;

    /// @dev Number of required confirmations for update operations
    uint256 internal threshold;

    /// @dev Sets initial storage of contract.
    /// @param _network source chain network name
    /// @param _relayers List of relayers.
    /// @param _threshold Number of required confirmations for check commitment or change relayers.
    constructor(bytes32 _network, address[] memory _relayers, uint256 _threshold) public {
        // Threshold can only be 0 at initialization.
        // Check ensures that setup function can only be called once.
        require(threshold == 0, "setup");
        // Validate that threshold is smaller than number of added relayers.
        require(_threshold <= _relayers.length, "!threshold");
        // There has to be at least one relayer.
        require(_threshold >= 1, "0");
        // Initializing relayers.
        address current = SENTINEL;
        for (uint256 i = 0; i < _relayers.length; i++) {
            // Relayer address cannot be null.
            address r = _relayers[i];
            require(r != address(0) && r != SENTINEL && r != address(this) && current != r, "!relayer");
            // No duplicate relayers allowed.
            require(relayers[r] == address(0), "duplicate");
            relayers[current] = r;
            current = r;
            emit AddedRelayer(r);
        }
        relayers[current] = SENTINEL;
        count = _relayers.length;
        threshold = _threshold;
        NETWORK = _network;
    }

    /// @dev Allows to add a new relayer to the registry and update the threshold at the same time.
    ///      This can only be done via multi-sig.
    /// @notice Adds the `relayer` to the registry and updates the threshold to `_threshold`.
    /// @param _relayer New relayer address.
    /// @param _threshold New threshold.
    /// @param _signatures The signatures of the relayers which to add new relayer and update the `threshold` .
    function add_relayer_with_threshold(
        address _relayer,
        uint256 _threshold,
        bytes[] memory _signatures
    ) public {
        // Relayer address cannot be null, the sentinel or the registry itself.
        require(_relayer != address(0) && _relayer != SENTINEL && _relayer != address(this), "!replay");
        // No duplicate relayers allowed.
        require(relayers[_relayer] == address(0), "duplicate");
        _verify_relayer_signatures(msg.sig, abi.encode(_relayer, _threshold), _signatures);
        relayers[_relayer] = relayers[SENTINEL];
        relayers[SENTINEL] = _relayer;
        count++;
        emit AddedRelayer(_relayer);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) _change_threshold(_threshold);
    }

    /// @dev Allows to remove a relayer from the registry and update the threshold at the same time.
    ///      This can only be done via multi-sig.
    /// @notice Removes the `relayer` from the registry and updates the threshold to `_threshold`.
    /// @param _prevRelayer Relayer that pointed to the relayer to be removed in the linked list
    /// @param _relayer Relayer address to be removed.
    /// @param _threshold New threshold.
    /// @param _signatures The signatures of the relayers which to remove a relayer and update the `threshold` .
    function remove_relayer(
        address _prevRelayer,
        address _relayer,
        uint256 _threshold,
        bytes[] memory _signatures
    ) public {
        // Only allow to remove a relayer, if threshold can still be reached.
        require(count - 1 >= _threshold, "!threshold");
        // Validate relayer address and check that it corresponds to relayer index.
        require(_relayer != address(0) && _relayer != SENTINEL, "!relayer");
        require(relayers[_prevRelayer] == _relayer, "!pair");
        _verify_relayer_signatures(msg.sig, abi.encode(_prevRelayer, _relayer, _threshold), _signatures);
        relayers[_prevRelayer] = relayers[_relayer];
        relayers[_relayer] = address(0);
        count--;
        emit RemovedRelayer(_relayer);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) _change_threshold(_threshold);
    }

    /// @dev Allows to swap/replace a relayer from the registry with another address.
    ///      This can only be done via multi-sig.
    /// @notice Replaces the `oldRelayer` in the registry with `newRelayer`.
    /// @param _prevRelayer Relayer that pointed to the relayer to be replaced in the linked list
    /// @param _oldRelayer Relayer address to be replaced.
    /// @param _newRelayer New relayer address.
    /// @param _signatures The signatures of the guards which to swap/replace a relayer and update the `threshold` .
    function swap_relayer(
        address _prevRelayer,
        address _oldRelayer,
        address _newRelayer,
        bytes[] memory _signatures
    ) public {
        // Relayer address cannot be null, the sentinel or the registry itself.
        require(_newRelayer != address(0) && _newRelayer != SENTINEL && _newRelayer != address(this), "!relayer");
        // No duplicate guards allowed.
        require(relayers[_newRelayer] == address(0), "duplicate");
        // Validate oldRelayer address and check that it corresponds to relayer index.
        require(_oldRelayer != address(0) && _oldRelayer != SENTINEL, "!oldRelayer");
        require(relayers[_prevRelayer] == _oldRelayer, "!pair");
        _verify_relayer_signatures(msg.sig, abi.encode(_prevRelayer, _oldRelayer, _newRelayer), _signatures);
        relayers[_newRelayer] = relayers[_oldRelayer];
        relayers[_prevRelayer] = _newRelayer;
        relayers[_oldRelayer] = address(0);
        emit RemovedRelayer(_oldRelayer);
        emit AddedRelayer(_newRelayer);
    }

    /// @dev Allows to update the number of required confirmations by relayers.
    ///      This can only be done via multi-sig.
    /// @notice Changes the threshold of the registry to `_threshold`.
    /// @param _threshold New threshold.
    /// @param _signatures The signatures of the guards which to update the `threshold` .
    function change_threshold(uint256 _threshold, bytes[] memory _signatures) public {
        _verify_relayer_signatures(msg.sig, abi.encode(_threshold), _signatures);
        _change_threshold(_threshold);
    }

    function _change_threshold(uint256 _threshold) internal {
        // Validate that threshold is smaller than number of owners.
        require(_threshold <= count, "!threshold");
        // There has to be at least one guard.
        require(_threshold >= 1, "0");
        threshold = _threshold;
        emit ChangedThreshold(threshold);
    }

    function get_threshold() public view returns (uint256) {
        return threshold;
    }

    function is_relayer(address _relayer) public view returns (bool) {
        return _relayer != SENTINEL && relayers[_relayer] != address(0);
    }

    /// @dev Returns array of relayers.
    /// @return Array of relayers.
    function get_relayers() public view returns (address[] memory) {
        address[] memory array = new address[](count);

        // populate return array
        uint256 index = 0;
        address current = relayers[SENTINEL];
        while (current != SENTINEL) {
            array[index] = current;
            current = relayers[current];
            index++;
        }
        return array;
    }

    function _verify_relayer_signatures(
        bytes4 methodID,
        bytes memory params,
        bytes[] memory signatures
    ) internal {
        bytes32 structHash =
            keccak256(
                abi.encode(
                    RELAY_TYPEHASH,
                    NETWORK,
                    methodID,
                    params,
                    nonce
                )
            );
        _check_relayer_signatures(structHash, signatures);
        nonce++;
    }

    /// @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
    /// @param structHash The struct Hash of the data (could be either a message/commitment hash).
    /// @param signatures Signature data that should be verified. only ECDSA signature.
    ///  Signers need to be sorted in ascending order
    function _check_relayer_signatures(
        bytes32 structHash,
        bytes[] memory signatures
    ) internal view {
        // Load threshold to avoid multiple storage loads
        uint256 _threshold = threshold;
        // Check that a threshold is set
        require(_threshold > 0, "!threshold");
        bytes32 dataHash = encode_data_hash(structHash);
        _check_n_signatures(dataHash, signatures, _threshold);
    }

    /// @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
    /// @param dataHash Hash of the data (could be either a message hash or transaction hash).
    /// @param signatures Signature data that should be verified. only ECDSA signature.
    /// Signers need to be sorted in ascending order
    /// @param requiredSignatures Amount of required valid signatures.
    function _check_n_signatures(
        bytes32 dataHash,
        bytes[] memory signatures,
        uint256 requiredSignatures
    ) internal view {
        // Check that the provided signature data is not too short
        require(signatures.length >= requiredSignatures, "signatures");
        // There cannot be an owner with address 0.
        address last = address(0);
        address current;
        for (uint256 i = 0; i < requiredSignatures; i++) {
            current = ECDSA.recover(dataHash, signatures[i]);
            require(current > last && relayers[current] != address(0) && current != SENTINEL, "!signer");
            last = current;
        }
    }

    function domain_separator() public view returns (bytes32) {
        return DOMAIN_SEPARATOR_TYPEHASH;
    }

    function encode_data_hash(bytes32 structHash) internal view returns (bytes32) {
        return ECDSA.toTypedDataHash(domain_separator(), structHash);
    }
}
