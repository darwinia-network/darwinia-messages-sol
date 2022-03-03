// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @title A contract storing state on the current and next BEEFY authority set
 * @dev Stores the authority set as a Merkle root
 *  0  |   1   |    2   |  .. x   3 |     4
 *     [       )
 *  (current, next) = (0, 0) -> (0, 1) -> (1, 2) -> (2, 3)
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
    AuthoritySet public current;
    // next authority set
    AuthoritySet public next;

    function _updateCurrentAuthoritySet(AuthoritySet memory set) internal {
        current.id = set.id;
        current.len = set.len;
        current.root = set.root;
        emit BEEFYCurrentAuthoritySetUpdated(set.id, set.len, set.root);
    }

    function _updateNextAuthoritySet(AuthoritySet memory set) internal {
        next.id = set.id;
        next.len = set.len;
        next.root = set.root;
        emit BEEFYNextAuthoritySetUpdated(set.id, set.len, set.root);
    }
}
