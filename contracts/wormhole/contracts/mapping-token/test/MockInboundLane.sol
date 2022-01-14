// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
import "./MockMessageVerifier.sol";
import "../interfaces/ICrossChainFilter.sol";
import "hardhat/console.sol";

contract MockInboundLane is MockMessageVerifier {
    constructor(
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition
    ) MockMessageVerifier(
        _thisChainPosition,
        _thisLanePosition,
        _bridgedChainPosition,
        _bridgedLanePosition
    ) {
    }

    function mock_dispatch(address sender, address targetContract, bytes calldata encoded) external returns(bool) {
        if (targetContract == address(0)) {
            return false;
        }
        bool filter = ICrossChainFilter(targetContract).crossChainFilter(bridgedChainPosition, bridgedLanePosition, sender, encoded);
        console.log("inbound filter return %s", filter);

        if (filter) {
            (bool result, ) = targetContract.call(encoded);
            console.log("inbound call return %s, target %s", result, targetContract);
            return result;
        }
        return false;
    }
}
 
