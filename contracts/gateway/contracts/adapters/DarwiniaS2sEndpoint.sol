// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/AbstractMessageEndpoint.sol";
import "@darwinia/contracts-periphery/contracts/s2s/interfaces/IMessageEndpoint.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract DarwiniaS2sEndpoint is AbstractMessageEndpoint, Ownable2Step {
    address public remoteEndpointAddress;
    address public immutable darwiniaEndpointAddress;
    uint32 public specVersion = 6021;
    uint256 public gasLimit = 3_000_000;

    constructor(
        address gatewayAddress,
        address _darwiniaEndpointAddress
    ) AbstractMessageEndpoint(gatewayAddress) {
        darwiniaEndpointAddress = _darwiniaEndpointAddress;
    }

    function setRemoteEndpointAddress(
        address _remoteEndpointAddress
    ) external onlyOwner {
        remoteEndpointAddress = _remoteEndpointAddress;
    }

    function setSpecVersion(uint32 _specVersion) external onlyOwner {
        specVersion = _specVersion;
    }

    function setGasLimit(uint256 _gasLimit) external onlyOwner {
        gasLimit = _gasLimit;
    }

    function getRemoteEndpointAddress() public override returns (address) {
        return remoteEndpointAddress;
    }

    function remoteExecute(
        address _remoteAddress,
        bytes memory _remoteCallData
    ) internal override returns (uint256) {
        // check specVersion is set.
        require(specVersion != 0, "!specVersion");

        return
            IMessageEndpoint(darwiniaEndpointAddress).remoteExecute{
                value: msg.value
            }(specVersion, _remoteAddress, _remoteCallData, gasLimit);
    }

    function estimateFee() external view override returns (uint256) {
        return IMessageEndpoint(darwiniaEndpointAddress).fee();
    }
}
