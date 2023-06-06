// hevm: flattened sources of src/truth/arbitrum/ArbitrumRequestOracle.sol
// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.17;

////// src/interfaces/ILightClient.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.8.17; */

/// @title ILane
/// @notice A interface for light client
interface ILightClient {
    /// @notice Return the merkle root of light client
    /// @return merkle root
    function merkle_root() external view returns (bytes32);
    /// @notice Return the block number of light client
    /// @return block number
    function block_number() external view returns (uint256);
}

////// src/interfaces/IRequestOracle.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.8.17; */

interface IRequestOracle {
    function getLastRequestId() external view returns (uint64 requestId);
    function getRequestFee() external view returns (address feeToken, uint256 requestFee);
    function requestHash(uint256 block_number) external returns (uint64 requestId);
    function isRequestComplete(uint64 requestId) external view returns (bool isCompleted);
    function hashOf(uint64 requestId) external view returns (bytes32 hash);
}

////// src/truth/common/RequestOracle.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.8.17; */

/* import "../../interfaces/IRequestOracle.sol"; */

contract RequestOracle {
    event ImportStarted(uint64 indexed request_id);
    event ImportCancelled(uint64 indexed request_id);
    event ImportCompleted(uint64 indexed request_id);
    event StateRootImported(uint256 block_number, bytes32 state_root);

    IRequestOracle public oracle;
    mapping(address => OracleRequest) public requestOf;
    uint256 internal latest_block_number;
    bytes32 internal latest_state_root;

    uint64 constant internal TIMEOUT = 180;

    struct OracleRequest {
        uint64 id;
        uint64 at;
        uint64 block_number;
    }

    modifier canCompleteRequest() {
        require(is_oracle_requested(), "!requested");
        require(is_oracle_completed(), "!completed");
        _;
    }

    constructor(address oracle_) {
        oracle = IRequestOracle(oracle_);
    }

    function start_import(uint64 new_block_number) external {
        require(!is_oracle_requested(), "started");
        address relayer = msg.sender;
        require(new_block_number > latest_block_number, "!new");
        uint64 request_id = oracle.requestHash(new_block_number);
        requestOf[relayer] = OracleRequest(request_id, _current_time(), new_block_number);
        emit ImportStarted(request_id);
    }

    function cancel_import() external {
        require(is_oracle_timed_out(), "!time_out");
        address relayer = msg.sender;
        uint64 request_id = requestOf[relayer].id;
        delete requestOf[relayer];
        emit ImportCancelled(request_id);
    }

    function complete_import() external canCompleteRequest {
        address relayer = msg.sender;
        OracleRequest memory request = requestOf[relayer];
        uint64 request_id = request.id;
        bytes32 hash = oracle.hashOf(request_id);
        if (request.block_number > latest_block_number) {
            latest_block_number = request.block_number;
            latest_state_root = hash;
            emit StateRootImported(request.block_number, hash);
        }
        delete requestOf[relayer];
        emit ImportCompleted(request_id);
    }

    function is_oracle_completed() public view returns (bool) {
        uint64 request_id = requestOf[msg.sender].id;
        return oracle.isRequestComplete(request_id);
    }

    function is_oracle_requested() public view returns (bool) {
        return requestOf[msg.sender].id != 0;
    }

    function is_oracle_timed_out() public view returns (bool) {
        OracleRequest memory request = requestOf[msg.sender];
        if (request.at == 0) {
            return false;
        } else {
            return TIMEOUT + request.at < _current_time();
        }
    }

    function _current_time() internal view returns (uint64) {
        return uint64(block.timestamp);
    }
}

////// src/truth/arbitrum/ArbitrumRequestOracle.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
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

/* pragma solidity 0.8.17; */

/* import "../../interfaces/ILightClient.sol"; */
/* import "../common/RequestOracle.sol"; */

contract ArbitrumRequestOracle is ILightClient, RequestOracle {
    constructor(address oracle_) RequestOracle(oracle_) {}

    function block_number() public view override returns (uint256) {
        return latest_block_number;
    }

    function merkle_root() public view override returns (bytes32) {
        return latest_state_root;
    }
}

