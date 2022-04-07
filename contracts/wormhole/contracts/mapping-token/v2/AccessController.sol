// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@zeppelin-solidity-4.4.0/contracts/access/AccessControlEnumerable.sol";
import "@zeppelin-solidity-4.4.0/contracts/security/Pausable.sol";

contract AccessController is AccessControlEnumerable, Pausable {
    bytes32 public constant DAO_ADMIN_ROLE = keccak256("DAO_ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE  = keccak256("OPERATOR_ROLE");
    bytes32 public constant APP_ROLE       = keccak256("APP_ROLE");

    // access controller
    // admin is helix Dao
    modifier onlyAdmin() {
        require(hasRole(DAO_ADMIN_ROLE, msg.sender), "AccessController:Bad admin role");
        _;
    }

    // operator
    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "AccessController:Bad operator role");
        _;
    }

    modifier onlyApp() {
        require(hasRole(APP_ROLE, msg.sender), "cBridgeMessageHandle:Bad app role");
        _;
    }

    function _initialize(address admin) internal {
        _setRoleAdmin(OPERATOR_ROLE, DAO_ADMIN_ROLE);
        _setRoleAdmin(DAO_ADMIN_ROLE, DAO_ADMIN_ROLE);
        _setupRole(DAO_ADMIN_ROLE, admin);
    }

    function unpause() external onlyOperator {
        _unpause();
    }

    function pause() external onlyOperator {
        _pause();
    }
}

