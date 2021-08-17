// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "../binance/BasicChannel.sol";

contract DemoApp is BasicChannel {
    event Log(address from, address to, uint256 amount);

    constructor(address _inbound, address _outbound) public BasicChannel(_inbound, _outbound) {}

    function unlock(address origin, address recipient, uint256 amount) public onlyInbound filter(origin) {
        emit Log(origin, recipient, amount);
    }
}
