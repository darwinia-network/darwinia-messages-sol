// hevm: flattened sources of src/truth/arbitrum/ArbitrumFeedOracle.sol
// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.17;

////// src/interfaces/IFeedOracle.sol
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

interface IFeedOracle {
    function latestAnswer() external view returns (uint256 block_number, bytes32 state_root);
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

////// src/truth/common/FeedOracle.sol
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

/* import "../../interfaces/IFeedOracle.sol"; */

contract FeedOracle {
    IFeedOracle public oracle;

    constructor(address oracle_) {
        oracle = IFeedOracle(oracle_);
    }

    function _latest_block_number() internal view returns (uint256) {
        (uint256 block_number,) = oracle.latestAnswer();
        return block_number;
    }

    function _latest_state_root() internal view returns (bytes32) {
        (,bytes32 state_root) = oracle.latestAnswer();
        return state_root;
    }
}

////// src/truth/arbitrum/ArbitrumFeedOracle.sol
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
/* import "../common/FeedOracle.sol"; */

contract ArbitrumFeedOracle is ILightClient, FeedOracle {
    constructor(address oracle_) FeedOracle(oracle_) {}

    function block_number() public view override returns (uint256) {
        return _latest_block_number();
    }

    function merkle_root() public view override returns (bytes32) {
        return _latest_state_root();
    }
}

