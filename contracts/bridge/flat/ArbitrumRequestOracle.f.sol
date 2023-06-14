// hevm: flattened sources of src/truth/arbitrum/ArbitrumRequestOracle.sol
// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.17;

////// src/interfaces/IERC20.sol
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

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

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
    function requestFinalizedHash() external payable returns (uint64 requestId);
    function isRequestComplete(uint64 requestId) external view returns (bool isCompleted);
    function dataOf(uint64 requestId) external view returns (uint256 blockNumber, bytes32 hash);
}

////// src/utils/TransferHelper.sol
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

/* import "../interfaces/IERC20.sol"; */

library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(
            IERC20.transfer.selector,
            to,
            value
        ));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            from,
            to,
            value
        ));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }
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
/* import "../../utils/TransferHelper.sol"; */

contract RequestOracle {
    using TransferHelper for address;

    event ImportStarted(uint64 indexed request_id);
    event ImportCancelled(uint64 indexed request_id);
    event ImportCompleted(uint64 indexed request_id);
    event StateRootImported(uint256 block_number, bytes32 state_root);

    IRequestOracle public oracle;
    mapping(address => OracleRequest) public requestOf;
    uint256 internal latest_block_number;
    bytes32 internal latest_state_root;

    uint64  internal immutable TIMEOUT;

    struct OracleRequest {
        uint64 id;
        uint64 at;
    }

    modifier canCompleteRequest() {
        require(isOracleRequested(), "!requested");
        require(isOracleCompleted(), "!completed");
        _;
    }

    constructor(address oracle_, uint64 timeout_) {
        oracle = IRequestOracle(oracle_);
        TIMEOUT = timeout_;
    }

    function startImport() external returns (uint64 request_id) {
        require(!isOracleRequested(), "started");
        address relayer = msg.sender;
        (address feeToken, uint256 requestFee) = oracle.getRequestFee();
        if (feeToken == address(0)) {
            request_id = oracle.requestFinalizedHash{value: requestFee}();
        } else {
            feeToken.safeTransferFrom(relayer, address(oracle), requestFee);
            request_id = oracle.requestFinalizedHash();
        }
        requestOf[relayer] = OracleRequest(request_id, _currentTime());
        emit ImportStarted(request_id);
    }

    function cancelImport() external {
        require(isOracleTimedOut(), "!time_out");
        address relayer = msg.sender;
        uint64 request_id = requestOf[relayer].id;
        delete requestOf[relayer];
        emit ImportCancelled(request_id);
    }

    function completeImport() external canCompleteRequest {
        address relayer = msg.sender;
        OracleRequest memory request = requestOf[relayer];
        uint64 request_id = request.id;
        (uint256 block_number, bytes32 hash) = oracle.dataOf(request_id);
        if (block_number > latest_block_number) {
            latest_block_number = block_number;
            latest_state_root = hash;
            emit StateRootImported(block_number, hash);
        }
        delete requestOf[relayer];
        emit ImportCompleted(request_id);
    }

    function isOracleCompleted() public view returns (bool) {
        uint64 request_id = requestOf[msg.sender].id;
        return oracle.isRequestComplete(request_id);
    }

    function isOracleRequested() public view returns (bool) {
        return requestOf[msg.sender].id != 0;
    }

    function isOracleTimedOut() public view returns (bool) {
        OracleRequest memory request = requestOf[msg.sender];
        if (request.at == 0) {
            return false;
        } else {
            return TIMEOUT + request.at < _currentTime();
        }
    }

    function _currentTime() internal view returns (uint64) {
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
    constructor(address oracle_) RequestOracle(oracle_, 180) {}

    function block_number() public view override returns (uint256) {
        return latest_block_number;
    }

    function merkle_root() public view override returns (bytes32) {
        return latest_state_root;
    }
}

