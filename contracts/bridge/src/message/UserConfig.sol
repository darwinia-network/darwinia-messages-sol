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

import "../interfaces/IUserConfig.sol";

contract UserConfig {
    event SetDefaultConfigForChainId(uint32 indexed chainId, address relayer, address oracle, address verifier);
    event AppConfigUpdated(address indexed ua, uint32 indexed chainId, address relayer, address oracle, address verifier);

    // app address => chainId => config
    mapping(address => mapping(uint32 => Config)) public appConfig;
    // default UA settings if no version specified
    mapping(uint32 => Config) public defaultAppConfig;
    address public setter;

    modifier onlySetter {
        require(msg.sender == setter, "forbidden");
        _;
    }

    function changeSetter(address _setter) external onlySetter {
        setter = _setter;
    }

    constructor() {
        setter = msg.sender;
    }

    function setDefaultConfigForChainId(
        uint32 chainId,
        address relayer,
        address oracle,
        address verifier
    ) external onlySetter {
        defaultAppConfig[chainId] = Config(relayer, oracle, verifier);
        emit SetDefaultConfigForChainId(chainId, relayer, oracle, verifier);
    }

    // default to DEFAULT setting if ZERO value
    function getAppConfig(uint32 chainId, address ua) external view returns (Config memory) {
        Config memory c = appConfig[ua][chainId];
        Config memory defaultConfig = defaultAppConfig[chainId];

        if (c.relayer == address(0x0)) {
            c.relayer = defaultConfig.relayer;
        }

        if (c.oracle == address(0x0)) {
            c.oracle = defaultConfig.oracle;
        }

        if (c.verifier == address(0x0)) {
            c.verifier = defaultConfig.verifier;
        }

        return c;
    }

    function setAppConfig(
        uint32 chainId,
        address relayer,
        address oracle,
        address verifier
    ) external {
        appConfig[msg.sender][chainId] = Config(relayer, oracle, verifier);
        emit AppConfigUpdated(msg.sender, chainId, relayer, oracle, verifier);
    }
}
