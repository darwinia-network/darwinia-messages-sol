// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract SingletonLock {
    bool private singletonLock = false;

    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }
}
