// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
// SPDX-License-Identifier: GPL-3.0
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

import "../interfaces/IFeedOracle.sol";

contract Oracle {
    event Assigned(uint32 indexed index);
    event SetFee(uint32 indexed chainId, uint fee);

    address public immutable ENDPOINT;
    address public owner;

    // chainId => price
    mapping(uint32 => uint) public feeOf;
    // chainId => dapi
    mapping(uint32 => address) public dapiOf;

    modifier onlyOwner {
        require(msg.sender == owner, "!owner");
        _;
    }

    constructor(address endpoint) {
        ENDPOINT = endpoint;
        owner = msg.sender;
    }

    receive() external payable {}

    function withdraw(uint amount) external onlyOwner {
        payable(owner).transfer(amount);
    }

    function setFee(uint32 chainId, uint fee_) external onlyOwner {
        feeOf[chainId] = fee_;
        emit SetFee(chainId, fee_);
    }

    function fee(uint32 toChainId, address ua) public view returns (uint) {
        return feeOf[toChainId];
    }

    function assign(uint32 index, uint32 toChainId, address ua) external payable returns (uint) {
        require(msg.sender == ENDPOINT, "!enpoint");
        uint totalFee = feeOf[toChainId];
        require(msg.value == totalFee, "!fee");
        emit Assigned(index);
        return totalFee;
    }

    function merkle_root(uint32 chainId) external view returns (bytes32) {
        address dapi = dapiOf[chainId];
        (, bytes32 state_root) = IFeedOracle(dapi).latestAnswer();
        return state_root;
    }
}
