// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @title A contract storing state on the current and next BEEFY authority set
 * @dev Stores the authority set as a Merkle root
 *  0  |   1   |    2   |  .. x   3 |     4
 *     [       )
 *  (current, next)  = (0, 1)  -> (1, 2) -> (2, 3)
 */
contract BEEFYAuthorityRegistry {
    /* Events */

    event BEEFYCurrentAuthoritySetUpdated(uint256 id, uint256 len, bytes32 root);
    event BEEFYNextAuthoritySetUpdated(uint256 id, uint256 len, bytes32 root);

    struct AuthoritySet {
        // The validator set id
        uint64 id;
        // The length of validator set
        uint32 len;
        // The merkle root of authority set
        bytes32 root;
    }

    /* State */

    // current authority set
    AuthoritySet current;
    // next authority set
    AuthoritySet next;

    /**
     * @notice Update the current authority set
     * @param _id The new current authority set id
     * @param _len The new length of current authority set
     * @param _root The new merkle root of current authority set merkle root
     */
    function _updateCurrentAuthoritySet(uint64 _id, uint32 _len, bytes32 _root) internal {
        current.id = _id;
        current.len = _len;
        current.root = _root;
        emit BEEFYCurrentAuthoritySetUpdated(_id, _len, _root);
    }

    /**
     * @notice Update the next authority set
     * @param _id The new next authority set id
     * @param _len The new length of next authority set
     * @param _root The new merkle root of next authority set
     */
    function _updateNextAuthoritySet(uint64 _id, uint32 _len, bytes32 _root) internal {
        next.id = _id;
        next.len = _len;
        next.root = _root;
        emit BEEFYNextAuthoritySetUpdated(_id, _len, _root);
    }
}
