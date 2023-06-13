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

import "./RrpRequesterV0.sol";
import "../interfaces/IRequestOracle.sol";

contract AirnodeRrpRequester is IRequestOracle, RrpRequesterV0 {
    event AirnodeRrpRequested(uint64 indexed requestId, bytes32 indexed airnodeRequestId);
    event AirnodeRrpCompleted(uint64 indexed requestId, BlockData data);

    struct BlockData {
        uint256 blockNumber;
        bytes32 stateRoot;
    }

    uint64 public requestCount;
    mapping(bytes32 => uint64) public airnodeRequestIds;
    mapping(uint64 => BlockData) public fulfilledData;

    address public immutable AIRNODE;
    bytes32 public immutable ENDPOINTID;
    address public immutable SPONSOR;
    address payable public immutable SPONSOR_WALLET;

    uint256 public constant FEE = 2 * 10e18;

    constructor(
        address airnodeRrp,
        address airnode,
        bytes32 endpointId,
        address sponsor,
        address sponsorWallet
    ) RrpRequesterV0(airnodeRrp) {
        AIRNODE = airnode;
        ENDPOINTID = endpointId;
        SPONSOR = sponsor;
        SPONSOR_WALLET = payable(sponsorWallet);
    }

    function getLastRequestId() external view override returns (uint64) {
        return requestCount;
    }

    function getRequestFee() external pure override returns (address, uint256) {
        return (address(0), FEE);
    }
    function isRequestComplete(uint64 requestId) external view override returns (bool) {
        return fulfilledData[requestId].blockNumber > 0;
    }

    function dataOf(uint64 requestId) external view override returns (uint256, bytes32) {
        BlockData memory data = fulfilledData[requestId];
        return (data.blockNumber, data.stateRoot);
    }

    function requestFinalizedHash() external payable override returns (uint64 requestId) {
        require(msg.value == FEE, "!fee");
        SPONSOR_WALLET.transfer(FEE);
        requestId = _getNextRequestId();
        bytes32 oracleRequestId = airnodeRrp.makeFullRequest(
            AIRNODE,
            ENDPOINTID,
            SPONSOR,
            SPONSOR_WALLET,
            address(this),
            this.fulfill.selector,
            ""
        );
        airnodeRequestIds[oracleRequestId] = requestId;
        emit AirnodeRrpRequested(requestId, oracleRequestId);
    }

    function fulfill(
        bytes32 oracleRequestId,
        bytes calldata data
    ) external onlyAirnodeRrp {
        uint64 requestId = airnodeRequestIds[oracleRequestId];
        require(requestId > 0, "!requestId");
        delete airnodeRequestIds[oracleRequestId];
        BlockData memory decodedData = abi.decode(data, (BlockData));
        fulfilledData[requestId] = decodedData;
        emit AirnodeRrpCompleted(requestId, decodedData);
    }

    function _getNextRequestId() internal returns (uint64) {
      requestCount++;
      return requestCount;
    }
}
