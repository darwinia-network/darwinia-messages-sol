// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "./BasicMappingTokenFactory.sol";

contract Sub2SubMappingTokenFactory is BasicMappingTokenFactory {
    struct UnconfirmedInfo {
        address sender;
        address mapping_token;
        uint256 amount;
    }
    mapping(bytes => UnconfirmedInfo) public transferUnconfirmed;
    uint32 public message_pallet_index;
    bytes4 public lane_id;
    event IssuingMappingToken(bytes message_id, address mapping_token, address recipient, uint256 amount);
    event BurnAndWaitingConfirm(bytes message_id, address sender, bytes recipient, address token, uint256 amount);
    event RemoteUnlockConfirmed(bytes message_id, address sender, address token, uint256 amount, bool result);

    function setMessagePalletIndex(uint32 index) external onlyOwner {
        message_pallet_index = index;
    }

    function setLaneId(bytes4 laneid) external onlyOwner {
        lane_id = laneid;
    }

    function issueMappingToken(address mapping_token, address recipient, uint256 amount) public override {
        super.issueMappingToken(mapping_token, recipient, amount);
        (bool readSuccess, bytes memory message_id) = DISPATCH_ENCODER.call(
            abi.encodePacked(bytes4(keccak256("s2s_read_latest_recv_message_id()")),
                lane_id));
        require(readSuccess, "issuing: read s2s recv message id failed");
        emit IssuingMappingToken(message_id, mapping_token, recipient, amount);
    }

    // Step 1: User lock the mapped token to this contract and waiting the remote backing's unlock result.
    function burnAndRemoteUnlockWaitingConfirm(
        uint32 specVersion,
        uint64 weight,
        address mapping_token,
        bytes memory recipient,
        uint256 amount
    ) external payable whenNotPaused {
        require(amount > 0, "can not transfer amount zero");
        OriginalInfo memory info = mappingToken2OriginalInfo[mapping_token];
        require(info.original_token != address(0), "token is not created by factory");
        // Lock the fund in this before message on remote backing chain get dispatched successfully and burn finally
        // If remote backing chain unlock the origin token successfully, then this fund will be burned.
        // Otherwise, this fund will be transfered back to the msg.sender.
        require(IERC20(mapping_token).transferFrom(msg.sender, address(this), amount), "transfer token failed");

        (bool encodePayloadSuccess, bytes memory unlockMessage) = DISPATCH_ENCODER.call(
            abi.encodePacked(bytes4(keccak256("s2s_encode_remote_unlock_payload()")),
                abi.encode(specVersion,
                    weight,
                    info.tokenType,
                    info.original_token,
                    recipient, 
                    amount)));
        require(encodePayloadSuccess, "burn: encode remote unlock payload failed");

        // the pricision in contract is 18, and in pallet is 9, transform the fee value
        uint256 fee = msg.value/(10**9);
        (bool encodeSendMessageCall, bytes memory sendMessageCall) = DISPATCH_ENCODER.call(
            abi.encodePacked(bytes4(keccak256("s2s_encode_send_message_call()")),
                abi.encode(message_pallet_index, lane_id, unlockMessage, fee)));
        require(encodeSendMessageCall, "burn: encode send message call failed");

        // 1. send unlock message to remote backing across sub<>sub bridge
        (bool success, ) = DISPATCH.call(sendMessageCall);
        require(success, "burn: send unlock message failed");
        // 2. getting the messageid, saving and waiting confirm
        (bool readSuccess, bytes memory messageId) = DISPATCH_ENCODER.call(
            abi.encodePacked(bytes4(keccak256("s2s_read_latest_message_id()")),
                lane_id));
        require(readSuccess, "burn: read s2s message id failed");
        transferUnconfirmed[messageId] = UnconfirmedInfo(msg.sender, mapping_token, amount);
        emit BurnAndWaitingConfirm(messageId, msg.sender, recipient, mapping_token, amount);
    }

    // Step 2: The remote backing's unlock result comes. The result is true(success) or false(failure).
    // True:  if event is verified and the origin token unlocked successfully on remote chain, then we burn the mapped token
    // False: if event is verified, but the origin token unlocked on remote chain failed, then we take back the mapped token to user.
    function confirmBurnAndRemoteUnlock(bytes memory messageId, bool result) external onlySystem whenNotPaused {
        UnconfirmedInfo memory info = transferUnconfirmed[messageId];
        require(info.amount > 0 && info.sender != address(0) && info.mapping_token != address(0), "invalid unconfirmed message");
        if (result) {
            IERC20(info.mapping_token).burn(address(this), info.amount);
        } else {
            require(IERC20(info.mapping_token).transfer(info.sender, info.amount), "transfer back failed");
        }
        delete transferUnconfirmed[messageId];
        emit RemoteUnlockConfirmed(messageId, info.sender, info.mapping_token, info.amount, result);
    }
}
