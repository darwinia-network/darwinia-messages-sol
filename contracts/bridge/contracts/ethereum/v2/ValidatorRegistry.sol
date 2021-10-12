// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.6.0 <0.7.0;

/**
 * @title A contract storing state on the current validator set
 * @dev Stores the validator set as a Merkle root
 */
contract ValidatorRegistry {
    /* Events */

    event ValidatorRegistryUpdated(uint256 id, uint256 len, bytes32 root);

    /* State */

    /**
     * @notice Validato set supposed to sign the BEEFY commitment.
     * @dev The current validator set id
     */
    uint256 public validatorSetId;
    /**
     * @dev The current length of validator set
     */
    uint256 public validatorSetLen;
    /**
     * @dev The current merkle root of guard set
     */
    bytes32 public validatorSetRoot;

    /**
     * @notice Updates the validator set
     * @param _validatorSetId The new validator set id
     * @param _validatorSetLen The new length of validator set
     * @param _validatorSetRoot The new validator set root
     */
    function _updateValidatorSet(uint256 _validatorSetId, uint256 _validatorSetLen, bytes32 _validatorSetRoot) internal {
        validatorSetId = _validatorSetId;
        validatorSetLen = _validatorSetLen;
        validatorSetRoot = _validatorSetRoot;
        emit ValidatorRegistryUpdated(_validatorSetId, _validatorSetLen, validatorSetRoot);
    }
}
