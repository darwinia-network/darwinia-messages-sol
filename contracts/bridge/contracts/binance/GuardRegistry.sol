// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.6.0 <0.7.0;

/**
 * @title A contract storing state on the current guard set
 * @dev Stores the guard set as a Merkle root
 */
contract GuardRegistry {
    /* Events */

    event GuardRegistryUpdated(uint256 id, uint256 len, bytes32 root);

    /* State */

    /**
     * @notice Guard set supposed to sign to double-check the BEEFY commitment
     * when guard set changes, most of the guards should sign to confirm the change
     * @dev The current guard set id
     */
    uint256 public guardSetId;
    /**
     * @dev The current number of guard set
     */
    uint256 public numOfGuards;
    /**
     * @dev The current merkle root of guard set
     */
    bytes32 public guardSetRoot;
    /**
     * @dev The current threshold of guard set
     */
    uint256 public guardThreshold;

    /**
     * @notice Updates the guard set
     * @param _guardSetId The new guard set id
     * @param _numOfGuards The new number of guard set
     * @param _guardSetRoot The new guard set root
     * @param _guardThreshold The new guard threshold
     */
    function _updateGuardSet(uint256 _guardSetId, uint256 _numOfGuards, bytes32 _guardSetRoot, uint256 _guardThreshold) internal {
        guardSetId = _guardSetId;
        numOfGuards = _numOfGuards;
        guardSetRoot = _guardSetRoot;
        guardThreshold = _guardThreshold;
        emit GuardRegistryUpdated(_guardSetId, _numOfGuards, guardSetRoot);
    }
}
