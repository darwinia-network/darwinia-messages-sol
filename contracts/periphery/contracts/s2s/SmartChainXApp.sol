// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./SmartChainXLib.sol";

abstract contract SmartChainXApp {
    mapping(uint32 => SmartChainXLib.LaneIndex) lanes;

    function sendMessage(
        uint32 lanePosition,
        uint256 deliveryAndDispatchFee,
        uint32 specVersionOfTargetChain,
        uint64 callWeight,
        bytes memory callEncoded
    ) internal {
        bytes memory message = SmartChainXLib.buildMessage(
            specVersionOfTargetChain,
            callWeight,
            callEncoded
        );
        SmartChainXLib.sendMessage(
            lanes[lanePosition],
            deliveryAndDispatchFee,
            message
        );
    }

    function setLane(
        uint32 lanePosition,
        bytes2 sendMessageCallIndexAtSourceChain,
        bytes4 laneId
    ) public {
        SmartChainXLib.LaneIndex memory laneIndex = SmartChainXLib.LaneIndex(
            sendMessageCallIndexAtSourceChain,
            laneId
        );
        lanes[lanePosition] = laneIndex;
    }
}
