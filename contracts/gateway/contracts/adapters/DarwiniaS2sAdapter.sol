// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/AbstractMessageAdapter.sol";
import "@darwinia/contracts-periphery/contracts/s2s/interfaces/IMessageEndpoint.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract DarwiniaS2sAdapter is AbstractMessageAdapter, Ownable2Step {
    address public immutable endpointAddress;
    uint32 public specVersion = 6021;
    uint256 public gasLimit = 3_000_000;

    constructor(address _endpointAddress) {
        endpointAddress = _endpointAddress;
    }

    function setSpecVersion(uint32 _specVersion) external onlyOwner {
        specVersion = _specVersion;
    }

    function setGasLimit(uint256 _gasLimit) external onlyOwner {
        gasLimit = _gasLimit;
    }

    function setRemoteAdapterAddress(
        address _remoteAdapterAddress
    ) external override onlyOwner {
        remoteAdapterAddress = _remoteAdapterAddress;
    }

    function remoteExecute(
        address remoteAddress,
        bytes memory callData
    ) internal override returns (uint256) {
        // check specVersion is set.
        require(specVersion != 0, "!specVersion");

        return
            IMessageEndpoint(endpointAddress).remoteExecute{value: msg.value}(
                specVersion,
                remoteAddress,
                callData,
                gasLimit
            );
    }

    function estimateFee() external view override returns (uint256) {
        return IMessageEndpoint(endpointAddress).fee();
    }
}
