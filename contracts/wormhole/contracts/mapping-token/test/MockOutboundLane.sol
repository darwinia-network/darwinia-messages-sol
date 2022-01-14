// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
import "./MockMessageVerifier.sol";
import "./MockInboundLane.sol";
import "../interfaces/IOnMessageDelivered.sol";

contract MockOutboundLane is MockMessageVerifier {
    struct ConfirmInfo {
        address sender;
        bool result;
    }
    address remoteInboundLane;
    uint64 public nonce = 0;
    mapping(uint64 => ConfirmInfo) responses;
    constructor(
        uint32 _thisChainPosition,
        uint32 _thisLanePosition,
        uint32 _bridgedChainPosition,
        uint32 _bridgedLanePosition,
        address _remoteInboundLane
    ) MockMessageVerifier(
        _thisChainPosition,
        _thisLanePosition,
        _bridgedChainPosition,
        _bridgedLanePosition
    ) {
        remoteInboundLane = _remoteInboundLane;
    }

    function send_message(address targetContract, bytes calldata encoded) external payable returns (uint256) {
        // call target contract
        bool result = MockInboundLane(remoteInboundLane).mock_dispatch(msg.sender, targetContract, encoded);
        nonce += 1;
        responses[nonce] = ConfirmInfo(msg.sender, result);
        return encodeMessageKey(nonce);
    }

    function mock_confirm(uint64 _nonce) external {
        ConfirmInfo memory info = responses[_nonce];
        uint256 messageId = encodeMessageKey(_nonce);
        IOnMessageDelivered(info.sender).on_messages_delivered(messageId, info.result);
        delete responses[_nonce];
    }
}
 
