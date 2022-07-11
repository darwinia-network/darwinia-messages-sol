// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IEcho {
    function handleEcho(bytes memory _msg, address receivingContract) external;
    function receiveEcho(bytes memory _msg) external;
}