// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../../xapps/PangolinXApp.sol";
import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@darwinia/contracts-utils/contracts/SafeMath.sol";
import "../../interfaces/IERC20.sol";
import "../../types/PalletEthereum.sol";

pragma experimental ABIEncoderV2;

interface IIssuing {
    function issueFromRemote(
        address token,
        address recipient,
        uint256 amount
    ) external;
}

contract Backing is PangolinXApp {
    constructor() public {
        init();
    }

    using SafeMath for uint256;

    struct LockedInfo {
        address token;
        address sender;
        uint256 amount;
    }

    // token => IsRegistered
    mapping(address => bool) public registeredTokens;

    // (messageId => lockedInfo)
    mapping(bytes => LockedInfo) public lockMessages;

    event TokenLocked(
        bytes4 laneId,
        uint64 nonce,
        address token,
        address recipient,
        uint256 amount
    );

    function lockAndRemoteIssue(
        uint32 specVersion,
        uint64 weight,
        bytes4 laneId,
        address token,
        address recipient,
        uint256 amount
    ) external payable {
        // 0. balance check
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "Backing:transfer tokens failed"
        );

        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        require(
            balanceBefore.add(amount) == balanceAfter,
            "Backing:Transfer amount is invalid"
        );

        // 1. prepare the call that will be executed on the target chain
        PalletEthereum.TransactCall memory call = PalletEthereum.TransactCall(
            // the call index of substrate_transact
            0x2902,
            // the evm transaction to transact
            PalletEthereum.buildTransactionV2(
                0,
                1000000000,
                600000,
                0x50275d3F95E0F2FCb2cAb2Ec7A231aE188d7319d,
                0,
                // issueFromRemote
                abi.encodeWithSelector(
                    IIssuing.issueFromRemote.selector,
                    token,
                    recipient,
                    amount
                )
            )
        );
        bytes memory callEncoded = PalletEthereum.encodeTransactCall(call);

        // 2. send the message
        uint64 nonce = sendMessage(
            toPangoro,
            laneId,
            MessagePayload(specVersion, weight, callEncoded)
        );

        // 3.
        bytes memory messageId = abi.encode(laneId, nonce);
        lockMessages[messageId] = LockedInfo(token, msg.sender, amount);

        // 4.
        emit TokenLocked(laneId, nonce, token, recipient, amount);
    }
}
