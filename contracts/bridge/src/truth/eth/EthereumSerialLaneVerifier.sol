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

import "../common/SerialLaneStorageVerifier.sol";
import "../../spec/ChainMessagePosition.sol";
import "../../interfaces/ILightClient.sol";

contract EthereumSerialLaneVerifier is SerialLaneStorageVerifier {
    address public LIGHT_CLIENT;
    bool public changable;

    constructor(address lightclient) SerialLaneStorageVerifier(uint32(ChainMessagePosition.Ethereum), 1, 2) {
        LIGHT_CLIENT = lightclient;
        changable = true;
    }

    function state_root() public view override returns (bytes32) {
        return ILightClient(LIGHT_CLIENT).merkle_root();
    }

    function unchangable() onlySetter external {
        changable = false;
    }

    function changeLightClient(address new_lc) onlySetter external {
        require(changable == true, "!changable");
        LIGHT_CLIENT = new_lc;
    }
}
