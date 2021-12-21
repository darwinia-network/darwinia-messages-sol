// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
import "../interfaces/IMessageVerifier.sol";

contract MockMessageVerifier is IMessageVerifier {
    uint32 public immutable thisChainPosition;
    uint32 public immutable thisLanePosition;
    uint32 public immutable bridgedChainPosition;
    uint32 public immutable bridgedLanePosition;

    constructor(
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition
    ) {
        thisChainPosition = _thisChainPosition;
        thisLanePosition = _thisLanePosition;
        bridgedChainPosition = _bridgedChainPosition;
        bridgedLanePosition = _bridgedLanePosition;
    }
}
 
