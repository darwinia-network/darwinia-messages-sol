// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @title A contract storing state on the current BEEFY authority set
 * @dev Stores the authority set as a Merkle root
 *  0  |   1   |    2   |  .. x   3 |     4
 *     [       )
 */
contract BEEFYAuthorityRegistry {
    /* Events */

    event BEEFYAuthoritySetUpdated(uint256 id, uint256 len, bytes32 root);

    /* State */

    /**
     * @notice Authority set supposed to sign the BEEFY commitment.
     * @dev The current authority set id
     */
    uint256 public authoritySetId;
    /**
     * @dev The current length of authority set
     */
    uint256 public authoritySetLen;
    /**
     * @dev The current merkle root of authority set
     */
    bytes32 public authoritySetRoot;

    /**
     * @notice Updates the current authority set
     * @param _authoritySetId The new authority set id
     * @param _authoritySetLen The new length of authority set
     * @param _authoritySetRoot The new authority set root
     */
    function _updateAuthoritySet(uint256 _authoritySetId, uint256 _authoritySetLen, bytes32 _authoritySetRoot) internal {
        authoritySetId = _authoritySetId;
        authoritySetLen = _authoritySetLen;
        authoritySetRoot = _authoritySetRoot;
        emit BEEFYAuthoritySetUpdated(_authoritySetId, _authoritySetLen, _authoritySetRoot);
    }
}
