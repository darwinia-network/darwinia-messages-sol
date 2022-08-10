// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.7.6;
pragma abicoder v2;

import "../../utils/ECDSA.sol";

/// @title Manages a set of relayers and a threshold to message commitment
/// @dev Stores the relayers and a threshold
contract EcdsaAuthority {
    /// @dev Nonce to prevent replay of update operations
    uint256 public nonce;
    /// @dev Count of all relayers
    uint256 internal count;
    /// @dev Number of required confirmations for update operations
    uint256 internal threshold;
    /// @dev Store all relayers in the linked list
    mapping(address => address) internal relayers;

    // keccak256(
    //     "chain_id | spec_name | :: | pallet_name"
    // );
    bytes32 private immutable DOMAIN_SEPARATOR;

    // Method Id of `add_relayer`
    // bytes4(keccak256("add_relayer(address,uint256)"))
    bytes4 private constant ADD_RELAYER_SIG = bytes4(0xb7aafe32);
    // Method Id of `remove_relayer`
    // bytes4(keccak256("remove_relayer(address,address,uint256)"))
    bytes4 private constant REMOVE_RELAYER_SIG = bytes4(0x8621d1fa);
    // Method Id of `swap_relayer`
    // bytes4(keccak256("swap_relayer(address,address,address)"))
    bytes4 private constant SWAP_RELAYER_SIG = bytes4(0xcb76085b);
    // Method Id of `change_threshold`
    // bytes4(keccak256("change_threshold(uint256)"))
    bytes4 private constant CHANGE_THRESHOLD_SIG = bytes4(0x3c823333);
    // keccak256(
    //     "ChangeRelayer(bytes4 sig,bytes params,uint256 nonce)"
    // );
    bytes32 private constant RELAY_TYPEHASH = 0x30a82982a8d5050d1c83bbea574aea301a4d317840a8c4734a308ffaa6a63bc8;
    address private constant SENTINEL = address(0x1);

    event AddedRelayer(address relayer);
    event RemovedRelayer(address relayer);
    event ChangedThreshold(uint256 threshold);

    /// @dev Sets initial storage of contract.
    /// @param _domain_separator source chain domain_separator
    /// @param _relayers List of relayers.
    /// @param _threshold Number of required confirmations for check commitment or change relayers.
    constructor(
        bytes32 _domain_separator,
        address[] memory _relayers,
        uint256 _threshold,
        uint256 _nonce
    ) {
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
        DOMAIN_SEPARATOR = _domain_separator;
        nonce = _nonce;
    }

    /// @dev Allows to add a new relayer to the registry and update the threshold at the same time.
    ///      This can only be done via multi-sig.
    /// @notice Adds the `relayer` to the registry and updates the threshold to `_threshold`.
    /// @param _relayer New relayer address.
    /// @param _threshold New threshold.
    /// @param _signatures The signatures of the relayers which to add new relayer and update the `threshold` .
    function add_relayer(
        address _relayer,
        uint256 _threshold,
        bytes[] memory _signatures
    ) external {
        // Relayer address cannot be null, the sentinel or the registry itself.
        require(_relayer != address(0) && _relayer != SENTINEL && _relayer != address(this), "!relayer");
        // No duplicate relayers allowed.
        require(relayers[_relayer] == address(0), "duplicate");
        _verify_relayer_signatures(ADD_RELAYER_SIG, abi.encode(_relayer, _threshold), _signatures);
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
    ) external {
        // Only allow to remove a relayer, if threshold can still be reached.
        require(count - 1 >= _threshold, "!threshold");
        // Validate relayer address and check that it corresponds to relayer index.
        require(_relayer != address(0) && _relayer != SENTINEL, "!relayer");
        require(relayers[_prevRelayer] == _relayer, "!pair");
        _verify_relayer_signatures(REMOVE_RELAYER_SIG, abi.encode(_prevRelayer, _relayer, _threshold), _signatures);
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
    ) external {
        // Relayer address cannot be null, the sentinel or the registry itself.
        require(_newRelayer != address(0) && _newRelayer != SENTINEL && _newRelayer != address(this), "!relayer");
        // No duplicate guards allowed.
        require(relayers[_newRelayer] == address(0), "duplicate");
        // Validate oldRelayer address and check that it corresponds to relayer index.
        require(_oldRelayer != address(0) && _oldRelayer != SENTINEL, "!oldRelayer");
        require(relayers[_prevRelayer] == _oldRelayer, "!pair");
        _verify_relayer_signatures(SWAP_RELAYER_SIG, abi.encode(_prevRelayer, _oldRelayer, _newRelayer), _signatures);
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
    function change_threshold(uint256 _threshold, bytes[] memory _signatures) external {
        _verify_relayer_signatures(CHANGE_THRESHOLD_SIG, abi.encode(_threshold), _signatures);
        _change_threshold(_threshold);
    }

    function _change_threshold(uint256 _threshold) private {
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
    ) private {
        bytes32 structHash =
            keccak256(
                abi.encode(
                    RELAY_TYPEHASH,
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
    ) private view {
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
        return DOMAIN_SEPARATOR;
    }

    function encode_data_hash(bytes32 structHash) private view returns (bytes32) {
        return ECDSA.toTypedDataHash(domain_separator(), structHash);
    }
}
