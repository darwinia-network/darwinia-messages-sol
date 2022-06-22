// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@darwinia/contracts-utils/contracts/Scale.types.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../xapps/PangolinXApp.sol";
import "../../types/PalletEthereum.sol";

pragma experimental ABIEncoderV2;

interface IIssuing {
    function issueFromRemote(
        address mappedToken,
        address recipient,
        uint256 amount
    ) external;
}

contract Backing is PangolinXApp {
    constructor() {
        init();
    }

    struct LockedInfo {
        address token;
        address sender;
        uint256 amount;
    }

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
        
        // Lock `amount` of `token` on the source chain
        address token,
        // Remote issue `amount` of `mappedToken` to `recipient` on the target chain
        address issuingContractAddress,
        address mappedToken,
        address recipient,
        uint256 amount
    ) external payable {
        // 0. transfer msg.sender's amount to this contract address
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        // 1. prepare the call that will be executed on the target chain
        PalletEthereum.MessageTransactCall memory call = PalletEthereum.MessageTransactCall(
            // the call index of message_transact
            0x2901,
            // the evm transaction to transact
            PalletEthereum.buildTransactionV2ForMessageTransact(
                600000, // gas limit
                issuingContractAddress,
                abi.encodeWithSelector(
                    IIssuing.issueFromRemote.selector,
                    mappedToken,
                    recipient,
                    amount
                )
            )
        );
        bytes memory callEncoded = PalletEthereum.encodeMessageTransactCall(call);

        // 2. send the message
        uint64 messageNonce = sendMessage(
            toPangoro,
            laneId,
            MessagePayload(specVersion, weight, callEncoded)
        );

        // 3. record the lock info
        bytes memory messageId = abi.encode(laneId, messageNonce);
        lockMessages[messageId] = LockedInfo(token, msg.sender, amount);

        // 4. emit an event
        emit TokenLocked(laneId, messageNonce, token, recipient, amount);
    }
}
