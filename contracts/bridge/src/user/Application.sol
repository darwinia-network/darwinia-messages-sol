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

abstract contract Application {
    address public immutable TRUSTED_ENDPOINT;

    constructor(address endpoint) {
        TRUSTED_ENDPOINT = endpoint;
    }

    function isTrustedEndpoint(address endpoint) public view returns(bool) {
        return TRUSTED_ENDPOINT == endpoint;
    }

    function _messageId() internal pure returns (bytes32 _msgDataMessageId) {
      require(msg.data.length >= 84, "!message_id");
      assembly {
        _msgDataMessageId := calldataload(sub(calldatasize(), 84))
      }
    }

    function _fromChainId() internal pure returns (uint256 _msgDataFromChainId) {
      require(msg.data.length >= 52, "!from_chain_id");
      assembly {
        _msgDataFromChainId := calldataload(sub(calldatasize(), 52))
      }
    }

    function _xmsgSender() internal view returns (address payable _from) {
      require(msg.data.length >= 20 && isTrustedEndpoint(msg.sender));
      assembly {
        _from := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    }
}
