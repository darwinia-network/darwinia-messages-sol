// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IWETH.sol";
import { ScaleStruct } from "./common/Scale.struct.sol";

pragma experimental ABIEncoderV2;

interface IBacking {
    function crossChainSync(
        bytes memory message,
        bytes[] memory signatures,
        bytes32 root,
        uint32 MMRIndex,
        bytes memory blockHeader,
        bytes32[] memory peaks,
        bytes32[] memory siblings,
        bytes memory eventsProofStr
    ) external returns(ScaleStruct.IssuingEvent[] memory);
    function crossSendToken(
        address token,
        address recipient,
        uint256 amount) external;
}

contract BackingHelper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public weth;
    address public backing;

    event RedeemTokenEvent(address token, address recipient, uint256 value);

    constructor (address _weth, address _backing) public {
        weth = _weth;
        backing = _backing;
    }

    receive() external payable {
        assert(msg.sender == weth);
    }

    function crossSendETH(address recipient) external payable {
        require(msg.value > 0, "balance cannot be zero");
        IWETH(weth).deposit{value: msg.value}();
        IBacking(backing).crossSendToken(weth, recipient, msg.value);
    }

    function redeem(
        bytes memory message,
        bytes[] memory signatures,
        bytes32 root,
        uint32 MMRIndex,
        bytes memory blockHeader,
        bytes32[] memory peaks,
        bytes32[] memory siblings,
        bytes memory eventsProofStr
    ) external {
        ScaleStruct.IssuingEvent[] memory events = IBacking(backing).crossChainSync(
            message,
            signatures,
            root,
            MMRIndex,
            blockHeader,
            peaks,
            siblings,
            eventsProofStr);
        uint256 len = events.length;
        for( uint i = 0; i < len; i++) {
            ScaleStruct.IssuingEvent memory item = events[i];
            if (item.eventType == 1 && item.delegator == address(this)) {
                if (item.token == weth) {
                    IWETH(weth).withdraw(item.value);
                    item.recipient.transfer(item.value);
                } else {
                    IERC20(item.token).safeTransfer(item.recipient, item.value);
                }
                emit RedeemTokenEvent(item.token, item.recipient, item.value);
            }
        }
    }
}
 
