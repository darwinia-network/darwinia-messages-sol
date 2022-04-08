// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

/**
 * @title A contract storing state on the current BEEFY authority set
 * @dev Stores the authority set as a Merkle root
 *  0  |   1   |    2   |  .. x   3 |     4
 *     [       )
 */
contract BEEFYAuthorityRegistry {
    /* Events */

    event BEEFYAuthoritySetUpdated(uint64 id, uint32 len, bytes32 root);

    /* State */

    /**
     * @notice Authority set supposed to sign the BEEFY commitment.
     * @dev The current authority set id
     */
    uint64 public authoritySetId;
    /**
     * @dev The current length of authority set
     */
    uint32 public authoritySetLen;
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
    function _updateAuthoritySet(uint64 _authoritySetId, uint32 _authoritySetLen, bytes32 _authoritySetRoot) internal {
        authoritySetId = _authoritySetId;
        authoritySetLen = _authoritySetLen;
        authoritySetRoot = _authoritySetRoot;
        emit BEEFYAuthoritySetUpdated(_authoritySetId, _authoritySetLen, _authoritySetRoot);
    }
}
